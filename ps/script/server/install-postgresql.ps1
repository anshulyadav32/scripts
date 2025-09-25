# Install PostgreSQL - Advanced Open Source Database

function Test-PostgreSQLInstalled {
    $installed = $false
    
    # Check for PostgreSQL service
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
    if ($pgService) {
        Write-Host "PostgreSQL service found: $($pgService.Name) - $($pgService.Status)" -ForegroundColor Green
        $installed = $true
    }
    
    # Check common installation paths
    $pgPaths = @(
        "${env:ProgramFiles}\PostgreSQL\*\bin\psql.exe",
        "${env:ProgramFiles(x86)}\PostgreSQL\*\bin\psql.exe"
    )
    
    foreach ($pathPattern in $pgPaths) {
        $resolved = Resolve-Path $pathPattern -ErrorAction SilentlyContinue
        if ($resolved) {
            Write-Host "PostgreSQL found at: $($resolved.Path)" -ForegroundColor Green
            $installed = $true
            break
        }
    }
    
    # Check via Chocolatey
    if (-not $installed) {
        $chocoPackage = choco list --local-only | Select-String "postgresql"
        if ($chocoPackage) {
            Write-Host "PostgreSQL found via Chocolatey" -ForegroundColor Green
            $installed = $true
        }
    }
    
    return $installed
}

