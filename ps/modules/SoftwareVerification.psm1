# Software Verification Module
# Provides comprehensive software installation verification with version checking and path validation

# Color functions for consistent output
function Write-VerificationHeader {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-VerificationSuccess {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-VerificationError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-VerificationWarning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-VerificationInfo {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

# Enhanced software verification class
class SoftwareVerificationResult {
    [bool]$IsInstalled
    [string]$Version
    [string]$InstallPath
    [bool]$PathValid
    [string]$ExecutablePath
    [string]$Status
    [string]$ErrorMessage
    [hashtable]$AdditionalInfo
    
    SoftwareVerificationResult() {
        $this.IsInstalled = $false
        $this.Version = "Unknown"
        $this.InstallPath = ""
        $this.PathValid = $false
        $this.ExecutablePath = ""
        $this.Status = "Not Verified"
        $this.ErrorMessage = ""
        $this.AdditionalInfo = @{}
    }
}

# Main verification function
function Test-SoftwareInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExecutableNames = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$VersionCommands = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$CommonPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$RegistryKeys = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed = $false,
        
        [Parameter(Mandatory = $false)]
        [switch]$Quiet = $false
    )
    
    $result = [SoftwareVerificationResult]::new()
    $result.AdditionalInfo["SoftwareName"] = $SoftwareName
    
    try {
        if (-not $Quiet) {
            Write-VerificationHeader "Verifying $SoftwareName Installation"
        }
        
        # Check if executable is in PATH
        $foundInPath = $false
        foreach ($exe in $ExecutableNames) {
            $command = Get-Command $exe -ErrorAction SilentlyContinue
            if ($command) {
                $result.IsInstalled = $true
                $result.ExecutablePath = $command.Source
                $result.PathValid = Test-Path $command.Source
                $foundInPath = $true
                
                if (-not $Quiet) {
                    Write-VerificationSuccess "$exe found in PATH: $($command.Source)"
                }
                break
            }
        }
        
        # Try version commands to get version info
        if ($foundInPath -and $VersionCommands.Count -gt 0) {
            foreach ($versionCmd in $VersionCommands) {
                try {
                    $versionOutput = Invoke-Expression $versionCmd 2>$null
                    if ($versionOutput) {
                        $result.Version = ($versionOutput | Select-Object -First 3) -join " "
                        if (-not $Quiet) {
                            Write-VerificationSuccess "Version detected: $($result.Version)"
                        }
                        break
                    }
                } catch {
                    # Continue to next version command
                }
            }
        }
        
        # Check common installation paths
        if (-not $foundInPath -and $CommonPaths.Count -gt 0) {
            foreach ($path in $CommonPaths) {
                if (Test-Path $path) {
                    $result.IsInstalled = $true
                    $result.InstallPath = $path
                    $result.PathValid = $true
                    
                    if (-not $Quiet) {
                        Write-VerificationSuccess "Found installation at: $path"
                    }
                    
                    # Try to find executable in this path
                    foreach ($exe in $ExecutableNames) {
                        $exePath = Join-Path $path $exe
                        if (Test-Path $exePath) {
                            $result.ExecutablePath = $exePath
                            if (-not $Quiet) {
                                Write-VerificationSuccess "Executable found: $exePath"
                            }
                            break
                        }
                    }
                    break
                }
            }
        }
        
        # Check registry keys
        if (-not $result.IsInstalled -and $RegistryKeys.Count -gt 0) {
            foreach ($regKey in $RegistryKeys) {
                try {
                    $regValue = Get-ItemProperty -Path $regKey -ErrorAction SilentlyContinue
                    if ($regValue) {
                        $result.IsInstalled = $true
                        
                        # Try to get install path from registry
                        $installPath = $regValue.InstallLocation -or $regValue.InstallPath -or $regValue.Path
                        if ($installPath -and (Test-Path $installPath)) {
                            $result.InstallPath = $installPath
                            $result.PathValid = $true
                            
                            if (-not $Quiet) {
                                Write-VerificationSuccess "Found in registry with valid path: $installPath"
                            }
                        } else {
                            if (-not $Quiet) {
                                Write-VerificationWarning "Installation path exists in registry but is not accessible"
                            }
                        }
                        
                        # Try to get version from registry
                        $version = $regValue.Version -or $regValue.DisplayVersion
                        if ($version) {
                            $result.Version = $version
                            if (-not $Quiet) {
                                Write-VerificationSuccess "Version from registry: $version"
                            }
                        }
                        break
                    }
                } catch {
                    # Continue to next registry key
                }
            }
        }
        
        # Set final status
        if ($result.IsInstalled) {
            $result.Status = "Verified"
            if (-not $Quiet) {
                Write-VerificationSuccess "$SoftwareName verification completed successfully"
            }
        } else {
            $result.Status = "Not Found"
            if (-not $Quiet) {
                Write-VerificationError "$SoftwareName is not installed or not detectable"
            }
        }
        
    } catch {
        $result.Status = "Error"
        $result.ErrorMessage = $_.Exception.Message
        if (-not $Quiet) {
            Write-VerificationError "Verification failed: $($_.Exception.Message)"
        }
    }
    
    return $result
}

# Predefined software configurations
function Get-SoftwareConfig {
    param([string]$SoftwareName)
    
    $configs = @{
        "Git" = @{
            ExecutableNames = @("git.exe", "git")
            VersionCommands = @("git --version")
            CommonPaths = @(
                "${env:ProgramFiles}\Git\bin",
                "${env:ProgramFiles(x86)}\Git\bin",
                "${env:LOCALAPPDATA}\Programs\Git\bin"
            )
            RegistryKeys = @(
                "HKLM:\SOFTWARE\GitForWindows",
                "HKLM:\SOFTWARE\WOW6432Node\GitForWindows"
            )
        }
        "Node.js" = @{
            ExecutableNames = @("node.exe", "node")
            VersionCommands = @("node --version", "node -v")
            CommonPaths = @(
                "${env:ProgramFiles}\nodejs",
                "${env:ProgramFiles(x86)}\nodejs",
                "${env:APPDATA}\npm"
            )
            RegistryKeys = @(
                "HKLM:\SOFTWARE\Node.js",
                "HKLM:\SOFTWARE\WOW6432Node\Node.js"
            )
        }
        "Python" = @{
            ExecutableNames = @("python.exe", "python3.exe", "python")
            VersionCommands = @("python --version", "python -V", "python3 --version")
            CommonPaths = @(
                "${env:ProgramFiles}\Python*",
                "${env:ProgramFiles(x86)}\Python*",
                "${env:LOCALAPPDATA}\Programs\Python\Python*",
                "${env:APPDATA}\Python\Python*"
            )
            RegistryKeys = @(
                "HKLM:\SOFTWARE\Python\PythonCore\*\InstallPath",
                "HKCU:\SOFTWARE\Python\PythonCore\*\InstallPath"
            )
        }
        "Docker" = @{
            ExecutableNames = @("docker.exe", "docker")
            VersionCommands = @("docker --version", "docker version")
            CommonPaths = @(
                "${env:ProgramFiles}\Docker\Docker\resources\bin",
                "${env:ProgramFiles}\Docker\Docker\Resources\bin"
            )
            RegistryKeys = @(
                "HKLM:\SOFTWARE\Docker Inc.\Docker Desktop"
            )
        }
        "Chrome" = @{
            ExecutableNames = @("chrome.exe", "google-chrome")
            VersionCommands = @()
            CommonPaths = @(
                "${env:ProgramFiles}\Google\Chrome\Application",
                "${env:ProgramFiles(x86)}\Google\Chrome\Application",
                "${env:LOCALAPPDATA}\Google\Chrome\Application"
            )
            RegistryKeys = @(
                "HKLM:\SOFTWARE\Google\Chrome",
                "HKLM:\SOFTWARE\WOW6432Node\Google\Chrome"
            )
        }
        "Brave" = @{
            ExecutableNames = @("brave.exe")
            VersionCommands = @()
            CommonPaths = @(
                "${env:ProgramFiles}\BraveSoftware\Brave-Browser\Application",
                "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application",
                "${env:LOCALAPPDATA}\BraveSoftware\Brave-Browser\Application"
            )
            RegistryKeys = @(
                "HKLM:\SOFTWARE\BraveSoftware\Brave"
            )
        }
    }
    
    return $configs[$SoftwareName]
}

# Enhanced predefined software testing
function Test-PredefinedSoftware {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed = $false,
        
        [Parameter(Mandatory = $false)]
        [switch]$Quiet = $false
    )
    
    $config = Get-SoftwareConfig -SoftwareName $SoftwareName
    
    if ($config) {
        return Test-SoftwareInstallation @config -SoftwareName $SoftwareName -Detailed:$Detailed -Quiet:$Quiet
    } else {
        if (-not $Quiet) {
            Write-VerificationWarning "No predefined configuration for '$SoftwareName'. Using basic detection."
        }
        
        # Fallback to basic detection
        $result = [SoftwareVerificationResult]::new()
        $result.AdditionalInfo["SoftwareName"] = $SoftwareName
        
        try {
            $command = Get-Command $SoftwareName -ErrorAction SilentlyContinue
            if ($command) {
                $result.IsInstalled = $true
                $result.ExecutablePath = $command.Source
                $result.PathValid = Test-Path $command.Source
                $result.Status = "Verified"
                
                if (-not $Quiet) {
                    Write-VerificationSuccess "$SoftwareName found in PATH: $($command.Source)"
                }
            } else {
                $result.Status = "Not Found"
                if (-not $Quiet) {
                    Write-VerificationError "$SoftwareName not found in PATH"
                }
            }
        } catch {
            $result.Status = "Error"
            $result.ErrorMessage = $_.Exception.Message
            if (-not $Quiet) {
                Write-VerificationError "Error checking ${SoftwareName}: $($_.Exception.Message)"
            }
        }
        
        return $result
    }
}

