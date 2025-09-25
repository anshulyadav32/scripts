# WinGet Package Manager Installation Script
#Requires -RunAsAdministrator

function Test-WinGetInstallation {
    try {
        $null = & winget --version 2>$null
        return $true
    } catch {
        return $false
    }
}

function Install-WinGet {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "WinGet Package Manager Installation" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    if (Test-WinGetInstallation) {
        Write-Host "[OK] WinGet is already installed!" -ForegroundColor Green
        try {
            $version = & winget --version
            Write-Host "Version: $version" -ForegroundColor Gray
        } catch {
            Write-Host "Unable to determine version" -ForegroundColor Yellow
        }
        return $true
    }
    
    Write-Host "[INFO] WinGet not found. Installing..." -ForegroundColor Yellow
    
    try {
        $appInstallerUrl = "https://aka.ms/getwinget"
        $tempPath = "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        
        Write-Host "Downloading Microsoft App Installer..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $appInstallerUrl -OutFile $tempPath -UseBasicParsing
        
        Write-Host "Installing..." -ForegroundColor Yellow
        Add-AppxPackage -Path $tempPath -ForceApplicationShutdown
        
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        
        if (Test-WinGetInstallation) {
            Write-Host "[OK] WinGet installed successfully!" -ForegroundColor Green
            return $true
        } else {
            throw "Installation verification failed"
        }
        
    } catch {
        Write-Host "[ERROR] Failed to install WinGet: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Manual installation options:" -ForegroundColor Yellow
        Write-Host "1. Install from Microsoft Store" -ForegroundColor Gray
        Write-Host "2. Download from GitHub: https://github.com/microsoft/winget-cli/releases" -ForegroundColor Gray
        return $false
    }
}

function Test-WinGetFunctionality {
    Write-Host ""
    Write-Host "Testing WinGet functionality..." -ForegroundColor Cyan
    
    $testsPassed = 0
    $totalTests = 2
    
    # Test version
    Write-Host "Test 1: Version check" -ForegroundColor Yellow
    try {
        $version = & winget --version 2>$null
        if ($version) {
            Write-Host "✓ Version works" -ForegroundColor Green
            $testsPassed++
        }
    } catch {
        Write-Host "✗ Version check failed" -ForegroundColor Red
    }
    
    # Test search
    Write-Host "Test 2: Search functionality" -ForegroundColor Yellow
    try {
        $search = & winget search "notepad" --count 1 2>$null
        if ($search) {
            Write-Host "✓ Search works" -ForegroundColor Green
            $testsPassed++
        }
    } catch {
        Write-Host "✗ Search failed" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Tests passed: $testsPassed/$totalTests" -ForegroundColor Cyan
    
    if ($testsPassed -eq $totalTests) {
        Write-Host "✓ All tests passed!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "⚠ Some tests failed" -ForegroundColor Yellow
        return $false
    }
}

# Main execution
Install-WinGet
Test-WinGetInstallation
Test-WinGetFunctionality

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')