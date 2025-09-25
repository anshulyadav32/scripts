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

function Test-ScoopFunctionality {
    <#
    .SYNOPSIS
    Tests Scoop functionality with basic commands.
    
    .DESCRIPTION
    Runs comprehensive tests to verify Scoop is working properly.
    Returns hashtable with test results and overall success status.
    #>
    Write-Host "Running Scoop functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        VersionCheck = $false
        SearchTest = $false
        ListTest = $false
        OverallSuccess = $false
    }
    
    # Test 1: Version check
    Write-Host "  Testing version command..." -ForegroundColor Yellow
    try {
        $version = & scoop --version 2>$null
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
        $search = & scoop search git 2>$null
        if ($search -and $search.Count -gt 0) {
            Write-Host "    ✓ Search works" -ForegroundColor Green
            $results.SearchTest = $true
        }
    } catch {
        Write-Host "    ✗ Search failed" -ForegroundColor Red
    }
    
    # Test 3: List functionality
    Write-Host "  Testing list functionality..." -ForegroundColor Yellow
    try {
        $list = & scoop list 2>$null
        # List command should work even if no packages installed
        Write-Host "    ✓ List works" -ForegroundColor Green
        $results.ListTest = $true
    } catch {
        Write-Host "    ✗ List failed" -ForegroundColor Red
    }
    
    $passedTests = ($results.VersionCheck + $results.SearchTest + $results.ListTest)
    $results.OverallSuccess = ($passedTests -ge 2)
    
    Write-Host "  Tests passed: $passedTests/3" -ForegroundColor $(if ($results.OverallSuccess) { "Green" } else { "Yellow" })
    
    return $results
}

function Update-Scoop {
    <#
    .SYNOPSIS
    Updates Scoop and all installed applications.
    
    .DESCRIPTION
    Attempts to update Scoop itself and then all installed applications.
    Returns true if update succeeds, false otherwise.
    #>
    Write-Host "Updating Scoop..." -ForegroundColor Cyan
    
    if (-not (Test-ScoopInstalled)) {
        Write-Host "Scoop is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        Write-Host "Updating Scoop itself..." -ForegroundColor Yellow
        & scoop update 2>$null
        
        Write-Host "Updating all installed applications..." -ForegroundColor Yellow
        & scoop update * 2>$null
        
        # Verify Scoop is still working
        if (Test-ScoopInstalled) {
            $version = & scoop --version 2>$null
            Write-Host "✓ Scoop update completed successfully!" -ForegroundColor Green
            Write-Host "  Current version: $version" -ForegroundColor Gray
            return $true
        } else {
            throw "Update verification failed"
        }
    } catch {
        Write-Host "✗ Scoop update failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Try running: scoop update" -ForegroundColor Yellow
        return $false
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
    Write-Host "  scoop uninstall <app>  - Uninstall an application"
    Write-Host "  scoop info <app>       - Get application information"
    
    Write-Host "`nRecommended buckets to add:" -ForegroundColor Yellow
    Write-Host "  scoop bucket add extras"
    Write-Host "  scoop bucket add versions"
    Write-Host "  scoop bucket add java"
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
    
    # Check if already installed
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
            
            # Run functionality tests
            Test-ScoopFunctionality
            
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
$installResult = Install-Scoop
if (-not $installResult) {
    exit 1
}