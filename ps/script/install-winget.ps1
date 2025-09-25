<#
.SYNOPSIS
    Install WinGet (Windows Package Manager) on Windows 10/11 systems with auto-elevation

.DESCRIPTION
    This PowerShell script downloads and installs Microsoft App Installer which includes WinGet.
    The script is function-based with auto-execution, auto-elevation to admin mode, and includes proper error handling, system checks, and verification.

.EXAMPLE
    .\install-winget.ps1
    Installs WinGet on the current system (will auto-elevate if needed)

.NOTES
    Author: Auto-generated script
    Requires: PowerShell 5.1+
    Auto-elevates to Administrator privileges if needed
#>

[CmdletBinding()]
param()

# ========================================
# Auto-Elevation Check
# ========================================

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Write-Host "This script needs to run as Administrator to install WinGet." -ForegroundColor Yellow
    
    try {
        # Get the current script path
        $scriptPath = $MyInvocation.MyCommand.Path
        
        # Start a new PowerShell process with elevated privileges
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
        
        # Exit the current non-elevated instance
        exit 0
    }
    catch {
        Write-Host "[ERROR] Failed to elevate privileges: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator manually." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Set error action preference
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ========================================
# Main Functions
# ========================================

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
        Check if running as administrator
    #>
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run as Administrator! Please run PowerShell as Administrator and try again."
    }
    Write-Host "[OK] Administrator privileges confirmed" -ForegroundColor Green
}

function Get-SystemInfo {
    <#
    .SYNOPSIS
        Display system information
    #>
    $osVersion = [System.Environment]::OSVersion.Version
    Write-Host "[OK] Windows version: $($osVersion.Major).$($osVersion.Minor)" -ForegroundColor Green
}

function Test-WinGetInstallation {
    <#
    .SYNOPSIS
        Check if WinGet is already installed
    .OUTPUTS
        Boolean - True if WinGet is installed, False otherwise
    #>
    Write-Host "Checking for existing WinGet installation..." -ForegroundColor Yellow
    
    try {
        $wingetVersion = & winget --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] WinGet is already installed!" -ForegroundColor Green
            Write-Host "Current version: $wingetVersion" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "WinGet not found. Proceeding with installation..." -ForegroundColor Yellow
    }
    return $false
}

function Install-WinGetPackage {
    <#
    .SYNOPSIS
        Download and install Microsoft App Installer
    #>
    Write-Host "Downloading Microsoft App Installer..." -ForegroundColor Yellow
    
    $downloadUrl = "https://aka.ms/getwinget"
    $tempPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    
    Write-Host "Download URL: $downloadUrl" -ForegroundColor Gray
    Write-Host "Temporary file: $tempPath" -ForegroundColor Gray
    
    # Download with progress
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, $tempPath)
    
    if (-not (Test-Path $tempPath)) {
        throw "Download failed - file not found at $tempPath"
    }
    
    $fileSize = (Get-Item $tempPath).Length
    Write-Host "[OK] Download completed successfully ($([math]::Round($fileSize/1MB, 2)) MB)" -ForegroundColor Green

    # Install App Installer
    Write-Host "Installing Microsoft App Installer..." -ForegroundColor Yellow
    
    try {
        Add-AppxPackage -Path $tempPath -ForceApplicationShutdown -ErrorAction Stop
        Write-Host "[OK] App Installer installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "Standard installation failed, trying alternative method..."
        
        # Alternative installation method with better error handling
        try {
            $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy", "Bypass", "-Command", "Add-AppxPackage -Path '$tempPath' -ForceApplicationShutdown" -Wait -PassThru -WindowStyle Hidden
            
            if ($process.ExitCode -ne 0) {
                Write-Warning "Alternative method also failed. Trying DISM method..."
                
                # Try DISM method as last resort
                $dismResult = & dism /online /add-provisionedappxpackage /packagepath:"$tempPath" /skiplicense
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] App Installer installed successfully (DISM method)" -ForegroundColor Green
                } else {
                    throw "All installation methods failed. WinGet may already be installed or require manual installation from Microsoft Store."
                }
            } else {
                Write-Host "[OK] App Installer installed successfully (alternative method)" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "Installation may have failed, but continuing with verification..."
        }
    }

    # Clean up temporary file
    try {
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Temporary files cleaned up" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not remove temporary file: $tempPath"
    }
}

function Test-WinGetVerification {
    <#
    .SYNOPSIS
        Verify WinGet installation
    #>
    Write-Host "Verifying WinGet installation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3

    try {
        $wingetVersion = & winget --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] SUCCESS: WinGet has been installed successfully!" -ForegroundColor Green
            Write-Host "Installed version: $wingetVersion" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "WinGet installation completed but verification failed"
            Write-Warning "Please restart your PowerShell session and try running 'winget --version'"
            return $false
        }
    }
    catch {
        Write-Warning "WinGet installation completed but verification failed"
        Write-Warning "Please restart your PowerShell session and try running 'winget --version'"
        return $false
    }
}

function Install-WinGet {
    <#
    .SYNOPSIS
        Main installation function that orchestrates the entire process
    #>
    # Script banner
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "WinGet Installation Script (PowerShell)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    try {
        # Check administrator privileges
        Test-AdminPrivileges

        # Display system information
        Get-SystemInfo

        # Check if WinGet is already installed
        if (Test-WinGetInstallation) {
            Write-Host "Installation complete!" -ForegroundColor Green
            return
        }

        # Download and install
        Install-WinGetPackage

        # Verify installation
        Test-WinGetVerification

        Write-Host ""
        Write-Host "Installation process completed!" -ForegroundColor Green
        Write-Host "You can now use WinGet to install and manage applications." -ForegroundColor Cyan
        Write-Host "Example: winget search notepad" -ForegroundColor Gray
    }
    catch {
        Write-Host ""
        Write-Host "[ERROR] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
        Write-Host "1. Make sure you're running PowerShell as Administrator" -ForegroundColor Gray
        Write-Host "2. Check your internet connection" -ForegroundColor Gray
        Write-Host "3. Try installing from Microsoft Store manually" -ForegroundColor Gray
        Write-Host "4. Ensure Windows is up to date" -ForegroundColor Gray
        
        exit 1
    }
}

# ========================================
# Auto-execution
# ========================================

# Auto-run the main installation function
Install-WinGet

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")