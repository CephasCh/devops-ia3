# DevOps IA3 - one-click Azure setup.
# Creates the SSH key, signs in to Azure, fills terraform.tfvars, runs Terraform,
# and writes the VM's public IP into the Jenkinsfile.

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$tf   = Join-Path $root "terraform"
$key  = Join-Path $HOME ".ssh\devops_ia3"

function Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

# Make sure newly installed tools are on PATH
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

Step "1/5 SSH key"
if (Test-Path $key) {
    Write-Host "Key already exists: $key"
} else {
    New-Item -ItemType Directory -Force -Path (Split-Path $key) | Out-Null
    cmd /c "ssh-keygen -t rsa -b 4096 -q -f `"$key`" -N `"`""
    if (-not (Test-Path "$key.pub")) { throw "ssh-keygen failed" }
    Write-Host "Created $key and $key.pub" -ForegroundColor Green
}

Step "2/5 Azure sign-in"
$sub = $null; try { $sub = az account show --query id -o tsv 2>$null } catch { }
if (-not $sub) {
    Write-Host "A browser window will open - sign in with your Azure account." -ForegroundColor Yellow
    az login | Out-Null
    $sub = az account show --query id -o tsv
}
if (-not $sub) { throw "Could not get an Azure subscription. Check that your account has an active subscription (e.g. Azure for Students)." }
$name = az account show --query name -o tsv
Write-Host "Using subscription: $name ($sub)" -ForegroundColor Green

Step "Registering Azure services (Compute, Network)"
foreach ($ns in @("Microsoft.Compute", "Microsoft.Network")) {
    for ($try = 1; $try -le 3; $try++) {
        az provider register --namespace $ns --wait
        if ($LASTEXITCODE -eq 0) { Write-Host "$ns registered" -ForegroundColor Green; break }
        Write-Host "Retrying $ns ($try/3)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
}

Step "3/5 terraform.tfvars"
$tfvars = Join-Path $tf "terraform.tfvars"
$extra = ""
if (Test-Path $tfvars) {
    # keep any overrides (vm_size, location) the user added
    $extra = (Get-Content $tfvars | Where-Object { $_ -notmatch '^\s*subscription_id' }) -join "`n"
}
Set-Content -Path $tfvars -Encoding ascii -Value ("subscription_id = `"$sub`"`n" + $extra)
Write-Host "Wrote $tfvars" -ForegroundColor Green

Step "4/5 Terraform init / validate / apply"
Push-Location $tf
try {
    terraform init -input=false
    if ($LASTEXITCODE -ne 0) { throw "terraform init failed" }
    terraform validate
    if ($LASTEXITCODE -ne 0) { throw "terraform validate failed" }
    # Azure often has no capacity for the smallest sizes, so try several until one works
    $sizes = @("Standard_B2s", "Standard_B2ats_v2", "Standard_B2als_v2", "Standard_D2s_v3", "Standard_D2as_v5", "Standard_B1ms")
    $ok = $false
    foreach ($size in $sizes) {
        Write-Host "`n--- Trying VM size $size ---" -ForegroundColor Cyan
        $log = Join-Path $env:TEMP "tf-apply.log"
        $ErrorActionPreference = "Continue"
        terraform apply -auto-approve -input=false -parallelism=3 -var "vm_size=$size" 2>&1 | ForEach-Object { "$_" } | Tee-Object -FilePath $log
        $code = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($code -eq 0) { $ok = $true; Write-Host "VM created with size $size" -ForegroundColor Green; break }
        $text = Get-Content $log -Raw
        if ($text -notmatch "SkuNotAvailable|Capacity|QuotaExceeded|not available") {
            throw "terraform apply failed (not a VM-size problem - see the error above)"
        }
        Write-Host "$size not available right now, trying the next size..." -ForegroundColor Yellow
    }
    if (-not $ok) { throw "No VM size was available in this region. Add  location = `"South India`"  to terraform\terraform.tfvars and run again." }
    $ip = (terraform output -raw public_ip).Trim()
} finally {
    Pop-Location
}

Step "5/5 Update Jenkinsfile with VM IP"
$jf = Join-Path $root "Jenkinsfile"
(Get-Content $jf -Raw) -replace "VM_IP\s*=\s*'[^']*'", "VM_IP    = '$ip'" | Set-Content -Path $jf -Encoding ascii -NoNewline
Write-Host "Jenkinsfile now deploys to $ip" -ForegroundColor Green

Write-Host "`nWaiting for nginx to come up on the VM..."
for ($i = 0; $i -lt 20; $i++) {
    try {
        $r = Invoke-WebRequest -Uri "http://$ip" -UseBasicParsing -TimeoutSec 5
        if ($r.StatusCode -eq 200) { Write-Host "Website is UP: http://$ip" -ForegroundColor Green; break }
    } catch { Start-Sleep -Seconds 10 }
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host " DONE.  Public IP: $ip"                              -ForegroundColor Green
Write-Host " Open http://$ip in your browser."                   -ForegroundColor Green
Write-Host " Take a screenshot of this window for your report."  -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
