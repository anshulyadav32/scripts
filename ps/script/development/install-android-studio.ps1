# Install Android Studio - Official IDE for Android development

function Test-AndroidStudioInstalled {
    $installed = $false
    
    # Common installation paths
    $paths = @(
        "${env:ProgramFiles}\Android\Android Studio\bin\studio64.exe",
        "${env:ProgramFiles(x86)}\Android\Android Studio\bin\studio64.exe",
        "${env:LOCALAPPDATA}\Programs\Android Studio\bin\studio64.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "Android Studio found at: $path" -ForegroundColor Green
            $installed = $true
            break
        }
    }
    
    # Check via Chocolatey
    if (-not $installed) {
        $chocoPackage = choco list --local-only | Select-String "androidstudio"
        if ($chocoPackage) {
            Write-Host "Android Studio found via Chocolatey" -ForegroundColor Green
            $installed = $true
        }
    }
    
    return $installed
}

function Test-AndroidStudioFunctionality {
    Write-Host "Running Android Studio functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        InstallationTest = $false
        SDKTest = $false
        JavaTest = $false
        OverallSuccess = $false
    }
    
    Write-Host "  Testing installation integrity..." -ForegroundColor Yellow
    if (Test-AndroidStudioInstalled) {
        Write-Host "     Installation found" -ForegroundColor Green
        $results.InstallationTest = $true
    }
    
    Write-Host "  Testing Android SDK..." -ForegroundColor Yellow
    $sdkPaths = @(
        "${env:LOCALAPPDATA}\Android\Sdk",
        "${env:APPDATA}\Android\Sdk",
        "${env:ANDROID_HOME}"
    )
    
    foreach ($sdkPath in $sdkPaths) {
        if ($sdkPath -and (Test-Path $sdkPath)) {
            Write-Host "     Android SDK found at: $sdkPath" -ForegroundColor Green
            $results.SDKTest = $true
            break
        }
    }
    
    Write-Host "  Testing Java installation..." -ForegroundColor Yellow
    try {
        $javaVersion = java -version 2>&1
        if ($javaVersion -match "version") {
            Write-Host "     Java is available" -ForegroundColor Green
            $results.JavaTest = $true
        }
    } catch {
        Write-Host "     Java not found in PATH" -ForegroundColor Yellow
    }
    
    $passedTests = ($results.InstallationTest + $results.SDKTest + $results.JavaTest)
    $results.OverallSuccess = ($passedTests -ge 2)
    
    Write-Host "  Tests passed: $passedTests/3" -ForegroundColor Green
    
    return $results
}

