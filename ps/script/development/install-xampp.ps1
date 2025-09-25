# Install XAMPP Server Stack
# This script downloads and installs XAMPP (Apache, MySQL, PHP, Perl)

param(
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$StartServices = $true,
    [string]$InstallPath = "C:\xampp"
)

Write-Host "XAMPP Server Stack Installation Script" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Check if XAMPP is already installed
$xamppInstalled = Test-Path "$InstallPath\xampp-control.exe"
if ($xamppInstalled -and -not $Force) {
    Write-Host "XAMPP is already installed at $InstallPath" -ForegroundColor Yellow
    Write-Host "Use -Force to reinstall." -ForegroundColor Cyan
    
    if ($StartServices) {
        Write-Host "Starting XAMPP services..." -ForegroundColor Yellow
        Start-Process "$InstallPath\xampp-control.exe"
    }
    exit 0
}

Write-Host "Installing XAMPP..." -ForegroundColor Yellow

try {
    # Get latest XAMPP version
    Write-Host "Fetching latest XAMPP version..." -ForegroundColor Cyan
    
    # XAMPP download URL (typically points to latest version)
    $xamppUrl = "https://downloadsapachefriends.global.ssl.fastly.net/8.2.12/xampp-windows-x64-8.2.12-0-VS16-installer.exe"
    
    # Try to get the latest version dynamically
    try {
        $xamppDownloadPage = Invoke-WebRequest -Uri "https://www.apachefriends.org/download.html" -UseBasicParsing
        $downloadMatch = $xamppDownloadPage.Links | Where-Object {$_.href -like "*xampp-windows-x64*installer.exe"} | Select-Object -First 1
        if ($downloadMatch) {
            $xamppUrl = $downloadMatch.href
            if (-not $xamppUrl.StartsWith("http")) {
                $xamppUrl = "https://www.apachefriends.org" + $xamppUrl
            }
        }
    } catch {
        Write-Host "Using fallback download URL..." -ForegroundColor Yellow
    }
    
    $xamppPath = "$env:TEMP\xampp-installer.exe"
    
    Write-Host "Downloading XAMPP installer..." -ForegroundColor Yellow
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $xamppUrl -OutFile $xamppPath -UseBasicParsing
    Write-Host "Download completed." -ForegroundColor Green
    
    # Install XAMPP
    Write-Host "Installing XAMPP to $InstallPath..." -ForegroundColor Yellow
    Write-Host "This may take several minutes..." -ForegroundColor Cyan
    
    if ($Silent) {
        # Silent installation
        $installArgs = @(
            "--mode", "unattended",
            "--unattendedmodeui", "none",
            "--prefix", $InstallPath,
            "--enable-components", "apache,mysql,php,phpmyadmin,webalizer,fake_sendmail,tomcat,perl"
        )
    } else {
        # Interactive installation with predefined path
        $installArgs = @(
            "--mode", "qt",
            "--prefix", $InstallPath
        )
    }
    
    $process = Start-Process -FilePath $xamppPath -ArgumentList $installArgs -Wait -PassThru
    
    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1) {
        Write-Host "XAMPP installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "XAMPP installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
    }
    
    # Clean up installer
    Remove-Item $xamppPath -Force -ErrorAction SilentlyContinue
    
    # Add XAMPP to PATH
    Write-Host "Adding XAMPP to PATH..." -ForegroundColor Yellow
    $xamppBinPaths = @("$InstallPath", "$InstallPath\php", "$InstallPath\mysql\bin", "$InstallPath\apache\bin")
    
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $pathUpdated = $false
    
    foreach ($binPath in $xamppBinPaths) {
        if (Test-Path $binPath -and $currentPath -notlike "*$binPath*") {
            $currentPath = "$currentPath;$binPath"
            $pathUpdated = $true
        }
    }
    
    if ($pathUpdated) {
        [System.Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
        $env:Path = $currentPath
        Write-Host "XAMPP paths added to user PATH." -ForegroundColor Green
    }
    
    # Verify installation
    Write-Host "Verifying XAMPP installation..." -ForegroundColor Yellow
    
    $xamppComponents = @{
        "XAMPP Control Panel" = "$InstallPath\xampp-control.exe"
        "Apache" = "$InstallPath\apache\bin\httpd.exe"
        "MySQL" = "$InstallPath\mysql\bin\mysqld.exe"
        "PHP" = "$InstallPath\php\php.exe"
        "phpMyAdmin" = "$InstallPath\phpMyAdmin\index.php"
    }
    
    foreach ($component in $xamppComponents.Keys) {
        if (Test-Path $xamppComponents[$component]) {
            Write-Host "  ✓ $component installed" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $component not found" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Failed to install XAMPP: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "You can download XAMPP manually from https://www.apachefriends.org/" -ForegroundColor Yellow
    exit 1
}

# Configure XAMPP
Write-Host "`nConfiguring XAMPP..." -ForegroundColor Yellow

try {
    # Create desktop shortcut for XAMPP Control Panel
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktopPath\XAMPP Control Panel.lnk"
    
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "$InstallPath\xampp-control.exe"
    $Shortcut.WorkingDirectory = $InstallPath
    $Shortcut.Description = "XAMPP Control Panel"
    $Shortcut.Save()
    
    Write-Host "Desktop shortcut created." -ForegroundColor Green
    
    # Set up basic Apache configuration
    $apacheConf = "$InstallPath\apache\conf\httpd.conf"
    if (Test-Path $apacheConf) {
        Write-Host "Apache configuration found." -ForegroundColor Green
    }
    
    # Set up basic MySQL configuration
    $mysqlConf = "$InstallPath\mysql\bin\my.ini"
    if (Test-Path $mysqlConf) {
        Write-Host "MySQL configuration found." -ForegroundColor Green
    }
    
} catch {
    Write-Host "Configuration setup had some issues, but XAMPP should still work." -ForegroundColor Yellow
}

# Start XAMPP services if requested
if ($StartServices) {
    Write-Host "`nStarting XAMPP Control Panel..." -ForegroundColor Yellow
    try {
        Start-Process "$InstallPath\xampp-control.exe"
        Write-Host "XAMPP Control Panel launched." -ForegroundColor Green
        Write-Host "Use the Control Panel to start Apache and MySQL services." -ForegroundColor Cyan
    } catch {
        Write-Host "Could not start XAMPP Control Panel automatically." -ForegroundColor Yellow
    }
}

Write-Host "`nXAMPP installation completed!" -ForegroundColor Green

# Show installation summary
Write-Host "`nInstallation Summary:" -ForegroundColor Cyan
Write-Host "XAMPP Installation Path: $InstallPath" -ForegroundColor White
Write-Host "Control Panel: $InstallPath\xampp-control.exe" -ForegroundColor White
Write-Host "Document Root: $InstallPath\htdocs" -ForegroundColor White
Write-Host "Apache Port: 80 (HTTP), 443 (HTTPS)" -ForegroundColor White
Write-Host "MySQL Port: 3306" -ForegroundColor White
Write-Host "phpMyAdmin: http://localhost/phpmyadmin" -ForegroundColor White

# Show component versions (if available)
Write-Host "`nComponent Information:" -ForegroundColor Cyan
try {
    if (Test-Path "$InstallPath\php\php.exe") {
        $phpVersion = & "$InstallPath\php\php.exe" -v 2>$null | Select-String "PHP \d+\.\d+\.\d+" | ForEach-Object {$_.Matches[0].Value}
        Write-Host "PHP: $phpVersion" -ForegroundColor White
    }
    
    if (Test-Path "$InstallPath\apache\bin\httpd.exe") {
        $apacheVersion = & "$InstallPath\apache\bin\httpd.exe" -v 2>$null | Select-String "Apache/\d+\.\d+\.\d+" | ForEach-Object {$_.Matches[0].Value}
        Write-Host "Apache: $apacheVersion" -ForegroundColor White
    }
    
    if (Test-Path "$InstallPath\mysql\bin\mysqld.exe") {
        Write-Host "MySQL: Community Server (version in Control Panel)" -ForegroundColor White
    }
} catch {
    Write-Host "Component versions available in XAMPP Control Panel." -ForegroundColor Yellow
}

# Provide usage instructions
Write-Host "`nUsage Instructions:" -ForegroundColor Cyan
Write-Host "1. Launch XAMPP Control Panel from desktop shortcut or Start Menu" -ForegroundColor White
Write-Host "2. Start Apache and MySQL services using the Control Panel" -ForegroundColor White
Write-Host "3. Place your PHP files in: $InstallPath\htdocs" -ForegroundColor White
Write-Host "4. Access your applications at: http://localhost/" -ForegroundColor White
Write-Host "5. Manage databases at: http://localhost/phpmyadmin" -ForegroundColor White

Write-Host "`nQuick Access URLs:" -ForegroundColor Cyan
Write-Host "Dashboard: http://localhost/dashboard/" -ForegroundColor White
Write-Host "phpMyAdmin: http://localhost/phpmyadmin/" -ForegroundColor White
Write-Host "Webalizer: http://localhost/webalizer/" -ForegroundColor White

Write-Host "`nCommon XAMPP Commands:" -ForegroundColor Cyan
Write-Host "Start Services:" -ForegroundColor Yellow
Write-Host "  Use XAMPP Control Panel GUI (recommended)" -ForegroundColor White
Write-Host "  Or via command line from ${InstallPath}:" -ForegroundColor White
Write-Host "    apache_start.bat" -ForegroundColor White
Write-Host "    mysql_start.bat" -ForegroundColor White

Write-Host "`nFile Locations:" -ForegroundColor Cyan
Write-Host "Web Files: $InstallPath\htdocs\" -ForegroundColor White
Write-Host "Apache Config: $InstallPath\apache\conf\httpd.conf" -ForegroundColor White
Write-Host "PHP Config: $InstallPath\php\php.ini" -ForegroundColor White
Write-Host "MySQL Config: $InstallPath\mysql\bin\my.ini" -ForegroundColor White
Write-Host "Error Logs: $InstallPath\apache\logs\" -ForegroundColor White

Write-Host "`nSecurity Notice:" -ForegroundColor Yellow
Write-Host "XAMPP is configured for development use. For production:" -ForegroundColor Red
Write-Host "- Change default MySQL root password (currently blank)" -ForegroundColor White
Write-Host "- Configure proper Apache security settings" -ForegroundColor White
Write-Host "- Remove demo applications and files" -ForegroundColor White

# Usage examples
Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-xampp.ps1                           # Standard installation"
Write-Host "  .\install-xampp.ps1 -Silent                   # Silent installation"
Write-Host "  .\install-xampp.ps1 -InstallPath 'D:\xampp'   # Custom install path"
Write-Host "  .\install-xampp.ps1 -StartServices:`$false     # Don't start services"
Write-Host "  .\install-xampp.ps1 -Force                    # Force reinstall"
