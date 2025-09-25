# Install Windows Terminal - Modern command-line application

function Test-WindowsTerminalInstalled {
    $installed = $false
    
    # Check if installed via Microsoft Store
    $storeApp = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
    if ($storeApp) {
        Write-Host "Windows Terminal found via Microsoft Store" -ForegroundColor Green
        $installed = $true
    }
    
    # Check if installed via package manager
    $chocoPackage = choco list --local-only | Select-String "microsoft-windows-terminal"
    if ($chocoPackage) {
        Write-Host "Windows Terminal found via Chocolatey" -ForegroundColor Green
        $installed = $true
    }
    
    return $installed
}

function Test-WindowsTerminalFunctionality {
    Write-Host "Running Windows Terminal functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        LaunchTest = $false
        ConfigTest = $false
        OverallSuccess = $false
    }
    
    Write-Host "  Testing launch capability..." -ForegroundColor Yellow
    try {
        # Test if Windows Terminal can be launched
        $process = Start-Process -FilePath "wt.exe" -ArgumentList "--help" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
        if ($process) {
            Start-Sleep -Seconds 2
            if (!$process.HasExited) {
                $process.CloseMainWindow()
                $process.Kill()
            }
            Write-Host "     Launch test: PASSED" -ForegroundColor Green
            $results.LaunchTest = $true
        }
    } catch {
        Write-Host "     Launch test: FAILED" -ForegroundColor Red
    }
    
    Write-Host "  Testing configuration access..." -ForegroundColor Yellow
    try {
        $configPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $configPath) {
            Write-Host "     Configuration accessible" -ForegroundColor Green
            $results.ConfigTest = $true
        } else {
            Write-Host "     Configuration not found (may be new installation)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "     Configuration test: FAILED" -ForegroundColor Red
    }
    
    $passedTests = ($results.LaunchTest + $results.ConfigTest)
    $results.OverallSuccess = ($passedTests -ge 1)
    
    Write-Host "  Tests passed: $passedTests/2" -ForegroundColor Green
    
    return $results
}

function Update-WindowsTerminal {
    Write-Host "Updating Windows Terminal..." -ForegroundColor Cyan
    
    if (-not (Test-WindowsTerminalInstalled)) {
        Write-Host "Windows Terminal is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        # Try to update via Microsoft Store first
        Write-Host "Attempting to update via Microsoft Store..." -ForegroundColor Yellow
        $updateProcess = Start-Process -FilePath "ms-windows-store://pdp/?productid=9N0DX20HK701" -PassThru -ErrorAction SilentlyContinue
        
        if ($updateProcess) {
            Write-Host "Microsoft Store opened for Windows Terminal updates" -ForegroundColor Green
            return $true
        }
        
        # Fallback to Chocolatey if available
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Attempting to update via Chocolatey..." -ForegroundColor Yellow
            choco upgrade microsoft-windows-terminal -y
            return $true
        }
        
        Write-Host "Unable to update automatically. Please update via Microsoft Store." -ForegroundColor Yellow
        return $false
        
    } catch {
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-WindowsTerminalPackageManager {
    Write-Host "Installing Windows Terminal..." -ForegroundColor Cyan
    
    $installSuccess = $false
    
    # Method 1: Try Chocolatey first (more reliable for automation)
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing via Chocolatey..." -ForegroundColor Yellow
        try {
            choco install microsoft-windows-terminal -y
            $installSuccess = $true
            Write-Host "Windows Terminal installed successfully via Chocolatey!" -ForegroundColor Green
        } catch {
            Write-Host "Chocolatey installation failed, trying alternative method..." -ForegroundColor Yellow
        }
    }
    
    # Method 2: Try WinGet if available
    if (-not $installSuccess -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Installing via WinGet..." -ForegroundColor Yellow
        try {
            winget install --id Microsoft.WindowsTerminal --source winget
            $installSuccess = $true
            Write-Host "Windows Terminal installed successfully via WinGet!" -ForegroundColor Green
        } catch {
            Write-Host "WinGet installation failed, trying Microsoft Store..." -ForegroundColor Yellow
        }
    }
    
    # Method 3: Direct Microsoft Store installation
    if (-not $installSuccess) {
        Write-Host "Opening Microsoft Store for manual installation..." -ForegroundColor Yellow
        try {
            Start-Process -FilePath "ms-windows-store://pdp/?productid=9N0DX20HK701"
            Write-Host "Microsoft Store opened. Please install Windows Terminal manually." -ForegroundColor Cyan
            Write-Host "URL: https://aka.ms/terminal" -ForegroundColor Gray
        } catch {
            Write-Host "Failed to open Microsoft Store. Please visit: https://aka.ms/terminal" -ForegroundColor Red
        }
    }
    
    return $installSuccess
}

function Show-WindowsTerminalUsageInfo {
    Write-Host "`n=== Windows Terminal Usage Guide ===" -ForegroundColor Magenta
    Write-Host "Launch Commands:" -ForegroundColor Yellow
    Write-Host "  wt                    # Launch Windows Terminal" -ForegroundColor White
    Write-Host "  wt -p PowerShell      # Launch with PowerShell profile" -ForegroundColor White
    Write-Host "  wt -p 'Command Prompt'# Launch with Command Prompt" -ForegroundColor White
    Write-Host "  wt new-tab           # Open new tab" -ForegroundColor White
    
    Write-Host "`nKey Features:" -ForegroundColor Yellow
    Write-Host "  • Multiple tabs and panes" -ForegroundColor White
    Write-Host "  • GPU accelerated text rendering" -ForegroundColor White
    Write-Host "  • Rich theming and customization" -ForegroundColor White
    Write-Host "  • Unicode and UTF-8 support" -ForegroundColor White
    Write-Host "  • Custom key bindings" -ForegroundColor White
    
    Write-Host "`nCustomization:" -ForegroundColor Yellow
    Write-Host "  • Settings: Ctrl+, (Comma)" -ForegroundColor White
    Write-Host "  • JSON config: %LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -ForegroundColor White
    Write-Host "  • Themes: https://windowsterminalthemes.dev/" -ForegroundColor White
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows Terminal Installation Script" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan

if (Test-WindowsTerminalInstalled) {
    Write-Host "Windows Terminal is already installed!" -ForegroundColor Green
    
    # Run functionality tests
    $testResults = Test-WindowsTerminalFunctionality
    
    if ($testResults.OverallSuccess) {
        Write-Host "`n[SUCCESS] Windows Terminal is working correctly!" -ForegroundColor Green
    } else {
        Write-Host "`n[WARNING] Windows Terminal may have issues. Consider reinstalling." -ForegroundColor Yellow
    }
    
    Show-WindowsTerminalUsageInfo
} else {
    Write-Host "Installing Windows Terminal..." -ForegroundColor Yellow
    
    if (Install-WindowsTerminalPackageManager) {
        Write-Host "`n[SUCCESS] Windows Terminal installation completed!" -ForegroundColor Green
        
        # Test the installation
        Start-Sleep -Seconds 3
        $testResults = Test-WindowsTerminalFunctionality
        
        if ($testResults.OverallSuccess) {
            Write-Host "[SUCCESS] Installation verified successfully!" -ForegroundColor Green
        }
        
        Show-WindowsTerminalUsageInfo
    } else {
        Write-Host "`n[ERROR] Windows Terminal installation failed!" -ForegroundColor Red
        Write-Host "Please try manual installation from: https://aka.ms/terminal" -ForegroundColor Yellow
    }
}

Write-Host "`n[OK] Windows Terminal installation script completed!" -ForegroundColor Green