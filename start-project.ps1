# DevOps IA3 - start everything after a laptop restart.
# 1) makes sure the Azure VM is running, 2) starts Jenkins on http://localhost:8080

$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "=== Azure VM ===" -ForegroundColor Cyan
$state = az vm get-instance-view -g devopsia3-rg -n devopsia3-vm --query "instanceView.statuses[1].displayStatus" -o tsv 2>$null
if (-not $state) {
    Write-Host "Could not read the VM. Run 'az login' first (or the VM was destroyed - re-run setup-azure.ps1)." -ForegroundColor Yellow
} elseif ($state -ne "VM running") {
    Write-Host "VM is '$state' - starting it (about 1 minute)..."
    az vm start -g devopsia3-rg -n devopsia3-vm | Out-Null
    Write-Host "VM started." -ForegroundColor Green
} else {
    Write-Host "VM is already running." -ForegroundColor Green
}
$ip = az network public-ip show -g devopsia3-rg -n devopsia3-pip --query ipAddress -o tsv 2>$null
if ($ip) { Write-Host "Website: http://$ip" -ForegroundColor Green }

Write-Host "`n=== Jenkins ===" -ForegroundColor Cyan
$jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -Filter "jdk-21*" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $jdk) { Write-Host "Java 21 not found. Install it: winget install EclipseAdoptium.Temurin.21.JDK" -ForegroundColor Red; exit 1 }
$war = Join-Path $HOME "jenkins\jenkins.war"
if (-not (Test-Path $war)) { Write-Host "Jenkins not found at $war" -ForegroundColor Red; exit 1 }

Write-Host "Starting Jenkins - open http://localhost:8080 once you see 'fully up and running'."
Write-Host "Keep this window open; closing it stops Jenkins.`n" -ForegroundColor Yellow
& (Join-Path $jdk.FullName "bin\java.exe") -jar $war --httpPort=8080
