# Install WSL (Windows Subsystem for Linux) and WSL2
# This script enables WSL, installs WSL2, and sets up a default Linux distribution

param(
    [string]$Distribution = "Ubuntu",
    [switch]$WSL2Only = $false,
    [switch]$Silent = $false
)

Write-Host "WSL/WSL2 Installation Script" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

# Check Windows version compatibility
$windowsVersion = [System.Environment]::OSVersion.Version
if ($windowsVersion.Major -lt 10 -or ($windowsVersion.Major -eq 10 -and $windowsVersion.Build -lt 18362)) {
    Write-Host "WSL2 requires Windows 10 version 1903 (build 18362) or higher." -ForegroundColor Red
    Write-Host "Current version: $($windowsVersion)" -ForegroundColor Yellow
    exit 1
}

# Check if WSL is already installed
$wslInstalled = Get-Command wsl -ErrorAction SilentlyContinue
if ($wslInstalled) {
    Write-Host "WSL is already installed. Current version:" -ForegroundColor Yellow
    wsl --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "WSL2 is available." -ForegroundColor Green
    }
    
    if (-not $Silent) {
        $continue = Read-Host "Continue with setup? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 0
        }
    }
}

# Enable WSL feature
Write-Host "Enabling Windows Subsystem for Linux..." -ForegroundColor Yellow
try {
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to enable WSL feature"
    }
    Write-Host "WSL feature enabled successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to enable WSL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Enable Virtual Machine Platform for WSL2
if (-not $WSL2Only) {
    Write-Host "Enabling Virtual Machine Platform for WSL2..." -ForegroundColor Yellow
    try {
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to enable Virtual Machine Platform"
        }
        Write-Host "Virtual Machine Platform enabled successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to enable Virtual Machine Platform: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "WSL will be available, but WSL2 may not work properly." -ForegroundColor Yellow
    }
}

# Download and install WSL2 Linux kernel update
Write-Host "Downloading WSL2 Linux kernel update..." -ForegroundColor Yellow
$kernelUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$kernelUpdatePath = "$env:TEMP\wsl_update_x64.msi"

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $kernelUpdateUrl -OutFile $kernelUpdatePath -UseBasicParsing
    
    Write-Host "Installing WSL2 kernel update..." -ForegroundColor Yellow
    Start-Process msiexec.exe -ArgumentList "/i", $kernelUpdatePath, "/quiet" -Wait
    
    Write-Host "WSL2 kernel update installed successfully." -ForegroundColor Green
    Remove-Item $kernelUpdatePath -Force
} catch {
    Write-Host "Warning: Could not install WSL2 kernel update: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "You may need to install it manually later." -ForegroundColor Yellow
}

# Install WSL if not already available
if (-not $wslInstalled) {
    Write-Host "Installing WSL..." -ForegroundColor Yellow
    try {
        wsl --install --no-launch
        Write-Host "WSL installation initiated." -ForegroundColor Green
    } catch {
        Write-Host "Failed to install WSL via wsl --install. Trying alternative method..." -ForegroundColor Yellow
        
        # Alternative: Install via Microsoft Store (requires manual intervention)
        Write-Host "Please install a Linux distribution from Microsoft Store after restart." -ForegroundColor Cyan
    }
}

# Set WSL2 as default version
Write-Host "Setting WSL2 as default version..." -ForegroundColor Yellow
try {
    wsl --set-default-version 2
    Write-Host "WSL2 set as default version." -ForegroundColor Green
} catch {
    Write-Host "Could not set WSL2 as default. This will be available after restart." -ForegroundColor Yellow
}

# Install default distribution
if ($Distribution) {
    Write-Host "Installing $Distribution distribution..." -ForegroundColor Yellow
    try {
        wsl --install -d $Distribution --no-launch
        Write-Host "$Distribution installation initiated." -ForegroundColor Green
    } catch {
        Write-Host "Could not auto-install $Distribution. You can install it manually after restart." -ForegroundColor Yellow
    }
}

Write-Host "`nWSL/WSL2 installation completed!" -ForegroundColor Green
Write-Host "IMPORTANT: A system restart is required to complete the installation." -ForegroundColor Red
Write-Host "`nAfter restart:" -ForegroundColor Cyan
Write-Host "  1. WSL and WSL2 will be available" -ForegroundColor White
Write-Host "  2. Run 'wsl --list --online' to see available distributions" -ForegroundColor White
Write-Host "  3. Run 'wsl --install -d <DistroName>' to install a specific distribution" -ForegroundColor White
Write-Host "  4. Run 'wsl' to start your default Linux environment" -ForegroundColor White

# Usage examples
Write-Host "`nUsage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-wsl.ps1                          # Install WSL2 with Ubuntu"
Write-Host "  .\install-wsl.ps1 -Distribution Debian     # Install WSL2 with Debian"
Write-Host "  .\install-wsl.ps1 -WSL2Only                # Skip WSL1, install WSL2 only"
Write-Host "  .\install-wsl.ps1 -Silent                  # Silent installation"