# Install Docker Desktop for Windows
# This script downloads and installs Docker Desktop silently
# Enhanced with comprehensive software verification system

# Import the software verification module
$modulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "modules\SoftwareVerification.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Warning "Software verification module not found. Using basic verification."
}

param(
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$VerifyOnly = $false,
    [switch]$Detailed = $false
)

function Test-DockerInstallation {
    <#
    .SYNOPSIS
    Enhanced function to verify Docker installation with detailed information.
    
    .DESCRIPTION
    Uses the SoftwareVerification module for comprehensive verification, falls back to basic checks if unavailable.
    #>
    param(
        [switch]$Detailed
    )
    
    # Try to use the verification module first
    if (Get-Command Test-PredefinedSoftware -ErrorAction SilentlyContinue) {
        try {
            $result = Test-PredefinedSoftware -SoftwareName "Docker" -Detailed:$Detailed
            return $result
        } catch {
            Write-Warning "Verification module failed for Docker. Using fallback method."
        }
    }
    
    # Fallback to basic verification
    $isInstalled = $false
    $version = "Unknown"
    $paths = @()
    
    $dockerCommand = Get-Command docker -ErrorAction SilentlyContinue
    $dockerDesktopPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
    
    if ($dockerCommand) {
        $isInstalled = $true
        $paths += $dockerCommand.Source
        if (Test-Path $dockerDesktopPath) {
            $paths += $dockerDesktopPath
        }
        try {
            $dockerVersion = & docker --version 2>$null
            if ($dockerVersion) {
                $version = $dockerVersion
            }
        } catch {
            $version = "Unknown"
        }
    }
    
    return @{
        IsInstalled = $isInstalled
        Version = $version
        Paths = $paths
        Status = if ($isInstalled) { "Installed" } else { "Not Installed" }
    }
}

Write-Host "Docker Desktop Installation Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Handle verification-only mode
if ($VerifyOnly) {
    Write-Host "Verifying Docker installation..." -ForegroundColor Yellow
    $verificationResult = Test-DockerInstallation -Detailed:$Detailed
    
    if ($verificationResult.IsInstalled) {
        Write-Host "[OK] Docker is installed" -ForegroundColor Green
        Write-Host "Version: $($verificationResult.Version)" -ForegroundColor Cyan
        if ($Detailed -and $verificationResult.Paths) {
            Write-Host "Installation Path(s):" -ForegroundColor Cyan
            $verificationResult.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        }
    } else {
        Write-Host "[ERROR] Docker is not installed" -ForegroundColor Red
    }
    exit 0
}

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

# Check if Docker is already installed
$dockerVerification = Test-DockerInstallation -Detailed:$Detailed
if ($dockerVerification.IsInstalled -and -not $Force) {
    Write-Host "Docker is already installed: $($dockerVerification.Version)" -ForegroundColor Yellow
    if ($Detailed -and $dockerVerification.Paths) {
        Write-Host "Installation Path(s):" -ForegroundColor Cyan
        $dockerVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    }
    Write-Host "Use -Force to reinstall." -ForegroundColor Cyan
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

# Verify installation using enhanced verification
Write-Host "Verifying Docker installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$postInstallVerification = Test-DockerInstallation -Detailed:$Detailed

if ($postInstallVerification.IsInstalled) {
    Write-Host "[OK] Docker installation verified successfully!" -ForegroundColor Green
    Write-Host "Version: $($postInstallVerification.Version)" -ForegroundColor Cyan
    if ($Detailed -and $postInstallVerification.Paths) {
        Write-Host "Installation Path(s):" -ForegroundColor Cyan
        $postInstallVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    }
} else {
    Write-Host "[WARNING] Docker installation verification failed." -ForegroundColor Yellow
    Write-Host "A system restart may be required for Docker to function properly." -ForegroundColor Yellow
}

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
Write-Host "  .\install-docker.ps1                      # Interactive installation"
Write-Host "  .\install-docker.ps1 -Silent              # Silent installation"
Write-Host "  .\install-docker.ps1 -Force               # Force reinstall"
Write-Host "  .\install-docker.ps1 -VerifyOnly          # Verify installation only"
Write-Host "  .\install-docker.ps1 -VerifyOnly -Detailed # Detailed verification"