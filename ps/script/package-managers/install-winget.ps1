# ========================================
# WinGet Package Manager Installation Script
# ========================================

# Requires elevation
#Requires -RunAsAdministrator

function Test-WinGetInstallation {
    <#
    .SYNOPSIS
    Tests if WinGet is installed and accessible.
    
    .DESCRIPTION
    Checks if WinGet is available in the system by attempting to run winget --version.
    Returns $true if WinGet is accessible, $false otherwise.
    
    .OUTPUTS
    Boolean - $true if WinGet is installed and accessible, $false otherwise
    #>
    
    try {
        $null = & winget --version 2>$null
        return $true
    } catch {
        return $false

    }
function Install-WinGetPackage {
    <#
    .SYNOPSIS
    Downloads and installs the Microsoft App Installer package
    #>
    Write-Host "Downloading and installing Microsoft App Installer..." -ForegroundColor Yellow
    
    try {
        # Download URL for the latest Microsoft App Installer
        $appInstallerUrl = "https://aka.ms/getwinget"
        $tempPath = "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        
        Write-Host "Downloading from: $appInstallerUrl" -ForegroundColor Gray
        Invoke-WebRequest -Uri $appInstallerUrl -OutFile $tempPath -UseBasicParsing
        
        Write-Host "Installing Microsoft App Installer..." -ForegroundColor Yellow
        Add-AppxPackage -Path $tempPath -ForceApplicationShutdown
        
        # Clean up
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        
        Write-Host "[OK] Microsoft App Installer installed successfully!" -ForegroundColor Green
        
        # Wait a moment for the installation to complete
        Start-Sleep -Seconds 3
        
    } catch {
        throw "Failed to install Microsoft App Installer: $($_.Exception.Message)"
    }
    }

function Install-WinGet {
    <#
    .SYNOPSIS
    Main function to install WinGet package manager.
    
    .DESCRIPTION
    Checks if WinGet is already installed. If not, attempts to install it via Microsoft Store
    or direct download. Includes comprehensive testing after installation.
    #>
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "WinGet Package Manager Installation" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if WinGet is already installed
    if (Test-WinGetInstallation) {
        Write-Host "[OK] WinGet is already installed!" -ForegroundColor Green
        Write-Host "Version: " -NoNewline -ForegroundColor Gray
        try {
            & winget --version
        } catch {
            Write-Host "Unable to determine version" -ForegroundColor Yellow
        }
        return $true
    }
    
    Write-Host "[INFO] WinGet not found. Installing..." -ForegroundColor Yellow
    
    try {
        # Method 1: Try installing via Microsoft Store (requires Windows 10 1809+)
        Write-Host "Attempting to install via Microsoft Store..." -ForegroundColor Yellow
        
        # Check if we can use Add-AppxPackage
        if (Get-Command Add-AppxPackage -ErrorAction SilentlyContinue) {
            Install-WinGetPackage
        } else {
            throw "Add-AppxPackage not available"
        }
        
        # Verify installation
        if (Test-WinGetInstallation) {
            Write-Host "[OK] WinGet installed successfully!" -ForegroundColor Green
            return $true
        } else {
            throw "WinGet installation verification failed"
        }
        
    } catch {
        Write-Host "[ERROR] Failed to install WinGet: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual installation options:" -ForegroundColor Yellow
        Write-Host "1. Install from Microsoft Store: ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1" -ForegroundColor Gray
        Write-Host "2. Download from GitHub: https://github.com/microsoft/winget-cli/releases" -ForegroundColor Gray
        Write-Host "3. Use Windows Package Manager from Microsoft Store" -ForegroundColor Gray
        return $false
    }
    }
    }

function Test-WinGetFunctionality {
    <#
    .SYNOPSIS
    Tests WinGet functionality with basic commands.
    
    .DESCRIPTION
    Performs comprehensive testing of WinGet installation by running various commands
    to ensure it's working properly and accessible.
    
    .OUTPUTS
    Boolean - $true if all tests pass, $false otherwise
    #>
    
    Write-Host ""
    Write-Host "Testing WinGet functionality..." -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    
    $testsPassed = 0
    $totalTests = 4
    
    # Test 1: Version check
    Write-Host ""
    Write-Host "Test 1: Version check" -ForegroundColor Yellow
    try {
        $version = & winget --version 2>$null
        if ($version) {
            Write-Host "✓ Version: $version" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "✗ No version output" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Version check failed: Access denied or command not found" -ForegroundColor Red
    }
    
    # Test 2: Help command
    Write-Host ""
    Write-Host "Test 2: Help command" -ForegroundColor Yellow
    try {
        $help = & winget --help 2>$null
        if ($help -and $help.Length -gt 0) {
            Write-Host "✓ Help command works" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "✗ Help command failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Help command failed: Access denied" -ForegroundColor Red
    }
    
    # Test 3: Search functionality
    Write-Host ""
    Write-Host "Test 3: Search functionality" -ForegroundColor Yellow
    try {
        $search = & winget search "notepad" --count 1 2>$null
        if ($search) {
            Write-Host "✓ Search works" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "✗ Search failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Search failed: Access denied" -ForegroundColor Red
    }
    
    # Test 4: List installed packages
    Write-Host ""
    Write-Host "Test 4: List functionality" -ForegroundColor Yellow
    try {
        $list = & winget list --count 1 2>$null
        if ($list) {
            Write-Host "✓ List works" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "✗ List failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ List failed: Access denied" -ForegroundColor Red
    }
    
    # Summary
    Write-Host ""
    Write-Host "Test Results:" -ForegroundColor Cyan
    Write-Host "=============" -ForegroundColor Cyan
    Write-Host "Tests passed: $testsPassed/$totalTests" -ForegroundColor $(if ($testsPassed -eq $totalTests) { "Green" } else { "Yellow" })
    
    if ($testsPassed -eq $totalTests) {
        Write-Host "✓ All tests passed! WinGet is fully functional." -ForegroundColor Green
        return $true
    } elseif ($testsPassed -gt 0) {
        Write-Host "⚠ Some tests failed. WinGet is partially functional." -ForegroundColor Yellow
        Write-Host "You may need to restart your terminal or check your installation." -ForegroundColor Yellow
        return $false
    } else {
        Write-Host "✗ All tests failed. WinGet is not working properly." -ForegroundColor Red
        Write-Host "Please check your installation or try reinstalling WinGet." -ForegroundColor Red
        return $false
    }
}

# ========================================
# Auto-execution
# ========================================# Auto-run the main installation function
Install-WinGet

# Test WinGet functionality
Test-WinGetInstallation
Test-WinGetFunctionality

# Pause to show results
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')