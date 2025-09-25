# Install Visual Studio - Microsoft's premier IDE for .NET development

function Test-VisualStudioInstalled {
    $installed = $false
    $editions = @()
    
    # Check for Visual Studio installations via registry and common paths
    $vsVersions = @("2022", "2019", "2017")
    $vsEditions = @("Enterprise", "Professional", "Community", "BuildTools")
    
    foreach ($version in $vsVersions) {
        foreach ($edition in $vsEditions) {
            $vsPath = "${env:ProgramFiles}\Microsoft Visual Studio\$version\$edition\Common7\IDE\devenv.exe"
            if (Test-Path $vsPath) {
                Write-Host "Visual Studio $version $edition found at: $vsPath" -ForegroundColor Green
                $editions += "$version $edition"
                $installed = $true
            }
        }
    }
    
    # Check via Chocolatey
    if (-not $installed) {
        $chocoPackages = choco list --local-only | Select-String "visualstudio"
        if ($chocoPackages) {
            Write-Host "Visual Studio found via Chocolatey" -ForegroundColor Green
            $installed = $true
        }
    }
    
    if ($editions.Count -gt 0) {
        Write-Host "Installed editions: $($editions -join ', ')" -ForegroundColor Cyan
    }
    
    return $installed
}

function Test-VisualStudioFunctionality {
    Write-Host "Running Visual Studio functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        InstallationTest = $false
        WorkloadTest = $false
        DotNetTest = $false
        MSBuildTest = $false
        OverallSuccess = $false
    }
    
    Write-Host "  Testing installation..." -ForegroundColor Yellow
    if (Test-VisualStudioInstalled) {
        Write-Host "     Installation verified" -ForegroundColor Green
        $results.InstallationTest = $true
    }
    
    Write-Host "  Testing .NET SDK..." -ForegroundColor Yellow
    try {
        $dotnetVersion = dotnet --version 2>$null
        if ($dotnetVersion) {
            Write-Host "     .NET SDK version: $dotnetVersion" -ForegroundColor Green
            $results.DotNetTest = $true
        }
    } catch {
        Write-Host "     .NET SDK not found" -ForegroundColor Yellow
    }
    
    Write-Host "  Testing MSBuild..." -ForegroundColor Yellow
    try {
        # Check for MSBuild in common locations
        $msbuildPaths = @(
            "${env:ProgramFiles}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe",
            "${env:ProgramFiles}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe"
        )
        
        $msbuildFound = $false
        foreach ($path in $msbuildPaths) {
            $resolved = Resolve-Path $path -ErrorAction SilentlyContinue
            if ($resolved) {
                Write-Host "     MSBuild found: $($resolved.Path)" -ForegroundColor Green
                $results.MSBuildTest = $true
                $msbuildFound = $true
                break
            }
        }
        
        if (-not $msbuildFound) {
            Write-Host "     MSBuild not found in expected locations" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "     MSBuild test failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing installed workloads..." -ForegroundColor Yellow
    try {
        # Check for Visual Studio Installer
        $vsInstallerPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
        if (Test-Path $vsInstallerPath) {
            Write-Host "     Visual Studio Installer available" -ForegroundColor Green
            $results.WorkloadTest = $true
        } else {
            Write-Host "     Visual Studio Installer not found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "     Workload test failed" -ForegroundColor Red
    }
    
    $passedTests = ($results.InstallationTest + $results.DotNetTest + $results.MSBuildTest + $results.WorkloadTest)
    $results.OverallSuccess = ($passedTests -ge 2)
    
    Write-Host "  Tests passed: $passedTests/4" -ForegroundColor Green
    
    return $results
}

function Update-VisualStudio {
    Write-Host "Updating Visual Studio..." -ForegroundColor Cyan
    
    if (-not (Test-VisualStudioInstalled)) {
        Write-Host "Visual Studio is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        # Try Visual Studio Installer first
        $vsInstallerPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
        if (Test-Path $vsInstallerPath) {
            Write-Host "Launching Visual Studio Installer for updates..." -ForegroundColor Yellow
            Start-Process -FilePath $vsInstallerPath -ArgumentList "update" -Wait
            return $true
        }
        
        # Try Chocolatey as fallback
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Attempting to update via Chocolatey..." -ForegroundColor Yellow
            choco upgrade visualstudio2022community -y
            return $true
        }
        
        Write-Host "Please update Visual Studio manually:" -ForegroundColor Yellow
        Write-Host "  1. Open Visual Studio" -ForegroundColor White
        Write-Host "  2. Go to Help > Check for Updates" -ForegroundColor White
        Write-Host "  3. Or use Visual Studio Installer" -ForegroundColor White
        
        return $false
        
    } catch {
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-VisualStudioPackageManager {
    Write-Host "Installing Visual Studio Community 2022..." -ForegroundColor Cyan
    
    $installSuccess = $false
    
    # Method 1: Try Chocolatey first (most reliable for automation)
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing via Chocolatey..." -ForegroundColor Yellow
        try {
            # Install Visual Studio Community with common workloads
            Write-Host "Installing Visual Studio Community 2022..." -ForegroundColor Yellow
            choco install visualstudio2022community -y
            
            Write-Host "Installing common workloads..." -ForegroundColor Yellow
            # Install popular workloads
            choco install visualstudio2022-workload-netweb -y
            choco install visualstudio2022-workload-manageddesktop -y
            choco install visualstudio2022-workload-netcoretools -y
            
            $installSuccess = $true
            Write-Host "Visual Studio Community 2022 installed successfully via Chocolatey!" -ForegroundColor Green
        } catch {
            Write-Host "Chocolatey installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Method 2: Try WinGet if Chocolatey failed
    if (-not $installSuccess -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Installing via WinGet..." -ForegroundColor Yellow
        try {
            winget install --id Microsoft.VisualStudio.2022.Community --source winget
            $installSuccess = $true
            Write-Host "Visual Studio Community 2022 installed successfully via WinGet!" -ForegroundColor Green
        } catch {
            Write-Host "WinGet installation failed, providing manual installation guidance..." -ForegroundColor Yellow
        }
    }
    
    # Method 3: Manual installation guidance
    if (-not $installSuccess) {
        Write-Host "Automated installation failed. Manual installation options:" -ForegroundColor Yellow
        Write-Host "`n=== Manual Installation ===" -ForegroundColor Cyan
        Write-Host "Visual Studio Community (Free):" -ForegroundColor Green
        Write-Host "  Download: https://visualstudio.microsoft.com/vs/community/" -ForegroundColor White
        Write-Host "`nVisual Studio Professional:" -ForegroundColor Yellow  
        Write-Host "  Download: https://visualstudio.microsoft.com/vs/professional/" -ForegroundColor White
        Write-Host "`nVisual Studio Enterprise:" -ForegroundColor Magenta
        Write-Host "  Download: https://visualstudio.microsoft.com/vs/enterprise/" -ForegroundColor White
        
        Write-Host "`nInstallation Steps:" -ForegroundColor Yellow
        Write-Host "  1. Download the installer" -ForegroundColor White
        Write-Host "  2. Run as Administrator" -ForegroundColor White
        Write-Host "  3. Select workloads you need" -ForegroundColor White
        Write-Host "  4. Complete the installation" -ForegroundColor White
    }
    
    return $installSuccess
}

function Show-VisualStudioWorkloads {
    Write-Host "`n=== Recommended Workloads ===" -ForegroundColor Magenta
    Write-Host "Web Development:" -ForegroundColor Yellow
    Write-Host "  • ASP.NET and web development" -ForegroundColor White
    Write-Host "  • Node.js development" -ForegroundColor White
    
    Write-Host "`nDesktop Development:" -ForegroundColor Yellow
    Write-Host "  • .NET desktop development (WPF, WinForms)" -ForegroundColor White
    Write-Host "  • Universal Windows Platform development" -ForegroundColor White
    
    Write-Host "`nMobile Development:" -ForegroundColor Yellow
    Write-Host "  • Mobile development with .NET (Xamarin)" -ForegroundColor White
    
    Write-Host "`nCloud Development:" -ForegroundColor Yellow
    Write-Host "  • Azure development" -ForegroundColor White
    
    Write-Host "`nGame Development:" -ForegroundColor Yellow
    Write-Host "  • Game development with Unity" -ForegroundColor White
    Write-Host "  • Game development with C++" -ForegroundColor White
    
    Write-Host "`nData & Analytics:" -ForegroundColor Yellow
    Write-Host "  • Data storage and processing" -ForegroundColor White
    Write-Host "  • Data science and analytical applications" -ForegroundColor White
}

function Show-VisualStudioUsageInfo {
    Write-Host "`n=== Visual Studio Usage Guide ===" -ForegroundColor Magenta
    
    Write-Host "Getting Started:" -ForegroundColor Yellow
    Write-Host "  1. Launch Visual Studio from Start Menu" -ForegroundColor White
    Write-Host "  2. Sign in with Microsoft account (optional)" -ForegroundColor White
    Write-Host "  3. Choose development settings" -ForegroundColor White
    Write-Host "  4. Create new project or open existing" -ForegroundColor White
    
    Write-Host "`nProject Types:" -ForegroundColor Yellow
    Write-Host "  • Console App (.NET Core/Framework)" -ForegroundColor White
    Write-Host "  • ASP.NET Core Web Application" -ForegroundColor White
    Write-Host "  • WPF Application" -ForegroundColor White
    Write-Host "  • Windows Forms App" -ForegroundColor White
    Write-Host "  • Xamarin Mobile App" -ForegroundColor White
    Write-Host "  • Unity Game Project" -ForegroundColor White
    
    Write-Host "`nKey Features:" -ForegroundColor Yellow
    Write-Host "  • IntelliSense code completion" -ForegroundColor White
    Write-Host "  • Integrated debugger" -ForegroundColor White
    Write-Host "  • Git integration" -ForegroundColor White
    Write-Host "  • NuGet package manager" -ForegroundColor White
    Write-Host "  • Live code analysis" -ForegroundColor White
    Write-Host "  • Team collaboration tools" -ForegroundColor White
    
    Write-Host "`nUseful Shortcuts:" -ForegroundColor Yellow
    Write-Host "  Ctrl+Shift+N     # New project" -ForegroundColor White
    Write-Host "  Ctrl+Shift+O     # Open project/solution" -ForegroundColor White
    Write-Host "  F5               # Start debugging" -ForegroundColor White
    Write-Host "  Ctrl+F5          # Start without debugging" -ForegroundColor White
    Write-Host "  Ctrl+Shift+B     # Build solution" -ForegroundColor White
    Write-Host "  Ctrl+K, Ctrl+C   # Comment selection" -ForegroundColor White
    
    Show-VisualStudioWorkloads
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Visual Studio Installation Script" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan

if (Test-VisualStudioInstalled) {
    Write-Host "Visual Studio is already installed!" -ForegroundColor Green
    
    # Run functionality tests
    $testResults = Test-VisualStudioFunctionality
    
    if ($testResults.OverallSuccess) {
        Write-Host "`n[SUCCESS] Visual Studio is working correctly!" -ForegroundColor Green
    } else {
        Write-Host "`n[WARNING] Visual Studio may need additional configuration." -ForegroundColor Yellow
        
        if (-not $testResults.DotNetTest) {
            Write-Host "  • .NET SDK not found - install via Visual Studio Installer" -ForegroundColor Yellow
        }
        if (-not $testResults.MSBuildTest) {
            Write-Host "  • MSBuild not accessible - check workload installation" -ForegroundColor Yellow
        }
        if (-not $testResults.WorkloadTest) {
            Write-Host "  • Visual Studio Installer not found" -ForegroundColor Yellow
        }
    }
    
    Show-VisualStudioUsageInfo
} else {
    Write-Host "Installing Visual Studio Community 2022..." -ForegroundColor Yellow
    
    if (Install-VisualStudioPackageManager) {
        Write-Host "`n[SUCCESS] Visual Studio installation completed!" -ForegroundColor Green
        
        # Test the installation
        Start-Sleep -Seconds 10
        $testResults = Test-VisualStudioFunctionality
        
        if ($testResults.OverallSuccess) {
            Write-Host "[SUCCESS] Installation verified successfully!" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Installation completed, but some components may need configuration." -ForegroundColor Yellow
        }
        
        Show-VisualStudioUsageInfo
    } else {
        Write-Host "`n[INFO] Please complete Visual Studio installation manually." -ForegroundColor Yellow
        Show-VisualStudioUsageInfo
    }
}

Write-Host "`n[OK] Visual Studio installation script completed!" -ForegroundColor Green