# Test multiple software installations
function Test-MultipleSoftware {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$SoftwareList,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed = $false,
        
        [Parameter(Mandatory = $false)]
        [switch]$Quiet = $false
    )
    
    $results = @{}
    
    foreach ($software in $SoftwareList) {
        $results[$software] = Test-PredefinedSoftware -SoftwareName $software -Detailed:$Detailed -Quiet:$Quiet
    }
    
    if (-not $Quiet) {
        Write-VerificationHeader "Verification Summary"
        
        $installed = ($results.Values | Where-Object { $_.IsInstalled }).Count
        $total = $results.Count
        
        Write-VerificationInfo "Total software checked: $total"
        Write-VerificationInfo "Successfully verified: $installed"
        Write-VerificationInfo "Not found or failed: $($total - $installed)"
        
        foreach ($software in $SoftwareList) {
            $result = $results[$software]
            if ($result.IsInstalled) {
                $status = "[OK] Installed"
                if ($result.Version -ne "Unknown") {
                    $status += " (v$($result.Version))"
                }
                Write-Host "  $software : $status" -ForegroundColor Green
            } else {
                Write-Host "  $software : [X] Not Found" -ForegroundColor Red
            }
        }
    }
    
    return $results
}

# Export functions
Export-ModuleMember -Function @(
    'Test-SoftwareInstallation',
    'Test-PredefinedSoftware', 
    'Test-MultipleSoftware',
    'Get-SoftwareConfig',
    'Write-VerificationHeader',
    'Write-VerificationSuccess',
    'Write-VerificationError',
    'Write-VerificationWarning',
    'Write-VerificationInfo'
)