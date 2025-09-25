# Install Git for Windows
# This script downloads and installs Git with common developer configurations

param(
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [string]$UserName = "",
    [string]$UserEmail = "",
    [string]$DefaultBranch = "main"
)

Write-Host "Git Installation Script" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green

# Check if Git is already installed
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if ($gitInstalled -and -not $Force) {
    Write-Host "Git is already installed. Current version:" -ForegroundColor Yellow
    git --version
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
        Write-Host "Git installed successfully!" -ForegroundColor Green
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