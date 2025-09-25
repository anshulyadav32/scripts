# Install Scoop - A command-line installer for Windows
# This script installs Scoop package manager using PowerShell functions

function Test-ScoopInstalled {
    <#
    .SYNOPSIS
    Checks if Scoop is already installed on the system.
    
    .DESCRIPTION
    Returns true if Scoop command is available, false otherwise.
    #>
    return (Get-Command scoop -ErrorAction SilentlyContinue) -ne $null
}

function Set-ScoopExecutionPolicy {
    <#
    .SYNOPSIS
    Sets the execution policy required for Scoop installation.
    
    .DESCRIPTION
    Sets RemoteSigned execution policy for the current user.
    #>
    Write-Host "Setting execution policy..." -ForegroundColor Cyan
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

function Install-ScoopPackageManager {
    <#
    .SYNOPSIS
    Downloads and installs Scoop package manager.
    
    .DESCRIPTION
    Downloads the Scoop installation script and executes it with admin bypass.
    Returns true if installation succeeds, false otherwise.
    #>
    try {
        Write-Host "Downloading and installing Scoop..." -ForegroundColor Cyan
        
        # Download the installer first
        $installerPath = "$env:TEMP\install-scoop.ps1"
        Invoke-WebRequest -Uri "https://get.scoop.sh" -OutFile $installerPath
        
        # Run with -RunAsAdmin flag to bypass admin restrictions
        & $installerPath -RunAsAdmin
        
        # Clean up
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        
        return $true
    } catch {
        Write-Host "Error installing Scoop: $($_.Exception.Message)" -ForegroundColor Red
        
        # Try alternative method
        try {
            Write-Host "Trying alternative installation method..." -ForegroundColor Yellow
            Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
            return $true
        } catch {
            Write-Host "Alternative method also failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

function Show-ScoopUsageInfo {
    <#
    .SYNOPSIS
    Displays helpful Scoop usage information.
    
    .DESCRIPTION
    Shows common Scoop commands and recommendations for new users.
    #>
    Write-Host "Scoop version:" -ForegroundColor Cyan
    scoop --version
    
    Write-Host "`nUseful Scoop commands:" -ForegroundColor Yellow
    Write-Host "  scoop search <app>     - Search for applications"
    Write-Host "  scoop install <app>    - Install an application"
    Write-Host "  scoop list             - List installed applications"
    Write-Host "  scoop update           - Update Scoop and all apps"
    Write-Host "  scoop bucket add extras - Add the extras bucket for more apps"
    
    Write-Host "`nRecommended: Add the 'extras' bucket for more applications:" -ForegroundColor Cyan
    Write-Host "  scoop bucket add extras"
}

function Install-Scoop {
    <#
    .SYNOPSIS
    Main function to install Scoop package manager.
    
    .DESCRIPTION
    Orchestrates the complete Scoop installation process including checks,
    execution policy setup, installation, and verification.
    #>
    Write-Host "Installing Scoop..." -ForegroundColor Green
    
    # Check if Scoop is already installed
    if (Test-ScoopInstalled) {
        Write-Host "Scoop is already installed!" -ForegroundColor Yellow
        scoop --version
        return $true
    }
    
    # Set execution policy
    Set-ScoopExecutionPolicy
    
    # Install Scoop
    if (Install-ScoopPackageManager) {
        Write-Host "Scoop installation completed successfully!" -ForegroundColor Green
        
        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        
        # Verify installation
        if (Test-ScoopInstalled) {
            Show-ScoopUsageInfo
            Write-Host "`nScoop installation process completed!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Installation verification failed. Please restart your terminal and try 'scoop --version'." -ForegroundColor Red
            return $false
        }
    } else {
        return $false
    }
}

# Execute the main installation function
if (-not (Install-Scoop)) {
    exit 1
}