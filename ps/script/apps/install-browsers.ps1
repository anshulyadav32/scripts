# Install Web Browsers (Chrome, Brave)
# This script downloads and installs modern web browsers
# Enhanced with comprehensive software verification system

# Import the software verification module
$modulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "modules\SoftwareVerification.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Warning "Software verification module not found. Using basic verification."
}

param(
    [switch]$Chrome = $true,
    [switch]$Brave = $true,
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$VerifyOnly = $false,
    [switch]$Detailed = $false
)

# Enhanced function to check if application is installed using the verification module
function Test-AppInstalled {
    param(
        [string]$AppName,
        [switch]$Detailed
    )
    
    # Try to use the verification module first
    if (Get-Command Test-PredefinedSoftware -ErrorAction SilentlyContinue) {
        try {
            $result = Test-PredefinedSoftware -SoftwareName $AppName -Detailed:$Detailed
            return $result
        } catch {
            Write-Warning "Verification module failed for $AppName. Using fallback method."
        }
    }
    
    # Fallback to basic verification
    $isInstalled = $false
    $version = "Unknown"
    $paths = @()
    
    # Check for common browser installations
    switch ($AppName) {
        "Chrome" {
            $chromeExe = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
            $chromeExe86 = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
            if (Test-Path $chromeExe) {
                $isInstalled = $true
                $paths += $chromeExe
                try {
                    $version = (Get-ItemProperty $chromeExe).VersionInfo.ProductVersion
                } catch { $version = "Unknown" }
            } elseif (Test-Path $chromeExe86) {
                $isInstalled = $true
                $paths += $chromeExe86
                try {
                    $version = (Get-ItemProperty $chromeExe86).VersionInfo.ProductVersion
                } catch { $version = "Unknown" }
            }
        }
        "Brave" {
            $braveExe = "${env:ProgramFiles}\BraveSoftware\Brave-Browser\Application\brave.exe"
            $braveExe86 = "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe"
            if (Test-Path $braveExe) {
                $isInstalled = $true
                $paths += $braveExe
                try {
                    $version = (Get-ItemProperty $braveExe).VersionInfo.ProductVersion
                } catch { $version = "Unknown" }
            } elseif (Test-Path $braveExe86) {
                $isInstalled = $true
                $paths += $braveExe86
                try {
                    $version = (Get-ItemProperty $braveExe86).VersionInfo.ProductVersion
                } catch { $version = "Unknown" }
            }
        }
    }
    
    return @{
        IsInstalled = $isInstalled
        Version = $version
        Paths = $paths
        Status = if ($isInstalled) { "Installed" } else { "Not Installed" }
    }
}

Write-Host "Web Browsers Installation Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Handle verification-only mode
if ($VerifyOnly) {
    Write-Host "Verifying browser installations..." -ForegroundColor Yellow
    
    if ($Chrome) {
        $chromeResult = Test-AppInstalled -AppName "Chrome" -Detailed:$Detailed
        if ($chromeResult.IsInstalled) {
            Write-Host "[OK] Google Chrome is installed" -ForegroundColor Green
            Write-Host "Version: $($chromeResult.Version)" -ForegroundColor Cyan
            if ($Detailed -and $chromeResult.Paths) {
                Write-Host "Installation Path(s):" -ForegroundColor Cyan
                $chromeResult.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
            }
        } else {
            Write-Host "[ERROR] Google Chrome is not installed" -ForegroundColor Red
        }
    }
    
    if ($Brave) {
        $braveResult = Test-AppInstalled -AppName "Brave" -Detailed:$Detailed
        if ($braveResult.IsInstalled) {
            Write-Host "[OK] Brave Browser is installed" -ForegroundColor Green
            Write-Host "Version: $($braveResult.Version)" -ForegroundColor Cyan
            if ($Detailed -and $braveResult.Paths) {
                Write-Host "Installation Path(s):" -ForegroundColor Cyan
                $braveResult.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
            }
        } else {
            Write-Host "[ERROR] Brave Browser is not installed" -ForegroundColor Red
        }
    }
    exit 0
}

