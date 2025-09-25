# ========================================
# WinGet Functionality Test Script
# ========================================

<#
.SYNOPSIS
    Tests WinGet functionality after installation.

.DESCRIPTION
    This script performs comprehensive testing of WinGet installation by checking:
    - Version information
    - Help command functionality
    - Search functionality
    - Package listing capability

.EXAMPLE
    .\test-winget.ps1
    Runs all WinGet functionality tests.
#>

function Test-WinGetFunctionality {
    <#
    .SYNOPSIS
        Tests WinGet functionality comprehensively.
    
    .DESCRIPTION
        Performs multiple tests to verify WinGet is working correctly:
        1. Version check
        2. Help command
        3. Search functionality
        4. List packages
    
    .OUTPUTS
        Boolean - Returns $true if all tests pass, $false otherwise
    #>
    
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "Testing WinGet Functionality" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    $testsPassed = 0
    $totalTests = 4
    
    # Test 1: Version check
    Write-Host ""
    Write-Host "Test 1: Checking WinGet version..." -ForegroundColor Yellow
    try {
        $versionOutput = winget --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $versionOutput) {
            Write-Host "✓ Version check passed: $versionOutput" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "✗ Version check failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Version check failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 2: Help command
    Write-Host ""
    Write-Host "Test 2: Testing help command..." -ForegroundColor Yellow
    try {
        $helpOutput = winget --help 2>&1
        if ($LASTEXITCODE -eq 0 -and $helpOutput -match "Windows Package Manager") {
            Write-Host "✓ Help command passed" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "✗ Help command failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Help command failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 3: Search functionality
    Write-Host ""
    Write-Host "Test 3: Testing search functionality..." -ForegroundColor Yellow
    try {
        $searchOutput = winget search "Microsoft.PowerShell" --count 1 2>&1
        if ($LASTEXITCODE -eq 0 -and $searchOutput) {
            Write-Host "✓ Search functionality passed" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "✗ Search functionality failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Search functionality failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 4: List packages
    Write-Host ""
    Write-Host "Test 4: Testing list functionality..." -ForegroundColor Yellow
    try {
        $listOutput = winget list --count 5 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ List functionality passed" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "✗ List functionality failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ List functionality failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Summary
    Write-Host ""
    Write-Host "=============" -ForegroundColor Cyan
    Write-Host "Test Results" -ForegroundColor Cyan
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

# Run the test if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Test-WinGetFunctionality
}