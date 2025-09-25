# Install Git for Windows
# This script downloads and installs Git with common developer configurations
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
    [string]$UserName = "",
    [string]$UserEmail = "",
    [string]$DefaultBranch = "main",
    [switch]$VerifyOnly = $false,
    [switch]$Detailed = $false
)

function Test-GitInstallation {
    <#
    .SYNOPSIS
    Enhanced function to verify Git installation with detailed information.
    
    .DESCRIPTION
    Uses the SoftwareVerification module for comprehensive verification, falls back to basic checks if unavailable.
    #>
    param(
        [switch]$Detailed
    )
    
    # Try to use the verification module first
    if (Get-Command Test-PredefinedSoftware -ErrorAction SilentlyContinue) {
        try {
            $result = Test-PredefinedSoftware -SoftwareName "Git" -Detailed:$Detailed
            return $result
        } catch {
            Write-Warning "Verification module failed for Git. Using fallback method."
        }
    }
    
    # Fallback to basic verification
    $isInstalled = $false
    $version = "Unknown"
    $paths = @()
    
    $command = Get-Command git -ErrorAction SilentlyContinue
    if ($command) {
        $isInstalled = $true
        $paths += $command.Source
        try {
            $versionOutput = & git --version 2>$null
            if ($versionOutput) {
                $version = $versionOutput -replace "git version ", ""
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

Write-Host "Git Installation Script" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green

# Handle verification-only mode
if ($VerifyOnly) {
    Write-Host "Verifying Git installation..." -ForegroundColor Yellow
    $verificationResult = Test-GitInstallation -Detailed:$Detailed
    
    if ($verificationResult.IsInstalled) {
        Write-Host "[OK] Git is installed" -ForegroundColor Green
        Write-Host "Version: $($verificationResult.Version)" -ForegroundColor Cyan
        if ($Detailed -and $verificationResult.Paths) {
            Write-Host "Installation Path(s):" -ForegroundColor Cyan
            $verificationResult.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        }
    } else {
        Write-Host "[ERROR] Git is not installed" -ForegroundColor Red
    }
    exit 0
}

# Check if Git is already installed
$gitVerification = Test-GitInstallation -Detailed:$Detailed
if ($gitVerification.IsInstalled -and -not $Force) {
    Write-Host "Git is already installed. Current version: $($gitVerification.Version)" -ForegroundColor Yellow
    if ($Detailed -and $gitVerification.Paths) {
        Write-Host "Installation Path(s):" -ForegroundColor Cyan
        $gitVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    }
    Write-Host "Use -Force to reinstall." -ForegroundColor Cyan
    
    # Skip to configuration if Git is already installed
    if ($UserName -or $UserEmail) {
        Write-Host "Updating Git configuration..." -ForegroundColor Yellow
        if ($UserName) { git config --global user.name $UserName }
        if ($UserEmail) { git config --global user.email $UserEmail }
        Write-Host "Git configuration updated." -ForegroundColor Green
    }
    exit 0
}

# Get latest Git version info
Write-Host "Checking latest Git version..." -ForegroundColor Yellow
try {
    $gitReleasesUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"
    $latestRelease = Invoke-RestMethod -Uri $gitReleasesUrl -UseBasicParsing
    $downloadUrl = ($latestRelease.assets | Where-Object { $_.name -like "*64-bit.exe" }).browser_download_url
    $version = $latestRelease.tag_name
    Write-Host "Latest Git version: $version" -ForegroundColor Cyan
} catch {
    # Fallback to known stable download URL
    Write-Host "Could not fetch latest version, using stable download URL..." -ForegroundColor Yellow
    $downloadUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
    $version = "v2.42.0"
}

$tempPath = "$env:TEMP\GitInstaller.exe"

# Download Git installer
Write-Host "Downloading Git installer..." -ForegroundColor Yellow
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing
    Write-Host "Download completed successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to download Git: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Install Git
Write-Host "Installing Git..." -ForegroundColor Yellow
try {
    if ($Silent) {
        # Silent installation with common developer settings
        $installArgs = @(
            "/VERYSILENT",
            "/NORESTART",
            "/NOCANCEL",
            "/SP-",
            "/CLOSEAPPLICATIONS",
            "/RESTARTAPPLICATIONS",
            "/COMPONENTS=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh",
            "/o:PathOption=Cmd",
            "/o:BashTerminalOption=ConHost",
            "/o:EnableSymlinks=Enabled",
            "/o:EnablePseudoConsoleSupport=Enabled",
            "/o:EnableFSMonitor=Enabled"
        )
    } else {
        # Interactive installation
        $installArgs = @("/SP-", "/SILENT")
    }
    
    $process = Start-Process -FilePath $tempPath -ArgumentList $installArgs -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Git installation completed!" -ForegroundColor Green
        
        # Verify installation with enhanced verification
        Write-Host "Verifying Git installation..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2  # Allow time for installation to complete
        
        $postInstallVerification = Test-GitInstallation -Detailed:$Detailed
        if ($postInstallVerification.IsInstalled) {
            Write-Host "[OK] Git installed successfully!" -ForegroundColor Green
            Write-Host "Version: $($postInstallVerification.Version)" -ForegroundColor Cyan
            if ($Detailed -and $postInstallVerification.Paths) {
                Write-Host "Installation Path(s):" -ForegroundColor Cyan
                $postInstallVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
            }
        } else {
            Write-Host "[WARNING] Git installation completed but verification failed" -ForegroundColor Yellow
            Write-Host "You may need to restart your terminal or check your PATH environment variable" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Git installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Failed to install Git: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Clean up downloaded installer
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force
    }
}

# Refresh PATH environment variable
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Wait for installation to complete
Start-Sleep -Seconds 5

# Verify installation
Write-Host "Verifying Git installation..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "Git is working correctly: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "Git installation verification failed. You may need to restart your terminal." -ForegroundColor Yellow
}

# Configure Git if parameters provided
if ($UserName -or $UserEmail -or $DefaultBranch) {
    Write-Host "`nConfiguring Git..." -ForegroundColor Yellow
    
    if ($UserName) {
        git config --global user.name $UserName
        Write-Host "Set user.name to: $UserName" -ForegroundColor Cyan
    }
    
    if ($UserEmail) {
        git config --global user.email $UserEmail
        Write-Host "Set user.email to: $UserEmail" -ForegroundColor Cyan
    }
    
    if ($DefaultBranch) {
        git config --global init.defaultBranch $DefaultBranch
        Write-Host "Set default branch to: $DefaultBranch" -ForegroundColor Cyan
    }
}

# Set common Git configurations for better developer experience
Write-Host "Applying recommended Git configurations..." -ForegroundColor Yellow
try {
    git config --global core.autocrlf true
    git config --global core.safecrlf false
    git config --global pull.rebase false
    git config --global credential.helper manager
    git config --global core.longpaths true
    Write-Host "Applied recommended configurations." -ForegroundColor Green
} catch {
    Write-Host "Could not apply some configurations. Git is still functional." -ForegroundColor Yellow
}

Write-Host "`nGit installation completed!" -ForegroundColor Green
Write-Host "You can now use Git from any command prompt or PowerShell window." -ForegroundColor Cyan

# Show current configuration
Write-Host "`nCurrent Git Configuration:" -ForegroundColor Cyan
try {
    Write-Host "User Name: $(git config --global user.name)" -ForegroundColor White
    Write-Host "User Email: $(git config --global user.email)" -ForegroundColor White
    Write-Host "Default Branch: $(git config --global init.defaultBranch)" -ForegroundColor White
} catch {
    Write-Host "Run 'git config --global --list' to see all configurations." -ForegroundColor White
}

# Usage examples
Write-Host "`nUsage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-git.ps1                                           # Basic installation"
Write-Host "  .\install-git.ps1 -Silent                                   # Silent installation"
Write-Host "  .\install-git.ps1 -UserName 'John Doe' -UserEmail 'john@example.com'  # With config"
Write-Host "  .\install-git.ps1 -DefaultBranch 'master'                   # Custom default branch"
Write-Host "`nCommon Git Commands:" -ForegroundColor Cyan
Write-Host "  git init                    # Initialize a new repository"
Write-Host "  git clone <url>             # Clone a repository"
Write-Host "  git config --global --list  # View all Git configurations"