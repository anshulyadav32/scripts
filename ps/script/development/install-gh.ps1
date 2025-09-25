# Install GitHub CLI (gh)
# This script downloads and installs GitHub CLI for enhanced GitHub workflow

param(
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$LoginAfterInstall = $false
)

Write-Host "GitHub CLI (gh) Installation Script" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

# Check if gh is already installed
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if ($ghInstalled -and -not $Force) {
    Write-Host "GitHub CLI is already installed. Current version:" -ForegroundColor Yellow
    gh --version
    Write-Host "Use -Force to reinstall." -ForegroundColor Cyan
    
    if ($LoginAfterInstall) {
        Write-Host "Proceeding to login..." -ForegroundColor Yellow
        gh auth login
    }
    exit 0
}

# Check if Git is installed (recommended for gh)
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitInstalled) {
    Write-Host "Warning: Git is not installed. GitHub CLI works better with Git." -ForegroundColor Yellow
    Write-Host "Consider installing Git first using .\install-git.ps1" -ForegroundColor Cyan
}

# Get latest GitHub CLI version info
Write-Host "Checking latest GitHub CLI version..." -ForegroundColor Yellow
try {
    $ghReleasesUrl = "https://api.github.com/repos/cli/cli/releases/latest"
    $latestRelease = Invoke-RestMethod -Uri $ghReleasesUrl -UseBasicParsing
    $downloadUrl = ($latestRelease.assets | Where-Object { $_.name -like "*windows_amd64.msi" }).browser_download_url
    $version = $latestRelease.tag_name
    Write-Host "Latest GitHub CLI version: $version" -ForegroundColor Cyan
} catch {
    # Fallback to known stable download URL
    Write-Host "Could not fetch latest version, using stable download URL..." -ForegroundColor Yellow
    $downloadUrl = "https://github.com/cli/cli/releases/download/v2.36.0/gh_2.36.0_windows_amd64.msi"
    $version = "v2.36.0"
}

$tempPath = "$env:TEMP\GitHubCLI.msi"

# Download GitHub CLI installer
Write-Host "Downloading GitHub CLI installer..." -ForegroundColor Yellow
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing
    Write-Host "Download completed successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to download GitHub CLI: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Install GitHub CLI
Write-Host "Installing GitHub CLI..." -ForegroundColor Yellow
try {
    if ($Silent) {
        $installArgs = "/i", $tempPath, "/quiet", "/norestart"
    } else {
        $installArgs = "/i", $tempPath, "/passive", "/norestart"
    }
    
    $process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "GitHub CLI installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "GitHub CLI installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Failed to install GitHub CLI: $($_.Exception.Message)" -ForegroundColor Red
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
Write-Host "Verifying GitHub CLI installation..." -ForegroundColor Yellow
try {
    $ghVersion = gh --version
    Write-Host "GitHub CLI is working correctly!" -ForegroundColor Green
    Write-Host $ghVersion -ForegroundColor Cyan
} catch {
    Write-Host "GitHub CLI installation verification failed. You may need to restart your terminal." -ForegroundColor Yellow
}

# Optional login after installation
if ($LoginAfterInstall) {
    Write-Host "`nInitiating GitHub authentication..." -ForegroundColor Yellow
    try {
        gh auth login
        Write-Host "GitHub authentication completed!" -ForegroundColor Green
    } catch {
        Write-Host "Authentication failed. You can run 'gh auth login' manually later." -ForegroundColor Yellow
    }
}

Write-Host "`nGitHub CLI installation completed!" -ForegroundColor Green
Write-Host "You can now use 'gh' commands from any terminal." -ForegroundColor Cyan

# Show authentication status
Write-Host "`nAuthentication Status:" -ForegroundColor Cyan
try {
    gh auth status
} catch {
    Write-Host "Not authenticated. Run 'gh auth login' to authenticate with GitHub." -ForegroundColor Yellow
}

# Usage examples and common commands
Write-Host "`nUsage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-gh.ps1                    # Basic installation"
Write-Host "  .\install-gh.ps1 -Silent            # Silent installation"
Write-Host "  .\install-gh.ps1 -LoginAfterInstall # Install and login"
Write-Host "  .\install-gh.ps1 -Force             # Force reinstall"

Write-Host "`nCommon GitHub CLI Commands:" -ForegroundColor Cyan
Write-Host "  gh auth login              # Authenticate with GitHub"
Write-Host "  gh repo clone <repo>       # Clone a repository"
Write-Host "  gh repo create <name>      # Create a new repository"
Write-Host "  gh pr list                 # List pull requests"
Write-Host "  gh pr create               # Create a pull request"
Write-Host "  gh issue list              # List issues"
Write-Host "  gh issue create            # Create an issue"
Write-Host "  gh workflow list           # List GitHub Actions workflows"
Write-Host "  gh release list            # List releases"

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Run 'gh auth login' to authenticate with GitHub" -ForegroundColor White
Write-Host "  2. Navigate to a Git repository and try 'gh repo view'" -ForegroundColor White
Write-Host "  3. Use 'gh --help' to see all available commands" -ForegroundColor White