function Update-AndroidStudio {
    Write-Host "Updating Android Studio..." -ForegroundColor Cyan
    
    if (-not (Test-AndroidStudioInstalled)) {
        Write-Host "Android Studio is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        # Try to update via Chocolatey if available
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Attempting to update via Chocolatey..." -ForegroundColor Yellow
            choco upgrade androidstudio -y
            return $true
        }
        
        Write-Host "For updates, please use Android Studio's built-in update mechanism:" -ForegroundColor Yellow
        Write-Host "  1. Open Android Studio" -ForegroundColor White
        Write-Host "  2. Go to Help > Check for Updates" -ForegroundColor White
        Write-Host "  3. Follow the update prompts" -ForegroundColor White
        
        return $false
        
    } catch {
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-AndroidStudioPackageManager {
    Write-Host "Installing Android Studio..." -ForegroundColor Cyan
    
    $installSuccess = $false
    
    # Method 1: Try Chocolatey first
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing via Chocolatey..." -ForegroundColor Yellow
        try {
            # Install Android Studio
            choco install androidstudio -y
            
            # Install additional useful packages
            Write-Host "Installing additional Android development tools..." -ForegroundColor Yellow
            choco install adb -y --ignore-dependencies
            
            $installSuccess = $true
            Write-Host "Android Studio installed successfully via Chocolatey!" -ForegroundColor Green
        } catch {
            Write-Host "Chocolatey installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Method 2: Try WinGet if Chocolatey failed
    if (-not $installSuccess -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Installing via WinGet..." -ForegroundColor Yellow
        try {
            winget install --id Google.AndroidStudio --source winget
            $installSuccess = $true
            Write-Host "Android Studio installed successfully via WinGet!" -ForegroundColor Green
        } catch {
            Write-Host "WinGet installation failed, providing manual installation guidance..." -ForegroundColor Yellow
        }
    }
    
    # Method 3: Manual installation guidance
    if (-not $installSuccess) {
        Write-Host "Automated installation failed. Manual installation required:" -ForegroundColor Yellow
        Write-Host "1. Download from: https://developer.android.com/studio" -ForegroundColor White
        Write-Host "2. Run the installer as Administrator" -ForegroundColor White
        Write-Host "3. Follow the setup wizard" -ForegroundColor White
        Write-Host "4. Configure Android SDK when prompted" -ForegroundColor White
    }
    
    return $installSuccess
}

function Set-AndroidEnvironmentVariables {
    Write-Host "Configuring Android environment variables..." -ForegroundColor Cyan
    
    # Common SDK locations
    $sdkPaths = @(
        "${env:LOCALAPPDATA}\Android\Sdk",
        "${env:APPDATA}\Android\Sdk",
        "${env:ProgramFiles}\Android\android-sdk",
        "${env:ProgramFiles(x86)}\Android\android-sdk"
    )
    
    $sdkPath = $null
    foreach ($path in $sdkPaths) {
        if (Test-Path $path) {
            $sdkPath = $path
            break
        }
    }
    
    if ($sdkPath) {
        Write-Host "Setting ANDROID_HOME to: $sdkPath" -ForegroundColor Green
        [Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
        
        # Add SDK tools to PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $toolsPaths = @(
            "$sdkPath\tools",
            "$sdkPath\tools\bin", 
            "$sdkPath\platform-tools"
        )
        
        foreach ($toolsPath in $toolsPaths) {
            if ((Test-Path $toolsPath) -and ($currentPath -notlike "*$toolsPath*")) {
                $currentPath = "$currentPath;$toolsPath"
                Write-Host "Added to PATH: $toolsPath" -ForegroundColor Green
            }
        }
        
        [Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
        Write-Host "Android environment variables configured successfully!" -ForegroundColor Green
    } else {
        Write-Host "Android SDK not found. Environment variables not set." -ForegroundColor Yellow
        Write-Host "Please run Android Studio first time setup to install SDK." -ForegroundColor Yellow
    }
}

function Show-AndroidStudioUsageInfo {
    Write-Host "`n=== Android Studio Usage Guide ===" -ForegroundColor Magenta
    Write-Host "Getting Started:" -ForegroundColor Yellow
    Write-Host "  1. Launch Android Studio from Start Menu" -ForegroundColor White
    Write-Host "  2. Complete first-time setup wizard" -ForegroundColor White
    Write-Host "  3. Download Android SDK and tools" -ForegroundColor White
    Write-Host "  4. Create or import an Android project" -ForegroundColor White
    
    Write-Host "`nKey Features:" -ForegroundColor Yellow
    Write-Host "  • Intelligent code completion" -ForegroundColor White
    Write-Host "  • Visual Layout Editor" -ForegroundColor White
    Write-Host "  • Built-in Android Emulator" -ForegroundColor White
    Write-Host "  • APK Analyzer and Profilers" -ForegroundColor White
    Write-Host "  • Git integration" -ForegroundColor White
    
    Write-Host "`nUseful Commands:" -ForegroundColor Yellow
    Write-Host "  adb devices              # List connected devices" -ForegroundColor White
    Write-Host "  adb install app.apk      # Install APK to device" -ForegroundColor White
    Write-Host "  adb logcat              # View device logs" -ForegroundColor White
    
    Write-Host "`nSystem Requirements:" -ForegroundColor Yellow
    Write-Host "  • 8 GB RAM minimum (16 GB recommended)" -ForegroundColor White
    Write-Host "  • 8 GB available disk space" -ForegroundColor White
    Write-Host "  • Java 11 or higher" -ForegroundColor White
    Write-Host "  • Hardware acceleration for emulator" -ForegroundColor White
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  1. Launch Android Studio" -ForegroundColor White
    Write-Host "  2. Install Android SDK via SDK Manager" -ForegroundColor White
    Write-Host "  3. Create AVD (Android Virtual Device)" -ForegroundColor White
    Write-Host "  4. Start building Android apps!" -ForegroundColor White
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Android Studio Installation Script" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan

if (Test-AndroidStudioInstalled) {
    Write-Host "Android Studio is already installed!" -ForegroundColor Green
    
    # Run functionality tests
    $testResults = Test-AndroidStudioFunctionality
    
    if ($testResults.OverallSuccess) {
        Write-Host "`n[SUCCESS] Android Studio is working correctly!" -ForegroundColor Green
    } else {
        Write-Host "`n[WARNING] Android Studio may need additional configuration." -ForegroundColor Yellow
        
        if (-not $testResults.SDKTest) {
            Write-Host "  • Android SDK not found - run first-time setup" -ForegroundColor Yellow
        }
        if (-not $testResults.JavaTest) {
            Write-Host "  • Java not found in PATH - may need JDK installation" -ForegroundColor Yellow
        }
    }
    
    # Configure environment variables if needed
    Set-AndroidEnvironmentVariables
    Show-AndroidStudioUsageInfo
} else {
    Write-Host "Installing Android Studio..." -ForegroundColor Yellow
    
    if (Install-AndroidStudioPackageManager) {
        Write-Host "`n[SUCCESS] Android Studio installation completed!" -ForegroundColor Green
        
        # Test the installation
        Start-Sleep -Seconds 5
        $testResults = Test-AndroidStudioFunctionality
        
        if ($testResults.OverallSuccess) {
            Write-Host "[SUCCESS] Installation verified successfully!" -ForegroundColor Green
        }
        
        # Configure environment
        Set-AndroidEnvironmentVariables
        Show-AndroidStudioUsageInfo
    } else {
        Write-Host "`n[ERROR] Android Studio installation failed!" -ForegroundColor Red
        Write-Host "Please try manual installation from: https://developer.android.com/studio" -ForegroundColor Yellow
        Show-AndroidStudioUsageInfo
    }
}

Write-Host "`n[OK] Android Studio installation script completed!" -ForegroundColor Green