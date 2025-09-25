# Apps Installation Subscript
# Unified script for installing browsers, IDEs, and development tools
# Enhanced with comprehensive software verification system

param(
    # Browser options
    [switch]$Chrome = $false,
    [switch]$Brave = $false,
    [switch]$Firefox = $false,
    
    # IDE options
    [switch]$VSCode = $false,
    [switch]$Cursor = $false,
    
    # Installation options
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$All = $false,
    [switch]$Help = $false,
    
    # VSCode specific options
    [switch]$VSCodeSystem = $false,
    [string[]]$VSCodeExtensions = @(),
    [switch]$IncludeCommonExtensions = $false,
    
    # Verification options
    [switch]$VerifyOnly = $false,
    [switch]$Detailed = $false
)

# Import the software verification module
$modulePath = Join-Path $PSScriptRoot "..\modules\SoftwareVerification.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Warning "Software verification module not found. Using basic verification."
}

# Color functions
function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "* $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "X $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "i $Message" -ForegroundColor Blue
}

# Help function
function Show-Help {
    Write-Header "Apps Installation Script Help"
    Write-Host "Usage: .\install-apps.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "Browser Options:" -ForegroundColor Yellow
    Write-Host "  -Chrome          Install Google Chrome"
    Write-Host "  -Brave           Install Brave Browser"
    Write-Host "  -Firefox         Install Mozilla Firefox"
    Write-Host ""
    Write-Host "IDE Options:" -ForegroundColor Yellow
    Write-Host "  -VSCode          Install Visual Studio Code"
    Write-Host "  -Cursor          Install Cursor IDE"
    Write-Host ""
    Write-Host "Installation Options:" -ForegroundColor Yellow
    Write-Host "  -All             Install all available apps"
    Write-Host "  -Silent          Silent installation (where supported)"
    Write-Host "  -Force           Force reinstallation if already installed"
    Write-Host ""
    Write-Host "Verification Options:" -ForegroundColor Yellow
    Write-Host "  -VerifyOnly      Only verify installation status (no installation)"
    Write-Host "  -Detailed        Show detailed verification information"
    Write-Host ""
    Write-Host "VSCode Specific Options:" -ForegroundColor Yellow
    Write-Host "  -VSCodeSystem    Install VSCode system-wide (requires admin)"
    Write-Host "  -VSCodeExtensions @('ext1','ext2')  Install specific extensions"
    Write-Host "  -IncludeCommonExtensions  Install common development extensions"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\install-apps.ps1 -Chrome -VSCode"
    Write-Host "  .\install-apps.ps1 -All -Silent"
    Write-Host "  .\install-apps.ps1 -VSCode -IncludeCommonExtensions"
    Write-Host "  .\install-apps.ps1 -VerifyOnly -All -Detailed"
    Write-Host "  .\install-apps.ps1 -Chrome -Force -Detailed"
    exit 0
}

