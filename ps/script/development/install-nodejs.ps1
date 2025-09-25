# Install Node.js LTS and npm
# This script downloads and installs Node.js LTS with npm package manager

param(
    [switch]$LTS = $true,
    [switch]$Current = $false,
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$InstallYarn = $false,
    [switch]$InstallPnpm = $false
)

Write-Host "Node.js and npm Installation Script" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

# Check if Node.js is already installed
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
if ($nodeInstalled -and -not $Force) {
    Write-Host "Node.js is already installed:" -ForegroundColor Yellow
    node --version
    npm --version
    Write-Host "Use -Force to reinstall." -ForegroundColor Cyan
    
    # Skip to package manager installation if Node.js exists
    if ($InstallYarn -or $InstallPnpm) {
        Write-Host "Proceeding to additional package managers installation..." -ForegroundColor Yellow
    } else {
        exit 0
    }
} else {
    # Determine which version to install
    $versionType = if ($Current) { "Current" } else { "LTS" }
    Write-Host "Installing Node.js $versionType version..." -ForegroundColor Yellow

    try {
        # Get Node.js version information
        Write-Host "Fetching latest Node.js $versionType version info..." -ForegroundColor Cyan
        
        if ($LTS) {
            # Get LTS version
            $nodeApiUrl = "https://api.github.com/repos/nodejs/node/releases"
            $releases = Invoke-RestMethod -Uri $nodeApiUrl -UseBasicParsing
            $ltsRelease = $releases | Where-Object { $_.name -match "LTS" -or $_.tag_name -match "v\d+\.\d+\.\d+$" } | Select-Object -First 1
            $version = $ltsRelease.tag_name
            $downloadUrl = "https://nodejs.org/dist/$version/node-$version-x64.msi"
        } else {
            # Get current version
            $nodeDistUrl = "https://nodejs.org/dist/index.json"
            $nodeVersions = Invoke-RestMethod -Uri $nodeDistUrl -UseBasicParsing
            $latestVersion = $nodeVersions[0]
            $version = $latestVersion.version
            $downloadUrl = "https://nodejs.org/dist/$version/node-$version-x64.msi"
        }
        
        Write-Host "Latest $versionType version: $version" -ForegroundColor Cyan
        
        $installerPath = "$env:TEMP\nodejs-installer.msi"
        
        # Download Node.js installer
        Write-Host "Downloading Node.js installer..." -ForegroundColor Yellow
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "Download completed." -ForegroundColor Green
        
        # Install Node.js
        Write-Host "Installing Node.js..." -ForegroundColor Yellow
        if ($Silent) {
            $installArgs = "/i", $installerPath, "/quiet", "/norestart", "ADDLOCAL=ALL"
        } else {
            $installArgs = "/i", $installerPath, "/passive", "/norestart", "ADDLOCAL=ALL"
        }
        
        $process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Node.js installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Node.js installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            exit 1
        }
        
        # Clean up installer
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Wait a moment for installation to complete
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-Host "Verifying Node.js installation..." -ForegroundColor Yellow
        try {
            $nodeVersion = node --version
            $npmVersion = npm --version
            Write-Host "Node.js version: $nodeVersion" -ForegroundColor Green
            Write-Host "npm version: $npmVersion" -ForegroundColor Green
        } catch {
            Write-Host "Node.js installation verification failed. You may need to restart your terminal." -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "Failed to install Node.js: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Update npm to latest version
Write-Host "`nUpdating npm to latest version..." -ForegroundColor Yellow
try {
    npm install -g npm@latest
    $npmVersion = npm --version
    Write-Host "npm updated to version: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "Could not update npm. It may already be the latest version." -ForegroundColor Yellow
}

# Install Yarn package manager if requested
if ($InstallYarn) {
    Write-Host "`nInstalling Yarn package manager..." -ForegroundColor Yellow
    try {
        npm install -g yarn
        $yarnVersion = yarn --version
        Write-Host "Yarn installed successfully: v$yarnVersion" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install Yarn: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Install pnpm package manager if requested
if ($InstallPnpm) {
    Write-Host "`nInstalling pnpm package manager..." -ForegroundColor Yellow
    try {
        npm install -g pnpm
        $pnpmVersion = pnpm --version
        Write-Host "pnpm installed successfully: v$pnpmVersion" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install pnpm: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Set npm configuration for better performance
Write-Host "`nConfiguring npm for optimal performance..." -ForegroundColor Yellow
try {
    npm config set fund false
    npm config set audit-level moderate
    Write-Host "npm configuration optimized." -ForegroundColor Green
} catch {
    Write-Host "Could not optimize npm configuration." -ForegroundColor Yellow
}

Write-Host "`nNode.js installation completed!" -ForegroundColor Green

# Show installation summary
Write-Host "`nInstallation Summary:" -ForegroundColor Cyan
try {
    Write-Host "Node.js: $(node --version)" -ForegroundColor White
    Write-Host "npm: $(npm --version)" -ForegroundColor White
    if ($InstallYarn) {
        Write-Host "Yarn: $(yarn --version)" -ForegroundColor White
    }
    if ($InstallPnpm) {
        Write-Host "pnpm: $(pnpm --version)" -ForegroundColor White
    }
} catch {
    Write-Host "Some tools may not be immediately available in this terminal session." -ForegroundColor Yellow
}

# Provide useful npm commands
Write-Host "`nUseful npm Commands:" -ForegroundColor Cyan
Write-Host "  npm init                    # Create new package.json"
Write-Host "  npm install <package>       # Install package locally"
Write-Host "  npm install -g <package>    # Install package globally"
Write-Host "  npm update                  # Update packages"
Write-Host "  npm list -g --depth=0       # List global packages"
Write-Host "  npm cache clean --force     # Clear npm cache"

if ($InstallYarn) {
    Write-Host "`nUseful Yarn Commands:" -ForegroundColor Cyan
    Write-Host "  yarn init                   # Create new package.json"
    Write-Host "  yarn add <package>          # Add package"
    Write-Host "  yarn global add <package>   # Add global package"
    Write-Host "  yarn upgrade                # Update packages"
}

if ($InstallPnpm) {
    Write-Host "`nUseful pnpm Commands:" -ForegroundColor Cyan
    Write-Host "  pnpm init                   # Create new package.json"
    Write-Host "  pnpm add <package>          # Add package"
    Write-Host "  pnpm add -g <package>       # Add global package"
    Write-Host "  pnpm update                 # Update packages"
}

# Usage examples
Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-nodejs.ps1                     # Install LTS version"
Write-Host "  .\install-nodejs.ps1 -Current            # Install current version"
Write-Host "  .\install-nodejs.ps1 -InstallYarn        # Install with Yarn"
Write-Host "  .\install-nodejs.ps1 -InstallPnpm        # Install with pnpm"
Write-Host "  .\install-nodejs.ps1 -Silent             # Silent installation"
Write-Host "  .\install-nodejs.ps1 -Force              # Force reinstall"