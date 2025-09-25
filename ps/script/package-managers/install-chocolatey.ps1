# Install Chocolatey - The Package Manager for Windows
# This script installs Chocolatey package manager using PowerShell functions

function Test-ChocolateyInstalled {
    <#
    .SYNOPSIS
    Checks if Chocolatey is already installed on the system.
    
    .DESCRIPTION
    Returns true if Chocolatey command is available, false otherwise.
    #>
    return (Get-Command choco -ErrorAction SilentlyContinue) -ne $null
}

function Set-ChocolateyExecutionPolicy {
    <#
    .SYNOPSIS
    Sets the execution policy required for Chocolatey installation.
    
    .DESCRIPTION
    Sets Bypass execution policy for the current process to allow installation.
    #>
    Write-Host "Setting execution policy..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
}

function Install-ChocolateyPackageManager {
    <#
    .SYNOPSIS
    Downloads and installs Chocolatey package manager.
    
    .DESCRIPTION
    Downloads the Chocolatey installation script and executes it.
    Returns true if installation succeeds, false otherwise.
    #>
    try {
        Write-Host "Downloading and installing Chocolatey..." -ForegroundColor Cyan
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        return $true
    } catch {
        Write-Host "Error installing Chocolatey: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-ChocolateyFunctionality {
    <#
    .SYNOPSIS
    Tests Chocolatey functionality with basic commands.
    
    .DESCRIPTION
    Runs comprehensive tests to verify Chocolatey is working properly.
    Returns hashtable with test results and overall success status.
    #>
    Write-Host "Running Chocolatey functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        VersionCheck = $false
        SearchTest = $false
        ListTest = $false
        OverallSuccess = $false
    }
    
    # Test 1: Version check
    Write-Host "  Testing version command..." -ForegroundColor Yellow
    try {
        $version = & choco --version 2>$null
        if ($version) {
            Write-Host "    ✓ Version: $version" -ForegroundColor Green
            $results.VersionCheck = $true
        }
    } catch {
        Write-Host "    ✗ Version check failed" -ForegroundColor Red
    }
    
    # Test 2: Search functionality
    Write-Host "  Testing search functionality..." -ForegroundColor Yellow
    try {
        $search = & choco search chocolatey --limit-output --exact 2>$null
        if ($search) {
            Write-Host "    ✓ Search works" -ForegroundColor Green
            $results.SearchTest = $true
        }
    } catch {
        Write-Host "    ✗ Search failed" -ForegroundColor Red
    }
    
    # Test 3: List functionality
    Write-Host "  Testing list functionality..." -ForegroundColor Yellow
    try {
        $list = & choco list --local-only --limit-output 2>$null
        if ($list) {
            Write-Host "    ✓ List works" -ForegroundColor Green
            $results.ListTest = $true
        }
    } catch {
        Write-Host "    ✗ List failed" -ForegroundColor Red
    }
    
    $passedTests = ($results.VersionCheck + $results.SearchTest + $results.ListTest)
    $results.OverallSuccess = ($passedTests -ge 2)
    
    Write-Host "  Tests passed: $passedTests/3" -ForegroundColor $(if ($results.OverallSuccess) { "Green" } else { "Yellow" })
    
    return $results
}

function Update-Chocolatey {
    <#
    .SYNOPSIS
    Updates Chocolatey to the latest version.
    
    .DESCRIPTION
    Attempts to update Chocolatey using choco upgrade.
    Returns true if update succeeds, false otherwise.
    #>
    Write-Host "Updating Chocolatey..." -ForegroundColor Cyan
    
    if (-not (Test-ChocolateyInstalled)) {
        Write-Host "Chocolatey is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        Write-Host "Attempting to update Chocolatey..." -ForegroundColor Yellow
        & choco upgrade chocolatey -y 2>$null
        
        # Verify the update
        if (Test-ChocolateyInstalled) {
            $version = & choco --version 2>$null
            Write-Host "✓ Chocolatey update completed successfully!" -ForegroundColor Green
            Write-Host "  Current version: $version" -ForegroundColor Gray
            return $true
        } else {
            throw "Update verification failed"
        }
    } catch {
        Write-Host "✗ Chocolatey update failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Try running: choco upgrade chocolatey" -ForegroundColor Yellow
        return $false
    }
}

function Show-ChocolateyUsageInfo {
    <#
    .SYNOPSIS
    Displays helpful Chocolatey usage information.
    
    .DESCRIPTION
    Shows common Chocolatey commands and recommendations for new users.
    #>
    Write-Host "Chocolatey version:" -ForegroundColor Cyan
    choco --version
    
    Write-Host "`nUseful Chocolatey commands:" -ForegroundColor Yellow
    Write-Host "  choco search <package>     - Search for packages"
    Write-Host "  choco install <package>    - Install a package"
    Write-Host "  choco list                 - List installed packages"
    Write-Host "  choco upgrade all          - Update all packages"
    Write-Host "  choco uninstall <package>  - Uninstall a package"
    Write-Host "  choco info <package>       - Get package information"
    
    Write-Host "`nPopular packages to get started:" -ForegroundColor Cyan
    Write-Host "  choco install git"
    Write-Host "  choco install nodejs"
    Write-Host "  choco install vscode"
    Write-Host "  choco install googlechrome"
    
    Write-Host "`nNote: You may need to restart your terminal or refresh environment variables." -ForegroundColor Yellow
}

function Refresh-EnvironmentVariables {
    <#
    .SYNOPSIS
    Refreshes environment variables in the current session.
    
    .DESCRIPTION
    Updates PATH and other environment variables without requiring a restart.
    #>
    try {
        Write-Host "Refreshing environment variables..." -ForegroundColor Cyan
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        # Try to use refreshenv if available, otherwise just update PATH
        if (Get-Command refreshenv -ErrorAction SilentlyContinue) {
            refreshenv
        } else {
            Write-Host "Environment variables updated in current session." -ForegroundColor Green
        }
    } catch {
        Write-Host "Could not refresh environment variables automatically. You may need to restart your terminal." -ForegroundColor Yellow
    }
}

function Install-Chocolatey {
    <#
    .SYNOPSIS
    Main function to install Chocolatey package manager.
    
    .DESCRIPTION
    Orchestrates the complete Chocolatey installation process including checks,
    execution policy setup, installation, and verification.
    #>
    Write-Host "Installing Chocolatey..." -ForegroundColor Green
    
    # Check if Chocolatey is already installed
    if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey is already installed!" -ForegroundColor Yellow
        choco --version
        return $true
    }
    
    # Set execution policy
    Set-ChocolateyExecutionPolicy
    
    # Install Chocolatey
    if (Install-ChocolateyPackageManager) {
        Write-Host "Chocolatey installation completed successfully!" -ForegroundColor Green
        
        # Refresh environment variables
        Refresh-EnvironmentVariables
        
        # Verify installation
        if (Test-ChocolateyInstalled) {
            Show-ChocolateyUsageInfo
            
            # Run functionality tests
            Test-ChocolateyFunctionality
            
            Write-Host "`nChocolatey installation process completed!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Installation verification failed. Please restart your terminal and try 'choco --version'." -ForegroundColor Red
            return $false
        }
    } else {
        return $false
    }
}

# Execute the main installation function
$installResult = Install-Chocolatey
if (-not $installResult) {
    exit 1
}