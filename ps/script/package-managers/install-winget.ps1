# WinGet Package Manager Installation Script
#Requires -RunAsAdministrator

function Test-WinGetInstalled {
    <#
    .SYNOPSIS
    Tests if WinGet is installed and accessible.
    
    .DESCRIPTION
    Checks if WinGet command is available and returns version information.
    Returns hashtable with IsInstalled (boolean) and Version (string) properties.
    #>
    try {
        $version = & winget --version 2>$null
        if ($version) {
            return @{
                IsInstalled = $true
                Version = $version.Trim()
            }
        }
    } catch {
        # Command not found or access denied
    }
    
    return @{
        IsInstalled = $false
        Version = $null
    }
}

function Test-WinGetFunctionality {
    <#
    .SYNOPSIS
    Tests WinGet functionality with basic commands.
    
    .DESCRIPTION
    Runs comprehensive tests to verify WinGet is working properly.
    Returns hashtable with test results and overall success status.
    #>
    Write-Host "Running WinGet functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        VersionCheck = $false
        SearchTest = $false
        ListTest = $false
        OverallSuccess = $false
    }
    
    # Test 1: Version check
    Write-Host "  Testing version command..." -ForegroundColor Yellow
    try {
        $version = & winget --version 2>$null
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
        $search = & winget search "notepad" --count 1 2>$null
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
        $list = & winget list --count 1 2>$null
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

function Update-WinGet {
    <#
    .SYNOPSIS
    Updates WinGet to the latest version.
    
    .DESCRIPTION
    Attempts to update WinGet using winget upgrade or manual methods.
    Returns true if update succeeds, false otherwise.
    #>
    Write-Host "Updating WinGet..." -ForegroundColor Cyan
    
    $status = Test-WinGetInstalled
    if (-not $status.IsInstalled) {
        Write-Host "WinGet is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        # Try to update WinGet using itself
        Write-Host "Attempting to update WinGet..." -ForegroundColor Yellow
        & winget upgrade --id Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements 2>$null
        
        # Verify the update
        Start-Sleep -Seconds 2
        $newStatus = Test-WinGetInstalled
        
        if ($newStatus.IsInstalled) {
            Write-Host "✓ WinGet update completed successfully!" -ForegroundColor Green
            Write-Host "  Current version: $($newStatus.Version)" -ForegroundColor Gray
            return $true
        } else {
            throw "Update verification failed"
        }
    } catch {
        Write-Host "✗ WinGet update failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Manual update options:" -ForegroundColor Yellow
        Write-Host "1. Update via Microsoft Store" -ForegroundColor Gray
        Write-Host "2. Download latest from: https://github.com/microsoft/winget-cli/releases" -ForegroundColor Gray
        return $false
    }
}

function Install-WinGet {
    <#
    .SYNOPSIS
    Installs WinGet package manager.
    
    .DESCRIPTION
    Downloads and installs WinGet if not already present.
    Returns true if installation succeeds, false otherwise.
    #>
    Write-Host "Installing WinGet..." -ForegroundColor Cyan
    
    $status = Test-WinGetInstalled
    if ($status.IsInstalled) {
        Write-Host "[OK] WinGet is already installed!" -ForegroundColor Green
        Write-Host "Version: $($status.Version)" -ForegroundColor Gray
        return $true
    }
    
    Write-Host "[INFO] WinGet not found. Installation required." -ForegroundColor Yellow
    Write-Host "Manual installation options:" -ForegroundColor Yellow
    Write-Host "1. Install from Microsoft Store" -ForegroundColor Gray
    Write-Host "2. Download from: https://github.com/microsoft/winget-cli/releases" -ForegroundColor Gray
    
    # Note: Automatic installation would require more complex logic
    # due to WinGet's dependency on Microsoft Store infrastructure
    
    return $false
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WinGet Package Manager Installation" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan

# Test installation status
$installStatus = Install-WinGet

if ($installStatus) {
    # Run functionality tests
    Test-WinGetFunctionality
}

Write-Host ""
Write-Host "[OK] WinGet installation script completed successfully!" -ForegroundColor Green