# Enhanced function to check if application is installed using the verification module
function Test-AppInstalled {
    param(
        [string]$AppName, 
        [string[]]$SearchPaths = @(),
        [switch]$Detailed = $false
    )
    
    # Try to use the verification module first
    if (Get-Command "Test-PredefinedSoftware" -ErrorAction SilentlyContinue) {
        try {
            $result = Test-PredefinedSoftware -SoftwareName $AppName -Detailed:$Detailed -Quiet
            return @{
                IsInstalled = $result.IsInstalled
                Version = $result.Version
                InstallPath = $result.InstallPath
                ExecutablePath = $result.ExecutablePath
                Status = $result.Status
                VerificationResult = $result
            }
        } catch {
            Write-Warning "Verification module failed for $AppName. Using fallback method."
        }
    }
    
    # Fallback to original method if verification module is not available
    $command = Get-Command $AppName -ErrorAction SilentlyContinue
    if ($command) { 
        return @{
            IsInstalled = $true
            Version = "Unknown"
            InstallPath = Split-Path $command.Source -Parent
            ExecutablePath = $command.Source
            Status = "Command Found"
            VerificationResult = $null
        }
    }
    
    # Check common installation paths
    $defaultPaths = @(
        "${env:ProgramFiles}\*$AppName*",
        "${env:ProgramFiles(x86)}\*$AppName*",
        "${env:LOCALAPPDATA}\Programs\*$AppName*",
        "${env:APPDATA}\*$AppName*"
    )
    
    $allPaths = $defaultPaths + $SearchPaths
    foreach ($path in $allPaths) {
        if (Test-Path $path) {
            return @{
                IsInstalled = $true
                Version = "Unknown"
                InstallPath = $path
                ExecutablePath = ""
                Status = "Path Found"
                VerificationResult = $null
            }
        }
    }
    
    # Check Windows Registry for installed programs
    try {
        $installed = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$AppName*" }
        if ($installed) { 
            return @{
                IsInstalled = $true
                Version = $installed.Version
                InstallPath = $installed.InstallLocation
                ExecutablePath = ""
                Status = "Registry Found"
                VerificationResult = $null
            }
        }
    } catch {
        # WMI query failed, continue with other checks
    }
    
    return @{
        IsInstalled = $false
        Version = "Not Installed"
        InstallPath = ""
        ExecutablePath = ""
        Status = "Not Found"
        VerificationResult = $null
    }
}

# Function to download and install an application
function Install-App {
    param(
        [string]$AppName,
        [string]$DownloadUrl,
        [string]$InstallerName,
        [string[]]$InstallArgs = @(),
        [string[]]$SilentArgs = @()
    )
    
    Write-Info "Installing $AppName..."
    
    $tempPath = "$env:TEMP\$InstallerName"
    
    try {
        Write-Info "Downloading $AppName..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $tempPath -UseBasicParsing
        
        Write-Info "Installing $AppName..."
        $args = if ($Silent -and $SilentArgs.Count -gt 0) { $SilentArgs } else { $InstallArgs }
        
        if ($args.Count -gt 0) {
            Start-Process -FilePath $tempPath -ArgumentList $args -Wait
        } else {
            Start-Process -FilePath $tempPath -Wait
        }
        
        Write-Success "$AppName installed successfully!"
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        Write-Error "Failed to install $AppName`: $($_.Exception.Message)"
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        return $false
    }
}

