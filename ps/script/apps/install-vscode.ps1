# Install Visual Studio Code
# This script downloads and installs VS Code with optional extensions

param(
    [switch]$Silent = $false,
    [switch]$System = $false,
    [string[]]$Extensions = @(),
    [switch]$IncludeCommonExtensions = $false
)

Write-Host "Visual Studio Code Installation Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check if VS Code is already installed
$codeInstalled = Get-Command code -ErrorAction SilentlyContinue
if ($codeInstalled -and -not $Force) {
    Write-Host "Visual Studio Code is already installed." -ForegroundColor Yellow
    code --version
    Write-Host "Use -Force to reinstall or skip to extension installation." -ForegroundColor Cyan
    
    if ($Extensions.Count -eq 0 -and -not $IncludeCommonExtensions) {
        exit 0
    }
} else {
    # Determine installation type and download URL
    if ($System) {
        $downloadUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
        $installerName = "VSCodeSetup.exe"
        Write-Host "Installing VS Code system-wide (requires administrator privileges)..." -ForegroundColor Yellow
    } else {
        $downloadUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
        $installerName = "VSCodeUserSetup.exe"
        Write-Host "Installing VS Code for current user..." -ForegroundColor Yellow
    }

    $tempPath = "$env:TEMP\$installerName"

    # Download VS Code
    Write-Host "Downloading Visual Studio Code..." -ForegroundColor Yellow
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing
        Write-Host "Download completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to download VS Code: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    # Install VS Code
    Write-Host "Installing Visual Studio Code..." -ForegroundColor Yellow
    try {
        if ($Silent) {
            $installArgs = "/verysilent", "/norestart", "/mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
        } else {
            $installArgs = "/silent", "/norestart", "/mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
        }
        
        $process = Start-Process -FilePath $tempPath -ArgumentList $installArgs -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Visual Studio Code installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "VS Code installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Failed to install VS Code: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    } finally {
        # Clean up downloaded installer
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Force
        }
    }

    # Wait for installation to complete and PATH to update
    Write-Host "Waiting for installation to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Define common extensions
$commonExtensions = @(
    "ms-vscode.powershell",                    # PowerShell
    "ms-python.python",                        # Python
    "ms-vscode.vscode-typescript-next",        # TypeScript
    "ms-vscode.vscode-json",                   # JSON
    "ms-vscode-remote.remote-wsl",             # Remote - WSL
    "ms-vscode-remote.remote-containers",      # Remote - Containers
    "ms-vscode.hexeditor",                     # Hex Editor
    "eamodio.gitlens",                         # GitLens
    "ms-vscode.vscode-github-account",         # GitHub Account
    "github.vscode-pull-request-github",       # GitHub Pull Requests
    "ms-vsliveshare.vsliveshare"               # Live Share
)

# Combine user extensions with common extensions if requested
$allExtensions = $Extensions
if ($IncludeCommonExtensions) {
    $allExtensions += $commonExtensions
}

# Install extensions
if ($allExtensions.Count -gt 0) {
    Write-Host "`nInstalling VS Code extensions..." -ForegroundColor Yellow
    
    foreach ($extension in $allExtensions) {
        try {
            Write-Host "Installing extension: $extension" -ForegroundColor Cyan
            & code --install-extension $extension --force
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ $extension installed successfully" -ForegroundColor Green
            } else {
                Write-Host "  ✗ Failed to install $extension" -ForegroundColor Red
            }
        } catch {
            Write-Host "  ✗ Error installing $extension`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Verify installation
Write-Host "`nVerifying VS Code installation..." -ForegroundColor Yellow
try {
    $codeVersion = & code --version
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Visual Studio Code is working correctly!" -ForegroundColor Green
        Write-Host "Version: $($codeVersion[0])" -ForegroundColor Cyan
    }
} catch {
    Write-Host "VS Code installation verification failed. You may need to restart your terminal or computer." -ForegroundColor Yellow
}

Write-Host "`nVisual Studio Code installation completed!" -ForegroundColor Green
Write-Host "You can now launch VS Code by typing 'code' in any terminal or from the Start Menu." -ForegroundColor Cyan

# Usage examples
Write-Host "`nUsage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-vscode.ps1                                    # Basic installation"
Write-Host "  .\install-vscode.ps1 -Silent                           # Silent installation"
Write-Host "  .\install-vscode.ps1 -System                           # System-wide installation"
Write-Host "  .\install-vscode.ps1 -IncludeCommonExtensions          # Install with common extensions"
Write-Host "  .\install-vscode.ps1 -Extensions @('ext1','ext2')      # Install specific extensions"
Write-Host "`nCommon Commands:" -ForegroundColor Cyan
Write-Host "  code .                    # Open current folder in VS Code"
Write-Host "  code filename.txt         # Open specific file"
Write-Host "  code --list-extensions    # List installed extensions"