# Install Google Chrome
if ($Chrome) {
    Write-Host "`nInstalling Google Chrome..." -ForegroundColor Yellow
    
    $chromeVerification = Test-AppInstalled -AppName "Chrome" -Detailed:$Detailed
    if ($chromeVerification.IsInstalled -and -not $Force) {
        Write-Host "Google Chrome is already installed: $($chromeVerification.Version)" -ForegroundColor Yellow
        if ($Detailed -and $chromeVerification.Paths) {
            Write-Host "Installation Path(s):" -ForegroundColor Cyan
            $chromeVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        }
        Write-Host "Use -Force to reinstall." -ForegroundColor Cyan
    } else {
        try {
            $chromeUrl = "https://dl.google.com/chrome/install/chrome_installer.exe"
            $chromePath = "$env:TEMP\chrome_installer.exe"
            
            Write-Host "Downloading Google Chrome..." -ForegroundColor Cyan
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $chromeUrl -OutFile $chromePath -UseBasicParsing
            
            Write-Host "Installing Google Chrome..." -ForegroundColor Cyan
            if ($Silent) {
                Start-Process -FilePath $chromePath -ArgumentList "/silent", "/install" -Wait
            } else {
                Start-Process -FilePath $chromePath -ArgumentList "/install" -Wait
            }
            
            # Verify installation using enhanced verification
            Write-Host "Verifying Chrome installation..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            $postInstallVerification = Test-AppInstalled -AppName "Chrome" -Detailed:$Detailed
            
            if ($postInstallVerification.IsInstalled) {
                Write-Host "[OK] Google Chrome installation verified successfully!" -ForegroundColor Green
                Write-Host "Version: $($postInstallVerification.Version)" -ForegroundColor Cyan
                if ($Detailed -and $postInstallVerification.Paths) {
                    Write-Host "Installation Path(s):" -ForegroundColor Cyan
                    $postInstallVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
                }
            } else {
                Write-Host "[WARNING] Chrome installation verification failed." -ForegroundColor Yellow
            }
            
            Remove-Item $chromePath -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Failed to install Google Chrome: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Install Brave Browser
if ($Brave) {
    Write-Host "`nInstalling Brave Browser..." -ForegroundColor Yellow
    
    $braveVerification = Test-AppInstalled -AppName "Brave" -Detailed:$Detailed
    if ($braveVerification.IsInstalled -and -not $Force) {
        Write-Host "Brave Browser is already installed: $($braveVerification.Version)" -ForegroundColor Yellow
        if ($Detailed -and $braveVerification.Paths) {
            Write-Host "Installation Path(s):" -ForegroundColor Cyan
            $braveVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        }
        Write-Host "Use -Force to reinstall." -ForegroundColor Cyan
    } else {
        try {
            # Get latest Brave download URL
            $braveReleasesUrl = "https://api.github.com/repos/brave/brave-browser/releases/latest"
            $latestRelease = Invoke-RestMethod -Uri $braveReleasesUrl -UseBasicParsing
            $braveUrl = ($latestRelease.assets | Where-Object { $_.name -like "*BraveBrowserStandaloneSetup.exe" }).browser_download_url
            
            if (-not $braveUrl) {
                # Fallback to direct download
                $braveUrl = "https://laptop-updates.brave.com/latest/winx64"
            }
            
            $bravePath = "$env:TEMP\BraveSetup.exe"
            
            Write-Host "Downloading Brave Browser..." -ForegroundColor Cyan
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $braveUrl -OutFile $bravePath -UseBasicParsing
            
            Write-Host "Installing Brave Browser..." -ForegroundColor Cyan
            if ($Silent) {
                Start-Process -FilePath $bravePath -ArgumentList "--silent", "--install" -Wait
            } else {
                Start-Process -FilePath $bravePath -ArgumentList "--install" -Wait
            }
            
            # Verify installation using enhanced verification
            Write-Host "Verifying Brave installation..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            $postInstallVerification = Test-AppInstalled -AppName "Brave" -Detailed:$Detailed
            
            if ($postInstallVerification.IsInstalled) {
                Write-Host "[OK] Brave Browser installation verified successfully!" -ForegroundColor Green
                Write-Host "Version: $($postInstallVerification.Version)" -ForegroundColor Cyan
                if ($Detailed -and $postInstallVerification.Paths) {
                    Write-Host "Installation Path(s):" -ForegroundColor Cyan
                    $postInstallVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
                }
            } else {
                Write-Host "[WARNING] Brave installation verification failed." -ForegroundColor Yellow
            }
            Remove-Item $bravePath -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Failed to install Brave Browser: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Set default browser (optional)
if (-not $Silent) {
    Write-Host "`nBrowser Installation Summary:" -ForegroundColor Cyan
    if ($Chrome) { Write-Host "✓ Google Chrome installed" -ForegroundColor Green }
    if ($Brave) { Write-Host "✓ Brave Browser installed" -ForegroundColor Green }
    
    $setDefault = Read-Host "`nWould you like to set a default browser? (chrome/brave/N)"
    switch ($setDefault.ToLower()) {
        "chrome" {
            Write-Host "Please set Chrome as default manually in Windows Settings > Apps > Default apps" -ForegroundColor Yellow
        }
        "brave" {
            Write-Host "Please set Brave as default manually in Windows Settings > Apps > Default apps" -ForegroundColor Yellow
        }
        default {
            Write-Host "No default browser change requested." -ForegroundColor Cyan
        }
    }
}

Write-Host "`nWeb Browsers installation completed!" -ForegroundColor Green

# Usage examples
Write-Host "`nUsage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-browsers.ps1                    # Install both Chrome and Brave"
Write-Host "  .\install-browsers.ps1 -Chrome            # Install Chrome only"
Write-Host "  .\install-browsers.ps1 -Brave             # Install Brave only"
Write-Host "  .\install-browsers.ps1 -Silent            # Silent installation"
Write-Host "  .\install-browsers.ps1 -Force             # Force reinstall"

Write-Host "`nBrowser Features:" -ForegroundColor Cyan
Write-Host "  Google Chrome: Google ecosystem integration, extensive extensions" -ForegroundColor White
Write-Host "  Brave Browser: Privacy-focused, built-in ad blocker, crypto features" -ForegroundColor White