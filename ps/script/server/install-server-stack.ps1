# Complete Server Development Stack Installation
# Installs: XAMPP, PostgreSQL, Node.js LTS, Python 3.13, Git, GitHub CLI

param(
    [switch]$SkipXAMPP,
    [switch]$SkipPostgreSQL,
    [switch]$SkipNodeJS,
    [switch]$SkipPython,
    [switch]$SkipGit,
    [switch]$Interactive
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ServerScriptsPath = $ScriptPath

function Write-Header {
    param($Title)
    Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Write-Step {
    param($StepNumber, $Description)
    Write-Host "`n[$StepNumber] $Description" -ForegroundColor Yellow
}

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $results = @{
        Chocolatey = $false
        WinGet = $false
        PowerShell = $true
        Admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    
    # Check Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "✅ Chocolatey is available" -ForegroundColor Green
        $results.Chocolatey = $true
    } else {
        Write-Host "❌ Chocolatey not found" -ForegroundColor Red
    }
    
    # Check WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "✅ WinGet is available" -ForegroundColor Green
        $results.WinGet = $true
    } else {
        Write-Host "❌ WinGet not found" -ForegroundColor Yellow
    }
    
    # Check Admin privileges
    if ($results.Admin) {
        Write-Host "✅ Running as Administrator" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Not running as Administrator (some installations may fail)" -ForegroundColor Yellow
    }
    
    return $results
}

function Show-InstallationPlan {
    Write-Header "Installation Plan"
    
    Write-Host "The following server components will be installed:" -ForegroundColor Cyan
    
    if (-not $SkipXAMPP) {
        Write-Host "  🌐 XAMPP (Apache + MySQL + PHP + phpMyAdmin)" -ForegroundColor White
    }
    
    if (-not $SkipPostgreSQL) {
        Write-Host "  🐘 PostgreSQL + pgAdmin" -ForegroundColor White
    }
    
    if (-not $SkipNodeJS) {
        Write-Host "  🟢 Node.js LTS + npm + Global Tools" -ForegroundColor White
    }
    
    if (-not $SkipPython) {
        Write-Host "  🐍 Python 3.13 + pip + Virtual Environment Tools" -ForegroundColor White
    }
    
    if (-not $SkipGit) {
        Write-Host "  📚 Git + GitHub CLI" -ForegroundColor White
    }
    
    Write-Host "`nEstimated installation time: 15-30 minutes" -ForegroundColor Gray
    Write-Host "Disk space required: ~2-3 GB" -ForegroundColor Gray
}

function Confirm-Installation {
    if ($Interactive) {
        Write-Host "`nProceed with installation? " -ForegroundColor Yellow -NoNewline
        $response = Read-Host "[Y/n]"
        if ($response -eq 'n' -or $response -eq 'N') {
            Write-Host "Installation cancelled by user." -ForegroundColor Red
            exit 1
        }
    }
}