# Main installation function
function Start-AppsInstallation {
    Write-Header "Apps Installation Script"
    
    if ($Help) {
        Show-Help
    }
    
    # Handle verification-only mode
    if ($VerifyOnly) {
        Write-Header "Software Verification Mode"
        
        $softwareToVerify = @()
        if ($Chrome -or $All) { $softwareToVerify += "Chrome" }
        if ($Brave -or $All) { $softwareToVerify += "Brave" }
        if ($Firefox -or $All) { $softwareToVerify += "Firefox" }
        if ($VSCode -or $All) { $softwareToVerify += "VSCode" }
        if ($Cursor -or $All) { $softwareToVerify += "Cursor" }
        
        if ($softwareToVerify.Count -eq 0) {
            Write-Info "No software selected for verification. Use -All to verify all supported software."
            return
        }
        
        if (Get-Command "Test-MultipleSoftware" -ErrorAction SilentlyContinue) {
            $results = Test-MultipleSoftware -SoftwareList $softwareToVerify -Detailed:$Detailed
            return $results
        } else {
            Write-Warning "Verification module not available. Performing basic checks."
            foreach ($software in $softwareToVerify) {
                $result = Test-AppInstalled -AppName $software -Detailed:$Detailed
                Write-Host "$software`: $($result.Status)" -ForegroundColor $(if ($result.IsInstalled) { "Green" } else { "Red" })
            }
        }
        return
    }
    
    # Set all apps if -All is specified
    if ($All) {
        $Chrome = $true
        $Brave = $true
        $Firefox = $true
        $VSCode = $true
        $Cursor = $true
    }
    
    # Check if any app is selected
    if (-not ($Chrome -or $Brave -or $Firefox -or $VSCode -or $Cursor)) {
        Write-Info "No applications selected for installation."
        Write-Info "Use -Help to see available options, -All to install everything, or -VerifyOnly to check installation status."
        return
    }
    
    $results = @()
    
    # Install Browsers
    if ($Chrome -or $Brave -or $Firefox) {
        Write-Header "Installing Browsers"
        
        # Google Chrome
        if ($Chrome) {
            $chromeCheck = Test-AppInstalled "Chrome" -Detailed:$Detailed
            if ($chromeCheck.IsInstalled -and -not $Force) {
                Write-Info "Google Chrome is already installed ($($chromeCheck.Status)). Use -Force to reinstall."
                if ($chromeCheck.Version -ne "Unknown" -and $chromeCheck.Version -ne "Not Installed") {
                    Write-Info "Current version: $($chromeCheck.Version.Split("`n")[0])"
                }
                $results += @{ App = "Chrome"; Status = "Already Installed"; Version = $chromeCheck.Version; Path = $chromeCheck.InstallPath }
            } else {
                $success = Install-App -AppName "Google Chrome" `
                    -DownloadUrl "https://dl.google.com/chrome/install/chrome_installer.exe" `
                    -InstallerName "chrome_installer.exe" `
                    -InstallArgs @("/install") `
                    -SilentArgs @("/silent", "/install")
                
                if ($success) {
                    # Verify installation after successful install
                    Start-Sleep -Seconds 2
                    $postInstallCheck = Test-AppInstalled "Chrome" -Detailed:$Detailed
                    $results += @{ App = "Chrome"; Status = "Installed"; Version = $postInstallCheck.Version; Path = $postInstallCheck.InstallPath }
                } else {
                    $results += @{ App = "Chrome"; Status = "Failed"; Version = "N/A"; Path = "N/A" }
                }
            }
        }
        
        # Brave Browser
        if ($Brave) {
            $braveInstalled = Test-AppInstalled "Brave"
            if ($braveInstalled -and -not $Force) {
                Write-Info "Brave Browser is already installed. Use -Force to reinstall."
                $results += @{ App = "Brave"; Status = "Already Installed" }
            } else {
                $success = Install-App -AppName "Brave Browser" `
                    -DownloadUrl "https://laptop-updates.brave.com/latest/winx64" `
                    -InstallerName "brave_installer.exe" `
                    -InstallArgs @() `
                    -SilentArgs @("/silent")
                $results += @{ App = "Brave"; Status = if ($success) { "Installed" } else { "Failed" } }
            }
        }
        
        # Mozilla Firefox
        if ($Firefox) {
            $firefoxInstalled = Test-AppInstalled "Firefox"
            if ($firefoxInstalled -and -not $Force) {
                Write-Info "Mozilla Firefox is already installed. Use -Force to reinstall."
                $results += @{ App = "Firefox"; Status = "Already Installed" }
            } else {
                $success = Install-App -AppName "Mozilla Firefox" `
                    -DownloadUrl "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US" `
                    -InstallerName "firefox_installer.exe" `
                    -InstallArgs @("/S") `
                    -SilentArgs @("/S")
                $results += @{ App = "Firefox"; Status = if ($success) { "Installed" } else { "Failed" } }
            }
        }
    }
    
    # Install IDEs
    if ($VSCode -or $Cursor) {
        Write-Header "Installing Development IDEs"
        
        # Visual Studio Code
        if ($VSCode) {
            $vscodeInstalled = Test-AppInstalled "code"
            if ($vscodeInstalled -and -not $Force) {
                Write-Info "Visual Studio Code is already installed. Use -Force to reinstall."
                $results += @{ App = "VSCode"; Status = "Already Installed" }
            } else {
                $downloadUrl = if ($VSCodeSystem) {
                    "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
                } else {
                    "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
                }
                
                $installerName = if ($VSCodeSystem) { "VSCodeSetup.exe" } else { "VSCodeUserSetup.exe" }
                $installType = if ($VSCodeSystem) { "system-wide" } else { "user" }
                
                Write-Info "Installing VS Code ($installType)..."
                
                $success = Install-App -AppName "Visual Studio Code" `
                    -DownloadUrl $downloadUrl `
                    -InstallerName $installerName `
                    -InstallArgs @("/VERYSILENT", "/NORESTART", "/MERGETASKS=!runcode") `
                    -SilentArgs @("/VERYSILENT", "/NORESTART", "/MERGETASKS=!runcode")
                
                if ($success) {
                    # Install extensions if specified
                    if ($VSCodeExtensions.Count -gt 0 -or $IncludeCommonExtensions) {
                        Write-Info "Installing VS Code extensions..."
                        
                        $extensionsToInstall = $VSCodeExtensions
                        if ($IncludeCommonExtensions) {
                            $commonExtensions = @(
                                "ms-python.python",
                                "ms-vscode.powershell",
                                "ms-vscode.vscode-typescript-next",
                                "esbenp.prettier-vscode",
                                "ms-vscode.vscode-json",
                                "redhat.vscode-yaml"
                            )
                            $extensionsToInstall += $commonExtensions
                        }
                        
                        foreach ($extension in $extensionsToInstall) {
                            try {
                                Write-Info "Installing extension: $extension"
                                & code --install-extension $extension --force
                            } catch {
                                Write-Error "Failed to install extension $extension`: $($_.Exception.Message)"
                            }
                        }
                    }
                }
                
                $results += @{ App = "VSCode"; Status = if ($success) { "Installed" } else { "Failed" } }
            }
        }
        
        # Cursor IDE
        if ($Cursor) {
            $cursorInstalled = Test-AppInstalled "Cursor"
            if ($cursorInstalled -and -not $Force) {
                Write-Info "Cursor IDE is already installed. Use -Force to reinstall."
                $results += @{ App = "Cursor"; Status = "Already Installed" }
            } else {
                $success = Install-App -AppName "Cursor IDE" `
                    -DownloadUrl "https://download.todesktop.com/200122auv92xb0r/Cursor%20Setup%200.42.3%20-%20x64.exe" `
                    -InstallerName "cursor_setup.exe" `
                    -InstallArgs @("/S") `
                    -SilentArgs @("/S")
                $results += @{ App = "Cursor"; Status = if ($success) { "Installed" } else { "Failed" } }
            }
        }
    }
    
    # Show installation summary
    Write-Header "Installation Summary"
    foreach ($result in $results) {
        $statusColor = switch ($result.Status) {
            "Installed" { "Green" }
            "Already Installed" { "Cyan" }
            "Failed" { "Red" }
            default { "White" }
        }
        
        Write-Host "$($result.App): " -NoNewline -ForegroundColor White
        Write-Host $result.Status -ForegroundColor $statusColor
        
        if ($result.Version -and $result.Version -ne "Unknown" -and $result.Version -ne "N/A") {
            $versionLine = $result.Version.Split("`n")[0].Trim()
            Write-Host "  Version: $versionLine" -ForegroundColor Gray
        }
        
        if ($result.Path -and $result.Path -ne "N/A" -and $result.Path -ne "") {
            Write-Host "  Path: $($result.Path)" -ForegroundColor Gray
        }
    }
    
    Write-Info "Apps installation process completed."
    
    # Provide verification suggestion
    if ($results | Where-Object { $_.Status -eq "Installed" }) {
        Write-Info "To verify installations, run: .\install-apps.ps1 -VerifyOnly -All -Detailed"
    }
    
    return $results
}

# Auto-execute if script is run directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    Start-AppsInstallation
}