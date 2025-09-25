# Install Python and pip
# This script downloads and installs Python with pip package manager
# Enhanced with comprehensive software verification system

# Import the software verification module
$modulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "modules\SoftwareVerification.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Warning "Software verification module not found. Using basic verification."
}

param(
    [string]$Version = "latest",
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$AddToPath = $true,
    [switch]$InstallPipTools = $true,
    [switch]$VerifyOnly = $false,
    [switch]$Detailed = $false
)

function Test-PythonInstallation {
    <#
    .SYNOPSIS
    Enhanced function to verify Python installation with detailed information.
    
    .DESCRIPTION
    Uses the SoftwareVerification module for comprehensive verification, falls back to basic checks if unavailable.
    #>
    param(
        [switch]$Detailed
    )
    
    # Try to use the verification module first
    if (Get-Command Test-PredefinedSoftware -ErrorAction SilentlyContinue) {
        try {
            $result = Test-PredefinedSoftware -SoftwareName "Python" -Detailed:$Detailed
            return $result
        } catch {
            Write-Warning "Verification module failed for Python. Using fallback method."
        }
    }
    
    # Fallback to basic verification
    $isInstalled = $false
    $version = "Unknown"
    $paths = @()
    
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    $pipCommand = Get-Command pip -ErrorAction SilentlyContinue
    
    if ($pythonCommand -and $pipCommand) {
        $isInstalled = $true
        $paths += $pythonCommand.Source
        $paths += $pipCommand.Source
        try {
            $pythonVersion = & python --version 2>$null
            $pipVersion = & pip --version 2>$null
            if ($pythonVersion -and $pipVersion) {
                $version = "$pythonVersion, pip: $($pipVersion -split ' ' | Select-Object -First 2 -Join ' ')"
            }
        } catch {
            $version = "Unknown"
        }
    }
    
    return @{
        IsInstalled = $isInstalled
        Version = $version
        Paths = $paths
        Status = if ($isInstalled) { "Installed" } else { "Not Installed" }
    }
}

Write-Host "Python and pip Installation Script" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Handle verification-only mode
if ($VerifyOnly) {
    Write-Host "Verifying Python installation..." -ForegroundColor Yellow
    $verificationResult = Test-PythonInstallation -Detailed:$Detailed
    
    if ($verificationResult.IsInstalled) {
        Write-Host "[OK] Python is installed" -ForegroundColor Green
        Write-Host "Version: $($verificationResult.Version)" -ForegroundColor Cyan
        if ($Detailed -and $verificationResult.Paths) {
            Write-Host "Installation Path(s):" -ForegroundColor Cyan
            $verificationResult.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        }
    } else {
        Write-Host "[ERROR] Python is not installed" -ForegroundColor Red
    }
    exit 0
}

# Check if Python is already installed
$pythonVerification = Test-PythonInstallation -Detailed:$Detailed
if ($pythonVerification.IsInstalled -and -not $Force) {
    Write-Host "Python is already installed: $($pythonVerification.Version)" -ForegroundColor Yellow
    if ($Detailed -and $pythonVerification.Paths) {
        Write-Host "Installation Path(s):" -ForegroundColor Cyan
        $pythonVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    }
    Write-Host "Use -Force to reinstall." -ForegroundColor Cyan
    
    # Skip to pip tools installation if Python exists
    if ($InstallPipTools) {
        Write-Host "Proceeding to pip tools installation..." -ForegroundColor Yellow
    } else {
        exit 0
    }
} else {
    Write-Host "Installing Python..." -ForegroundColor Yellow
    
    try {
        # Get Python version information
        Write-Host "Fetching Python version information..." -ForegroundColor Cyan
        
        if ($Version -eq "latest") {
            # Get latest Python version from python.org API
            $pythonReleasesUrl = "https://api.github.com/repos/python/cpython/releases/latest"
            $latestRelease = Invoke-RestMethod -Uri $pythonReleasesUrl -UseBasicParsing
            $version = $latestRelease.tag_name -replace "v", ""
            
            # Construct download URL for Windows x64 installer
            $majorMinor = $version -replace "\.\d+$", ""
            $downloadUrl = "https://www.python.org/ftp/python/$version/python-$version-amd64.exe"
        } else {
            # Use specified version
            $majorMinor = $Version -replace "\.\d+$", ""
            $downloadUrl = "https://www.python.org/ftp/python/$Version/python-$Version-amd64.exe"
            $version = $Version
        }
        
        Write-Host "Installing Python $version..." -ForegroundColor Cyan
        
        $installerPath = "$env:TEMP\python-installer.exe"
        
        # Download Python installer
        Write-Host "Downloading Python installer..." -ForegroundColor Yellow
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "Download completed." -ForegroundColor Green
        
        # Install Python
        Write-Host "Installing Python..." -ForegroundColor Yellow
        
        # Build installation arguments
        $installArgs = @()
        if ($Silent) {
            $installArgs += "/quiet"
        } else {
            $installArgs += "/passive"
        }
        
        # Add Python to PATH
        if ($AddToPath) {
            $installArgs += "PrependPath=1"
        }
        
        # Include pip, tcl/tk and IDLE, Python test suite, py launcher
        $installArgs += @(
            "InstallAllUsers=0",  # Install for current user
            "TargetDir=$env:LOCALAPPDATA\Programs\Python\Python$($version.Replace('.', ''))",
            "Include_pip=1",
            "Include_tcltk=1",
            "Include_test=1",
            "Include_launcher=1",
            "AssociateFiles=1"
        )
        
        $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Python installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Python installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            exit 1
        }
        
        # Clean up installer
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Wait a moment for installation to complete
        Start-Sleep -Seconds 5
        
        # Verify installation using enhanced verification
        Write-Host "Verifying Python installation..." -ForegroundColor Yellow
        $postInstallVerification = Test-PythonInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-Host "[OK] Python installation verified successfully!" -ForegroundColor Green
            Write-Host "Version: $($postInstallVerification.Version)" -ForegroundColor Cyan
            if ($Detailed -and $postInstallVerification.Paths) {
                Write-Host "Installation Path(s):" -ForegroundColor Cyan
                $postInstallVerification.Paths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
            }
        } else {
            Write-Host "[WARNING] Python installation verification failed. You may need to restart your terminal." -ForegroundColor Yellow
            Write-Host "Try using 'py' command instead of 'python' if PATH wasn't updated." -ForegroundColor Cyan
        }
        
    } catch {
        Write-Host "Failed to install Python: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You can download Python manually from https://python.org" -ForegroundColor Yellow
        exit 1
    }
}

