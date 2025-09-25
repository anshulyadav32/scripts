# Install Python 3.13 - Latest Python with pip and virtual environment support

function Test-PythonInstalled {
    $installed = $false
    
    try {
        $pythonVersion = python --version 2>$null
        if ($pythonVersion) {
            Write-Host "Python found: $pythonVersion" -ForegroundColor Green
            $installed = $true
        }
    } catch {
        try {
            $python3Version = python3 --version 2>$null
            if ($python3Version) {
                Write-Host "Python3 found: $python3Version" -ForegroundColor Green
                $installed = $true
            }
        } catch {
            Write-Host "Python not found in PATH" -ForegroundColor Yellow
        }
    }
    
    # Check via Chocolatey
    if (-not $installed) {
        $chocoPackage = choco list --local-only | Select-String "python"
        if ($chocoPackage) {
            Write-Host "Python found via Chocolatey" -ForegroundColor Green
            $installed = $true
        }
    }
    
    return $installed
}

function Test-PythonFunctionality {
    Write-Host "Running Python functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        PythonTest = $false
        PipTest = $false
        VenvTest = $false
        ModuleTest = $false
        OverallSuccess = $false
    }
    
    Write-Host "  Testing Python..." -ForegroundColor Yellow
    try {
        $pythonVersion = python --version 2>$null
        if ($pythonVersion) {
            Write-Host "     Python version: $pythonVersion" -ForegroundColor Green
            
            # Check if it's Python 3.13
            if ($pythonVersion -match "Python 3\.(\d+)\.") {
                $minorVersion = [int]$matches[1]
                if ($minorVersion -eq 13) {
                    Write-Host "     ✓ Python 3.13 detected" -ForegroundColor Green
                } elseif ($minorVersion -gt 13) {
                    Write-Host "     ✓ Newer than 3.13" -ForegroundColor Green
                } else {
                    Write-Host "     ⚠ Older than Python 3.13" -ForegroundColor Yellow
                }
            }
            
            $results.PythonTest = $true
        }
    } catch {
        Write-Host "     Python test failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing pip..." -ForegroundColor Yellow
    try {
        $pipVersion = pip --version 2>$null
        if ($pipVersion) {
            Write-Host "     pip version: $pipVersion" -ForegroundColor Green
            $results.PipTest = $true
        }
    } catch {
        Write-Host "     pip test failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing virtual environment..." -ForegroundColor Yellow
    try {
        # Test venv module
        $venvTest = python -m venv --help 2>$null
        if ($venvTest) {
            Write-Host "     venv module available" -ForegroundColor Green
            $results.VenvTest = $true
        }
    } catch {
        Write-Host "     venv test failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing essential modules..." -ForegroundColor Yellow
    try {
        # Test some essential modules
        $moduleTest = python -c "import sys, os, json, urllib, ssl; print('Essential modules OK')" 2>$null
        if ($moduleTest) {
            Write-Host "     Essential modules available" -ForegroundColor Green
            $results.ModuleTest = $true
        }
    } catch {
        Write-Host "     Module test failed" -ForegroundColor Red
    }
    
    $passedTests = ($results.PythonTest + $results.PipTest + $results.VenvTest + $results.ModuleTest)
    $results.OverallSuccess = ($passedTests -ge 3)
    
    Write-Host "  Tests passed: $passedTests/4" -ForegroundColor Green
    
    return $results
}

function Update-Python {
    Write-Host "Updating Python..." -ForegroundColor Cyan
    
    if (-not (Test-PythonInstalled)) {
        Write-Host "Python is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        # Try to update via Chocolatey if available
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Attempting to update via Chocolatey..." -ForegroundColor Yellow
            choco upgrade python -y
            return $true
        }
        
        # Try WinGet update
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Attempting to update via WinGet..." -ForegroundColor Yellow
            winget upgrade Python.Python.3.13
            return $true
        }
        
        # Update pip itself
        Write-Host "Updating pip to latest version..." -ForegroundColor Yellow
        python -m pip install --upgrade pip
        
        Write-Host "For Python updates:" -ForegroundColor Yellow
        Write-Host "  1. Download latest from https://www.python.org/" -ForegroundColor White
        Write-Host "  2. Run installer (will automatically update)" -ForegroundColor White
        Write-Host "  3. Or use package manager for automatic updates" -ForegroundColor White
        
        return $true
        
    } catch {
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-PythonPackageManager {
    Write-Host "Installing Python 3.13..." -ForegroundColor Cyan
    
    $installSuccess = $false
    
    # Method 1: Try Chocolatey first
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing via Chocolatey..." -ForegroundColor Yellow
        try {
            # Install Python 3.13 (or latest available)
            choco install python -y
            $installSuccess = $true
            Write-Host "Python installed successfully via Chocolatey!" -ForegroundColor Green
        } catch {
            Write-Host "Chocolatey installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Method 2: Try WinGet if Chocolatey failed
    if (-not $installSuccess -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Installing via WinGet..." -ForegroundColor Yellow
        try {
            # Try Python 3.13 specifically, fallback to general Python
            try {
                winget install --id Python.Python.3.13 --source winget
            } catch {
                winget install --id Python.Python.3 --source winget
            }
            $installSuccess = $true
            Write-Host "Python installed successfully via WinGet!" -ForegroundColor Green
        } catch {
            Write-Host "WinGet installation failed, providing manual installation guidance..." -ForegroundColor Yellow
        }
    }
    
    # Method 3: Manual installation guidance
    if (-not $installSuccess) {
        Write-Host "Automated installation failed. Manual installation required:" -ForegroundColor Yellow
        Write-Host "`n=== Manual Installation ===" -ForegroundColor Cyan
        Write-Host "1. Download Python 3.13 from: https://www.python.org/downloads/" -ForegroundColor White
        Write-Host "2. Choose 'Download Python 3.13.x'" -ForegroundColor White
        Write-Host "3. Run installer as Administrator" -ForegroundColor White
        Write-Host "4. ✅ Check 'Add Python to PATH'" -ForegroundColor White
        Write-Host "5. ✅ Check 'Install pip'" -ForegroundColor White
        Write-Host "6. Choose 'Customize installation' for advanced options" -ForegroundColor White
        Write-Host "7. ✅ Install for all users (optional)" -ForegroundColor White
    }
    
    return $installSuccess
}

function Configure-Python {
    Write-Host "Configuring Python environment..." -ForegroundColor Cyan
    
    try {
        # Upgrade pip to latest version
        Write-Host "Upgrading pip to latest version..." -ForegroundColor Yellow
        python -m pip install --upgrade pip
        
        # Install essential packages
        Write-Host "Installing essential Python packages..." -ForegroundColor Yellow
        $essentialPackages = @(
            "virtualenv",       # Virtual environment tool
            "virtualenvwrapper-win", # Windows virtual environment wrapper
            "wheel",            # Package building
            "setuptools",       # Package utilities
            "requests",         # HTTP library
            "certifi",          # SSL certificates
            "urllib3"           # HTTP client
        )
        
        foreach ($package in $essentialPackages) {
            Write-Host "  Installing $package..." -ForegroundColor Gray
            python -m pip install $package --quiet
        }
        
        # Set up useful environment variables
        Write-Host "Setting up Python environment variables..." -ForegroundColor Yellow
        
        # Set PYTHONPATH if not set
        $pythonPath = [Environment]::GetEnvironmentVariable("PYTHONPATH", "User")
        if (-not $pythonPath) {
            [Environment]::SetEnvironmentVariable("PYTHONPATH", "", "User")
        }
        
        # Create common virtual environment directory
        $venvDir = "$env:USERPROFILE\venvs"
        if (-not (Test-Path $venvDir)) {
            New-Item -Path $venvDir -ItemType Directory -Force
            Write-Host "Created virtual environment directory: $venvDir" -ForegroundColor Green
        }
        
        Write-Host "Python configuration completed!" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "Configuration failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Show-PythonUsageInfo {
    Write-Host "`n=== Python Usage Guide ===" -ForegroundColor Magenta
    
    Write-Host "Python Commands:" -ForegroundColor Yellow
    Write-Host "  python --version            # Check Python version" -ForegroundColor White
    Write-Host "  python script.py            # Run Python script" -ForegroundColor White
    Write-Host "  python -c 'print(`"Hello`")'  # Execute inline code" -ForegroundColor White
    Write-Host "  python -i                   # Interactive interpreter" -ForegroundColor White
    Write-Host "  python -m module_name       # Run module as script" -ForegroundColor White
    
    Write-Host "`npip Commands:" -ForegroundColor Yellow
    Write-Host "  pip --version               # Check pip version" -ForegroundColor White
    Write-Host "  pip install package-name    # Install package" -ForegroundColor White
    Write-Host "  pip install -r requirements.txt # Install from file" -ForegroundColor White
    Write-Host "  pip list                    # List installed packages" -ForegroundColor White
    Write-Host "  pip show package-name       # Show package info" -ForegroundColor White
    Write-Host "  pip freeze > requirements.txt # Export dependencies" -ForegroundColor White
    Write-Host "  pip uninstall package-name  # Uninstall package" -ForegroundColor White
    Write-Host "  pip search package-name     # Search packages" -ForegroundColor White
    
    Write-Host "`nVirtual Environment:" -ForegroundColor Yellow
    Write-Host "  python -m venv myproject    # Create virtual environment" -ForegroundColor White
    Write-Host "  myproject\Scripts\activate  # Activate environment (Windows)" -ForegroundColor White
    Write-Host "  deactivate                  # Deactivate environment" -ForegroundColor White
    Write-Host "  pip freeze > requirements.txt # Save dependencies" -ForegroundColor White
    
    Write-Host "`nUseful Packages to Install:" -ForegroundColor Yellow
    Write-Host "  # Web Development" -ForegroundColor Gray
    Write-Host "  pip install django flask fastapi" -ForegroundColor White
    Write-Host "  # Data Science" -ForegroundColor Gray
    Write-Host "  pip install numpy pandas matplotlib jupyter" -ForegroundColor White
    Write-Host "  # Development Tools" -ForegroundColor Gray
    Write-Host "  pip install black flake8 pytest mypy" -ForegroundColor White
    Write-Host "  # Utilities" -ForegroundColor Gray
    Write-Host "  pip install click rich typer" -ForegroundColor White
    
    Write-Host "`nProject Structure:" -ForegroundColor Yellow
    Write-Host "  requirements.txt            # Dependencies file" -ForegroundColor White
    Write-Host "  setup.py                    # Package setup" -ForegroundColor White
    Write-Host "  .gitignore                  # Git ignore (include __pycache__/)" -ForegroundColor White
    Write-Host "  venv/ or .venv/             # Virtual environment" -ForegroundColor White
    
    Write-Host "`nBest Practices:" -ForegroundColor Yellow
    Write-Host "  • Always use virtual environments" -ForegroundColor White
    Write-Host "  • Pin dependency versions in requirements.txt" -ForegroundColor White
    Write-Host "  • Use .gitignore for __pycache__ and .pyc files" -ForegroundColor White
    Write-Host "  • Follow PEP 8 style guide" -ForegroundColor White
    Write-Host "  • Write tests for your code" -ForegroundColor White
    
    Write-Host "`nPython 3.13 New Features:" -ForegroundColor Yellow
    Write-Host "  • Improved error messages" -ForegroundColor White
    Write-Host "  • Performance optimizations" -ForegroundColor White
    Write-Host "  • Enhanced type hints" -ForegroundColor White
    Write-Host "  • Better debugging support" -ForegroundColor White
    
    Write-Host "`nEnvironment Paths:" -ForegroundColor Yellow
    Write-Host "  • Virtual envs: %USERPROFILE%\venvs\" -ForegroundColor White
    Write-Host "  • Site packages: python -m site --user-site" -ForegroundColor White
    Write-Host "  • Python executable: where python" -ForegroundColor White
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Python 3.13 Installation Script" -ForegroundColor Cyan
Write-Host "Latest Python + pip + Essential Packages" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-PythonInstalled) {
    Write-Host "Python is already installed!" -ForegroundColor Green
    
    # Test Python functionality
    $testResults = Test-PythonFunctionality
    
    if ($testResults.OverallSuccess) {
        Write-Host "`n[SUCCESS] Python is working correctly!" -ForegroundColor Green
    } else {
        Write-Host "`n[WARNING] Python may need additional configuration." -ForegroundColor Yellow
        
        if (-not $testResults.PipTest) {
            Write-Host "  • pip not working - reinstall Python with pip" -ForegroundColor Yellow
        }
        if (-not $testResults.VenvTest) {
            Write-Host "  • venv module not available" -ForegroundColor Yellow
        }
        if (-not $testResults.ModuleTest) {
            Write-Host "  • Essential modules missing" -ForegroundColor Yellow
        }
    }
    
    # Configure Python
    Configure-Python
    Show-PythonUsageInfo
} else {
    Write-Host "Installing Python 3.13..." -ForegroundColor Yellow
    
    if (Install-PythonPackageManager) {
        Write-Host "`n[SUCCESS] Python installation completed!" -ForegroundColor Green
        
        # Test the installation
        Start-Sleep -Seconds 5
        $testResults = Test-PythonFunctionality
        
        if ($testResults.OverallSuccess) {
            Write-Host "[SUCCESS] Installation verified successfully!" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Installation completed, but may need PATH refresh." -ForegroundColor Yellow
        }
        
        # Configure Python
        Configure-Python
        Show-PythonUsageInfo
    } else {
        Write-Host "`n[INFO] Please complete Python installation manually." -ForegroundColor Yellow
        Show-PythonUsageInfo
    }
}

Write-Host "`n[OK] Python installation script completed!" -ForegroundColor Green