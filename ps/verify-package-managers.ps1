# Package Manager Verification Script
# Verifies installation and functionality of Chocolatey, Scoop, and WinGet

param(
    [switch]$Detailed,
    [switch]$FixIssues
)

# Color functions for better output
function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

# Test individual package manager
function Test-PackageManager {
    param(
        [string]$Name,
        [string]$Command,
        [string]$VersionArg = "--version"
    )
    
    $result = @{
        Name = $Name
        Installed = $false
        Version = $null
        Path = $null
        Working = $false
        Error = $null
    }
    
    try {
        # Check if command exists
        $commandInfo = Get-Command $Command -ErrorAction SilentlyContinue
        if ($commandInfo) {
            $result.Installed = $true
            $result.Path = $commandInfo.Source
            
            # Try to get version
            try {
                $versionOutput = & $Command $VersionArg 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $result.Version = ($versionOutput | Select-Object -First 1).ToString().Trim()
                    $result.Working = $true
                } else {
                    $result.Error = "Command failed with exit code $LASTEXITCODE"
                }
            } catch {
                $result.Error = $_.Exception.Message
            }
        } else {
            $result.Error = "Command not found in PATH"
        }
    } catch {
        $result.Error = $_.Exception.Message
    }
    
    return $result
}

# Main verification function
function Test-AllPackageManagers {
    Write-Header "Package Manager Verification"
    
    $results = @()
    
    # Test Chocolatey
    Write-Host "ℹ Testing Chocolatey..." -ForegroundColor Blue
    $chocoResult = Test-PackageManager -Name "Chocolatey" -Command "choco"
    $results += $chocoResult
    
    # Test Scoop
    Write-Host "ℹ Testing Scoop..." -ForegroundColor Blue
    $scoopResult = Test-PackageManager -Name "Scoop" -Command "scoop"
    $results += $scoopResult
    
    # Test WinGet
    Write-Host "ℹ Testing WinGet..." -ForegroundColor Blue
    $wingetResult = Test-PackageManager -Name "WinGet" -Command "winget"
    $results += $wingetResult
    
    return $results
}

# Show basic summary
function Show-Summary {
    param([array]$Results)
    
    Write-Header "Summary"
    
    $working = 0
    $total = $Results.Count
    
    foreach ($result in $Results) {
        if ($result.Working) {
            Write-Success "$($result.Name): Working (v$($result.Version))"
            $working++
        } else {
            Write-Error "$($result.Name): Not working - $($result.Error)"
        }
    }
    
    Write-Host "`nOverall Status: $working/$total package managers working" -ForegroundColor $(if ($working -eq $total) { "Green" } elseif ($working -gt 0) { "Yellow" } else { "Red" })
}

# Show detailed report
function Show-DetailedReport {
    param([array]$Results)
    
    Write-Header "Detailed Report"
    
    foreach ($result in $Results) {
        Write-Host "`n--- $($result.Name) ---" -ForegroundColor White
        Write-Host "Installed: $($result.Installed)" -ForegroundColor $(if ($result.Installed) { "Green" } else { "Red" })
        
        if ($result.Path) {
            Write-Host "Path: $($result.Path)" -ForegroundColor Gray
        }
        
        if ($result.Version) {
            Write-Host "Version: $($result.Version)" -ForegroundColor Gray
        }
        
        Write-Host "Working: $($result.Working)" -ForegroundColor $(if ($result.Working) { "Green" } else { "Red" })
        
        if ($result.Error) {
            Write-Host "Error: $($result.Error)" -ForegroundColor Red
        }
    }
}

# Attempt to fix common issues
function Fix-CommonIssues {
    Write-Header "Attempting to Fix Common Issues"
    
    # Refresh environment variables
    Write-Host "ℹ Refreshing environment variables..." -ForegroundColor Blue
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = $machinePath + ";" + $userPath
    
    # Check for Scoop in user profile
    $scoopPath = "$env:USERPROFILE\scoop\shims"
    if ((Test-Path $scoopPath) -and ($env:PATH -notlike "*$scoopPath*")) {
        Write-Host "ℹ Adding Scoop to PATH: $scoopPath" -ForegroundColor Blue
        $env:PATH += ";$scoopPath"
    }
    
    # Check for WinGet in Windows Apps
    $wingetPath1 = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    $wingetPath2 = "$env:ProgramFiles\WindowsApps"
    
    if (Test-Path $wingetPath1) {
        Write-Host "ℹ Found WinGet at: $wingetPath1" -ForegroundColor Blue
    } elseif (Test-Path $wingetPath2) {
        $wingetInstalls = Get-ChildItem "$wingetPath2\Microsoft.DesktopAppInstaller*" -ErrorAction SilentlyContinue
        if ($wingetInstalls) {
            foreach ($install in $wingetInstalls) {
                $wingetExe = Join-Path $install.FullName "winget.exe"
                if (Test-Path $wingetExe) {
                    Write-Host "ℹ Found WinGet at: $wingetExe" -ForegroundColor Blue
                    break
                }
            }
        }
    }
    
    Write-Host "ℹ Environment fixes applied. Re-testing..." -ForegroundColor Blue
}

# Main execution
try {
    if ($FixIssues) {
        Fix-CommonIssues
    }
    
    $results = Test-AllPackageManagers
    
    if ($Detailed) {
        Show-DetailedReport -Results $results
    }
    
    Show-Summary -Results $results
    
    # Provide recommendations
    $failedManagers = $results | Where-Object { -not $_.Working }
    if ($failedManagers) {
        Write-Header "Recommendations"
        
        foreach ($failed in $failedManagers) {
             switch ($failed.Name) {
                 "Chocolatey" {
                     Write-Host "ℹ To install Chocolatey, run: Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor Blue
                 }
                 "Scoop" {
                     Write-Host "ℹ To install Scoop, run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm get.scoop.sh | iex" -ForegroundColor Blue
                 }
                 "WinGet" {
                     Write-Host "ℹ WinGet should be pre-installed on Windows 10/11. Try restarting PowerShell or installing from Microsoft Store." -ForegroundColor Blue
                 }
             }
         }
    }
    
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}