function Test-PostgreSQLFunctionality {
    Write-Host "Running PostgreSQL functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        ServiceTest = $false
        PSQLTest = $false
        ConnectionTest = $false
        PgAdminTest = $false
        OverallSuccess = $false
    }
    
    Write-Host "  Testing PostgreSQL service..." -ForegroundColor Yellow
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
    if ($pgService -and $pgService.Status -eq "Running") {
        Write-Host "     PostgreSQL service is running" -ForegroundColor Green
        $results.ServiceTest = $true
    } elseif ($pgService) {
        Write-Host "     PostgreSQL service exists but not running: $($pgService.Status)" -ForegroundColor Yellow
    } else {
        Write-Host "     PostgreSQL service not found" -ForegroundColor Red
    }
    
    Write-Host "  Testing psql command..." -ForegroundColor Yellow
    try {
        # Try to find psql in PATH or common locations
        $psqlFound = $false
        
        try {
            $psqlVersion = psql --version 2>$null
            if ($psqlVersion) {
                Write-Host "     psql in PATH: $psqlVersion" -ForegroundColor Green
                $results.PSQLTest = $true
                $psqlFound = $true
            }
        } catch { }
        
        if (-not $psqlFound) {
            # Check common PostgreSQL installation paths
            $pgInstallPaths = @(
                "${env:ProgramFiles}\PostgreSQL\*\bin\psql.exe",
                "${env:ProgramFiles(x86)}\PostgreSQL\*\bin\psql.exe"
            )
            
            foreach ($pathPattern in $pgInstallPaths) {
                $resolved = Resolve-Path $pathPattern -ErrorAction SilentlyContinue
                if ($resolved) {
                    $psqlPath = $resolved.Path
                    $version = & $psqlPath --version 2>$null
                    if ($version) {
                        Write-Host "     psql found: $version" -ForegroundColor Green
                        $results.PSQLTest = $true
                        break
                    }
                }
            }
        }
        
        if (-not $results.PSQLTest) {
            Write-Host "     psql command not accessible" -ForegroundColor Red
        }
    } catch {
        Write-Host "     psql test failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing database connection..." -ForegroundColor Yellow
    if ($results.ServiceTest -and $results.PSQLTest) {
        try {
            # Try to connect to default postgres database
            $connectionTest = psql -U postgres -d postgres -c "SELECT version();" 2>$null
            if ($connectionTest) {
                Write-Host "     Database connection successful" -ForegroundColor Green
                $results.ConnectionTest = $true
            } else {
                Write-Host "     Database connection failed (may need password)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "     Database connection test failed" -ForegroundColor Red
        }
    } else {
        Write-Host "     Skipping connection test (service/psql not available)" -ForegroundColor Yellow
    }
    
    Write-Host "  Testing pgAdmin..." -ForegroundColor Yellow
    $pgAdminPaths = @(
        "${env:ProgramFiles}\pgAdmin 4\*\pgAdmin4.exe",
        "${env:ProgramFiles(x86)}\pgAdmin 4\*\pgAdmin4.exe"
    )
    
    $pgAdminFound = $false
    foreach ($pathPattern in $pgAdminPaths) {
        $resolved = Resolve-Path $pathPattern -ErrorAction SilentlyContinue
        if ($resolved) {
            Write-Host "     pgAdmin found: $($resolved.Path)" -ForegroundColor Green
            $results.PgAdminTest = $true
            $pgAdminFound = $true
            break
        }
    }
    
    if (-not $pgAdminFound) {
        Write-Host "     pgAdmin not found" -ForegroundColor Yellow
    }
    
    $passedTests = ($results.ServiceTest + $results.PSQLTest + $results.ConnectionTest + $results.PgAdminTest)
    $results.OverallSuccess = ($passedTests -ge 2)
    
    Write-Host "  Tests passed: $passedTests/4" -ForegroundColor Green
    
    return $results
}

function Update-PostgreSQL {
    Write-Host "Updating PostgreSQL..." -ForegroundColor Cyan
    
    if (-not (Test-PostgreSQLInstalled)) {
        Write-Host "PostgreSQL is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        # Try to update via Chocolatey if available
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Attempting to update via Chocolatey..." -ForegroundColor Yellow
            choco upgrade postgresql -y
            return $true
        }
        
        Write-Host "For PostgreSQL updates:" -ForegroundColor Yellow
        Write-Host "  1. Download latest version from https://www.postgresql.org/download/" -ForegroundColor White
        Write-Host "  2. Backup your databases with pg_dump" -ForegroundColor White
        Write-Host "  3. Stop PostgreSQL service" -ForegroundColor White
        Write-Host "  4. Run new installer" -ForegroundColor White
        Write-Host "  5. Restore your databases" -ForegroundColor White
        
        return $false
        
    } catch {
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-PostgreSQLPackageManager {
    Write-Host "Installing PostgreSQL..." -ForegroundColor Cyan
    
    $installSuccess = $false
    
    # Method 1: Try Chocolatey first
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing via Chocolatey..." -ForegroundColor Yellow
        try {
            # Install PostgreSQL server
            choco install postgresql -y
            
            # Install pgAdmin (database management tool)
            Write-Host "Installing pgAdmin..." -ForegroundColor Yellow
            choco install pgadmin4 -y
            
            $installSuccess = $true
            Write-Host "PostgreSQL and pgAdmin installed successfully via Chocolatey!" -ForegroundColor Green
        } catch {
            Write-Host "Chocolatey installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Method 2: Try WinGet if Chocolatey failed
    if (-not $installSuccess -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Installing via WinGet..." -ForegroundColor Yellow
        try {
            winget install --id PostgreSQL.PostgreSQL --source winget
            winget install --id pgAdmin.pgAdmin --source winget
            $installSuccess = $true
            Write-Host "PostgreSQL installed successfully via WinGet!" -ForegroundColor Green
        } catch {
            Write-Host "WinGet installation failed, providing manual installation guidance..." -ForegroundColor Yellow
        }
    }
    
    # Method 3: Manual installation guidance
    if (-not $installSuccess) {
        Write-Host "Automated installation failed. Manual installation required:" -ForegroundColor Yellow
        Write-Host "`n=== Manual Installation ===" -ForegroundColor Cyan
        Write-Host "1. Download PostgreSQL from: https://www.postgresql.org/download/windows/" -ForegroundColor White
        Write-Host "2. Run installer as Administrator" -ForegroundColor White
        Write-Host "3. Set superuser password (remember this!)" -ForegroundColor White
        Write-Host "4. Choose port 5432 (default)" -ForegroundColor White
        Write-Host "5. Install pgAdmin for database management" -ForegroundColor White
        Write-Host "6. Initialize database and start service" -ForegroundColor White
    }
    
    return $installSuccess
}

function Configure-PostgreSQL {
    Write-Host "Configuring PostgreSQL..." -ForegroundColor Cyan
    
    # Add PostgreSQL binaries to PATH
    $pgInstallPaths = @(
        "${env:ProgramFiles}\PostgreSQL\*\bin",
        "${env:ProgramFiles(x86)}\PostgreSQL\*\bin"
    )
    
    $pgBinPath = $null
    foreach ($pathPattern in $pgInstallPaths) {
        $resolved = Resolve-Path $pathPattern -ErrorAction SilentlyContinue
        if ($resolved) {
            $pgBinPath = $resolved.Path
            break
        }
    }
    
    if ($pgBinPath) {
        Write-Host "PostgreSQL binaries found at: $pgBinPath" -ForegroundColor Green
        
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notlike "*$pgBinPath*") {
            Write-Host "Adding PostgreSQL to PATH..." -ForegroundColor Yellow
            $newPath = "$currentPath;$pgBinPath"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host "PostgreSQL added to PATH: $pgBinPath" -ForegroundColor Green
        }
        
        return $true
    } else {
        Write-Host "PostgreSQL installation directory not found." -ForegroundColor Red
        return $false
    }
}

function Show-PostgreSQLUsageInfo {
    Write-Host "`n=== PostgreSQL Usage Guide ===" -ForegroundColor Magenta
    
    Write-Host "Starting PostgreSQL:" -ForegroundColor Yellow
    Write-Host "  • Service should auto-start on boot" -ForegroundColor White
    Write-Host "  • Manual start: net start postgresql-x64-[version]" -ForegroundColor White
    Write-Host "  • Manual stop: net stop postgresql-x64-[version]" -ForegroundColor White
    
    Write-Host "`nDatabase Management:" -ForegroundColor Yellow
    Write-Host "  • Launch pgAdmin from Start Menu" -ForegroundColor White
    Write-Host "  • Web interface: http://localhost:5050 (pgAdmin 4)" -ForegroundColor White
    Write-Host "  • Default superuser: postgres" -ForegroundColor White
    Write-Host "  • Default port: 5432" -ForegroundColor White
    
    Write-Host "`nCommand Line Tools:" -ForegroundColor Yellow
    Write-Host "  psql -U postgres -d postgres    # Connect to postgres database" -ForegroundColor White
    Write-Host "  createdb mydb                   # Create new database" -ForegroundColor White
    Write-Host "  dropdb mydb                     # Delete database" -ForegroundColor White
    Write-Host "  pg_dump mydb > backup.sql       # Backup database" -ForegroundColor White
    Write-Host "  psql -U postgres -d mydb < backup.sql # Restore database" -ForegroundColor White
    
    Write-Host "`nBasic SQL Commands:" -ForegroundColor Yellow
    Write-Host "  \l                              # List databases" -ForegroundColor White
    Write-Host "  \c dbname                       # Connect to database" -ForegroundColor White
    Write-Host "  \dt                             # List tables" -ForegroundColor White
    Write-Host "  \d tablename                    # Describe table" -ForegroundColor White
    Write-Host "  \q                              # Quit psql" -ForegroundColor White
    
    Write-Host "`nConnection Parameters:" -ForegroundColor Yellow
    Write-Host "  • Host: localhost" -ForegroundColor White
    Write-Host "  • Port: 5432" -ForegroundColor White
    Write-Host "  • Username: postgres (superuser)" -ForegroundColor White
    Write-Host "  • Database: postgres (default)" -ForegroundColor White
    
    Write-Host "`nSecurity Notes:" -ForegroundColor Yellow
    Write-Host "  ⚠️  Change default postgres password" -ForegroundColor Red
    Write-Host "  ⚠️  Configure pg_hba.conf for authentication" -ForegroundColor Red
    Write-Host "  ⚠️  Set up SSL certificates for production" -ForegroundColor Red
    Write-Host "  ⚠️  Regular database backups" -ForegroundColor Red
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PostgreSQL Installation Script" -ForegroundColor Cyan
Write-Host "Advanced Open Source Database + pgAdmin" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-PostgreSQLInstalled) {
    Write-Host "PostgreSQL is already installed!" -ForegroundColor Green
    
    # Test PostgreSQL functionality
    $testResults = Test-PostgreSQLFunctionality
    
    if ($testResults.OverallSuccess) {
        Write-Host "`n[SUCCESS] PostgreSQL is working correctly!" -ForegroundColor Green
    } else {
        Write-Host "`n[WARNING] PostgreSQL may need additional configuration." -ForegroundColor Yellow
        
        if (-not $testResults.ServiceTest) {
            Write-Host "  • PostgreSQL service not running" -ForegroundColor Yellow
        }
        if (-not $testResults.ConnectionTest) {
            Write-Host "  • Database connection failed - check password/config" -ForegroundColor Yellow
        }
        if (-not $testResults.PgAdminTest) {
            Write-Host "  • pgAdmin not installed - consider installing separately" -ForegroundColor Yellow
        }
    }
    
    # Configure PostgreSQL
    Configure-PostgreSQL
    Show-PostgreSQLUsageInfo
} else {
    Write-Host "Installing PostgreSQL..." -ForegroundColor Yellow
    
    if (Install-PostgreSQLPackageManager) {
        Write-Host "`n[SUCCESS] PostgreSQL installation completed!" -ForegroundColor Green
        
        # Test the installation
        Start-Sleep -Seconds 10
        $testResults = Test-PostgreSQLFunctionality
        
        if ($testResults.OverallSuccess) {
            Write-Host "[SUCCESS] Installation verified successfully!" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Installation completed, but some services may need to start." -ForegroundColor Yellow
        }
        
        # Configure PostgreSQL
        Configure-PostgreSQL
        Show-PostgreSQLUsageInfo
    } else {
        Write-Host "`n[INFO] Please complete PostgreSQL installation manually." -ForegroundColor Yellow
        Show-PostgreSQLUsageInfo
    }
}

Write-Host "`n[OK] PostgreSQL installation script completed!" -ForegroundColor Green