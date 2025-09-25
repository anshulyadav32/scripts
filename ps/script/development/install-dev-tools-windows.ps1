# Install Development Tools on Windows
# This script installs essential development tools and programming languages on Windows

param(
    [string]$PackageManager = "Auto", # Auto, Chocolatey, Scoop, Winget
    [switch]$Silent = $false,
    [switch]$SkipPython = $false,
    [switch]$SkipPHP = $false,
    [switch]$SkipCpp = $false,
    [switch]$SkipNodeJS = $false,
    [switch]$Force = $false
)

Write-Host "Windows Development Tools Installation Script" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

# Function to check if a command exists
function Test-CommandExists {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Function to install via Chocolatey
function Install-ViaChocolatey {
    param($PackageName, $DisplayName)
    
    Write-Host "Installing $DisplayName via Chocolatey..." -ForegroundColor Yellow
    try {
        if ($Silent) {
            choco install $PackageName -y --no-progress
        } else {
            choco install $PackageName -y
        }
        Write-Host "$DisplayName installed successfully via Chocolatey." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to install $DisplayName via Chocolatey: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to install via Scoop
function Install-ViaScoop {
    param($PackageName, $DisplayName, $Bucket = $null)
    
    Write-Host "Installing $DisplayName via Scoop..." -ForegroundColor Yellow
    try {
        if ($Bucket) {
            scoop bucket add $Bucket 2>$null
        }
        scoop install $PackageName
        Write-Host "$DisplayName installed successfully via Scoop." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to install $DisplayName via Scoop: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to install via Winget
function Install-ViaWinget {
    param($PackageName, $DisplayName)
    
    Write-Host "Installing $DisplayName via Winget..." -ForegroundColor Yellow
    try {
        if ($Silent) {
            winget install $PackageName --silent --accept-package-agreements --accept-source-agreements
        } else {
            winget install $PackageName --accept-package-agreements --accept-source-agreements
        }
        Write-Host "$DisplayName installed successfully via Winget." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to install $DisplayName via Winget: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Determine available package managers
Write-Host "Checking available package managers..." -ForegroundColor Cyan
$hasChocolatey = Test-CommandExists "choco"
$hasScoop = Test-CommandExists "scoop" 
$hasWinget = Test-CommandExists "winget"

Write-Host "Package Managers Available:" -ForegroundColor Cyan
Write-Host "  Chocolatey: $(if ($hasChocolatey) { 'Yes' } else { 'No' })" -ForegroundColor White
Write-Host "  Scoop: $(if ($hasScoop) { 'Yes' } else { 'No' })" -ForegroundColor White
Write-Host "  Winget: $(if ($hasWinget) { 'Yes' } else { 'No' })" -ForegroundColor White

# Install package managers if needed
if (-not $hasChocolatey -and $PackageManager -eq "Chocolatey") {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $hasChocolatey = Test-CommandExists "choco"
}

if (-not $hasScoop -and $PackageManager -eq "Scoop") {
    Write-Host "Installing Scoop..." -ForegroundColor Yellow
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    $hasScoop = Test-CommandExists "scoop"
}

# Determine which package manager to use
$usePackageManager = "None"
if ($PackageManager -eq "Auto") {
    if ($hasChocolatey) { $usePackageManager = "Chocolatey" }
    elseif ($hasWinget) { $usePackageManager = "Winget" }
    elseif ($hasScoop) { $usePackageManager = "Scoop" }
} else {
    $usePackageManager = $PackageManager
}

Write-Host "Using package manager: $usePackageManager" -ForegroundColor Green

# Installation functions for each tool
function Install-Git {
    Write-Host "`nInstalling Git..." -ForegroundColor Cyan
    
    if (Test-CommandExists "git" -and -not $Force) {
        Write-Host "Git is already installed." -ForegroundColor Yellow
        return
    }
    
    switch ($usePackageManager) {
        "Chocolatey" { Install-ViaChocolatey "git" "Git" }
        "Scoop" { Install-ViaScoop "git" "Git" }
        "Winget" { Install-ViaWinget "Git.Git" "Git" }
        default {
            Write-Host "Installing Git manually..." -ForegroundColor Yellow
            $gitUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-2.42.0.2-64-bit.exe"
            $gitPath = "$env:TEMP\git-installer.exe"
            Invoke-WebRequest -Uri $gitUrl -OutFile $gitPath -UseBasicParsing
            Start-Process -FilePath $gitPath -ArgumentList "/SILENT" -Wait
            Remove-Item $gitPath -Force
        }
    }
}

function Install-Curl {
    Write-Host "`nInstalling cURL..." -ForegroundColor Cyan
    
    # cURL is built into Windows 10+, but we can install a newer version
    if (Test-CommandExists "curl" -and -not $Force) {
        $curlVersion = curl --version 2>$null | Select-String "curl \d+\.\d+\.\d+" | ForEach-Object {$_.Matches[0].Value}
        Write-Host "cURL is already available: $curlVersion" -ForegroundColor Yellow
        Write-Host "Installing standalone version anyway..." -ForegroundColor Yellow
    }
    
    switch ($usePackageManager) {
        "Chocolatey" { Install-ViaChocolatey "curl" "cURL" }
        "Scoop" { Install-ViaScoop "curl" "cURL" }
        "Winget" { Install-ViaWinget "cURL.cURL" "cURL" }
        default { Write-Host "cURL is built into Windows 10+. Use 'curl' command." -ForegroundColor Green }
    }
}

function Install-Wget {
    Write-Host "`nInstalling Wget..." -ForegroundColor Cyan
    
    if (Test-CommandExists "wget" -and -not $Force) {
        Write-Host "Wget is already installed." -ForegroundColor Yellow
        return
    }
    
    switch ($usePackageManager) {
        "Chocolatey" { Install-ViaChocolatey "wget" "Wget" }
        "Scoop" { Install-ViaScoop "wget" "Wget" }
        "Winget" { Write-Host "Wget not available via Winget. Using Chocolatey fallback." -ForegroundColor Yellow; Install-ViaChocolatey "wget" "Wget" }
        default {
            Write-Host "Installing Wget manually..." -ForegroundColor Yellow
            $wgetUrl = "https://eternallybored.org/misc/wget/1.21.4/64/wget.exe"
            $wgetPath = "$env:ProgramFiles\wget\wget.exe"
            New-Item -Path "$env:ProgramFiles\wget" -ItemType Directory -Force
            Invoke-WebRequest -Uri $wgetUrl -OutFile $wgetPath -UseBasicParsing
            # Add to PATH
            $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
            if ($currentPath -notlike "*$env:ProgramFiles\wget*") {
                [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$env:ProgramFiles\wget", "Machine")
            }
        }
    }
}

function Install-CppTools {
    if ($SkipCpp) { return }
    
    Write-Host "`nInstalling C++ Development Tools..." -ForegroundColor Cyan
    
    # Check for Visual Studio Build Tools or Visual Studio
    $vsBuildTools = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
                    Where-Object { $_.DisplayName -like "*Visual Studio*Build Tools*" -or $_.DisplayName -like "*Visual Studio*2022*" }
    
    if ($vsBuildTools -and -not $Force) {
        Write-Host "Visual Studio Build Tools detected. C++ compiler available." -ForegroundColor Yellow
    } else {
        switch ($usePackageManager) {
            "Chocolatey" { 
                Install-ViaChocolatey "visualstudio2022buildtools" "Visual Studio 2022 Build Tools"
                Install-ViaChocolatey "visualstudio2022-workload-vctools" "C++ Build Tools"
            }
            "Winget" { Install-ViaWinget "Microsoft.VisualStudio.2022.BuildTools" "Visual Studio 2022 Build Tools" }
            default {
                Write-Host "Installing Visual Studio Build Tools manually..." -ForegroundColor Yellow
                $vsUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
                $vsPath = "$env:TEMP\vs_buildtools.exe"
                Invoke-WebRequest -Uri $vsUrl -OutFile $vsPath -UseBasicParsing
                Start-Process -FilePath $vsPath -ArgumentList "--quiet", "--wait", "--add", "Microsoft.VisualStudio.Workload.VCTools" -Wait
                Remove-Item $vsPath -Force
            }
        }
    }
    
    # Install CMake
    Write-Host "Installing CMake..." -ForegroundColor Yellow
    switch ($usePackageManager) {
        "Chocolatey" { Install-ViaChocolatey "cmake" "CMake" }
        "Scoop" { Install-ViaScoop "cmake" "CMake" }
        "Winget" { Install-ViaWinget "Kitware.CMake" "CMake" }
        default {
            $cmakeUrl = "https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-windows-x86_64.msi"
            $cmakePath = "$env:TEMP\cmake-installer.msi"
            Invoke-WebRequest -Uri $cmakeUrl -OutFile $cmakePath -UseBasicParsing
            Start-Process -FilePath "msiexec" -ArgumentList "/i", $cmakePath, "/quiet" -Wait
            Remove-Item $cmakePath -Force
        }
    }
}

function Install-Python {
    if ($SkipPython) { return }
    
    Write-Host "`nInstalling Python..." -ForegroundColor Cyan
    
    if (Test-CommandExists "python" -and -not $Force) {
        $pythonVersion = python --version 2>$null
        Write-Host "Python is already installed: $pythonVersion" -ForegroundColor Yellow
        return
    }
    
    switch ($usePackageManager) {
        "Chocolatey" { Install-ViaChocolatey "python" "Python" }
        "Scoop" { Install-ViaScoop "python" "Python" }
        "Winget" { Install-ViaWinget "Python.Python.3.12" "Python 3.12" }
        default {
            Write-Host "Installing Python manually..." -ForegroundColor Yellow
            $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
            $pythonPath = "$env:TEMP\python-installer.exe"
            Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonPath -UseBasicParsing
            Start-Process -FilePath $pythonPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait
            Remove-Item $pythonPath -Force
        }
    }
    
    # Install essential Python packages
    Write-Host "Installing essential Python packages..." -ForegroundColor Yellow
    try {
        python -m pip install --upgrade pip
        python -m pip install virtualenv pipenv requests flask django numpy pandas matplotlib jupyter
        Write-Host "Python packages installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Some Python packages may have failed to install." -ForegroundColor Yellow
    }
}

function Install-PHP {
    if ($SkipPHP) { return }
    
    Write-Host "`nInstalling PHP..." -ForegroundColor Cyan
    
    if (Test-CommandExists "php" -and -not $Force) {
        $phpVersion = php --version 2>$null | Select-String "PHP \d+\.\d+\.\d+" | ForEach-Object {$_.Matches[0].Value}
        Write-Host "PHP is already installed: $phpVersion" -ForegroundColor Yellow
    } else {
        switch ($usePackageManager) {
            "Chocolatey" { Install-ViaChocolatey "php" "PHP" }
            "Scoop" { Install-ViaScoop "php" "PHP" }
            "Winget" { Write-Host "PHP not directly available via Winget. Using Chocolatey fallback." -ForegroundColor Yellow; Install-ViaChocolatey "php" "PHP" }
            default {
                Write-Host "Installing PHP manually..." -ForegroundColor Yellow
                # Download PHP zip
                $phpUrl = "https://windows.php.net/downloads/releases/php-8.3.0-Win32-vs16-x64.zip"
                $phpZip = "$env:TEMP\php.zip"
                $phpDir = "C:\php"
                
                Invoke-WebRequest -Uri $phpUrl -OutFile $phpZip -UseBasicParsing
                Expand-Archive -Path $phpZip -DestinationPath $phpDir -Force
                Remove-Item $phpZip -Force
                
                # Add to PATH
                $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
                if ($currentPath -notlike "*$phpDir*") {
                    [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$phpDir", "Machine")
                }
                
                # Create basic php.ini
                Copy-Item "$phpDir\php.ini-production" "$phpDir\php.ini" -Force
            }
        }
    }
    
    # Install Composer
    Write-Host "Installing Composer..." -ForegroundColor Yellow
    if (Test-CommandExists "composer" -and -not $Force) {
        Write-Host "Composer is already installed." -ForegroundColor Yellow
    } else {
        switch ($usePackageManager) {
            "Chocolatey" { Install-ViaChocolatey "composer" "Composer" }
            "Scoop" { Install-ViaScoop "composer" "Composer" }
            "Winget" { Install-ViaWinget "Composer.Composer" "Composer" }
            default {
                Write-Host "Installing Composer manually..." -ForegroundColor Yellow
                $composerUrl = "https://getcomposer.org/Composer-Setup.exe"
                $composerPath = "$env:TEMP\composer-setup.exe"
                Invoke-WebRequest -Uri $composerUrl -OutFile $composerPath -UseBasicParsing
                Start-Process -FilePath $composerPath -ArgumentList "/SILENT" -Wait
                Remove-Item $composerPath -Force
            }
        }
    }
}

function Install-NodeJS {
    if ($SkipNodeJS) { return }
    
    Write-Host "`nInstalling Node.js LTS..." -ForegroundColor Cyan
    
    if (Test-CommandExists "node" -and -not $Force) {
        $nodeVersion = node --version 2>$null
        Write-Host "Node.js is already installed: $nodeVersion" -ForegroundColor Yellow
    } else {
        switch ($usePackageManager) {
            "Chocolatey" { Install-ViaChocolatey "nodejs-lts" "Node.js LTS" }
            "Scoop" { Install-ViaScoop "nodejs-lts" "Node.js LTS" }
            "Winget" { Install-ViaWinget "OpenJS.NodeJS.LTS" "Node.js LTS" }
            default {
                Write-Host "Installing Node.js manually..." -ForegroundColor Yellow
                $nodeUrl = "https://nodejs.org/dist/v20.9.0/node-v20.9.0-x64.msi"
                $nodePath = "$env:TEMP\nodejs-installer.msi"
                Invoke-WebRequest -Uri $nodeUrl -OutFile $nodePath -UseBasicParsing
                Start-Process -FilePath "msiexec" -ArgumentList "/i", $nodePath, "/quiet" -Wait
                Remove-Item $nodePath -Force
            }
        }
    }
    
    # Install additional npm packages
    Write-Host "Installing additional npm packages..." -ForegroundColor Yellow
    try {
        npm install -g npm@latest
        npm install -g yarn
        npm install -g pnpm  
        npm install -g nodemon
        npm install -g http-server
        Write-Host "npm packages installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Some npm packages may have failed to install." -ForegroundColor Yellow
    }
}

# Main installation process
Write-Host "`nStarting development tools installation..." -ForegroundColor Green

# Core tools
Install-Git
Install-Curl
Install-Wget

# Programming languages and compilers
Install-CppTools
Install-Python
Install-PHP  
Install-NodeJS

# Refresh environment variables
Write-Host "`nRefreshing environment variables..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Verify installations
Write-Host "`nVerifying installations..." -ForegroundColor Cyan

$tools = @{
    "Git" = "git --version"
    "cURL" = "curl --version"  
    "Wget" = "wget --version"
    "Python" = "python --version"
    "pip" = "pip --version"
    "PHP" = "php --version"
    "Composer" = "composer --version"
    "Node.js" = "node --version"
    "npm" = "npm --version"
    "CMake" = "cmake --version"
}

foreach ($tool in $tools.Keys) {
    try {
        $version = Invoke-Expression $tools[$tool] 2>$null | Select-Object -First 1
        if ($version) {
            Write-Host "  ✓ $tool installed" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $tool not found" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ $tool not found" -ForegroundColor Red
    }
}

Write-Host "`nDevelopment tools installation completed!" -ForegroundColor Green

# Show installation summary
Write-Host "`nInstallation Summary:" -ForegroundColor Cyan
Write-Host "Package Manager Used: $usePackageManager" -ForegroundColor White
Write-Host "Core Tools: Git, cURL, Wget" -ForegroundColor White
Write-Host "Languages: Python, PHP, Node.js, C++" -ForegroundColor White
Write-Host "Package Managers: pip, Composer, npm" -ForegroundColor White
Write-Host "Build Tools: CMake, Visual Studio Build Tools" -ForegroundColor White

Write-Host "`nQuick Commands:" -ForegroundColor Cyan
Write-Host "  git --version       # Check Git version" -ForegroundColor White
Write-Host "  python --version    # Check Python version" -ForegroundColor White
Write-Host "  php --version       # Check PHP version" -ForegroundColor White
Write-Host "  node --version      # Check Node.js version" -ForegroundColor White
Write-Host "  cmake --version     # Check CMake version" -ForegroundColor White

Write-Host "`nDevelopment Shortcuts:" -ForegroundColor Cyan
Write-Host "  python -m http.server 8000    # Python HTTP server" -ForegroundColor White
Write-Host "  php -S localhost:8000         # PHP development server" -ForegroundColor White
Write-Host "  npx http-server -p 3000       # Node.js HTTP server" -ForegroundColor White

Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-dev-tools-windows.ps1                    # Install all tools" -ForegroundColor White
Write-Host "  .\install-dev-tools-windows.ps1 -PackageManager Chocolatey  # Use specific package manager" -ForegroundColor White
Write-Host "  .\install-dev-tools-windows.ps1 -SkipPython       # Skip Python installation" -ForegroundColor White
Write-Host "  .\install-dev-tools-windows.ps1 -Silent           # Silent installation" -ForegroundColor White
Write-Host "  .\install-dev-tools-windows.ps1 -Force            # Force reinstall" -ForegroundColor White