# Update pip to latest version
Write-Host "`nUpdating pip to latest version..." -ForegroundColor Yellow
try {
    python -m pip install --upgrade pip
    Write-Host "pip updated successfully." -ForegroundColor Green
} catch {
    Write-Host "Could not update pip. It may already be the latest version." -ForegroundColor Yellow
}

# Install essential Python tools and packages
if ($InstallPipTools) {
    Write-Host "`nInstalling essential Python packages..." -ForegroundColor Yellow
    
    $essentialPackages = @(
        "wheel",           # Python wheel format support
        "setuptools",      # Package development utilities
        "virtualenv",      # Virtual environment creator
        "pipenv",          # Python dependency management
        "requests",        # HTTP library
        "numpy",           # Numerical computing
        "pandas",          # Data analysis and manipulation
        "matplotlib",      # Plotting library
        "jupyter",         # Jupyter notebook
        "ipython",         # Enhanced interactive Python
        "pytest",          # Testing framework
        "black",           # Code formatter
        "flake8",          # Linting tool
        "pylint"           # Code analysis tool
    )
    
    foreach ($package in $essentialPackages) {
        try {
            Write-Host "Installing $package..." -ForegroundColor Cyan
            pip install $package --quiet
            Write-Host "  ✓ $package installed" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to install $package" -ForegroundColor Red
        }
    }
}

# Configure pip for better user experience
Write-Host "`nConfiguring pip..." -ForegroundColor Yellow
try {
    # Create pip configuration directory
    $pipConfigDir = "$env:APPDATA\pip"
    if (-not (Test-Path $pipConfigDir)) {
        New-Item -ItemType Directory -Path $pipConfigDir -Force | Out-Null
    }
    
    # Create pip.ini configuration file
    $pipConfig = @"
[global]
timeout = 60
index-url = https://pypi.org/simple/
trusted-host = pypi.org
               files.pythonhosted.org
"@
    
    $pipConfigFile = "$pipConfigDir\pip.ini"
    $pipConfig | Out-File -FilePath $pipConfigFile -Encoding UTF8
    Write-Host "pip configuration created." -ForegroundColor Green
} catch {
    Write-Host "Could not create pip configuration." -ForegroundColor Yellow
}

Write-Host "`nPython and pip installation completed!" -ForegroundColor Green

# Show installation summary
Write-Host "`nInstallation Summary:" -ForegroundColor Cyan
try {
    Write-Host "Python: $(python --version 2>&1)" -ForegroundColor White
    Write-Host "pip: $(pip --version)" -ForegroundColor White
    Write-Host "Virtual Environment: $(virtualenv --version)" -ForegroundColor White
} catch {
    Write-Host "Some tools may not be immediately available in this terminal session." -ForegroundColor Yellow
}

# Provide useful Python commands
Write-Host "`nUseful Python Commands:" -ForegroundColor Cyan
Write-Host "  python --version            # Check Python version"
Write-Host "  pip --version              # Check pip version"
Write-Host "  pip install <package>      # Install package"
Write-Host "  pip install -r requirements.txt  # Install from requirements file"
Write-Host "  pip list                   # List installed packages"
Write-Host "  pip show <package>         # Show package info"
Write-Host "  pip uninstall <package>    # Uninstall package"

Write-Host "`nVirtual Environment Commands:" -ForegroundColor Cyan
Write-Host "  python -m venv myenv       # Create virtual environment"
Write-Host "  myenv\Scripts\activate     # Activate virtual environment (Windows)"
Write-Host "  deactivate                 # Deactivate virtual environment"
Write-Host "  pipenv install             # Install dependencies with Pipenv"
Write-Host "  pipenv shell               # Activate Pipenv shell"

Write-Host "`nJupyter Notebook Commands:" -ForegroundColor Cyan
Write-Host "  jupyter notebook           # Start Jupyter Notebook"
Write-Host "  jupyter lab                # Start JupyterLab"
Write-Host "  ipython                    # Start IPython interactive shell"

# Usage examples
Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-python.ps1                     # Install latest Python"
Write-Host "  .\install-python.ps1 -Version '3.11.5'   # Install specific version"
Write-Host "  .\install-python.ps1 -Silent             # Silent installation"
Write-Host "  .\install-python.ps1 -Force              # Force reinstall"
Write-Host "  .\install-python.ps1 -InstallPipTools:`$false  # Skip pip tools"