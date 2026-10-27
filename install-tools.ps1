# DevOps IA3 - installs Git, Azure CLI, Terraform, Java 17 and Jenkins using winget.
# Run from an ADMINISTRATOR PowerShell window.

$ErrorActionPreference = "Continue"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script from PowerShell opened with 'Run as administrator'." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Red
    exit 1
}

# Java must be installed before Jenkins
$packages = @(
    @{ Id = "Git.Git";                        Name = "Git" },
    @{ Id = "Microsoft.AzureCLI";             Name = "Azure CLI" },
    @{ Id = "Hashicorp.Terraform";            Name = "Terraform" },
    @{ Id = "EclipseAdoptium.Temurin.17.JDK"; Name = "Java 17 (Temurin JDK)" },
    @{ Id = "Jenkins.Jenkins";                Name = "Jenkins LTS" }
)

foreach ($p in $packages) {
    Write-Host "`n=== Installing $($p.Name) ===" -ForegroundColor Cyan
    winget install --id $p.Id --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$($p.Name): installed" -ForegroundColor Green
    } else {
        Write-Host "$($p.Name): winget exit code $LASTEXITCODE (may already be installed)" -ForegroundColor Yellow
    }
}

# Reload PATH so the new tools are visible in this window
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "`n=== Versions ===" -ForegroundColor Cyan
git --version
az --version | Select-Object -First 1
terraform -version | Select-Object -First 1
java -version 2>&1 | Select-Object -First 1

Write-Host "`n=== Jenkins ===" -ForegroundColor Cyan
Get-Service -Name Jenkins -ErrorAction SilentlyContinue | Format-Table Name, Status -AutoSize
$pw = "C:\ProgramData\Jenkins\.jenkins\secrets\initialAdminPassword"
if (Test-Path $pw) {
    Write-Host "Jenkins is at http://localhost:8080"
    Write-Host "Initial admin password: $(Get-Content $pw)" -ForegroundColor Green
} else {
    Write-Host "Jenkins password file not found yet - wait a minute, then open http://localhost:8080 and follow the path it shows."
}

Write-Host "`nDone. Close this window and open a NEW PowerShell before using the tools." -ForegroundColor Green