function Install-Component {
    param(
        [string]$ComponentName,
        [string]$ScriptName,
        [string]$StepNumber
    )
    
    Write-Step $StepNumber "Installing $ComponentName"
    
    $scriptPath = Join-Path $ServerScriptsPath $ScriptName
    
    if (Test-Path $scriptPath) {
        Write-Host "Executing: $ScriptName" -ForegroundColor Gray
        
        try {
            & powershell -ExecutionPolicy Bypass -File $scriptPath
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ $ComponentName installation completed successfully!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ $ComponentName installation failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "❌ $ComponentName installation failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "❌ Script not found: $scriptPath" -ForegroundColor Red
        return $false
    }
}

function Show-InstallationSummary {
    param($Results)
    
    Write-Header "Installation Summary"
    
    $successCount = 0
    $totalCount = 0
    
    foreach ($component in $Results.Keys) {
        $totalCount++
        if ($Results[$component]) {
            Write-Host "✅ $component" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "❌ $component" -ForegroundColor Red
        }
    }
    
    Write-Host "`nInstallation completed: $successCount/$totalCount components successful" -ForegroundColor Cyan
    
    if ($successCount -eq $totalCount) {
        Write-Host "`n🎉 All components installed successfully!" -ForegroundColor Green
        Write-Host "Your development server stack is ready!" -ForegroundColor Green
    } elseif ($successCount -gt 0) {
        Write-Host "`n⚠️  Some components failed to install. Check individual logs above." -ForegroundColor Yellow
    } else {
        Write-Host "`n❌ No components were installed successfully." -ForegroundColor Red
    }
}

function Show-PostInstallationInfo {
    Write-Header "Post-Installation Information"
    
    Write-Host "🚀 Quick Start Guide:" -ForegroundColor Yellow
    
    if (-not $SkipXAMPP) {
        Write-Host "`n📁 XAMPP:" -ForegroundColor Cyan
        Write-Host "  • Launch XAMPP Control Panel" -ForegroundColor White
        Write-Host "  • Start Apache and MySQL services" -ForegroundColor White
        Write-Host "  • Visit: http://localhost" -ForegroundColor White
        Write-Host "  • phpMyAdmin: http://localhost/phpmyadmin" -ForegroundColor White
    }
    
    if (-not $SkipPostgreSQL) {
        Write-Host "`n🐘 PostgreSQL:" -ForegroundColor Cyan
        Write-Host "  • Launch pgAdmin from Start Menu" -ForegroundColor White
        Write-Host "  • Default user: postgres" -ForegroundColor White
        Write-Host "  • Connect via: localhost:5432" -ForegroundColor White
    }
    
    if (-not $SkipNodeJS) {
        Write-Host "`n🟢 Node.js:" -ForegroundColor Cyan
        Write-Host "  • Test: node --version" -ForegroundColor White
        Write-Host "  • Create project: npm init -y" -ForegroundColor White
        Write-Host "  • Dev server: npx live-server" -ForegroundColor White
    }
    
    if (-not $SkipPython) {
        Write-Host "`n🐍 Python:" -ForegroundColor Cyan
        Write-Host "  • Test: python --version" -ForegroundColor White
        Write-Host "  • Virtual env: python -m venv myproject" -ForegroundColor White
        Write-Host "  • Activate: myproject\Scripts\activate" -ForegroundColor White
    }
    
    if (-not $SkipGit) {
        Write-Host "`n📚 Git & GitHub:" -ForegroundColor Cyan
        Write-Host "  • Configure: git config --global user.name 'Your Name'" -ForegroundColor White
        Write-Host "  • Configure: git config --global user.email 'your@email.com'" -ForegroundColor White
        Write-Host "  • GitHub auth: gh auth login" -ForegroundColor White
    }
    
    Write-Host "`n🔧 Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Configure user accounts and passwords" -ForegroundColor White
    Write-Host "  2. Set up your first project" -ForegroundColor White
    Write-Host "  3. Install additional packages as needed" -ForegroundColor White
    Write-Host "  4. Create development databases" -ForegroundColor White
    
    Write-Host "`n📖 Documentation:" -ForegroundColor Yellow
    Write-Host "  • XAMPP: https://www.apachefriends.org/docs/" -ForegroundColor White
    Write-Host "  • PostgreSQL: https://www.postgresql.org/docs/" -ForegroundColor White
    Write-Host "  • Node.js: https://nodejs.org/docs/" -ForegroundColor White
    Write-Host "  • Python: https://docs.python.org/" -ForegroundColor White
    Write-Host "  • Git: https://git-scm.com/docs" -ForegroundColor White
}

# Main execution
Clear-Host

Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                    SERVER STACK INSTALLER                   ║
║                                                              ║
║  Complete development server environment setup for Windows  ║
║                                                              ║
║  Components: XAMPP + PostgreSQL + Node.js + Python + Git    ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check prerequisites
$prerequisites = Test-Prerequisites

if (-not ($prerequisites.Chocolatey -or $prerequisites.WinGet)) {
    Write-Host "`n❌ Error: Neither Chocolatey nor WinGet found!" -ForegroundColor Red
    Write-Host "Please install at least one package manager before running this script." -ForegroundColor Yellow
    Write-Host "Run: script/package-managers/install-chocolatey.ps1" -ForegroundColor White
    exit 1
}

# Show installation plan
Show-InstallationPlan

# Confirm installation
Confirm-Installation

# Initialize results tracking
$installationResults = @{}

# Install components
$stepNumber = 1

if (-not $SkipXAMPP) {
    $installationResults["XAMPP"] = Install-Component "XAMPP" "install-xampp.ps1" $stepNumber
    $stepNumber++
}

if (-not $SkipPostgreSQL) {
    $installationResults["PostgreSQL"] = Install-Component "PostgreSQL" "install-postgresql.ps1" $stepNumber
    $stepNumber++
}

if (-not $SkipNodeJS) {
    $installationResults["Node.js LTS"] = Install-Component "Node.js LTS" "install-nodejs-lts.ps1" $stepNumber
    $stepNumber++
}

if (-not $SkipPython) {
    $installationResults["Python 3.13"] = Install-Component "Python 3.13" "install-python313.ps1" $stepNumber
    $stepNumber++
}

if (-not $SkipGit) {
    $installationResults["Git & GitHub CLI"] = Install-Component "Git & GitHub CLI" "install-git-github.ps1" $stepNumber
    $stepNumber++
}

# Show results
Show-InstallationSummary $installationResults
Show-PostInstallationInfo

Write-Host "`n🎯 Server stack installation completed!" -ForegroundColor Green
Write-Host "Happy coding! 🚀" -ForegroundColor Cyan

# Pause if interactive
if ($Interactive) {
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}