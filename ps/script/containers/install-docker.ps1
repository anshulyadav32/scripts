# Install Docker Desktop for Windows
# This script downloads and installs Docker Desktop silently

param(
    [switch]$Silent = $false,
    [switch]$Force = $false
)

Write-Host "Docker Desktop Installation Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

# Check if Docker is already installed
$dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerInstalled -and -not $Force) {
    Write-Host "Docker is already installed. Use -Force to reinstall." -ForegroundColor Yellow
    docker --version
    exit 0
}

# Enable required Windows features for Docker
Write-Host "Enabling Windows features required for Docker..." -ForegroundColor Yellow
try {
    Enable-WindowsOptionalFeature -Online -FeatureName containers-DisposableClientVM -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
} catch {
    Write-Host "Warning: Could not enable some Windows features. Docker may require manual feature configuration." -ForegroundColor Yellow
}

# Download Docker Desktop
$dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$tempPath = "$env:TEMP\DockerDesktopInstaller.exe"

Write-Host "Downloading Docker Desktop..." -ForegroundColor Yellow
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $dockerUrl -OutFile $tempPath -UseBasicParsing
    Write-Host "Download completed successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to download Docker Desktop: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Install Docker Desktop
Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
try {
    if ($Silent) {
        $installArgs = "install --quiet --accept-license"
    } else {
        $installArgs = "install --accept-license"
    }
    
    $process = Start-Process -FilePath $tempPath -ArgumentList $installArgs -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Docker Desktop installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Docker Desktop installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Failed to install Docker Desktop: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Clean up downloaded installer
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force
    }
}

# Verify installation
Write-Host "Verifying Docker installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check if Docker service is available (may need restart)
$dockerService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
if ($dockerService) {
    Write-Host "Docker service found: $($dockerService.Status)" -ForegroundColor Green
} else {
    Write-Host "Docker service not found. A system restart may be required." -ForegroundColor Yellow
}

Write-Host "`nDocker Desktop installation completed!" -ForegroundColor Green
Write-Host "Note: You may need to restart your computer and start Docker Desktop manually." -ForegroundColor Yellow
Write-Host "After restart, Docker Desktop should be available in your Start Menu." -ForegroundColor Cyan

# Usage examples
Write-Host "`nUsage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-docker.ps1                 # Interactive installation"
Write-Host "  .\install-docker.ps1 -Silent         # Silent installation"
Write-Host "  .\install-docker.ps1 -Force          # Force reinstall"
Write-Host "  .\install-docker.ps1 -Silent -Force  # Silent force reinstall"