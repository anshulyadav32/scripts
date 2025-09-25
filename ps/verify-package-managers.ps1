# Package Manager Verification Script
param(
    [switch]$Detailed,
    [switch]$FixIssues
)

# Color functions
function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "* $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "X $Message" -ForegroundColor Red
}

# Test package manager function
function Test-PackageManager {
    param(
        [string]$Name,
        [string]$Command
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
        $commandInfo = Get-Command $Command -ErrorAction SilentlyContinue
        if ($commandInfo) {
            $result.Installed = $true
            $result.Path = $commandInfo.Source
            
            try {
                $versionOutput = & $Command --version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $result.Version = ($versionOutput | Select-Object -First 1).ToString().Trim()
                    $result.Working = $true
                } else {
                    $result.Error = "Version command failed"
                }
            } catch {
                $result.Error = $_.Exception.Message
            }
        } else {
            $result.Error = "Command not found"
        }
    } catch {
        $result.Error = $_.Exception.Message
    }
    
    return $result
}

function Start-PackageManagerVerification {
    # Main execution
    Write-Header "Package Manager Verification"

    # Test all package managers
    $results = @()

    Write-Host "i Testing Chocolatey..." -ForegroundColor Blue
    $results += Test-PackageManager -Name "Chocolatey" -Command "choco"

    Write-Host "i Testing Scoop..." -ForegroundColor Blue
    $results += Test-PackageManager -Name "Scoop" -Command "scoop"

    Write-Host "i Testing WinGet..." -ForegroundColor Blue
    $results += Test-PackageManager -Name "WinGet" -Command "winget"

    # Show detailed report if requested
    if ($Detailed) {
        Write-Header "Detailed Report"
        
        foreach ($result in $results) {
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

    # Show summary
    Write-Header "Summary"

    $working = 0
    $total = $results.Count

    foreach ($result in $results) {
        if ($result.Working) {
            Write-Success "$($result.Name): Working (v$($result.Version))"
            $working++
        } else {
            Write-Error "$($result.Name): Not working - $($result.Error)"
        }
    }

    Write-Host "`nOverall Status: $working/$total package managers working" -ForegroundColor $(if ($working -eq $total) { "Green" } elseif ($working -gt 0) { "Yellow" } else { "Red" })

    # Show recommendations for failed managers
    $failedManagers = $results | Where-Object { -not $_.Working }
    if ($failedManagers) {
        Write-Header "Recommendations"
        
        foreach ($failed in $failedManagers) {
            switch ($failed.Name) {
                "Chocolatey" {
                    Write-Host "i To install Chocolatey: Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor Blue
                }
                "Scoop" {
                    Write-Host "i To install Scoop: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm get.scoop.sh | iex" -ForegroundColor Blue
                }
                "WinGet" {
                    Write-Host "i WinGet should be pre-installed. Try restarting PowerShell or install from Microsoft Store." -ForegroundColor Blue
                }
            }
        }
    }

    return $results
}

# Auto-execute if script is run directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    Start-PackageManagerVerification
}