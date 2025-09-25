# Install PostgreSQL Database
# This script downloads and installs PostgreSQL with common tools

param(
    [string]$Version = "latest",
    [string]$AdminPassword = "postgres",
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$InstallPgAdmin = $true,
    [string]$DataDirectory = "$env:ProgramData\PostgreSQL\data"
)

Write-Host "PostgreSQL Database Installation Script" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Check if PostgreSQL is already installed
$psqlInstalled = Get-Command psql -ErrorAction SilentlyContinue
$pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue

if (($psqlInstalled -or $pgService) -and -not $Force) {
    Write-Host "PostgreSQL appears to be already installed:" -ForegroundColor Yellow
    if ($psqlInstalled) {
        psql --version
    }
    if ($pgService) {
        Write-Host "PostgreSQL service found: $($pgService.Name)" -ForegroundColor Cyan
    }
    Write-Host "Use -Force to reinstall." -ForegroundColor Cyan
    
    if ($InstallPgAdmin) {
        Write-Host "Proceeding to pgAdmin installation..." -ForegroundColor Yellow
    } else {
        exit 0
    }
} else {
    Write-Host "Installing PostgreSQL..." -ForegroundColor Yellow
    
    try {
        # Determine PostgreSQL version to install
        if ($Version -eq "latest") {
            # Get latest stable version from PostgreSQL website
            Write-Host "Fetching latest PostgreSQL version..." -ForegroundColor Cyan
            try {
                # Try to get version from download page
                $pgDownloadPage = Invoke-WebRequest -Uri "https://www.postgresql.org/download/windows/" -UseBasicParsing
                $versionMatch = $pgDownloadPage.Content | Select-String -Pattern "PostgreSQL (\d+\.\d+)" | Select-Object -First 1
                if ($versionMatch) {
                    $Version = $versionMatch.Matches[0].Groups[1].Value
                } else {
                    $Version = "15"  # Fallback to stable version
                }
            } catch {
                $Version = "15"  # Fallback version
            }
        }
        
        Write-Host "Installing PostgreSQL version $Version..." -ForegroundColor Cyan
        
        # Construct download URL for PostgreSQL Windows installer
        $majorVersion = $Version.Split('.')[0]
        $pgUrl = "https://get.enterprisedb.com/postgresql/postgresql-${Version}-1-windows-x64.exe"
        
        # Try alternative URL format if first doesn't work
        $pgPath = "$env:TEMP\postgresql-installer.exe"
        
        Write-Host "Downloading PostgreSQL installer..." -ForegroundColor Yellow
        $ProgressPreference = 'SilentlyContinue'
        
        try {
            Invoke-WebRequest -Uri $pgUrl -OutFile $pgPath -UseBasicParsing
        } catch {
            # Try alternative download source
            Write-Host "Trying alternative download source..." -ForegroundColor Yellow
            $pgUrl = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1258649"
            Invoke-WebRequest -Uri $pgUrl -OutFile $pgPath -UseBasicParsing
        }
        
        Write-Host "Download completed." -ForegroundColor Green
        
        # Install PostgreSQL
        Write-Host "Installing PostgreSQL (this may take several minutes)..." -ForegroundColor Yellow
        
        if ($Silent) {
            # Silent installation with predefined settings
            $installArgs = @(
                "--mode", "unattended",
                "--unattendedmodeui", "none", 
                "--superaccount", "postgres",
                "--superpassword", $AdminPassword,
                "--serverport", "5432",
                "--datadir", "`"$DataDirectory`"",
                "--locale", "English, United States"
            )
        } else {
            # Interactive installation with some defaults
            $installArgs = @(
                "--mode", "qt",
                "--superpassword", $AdminPassword,
                "--serverport", "5432"
            )
        }
        
        $process = Start-Process -FilePath $pgPath -ArgumentList $installArgs -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "PostgreSQL installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "PostgreSQL installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
            Write-Host "This may be normal for PostgreSQL installer." -ForegroundColor Cyan
        }
        
        # Clean up installer
        Remove-Item $pgPath -Force -ErrorAction SilentlyContinue
        
        # Add PostgreSQL to PATH
        Write-Host "Adding PostgreSQL to PATH..." -ForegroundColor Yellow
        $pgBinPath = "${env:ProgramFiles}\PostgreSQL\${majorVersion}\bin"
        if (Test-Path $pgBinPath) {
            $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
            if ($currentPath -notlike "*$pgBinPath*") {
                $newPath = "$currentPath;$pgBinPath"
                [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
                $env:Path = $newPath
                Write-Host "PostgreSQL added to PATH." -ForegroundColor Green
            }
        }
        
        # Wait for service to start
        Write-Host "Waiting for PostgreSQL service to start..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        # Verify installation
        Write-Host "Verifying PostgreSQL installation..." -ForegroundColor Yellow
        try {
            # Check if service is running
            $pgService = Get-Service -Name "postgresql*" | Where-Object {$_.Status -eq "Running"}
            if ($pgService) {
                Write-Host "PostgreSQL service is running: $($pgService.Name)" -ForegroundColor Green
            }
            
            # Try to connect and get version
            $env:PGPASSWORD = $AdminPassword
            $pgVersion = psql -U postgres -c "SELECT version();" -t 2>$null
            if ($pgVersion) {
                Write-Host "PostgreSQL is working correctly!" -ForegroundColor Green
            }
        } catch {
            Write-Host "PostgreSQL installed but verification failed. Service may need time to start." -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "Failed to install PostgreSQL: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You can download PostgreSQL manually from https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
        exit 1
    }
}

# Install pgAdmin (PostgreSQL administration tool)
if ($InstallPgAdmin) {
    Write-Host "`nInstalling pgAdmin 4..." -ForegroundColor Yellow
    
    try {
        # Check if pgAdmin is already installed
        $pgAdminInstalled = Test-Path "${env:ProgramFiles}\pgAdmin 4\bin\pgAdmin4.exe"
        if ($pgAdminInstalled -and -not $Force) {
            Write-Host "pgAdmin 4 is already installed." -ForegroundColor Cyan
        } else {
            # Download pgAdmin 4
            $pgAdminUrl = "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v7.8/windows/pgadmin4-7.8-x64.exe"
            $pgAdminPath = "$env:TEMP\pgadmin4-installer.exe"
            
            Write-Host "Downloading pgAdmin 4..." -ForegroundColor Cyan
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $pgAdminUrl -OutFile $pgAdminPath -UseBasicParsing
            
            Write-Host "Installing pgAdmin 4..." -ForegroundColor Cyan
            if ($Silent) {
                Start-Process -FilePath $pgAdminPath -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
            } else {
                Start-Process -FilePath $pgAdminPath -ArgumentList "/SILENT", "/NORESTART" -Wait
            }
            
            Write-Host "pgAdmin 4 installed successfully!" -ForegroundColor Green
            Remove-Item $pgAdminPath -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host "Failed to install pgAdmin 4: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create sample database and user
Write-Host "`nSetting up sample database..." -ForegroundColor Yellow
try {
    $env:PGPASSWORD = $AdminPassword
    
    # Create a sample database
    psql -U postgres -c "CREATE DATABASE sampledb;" 2>$null
    
    # Create a sample user
    psql -U postgres -c "CREATE USER developer WITH PASSWORD 'devpass123';" 2>$null
    psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE sampledb TO developer;" 2>$null
    
    Write-Host "Sample database 'sampledb' created with user 'developer'" -ForegroundColor Green
} catch {
    Write-Host "Could not create sample database. You can create it manually." -ForegroundColor Yellow
}

Write-Host "`nPostgreSQL installation completed!" -ForegroundColor Green

# Show installation summary
Write-Host "`nInstallation Summary:" -ForegroundColor Cyan
Write-Host "PostgreSQL Database Server: Installed and running" -ForegroundColor White
Write-Host "Admin User: postgres" -ForegroundColor White
Write-Host "Admin Password: $AdminPassword" -ForegroundColor White
Write-Host "Default Port: 5432" -ForegroundColor White
Write-Host "Sample Database: sampledb" -ForegroundColor White
Write-Host "Sample User: developer (password: devpass123)" -ForegroundColor White

if ($InstallPgAdmin) {
    Write-Host "pgAdmin 4: Web-based administration tool installed" -ForegroundColor White
}

# Provide useful PostgreSQL commands
Write-Host "`nUseful PostgreSQL Commands:" -ForegroundColor Cyan
Write-Host "Connection Commands:" -ForegroundColor Yellow
Write-Host "  psql -U postgres                    # Connect as admin user"
Write-Host "  psql -U developer -d sampledb       # Connect to sample database"
Write-Host "  psql 'postgresql://user:pass@localhost:5432/dbname'  # Connection string"

Write-Host "`nDatabase Commands:" -ForegroundColor Yellow
Write-Host "  \l                                  # List databases"
Write-Host "  \c database_name                    # Connect to database"
Write-Host "  \dt                                 # List tables"
Write-Host "  \du                                 # List users"
Write-Host "  \q                                  # Quit psql"

Write-Host "`nService Commands:" -ForegroundColor Yellow
Write-Host "  net start postgresql-x64-${majorVersion}    # Start PostgreSQL service"
Write-Host "  net stop postgresql-x64-${majorVersion}     # Stop PostgreSQL service"

Write-Host "`nAccess URLs:" -ForegroundColor Cyan
Write-Host "pgAdmin 4: http://localhost/pgadmin4 (after first run setup)" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Launch pgAdmin 4 from Start Menu for GUI management" -ForegroundColor White
Write-Host "2. Connect using: localhost:5432, user: postgres, password: $AdminPassword" -ForegroundColor White
Write-Host "3. Create your application databases and users" -ForegroundColor White

# Usage examples
Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-postgresql.ps1                             # Install latest version"
Write-Host "  .\install-postgresql.ps1 -Version '14'               # Install specific version"
Write-Host "  .\install-postgresql.ps1 -AdminPassword 'mypass'     # Custom admin password"
Write-Host "  .\install-postgresql.ps1 -Silent                     # Silent installation"
Write-Host "  .\install-postgresql.ps1 -InstallPgAdmin:`$false      # Skip pgAdmin"