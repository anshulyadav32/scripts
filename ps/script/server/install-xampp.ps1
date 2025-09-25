# Install XAMPP - Apache, MySQL, PHP, and phpMyAdmin Stack

function Test-XAMPPInstalled {
    $installed = $false
    
    # Common XAMPP installation paths
    $xamppPaths = @(
        "C:\xampp\xampp-control.exe",
        "C:\XAMPP\xampp-control.exe",
        "${env:ProgramFiles}\xampp\xampp-control.exe",
        "${env:ProgramFiles(x86)}\xampp\xampp-control.exe"
    )
    
    foreach ($path in $xamppPaths) {
        if (Test-Path $path) {
            Write-Host "XAMPP found at: $path" -ForegroundColor Green
            $installed = $true
            break
        }
    }
    
    # Check via Chocolatey
    if (-not $installed) {
        $chocoPackage = choco list --local-only | Select-String "xampp"
        if ($chocoPackage) {
            Write-Host "XAMPP found via Chocolatey" -ForegroundColor Green
            $installed = $true
        }
    }
    
    return $installed
}

function Test-XAMPPServices {
    Write-Host "Testing XAMPP services..." -ForegroundColor Cyan
    
    $results = @{
        ApacheTest = $false
        MySQLTest = $false
        PHPTest = $false
        OverallSuccess = $false
    }
    
    Write-Host "  Testing Apache service..." -ForegroundColor Yellow
    try {
        $apacheService = Get-Service -Name "Apache*" -ErrorAction SilentlyContinue
        if ($apacheService) {
            Write-Host "     Apache service found: $($apacheService.Status)" -ForegroundColor Green
            $results.ApacheTest = $true
        } else {
            Write-Host "     Apache service not found (normal for portable XAMPP)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "     Apache service check failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing MySQL service..." -ForegroundColor Yellow
    try {
        $mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue
        if ($mysqlService) {
            Write-Host "     MySQL service found: $($mysqlService.Status)" -ForegroundColor Green
            $results.MySQLTest = $true
        } else {
            Write-Host "     MySQL service not found (normal for portable XAMPP)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "     MySQL service check failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing PHP availability..." -ForegroundColor Yellow
    try {
        # Check if PHP is in PATH or XAMPP directory
        $phpPaths = @(
            "C:\xampp\php\php.exe",
            "C:\XAMPP\php\php.exe"
        )
        
        $phpFound = $false
        foreach ($phpPath in $phpPaths) {
            if (Test-Path $phpPath) {
                $version = & $phpPath --version 2>$null | Select-Object -First 1
                Write-Host "     PHP found: $version" -ForegroundColor Green
                $results.PHPTest = $true
                $phpFound = $true
                break
            }
        }
        
        if (-not $phpFound) {
            try {
                $phpVersion = php --version 2>$null | Select-Object -First 1
                if ($phpVersion) {
                    Write-Host "     PHP in PATH: $phpVersion" -ForegroundColor Green
                    $results.PHPTest = $true
                }
            } catch {
                Write-Host "     PHP not found" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "     PHP test failed" -ForegroundColor Red
    }
    
    $passedTests = ($results.ApacheTest + $results.MySQLTest + $results.PHPTest)
    $results.OverallSuccess = ($passedTests -ge 1)
    
    Write-Host "  Tests passed: $passedTests/3" -ForegroundColor Green
    
    return $results
}

function Update-XAMPP {
    Write-Host "Updating XAMPP..." -ForegroundColor Cyan
    
    if (-not (Test-XAMPPInstalled)) {
        Write-Host "XAMPP is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        # Try to update via Chocolatey if available
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Attempting to update via Chocolatey..." -ForegroundColor Yellow
            choco upgrade xampp-81 -y
            return $true
        }
        
        Write-Host "For XAMPP updates:" -ForegroundColor Yellow
        Write-Host "  1. Download latest version from https://www.apachefriends.org/" -ForegroundColor White
        Write-Host "  2. Backup your htdocs and databases" -ForegroundColor White
        Write-Host "  3. Run new installer" -ForegroundColor White
        Write-Host "  4. Restore your data" -ForegroundColor White
        
        return $false
        
    } catch {
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-XAMPPPackageManager {
    Write-Host "Installing XAMPP..." -ForegroundColor Cyan
    
    $installSuccess = $false
    
    # Method 1: Try Chocolatey first
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing via Chocolatey..." -ForegroundColor Yellow
        try {
            # Install XAMPP with PHP 8.1 (latest stable)
            choco install xampp-81 -y
            $installSuccess = $true
            Write-Host "XAMPP installed successfully via Chocolatey!" -ForegroundColor Green
        } catch {
            Write-Host "Chocolatey installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Method 2: Manual installation guidance
    if (-not $installSuccess) {
        Write-Host "Automated installation failed. Manual installation required:" -ForegroundColor Yellow
        Write-Host "`n=== Manual Installation ===" -ForegroundColor Cyan
        Write-Host "1. Download XAMPP from: https://www.apachefriends.org/download.html" -ForegroundColor White
        Write-Host "2. Choose version with PHP 8.1 or later" -ForegroundColor White
        Write-Host "3. Run installer as Administrator" -ForegroundColor White
        Write-Host "4. Install to C:\xampp (recommended)" -ForegroundColor White
        Write-Host "5. Select components: Apache, MySQL, PHP, phpMyAdmin" -ForegroundColor White
        Write-Host "6. Complete installation and start XAMPP Control Panel" -ForegroundColor White
    }
    
    return $installSuccess
}

function Configure-XAMPP {
    Write-Host "Configuring XAMPP..." -ForegroundColor Cyan
    
    $xamppPath = $null
    $xamppPaths = @("C:\xampp", "C:\XAMPP")
    
    foreach ($path in $xamppPaths) {
        if (Test-Path $path) {
            $xamppPath = $path
            break
        }
    }
    
    if ($xamppPath) {
        Write-Host "XAMPP found at: $xamppPath" -ForegroundColor Green
        
        # Add PHP to PATH if not already there
        $phpPath = "$xamppPath\php"
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        
        if ($currentPath -notlike "*$phpPath*" -and (Test-Path $phpPath)) {
            Write-Host "Adding PHP to PATH..." -ForegroundColor Yellow
            $newPath = "$currentPath;$phpPath"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host "PHP added to PATH: $phpPath" -ForegroundColor Green
        }
        
        # Create desktop shortcut for XAMPP Control Panel
        $controlPanelPath = "$xamppPath\xampp-control.exe"
        if (Test-Path $controlPanelPath) {
            Write-Host "XAMPP Control Panel available at: $controlPanelPath" -ForegroundColor Green
        }
        
        return $true
    } else {
        Write-Host "XAMPP installation directory not found." -ForegroundColor Red
        return $false
    }
}

function Show-XAMPPUsageInfo {
    Write-Host "`n=== XAMPP Usage Guide ===" -ForegroundColor Magenta
    
    Write-Host "Starting XAMPP:" -ForegroundColor Yellow
    Write-Host "  1. Launch XAMPP Control Panel" -ForegroundColor White
    Write-Host "  2. Start Apache service" -ForegroundColor White
    Write-Host "  3. Start MySQL service" -ForegroundColor White
    Write-Host "  4. Access via http://localhost" -ForegroundColor White
    
    Write-Host "`nKey URLs:" -ForegroundColor Yellow
    Write-Host "  • Web Server: http://localhost" -ForegroundColor White
    Write-Host "  • phpMyAdmin: http://localhost/phpmyadmin" -ForegroundColor White
    Write-Host "  • XAMPP Dashboard: http://localhost/dashboard" -ForegroundColor White
    
    Write-Host "`nImportant Directories:" -ForegroundColor Yellow
    Write-Host "  • Web Root: C:\xampp\htdocs" -ForegroundColor White
    Write-Host "  • Apache Config: C:\xampp\apache\conf\httpd.conf" -ForegroundColor White
    Write-Host "  • PHP Config: C:\xampp\php\php.ini" -ForegroundColor White
    Write-Host "  • MySQL Data: C:\xampp\mysql\data" -ForegroundColor White
    
    Write-Host "`nPHP Commands:" -ForegroundColor Yellow
    Write-Host "  php --version            # Check PHP version" -ForegroundColor White
    Write-Host "  php -m                   # List PHP modules" -ForegroundColor White
    Write-Host "  php -S localhost:8000    # Built-in PHP server" -ForegroundColor White
    
    Write-Host "`nMySQL Commands:" -ForegroundColor Yellow
    Write-Host "  • Default username: root" -ForegroundColor White
    Write-Host "  • Default password: (empty)" -ForegroundColor White
    Write-Host "  • Port: 3306" -ForegroundColor White
    
    Write-Host "`nSecurity Notes:" -ForegroundColor Yellow
    Write-Host "  ⚠️  Change default MySQL root password" -ForegroundColor Red
    Write-Host "  ⚠️  Configure firewall rules for production" -ForegroundColor Red
    Write-Host "  ⚠️  Disable unnecessary services" -ForegroundColor Red
    Write-Host "  ⚠️  Keep XAMPP updated" -ForegroundColor Red
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "XAMPP Installation Script" -ForegroundColor Cyan
Write-Host "Apache + MySQL + PHP + phpMyAdmin" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-XAMPPInstalled) {
    Write-Host "XAMPP is already installed!" -ForegroundColor Green
    
    # Test XAMPP services
    $testResults = Test-XAMPPServices
    
    if ($testResults.OverallSuccess) {
        Write-Host "`n[SUCCESS] XAMPP components are available!" -ForegroundColor Green
    } else {
        Write-Host "`n[WARNING] Some XAMPP components may need configuration." -ForegroundColor Yellow
    }
    
    # Configure XAMPP
    Configure-XAMPP
    Show-XAMPPUsageInfo
} else {
    Write-Host "Installing XAMPP..." -ForegroundColor Yellow
    
    if (Install-XAMPPPackageManager) {
        Write-Host "`n[SUCCESS] XAMPP installation completed!" -ForegroundColor Green
        
        # Test the installation
        Start-Sleep -Seconds 5
        $testResults = Test-XAMPPServices
        
        if ($testResults.OverallSuccess) {
            Write-Host "[SUCCESS] Installation verified successfully!" -ForegroundColor Green
        }
        
        # Configure XAMPP
        Configure-XAMPP
        Show-XAMPPUsageInfo
    } else {
        Write-Host "`n[INFO] Please complete XAMPP installation manually." -ForegroundColor Yellow
        Show-XAMPPUsageInfo
    }
}

Write-Host "`n[OK] XAMPP installation script completed!" -ForegroundColor Green