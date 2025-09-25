# Install Web Browsers (Chrome, Brave)
# This script downloads and installs modern web browsers

param(
    [switch]$Chrome = $true,
    [switch]$Brave = $true,
    [switch]$Silent = $false,
    [switch]$Force = $false
)

Write-Host "Web Browsers Installation Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Function to check if application is installed
function Test-AppInstalled {
    param([string]$AppName)
    $installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$AppName*" }
    return $installed -ne $null
}

# Install Google Chrome
if ($Chrome) {
    Write-Host "`nInstalling Google Chrome..." -ForegroundColor Yellow
    
    $chromeInstalled = Test-AppInstalled "Chrome"
    if ($chromeInstalled -and -not $Force) {
        Write-Host "Google Chrome is already installed. Use -Force to reinstall." -ForegroundColor Cyan
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
            
            Write-Host "Google Chrome installed successfully!" -ForegroundColor Green
            Remove-Item $chromePath -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Failed to install Google Chrome: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Install Brave Browser
if ($Brave) {
    Write-Host "`nInstalling Brave Browser..." -ForegroundColor Yellow
    
    $braveInstalled = Test-AppInstalled "Brave"
    if ($braveInstalled -and -not $Force) {
        Write-Host "Brave Browser is already installed. Use -Force to reinstall." -ForegroundColor Cyan
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
            
            Write-Host "Brave Browser installed successfully!" -ForegroundColor Green
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