#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Firebase CLI-Style Server Installation Script with Interactive Menus
    
.DESCRIPTION
    This script provides a Firebase CLI-style interactive server installation system with:
    - Firebase-style interactive menus with arrow key navigation
    - Multi-select component selection with checkboxes
    - Real-time installation progress display
    - Subscription-based component management
    - Installation verification and testing
    - Comprehensive error handling and logging
    - Checkpoint system for critical stages
    
.PARAMETER Components
    Array of server components to install (e.g., "nodejs", "postgresql", "git", "python")
    
.PARAMETER VerifyOnly
    Only verify existing installations without installing new components
    
.PARAMETER All
    Install all available server components
    
.PARAMETER Detailed
    Show detailed installation and verification information
    
.PARAMETER LogPath
    Custom path for installation logs (default: .\logs\server-install.log)
    
.PARAMETER Interactive
    Force interactive mode even when parameters are provided
    
.PARAMETER Silent
    Run in silent mode without interactive menus (use parameters only)
    
.EXAMPLE
    .\install-server-firebase.ps1
    # Launches interactive Firebase-style menu
    
.EXAMPLE
    .\install-server-firebase.ps1 -Components @("nodejs", "postgresql") -Detailed
    # Direct installation with parameters
    
.EXAMPLE
    .\install-server-firebase.ps1 -Interactive
    # Force interactive mode
#>

param(
    [string[]]$Components = @(),
    [switch]$VerifyOnly,
    [switch]$All,
    [switch]$Detailed,
    [string]$LogPath = ".\logs\server-install.log",
    [switch]$Interactive,
    [switch]$Silent
)

# Import required modules
$modulePath = Join-Path $PSScriptRoot "..\modules"
$firebaseMenuPath = Join-Path $modulePath "FirebaseMenus.psm1"
$serverMenuPath = Join-Path $modulePath "ServerMenuTypes.psm1"
$softwareVerificationPath = Join-Path $modulePath "SoftwareVerification.psm1"

# Import modules with error handling
try {
    if (Test-Path $firebaseMenuPath) {
        Import-Module $firebaseMenuPath -Force
        Write-Verbose "Firebase menu module loaded successfully"
    } else {
        throw "Firebase menu module not found at: $firebaseMenuPath"
    }
    
    if (Test-Path $serverMenuPath) {
        Import-Module $serverMenuPath -Force
        Write-Verbose "Server menu types module loaded successfully"
    } else {
        throw "Server menu types module not found at: $serverMenuPath"
    }
    
    if (Test-Path $softwareVerificationPath) {
        Import-Module $softwareVerificationPath -Force
        Write-Verbose "Software verification module loaded successfully"
    } else {
        Write-Warning "Software verification module not found. Using basic verification."
    }
} catch {
    Write-Error "Failed to load required modules: $_"
    exit 1
}

# Global variables
$script:LogFile = $LogPath
$script:StartTime = Get-Date
$script:InstallationResults = @{}
$script:Checkpoints = @{}

# Server Component Registry with Firebase-style metadata
$script:ServerRegistry = @{
    'nodejs' = @{
        Name = "Node.js LTS"
        Description = "JavaScript runtime environment"
        Category = "Runtime"
        Critical = $true
        Dependencies = @()
        InstallScript = "install-nodejs-lts.ps1"
        VerificationCommand = "node --version"
        Icon = "[NODE]"
    }
    'postgresql' = @{
        Name = "PostgreSQL"
        Description = "Advanced relational database"
        Category = "Database"
        Critical = $true
        Dependencies = @()
        InstallScript = "install-postgresql.ps1"
        VerificationCommand = "psql --version"
        Icon = "[PSQL]"
    }
    'python' = @{
        Name = "Python 3.13"
        Description = "Python programming language"
        Category = "Runtime"
        Critical = $false
        Dependencies = @()
        InstallScript = "install-python313.ps1"
        VerificationCommand = "python --version"
        Icon = "[PY]"
    }
    'git' = @{
        Name = "Git & GitHub CLI"
        Description = "Version control system"
        Category = "Development"
        Critical = $true
        Dependencies = @()
        InstallScript = "install-git-github.ps1"
        VerificationCommand = "git --version"
        Icon = "[GIT]"
    }
    'xampp' = @{
        Name = "XAMPP Stack"
        Description = "Web development stack"
        Category = "Web Server"
        Critical = $false
        Dependencies = @()
        InstallScript = "install-xampp.ps1"
        VerificationCommand = "php --version"
        Icon = "[WEB]"
    }
    'serverstack' = @{
        Name = "Complete Server Stack"
        Description = "All components bundle"
        Category = "Bundle"
        Critical = $false
        Dependencies = @("nodejs", "postgresql", "python", "git", "xampp")
        InstallScript = "install-server-stack.ps1"
        VerificationCommand = $null
        Icon = "🏗️"
    }
}

function Initialize-ServerInstaller {
    <#
    .SYNOPSIS
    Initializes the server installer with logging and environment checks.
    #>
    
    # Create logs directory
    $logDir = Split-Path $script:LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Initialize logging
    $logHeader = @"
========================================
Server Installation Session Started
========================================
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
User: $env:USERNAME
Computer: $env:COMPUTERNAME
PowerShell Version: $($PSVersionTable.PSVersion)
OS: $((Get-CimInstance Win32_OperatingSystem).Caption)
========================================

"@
    
    $logHeader | Out-File -FilePath $script:LogFile -Encoding UTF8
    
    Write-Verbose "Server installer initialized successfully"
    Write-Verbose "Log file: $script:LogFile"
}

function Write-InstallLog {
    <#
    .SYNOPSIS
    Writes messages to both console and log file.
    #>
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    $logEntry | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
    
    # Write to console based on level
    switch ($Level) {
        'Info' { Write-Host $Message -ForegroundColor White }
        'Warning' { Write-Host $Message -ForegroundColor Yellow }
        'Error' { Write-Host $Message -ForegroundColor Red }
        'Success' { Write-Host $Message -ForegroundColor Green }
        'Debug' { Write-Verbose $Message }
    }
}

function Start-InteractiveMode {
    <#
    .SYNOPSIS
    Starts the Firebase-style interactive menu system.
    #>
    
    Write-InstallLog "Starting interactive mode" -Level 'Info'
    
    do {
        $mainChoice = Show-ServerMainMenu
        
        switch ($mainChoice.Action) {
            'install_all' {
                Write-InstallLog "User selected: Install All Server Components" -Level 'Info'
                $allComponents = $script:ServerRegistry.Keys | Where-Object { $_ -ne 'serverstack' }
                Start-ComponentInstallation -ComponentKeys $allComponents -ShowProgress $true
            }
            'select_components' {
                Write-InstallLog "User selected: Select Components" -Level 'Info'
                $selectionResult = Show-ComponentSelectionMenu
                
                if ($selectionResult.Action -eq 'install' -and $selectionResult.SelectedItems.Count -gt 0) {
                    Write-InstallLog "User selected components: $($selectionResult.SelectedItems -join ', ')" -Level 'Info'
                    Start-ComponentInstallation -ComponentKeys $selectionResult.SelectedItems -ShowProgress $true
                } elseif ($selectionResult.Action -eq 'back') {
                    continue
                }
            }
            'verify_only' {
                Write-InstallLog "User selected: Verify Installation" -Level 'Info'
                $verificationResult = Show-VerificationMenu
                
                switch ($verificationResult.Action) {
                    'verify_quick' { Start-ComponentVerification -Detailed $false }
                    'verify_detailed' { Start-ComponentVerification -Detailed $true }
                    'verify_health' { Start-HealthCheck }
                    'verify_report' { Generate-InstallationReport }
                    'back' { continue }
                }
            }
            'configure' {
                Write-InstallLog "User selected: Configuration Mode" -Level 'Info'
                $configResult = Show-ConfigurationMenu
                
                switch ($configResult.Action) {
                    'config_postgresql' { Start-PostgreSQLConfiguration }
                    'config_xampp' { Start-XAMPPConfiguration }
                    'config_nodejs' { Start-NodeJSConfiguration }
                    'config_git' { Start-GitConfiguration }
                    'config_env' { Start-EnvironmentConfiguration }
                    'back' { continue }
                }
            }
            'exit' {
                Write-InstallLog "User selected: Exit" -Level 'Info'
                Show-FirebaseHeader -Title "Thank You!" -Subtitle "Server installation session completed"
                Write-Host "Session log saved to: " -NoNewline -ForegroundColor DarkGray
                Write-Host $script:LogFile -ForegroundColor Cyan
                return
            }
            'cancel' {
                Write-InstallLog "User cancelled operation" -Level 'Warning'
                return
            }
        }
    } while ($true)
}

function Start-ComponentInstallation {
    <#
    .SYNOPSIS
    Starts the installation process for selected components with Firebase-style progress.
    #>
    param(
        [string[]]$ComponentKeys,
        [bool]$ShowProgress = $true
    )
    
    if ($ComponentKeys.Count -eq 0) {
        Write-InstallLog "No components selected for installation" -Level 'Warning'
        return
    }
    
    Write-InstallLog "Starting installation for components: $($ComponentKeys -join ', ')" -Level 'Info'
    
    $completedComponents = @()
    $failedComponents = @()
    $installStartTime = Get-Date
    
    foreach ($componentKey in $ComponentKeys) {
        if (-not $script:ServerRegistry.ContainsKey($componentKey)) {
            Write-InstallLog "Unknown component: $componentKey" -Level 'Error'
            $failedComponents += @{ Name = $componentKey; Error = "Component not found in registry" }
            continue
        }
        
        $component = $script:ServerRegistry[$componentKey]
        
        if ($ShowProgress) {
            Show-InstallationProgressMenu -Components $ComponentKeys -CurrentComponent $componentKey -CompletedComponents $completedComponents -FailedComponents ($failedComponents | ForEach-Object { $_.Name })
        }
        
        Write-InstallLog "Installing $($component.Name)..." -Level 'Info'
        
        try {
            # Check if component has dependencies
            if ($component.Dependencies.Count -gt 0) {
                Write-InstallLog "Checking dependencies for $($component.Name): $($component.Dependencies -join ', ')" -Level 'Info'
                foreach ($dependency in $component.Dependencies) {
                    if ($completedComponents -notcontains $dependency -and $ComponentKeys -notcontains $dependency) {
                        Write-InstallLog "Adding dependency $dependency to installation queue" -Level 'Info'
                        $ComponentKeys += $dependency
                    }
                }
            }
            
            # Install the component
            $installResult = Install-ServerComponent -ComponentKey $componentKey
            
            if ($installResult.Success) {
                $completedComponents += $componentKey
                Write-InstallLog "$($component.Name) installed successfully" -Level 'Success'
                
                # Post-installation verification
                if (-not $SkipVerification) {
                    $verifyResult = Test-ComponentInstallation -ComponentKey $componentKey
                    if (-not $verifyResult.IsInstalled) {
                        Write-InstallLog "Post-installation verification failed for $($component.Name)" -Level 'Warning'
                    }
                }
            } else {
                $failedComponents += @{ Name = $componentKey; Error = $installResult.Error }
                Write-InstallLog "Failed to install $($component.Name): $($installResult.Error)" -Level 'Error'
            }
        } catch {
            $failedComponents += @{ Name = $componentKey; Error = $_.Exception.Message }
            Write-InstallLog "Exception during installation of $($component.Name): $($_.Exception.Message)" -Level 'Error'
        }
        
        Start-Sleep -Milliseconds 500  # Brief pause for visual feedback
    }
    
    $installEndTime = Get-Date
    $duration = $installEndTime - $installStartTime
    $durationString = "{0:mm}m {0:ss}s" -f $duration
    
    # Show final summary
    Show-InstallationSummary -CompletedComponents $completedComponents -FailedComponents $failedComponents -Duration $durationString
    
    Write-InstallLog "Installation completed. Duration: $durationString" -Level 'Info'
    Write-InstallLog "Completed: $($completedComponents.Count), Failed: $($failedComponents.Count)" -Level 'Info'
}

function Install-ServerComponent {
    <#
    .SYNOPSIS
    Installs a single server component.
    #>
    param(
        [string]$ComponentKey
    )
    
    $component = $script:ServerRegistry[$ComponentKey]
    $scriptPath = Join-Path $PSScriptRoot "..\script\server\$($component.InstallScript)"
    
    Write-InstallLog "Looking for installation script: $scriptPath" -Level 'Debug'
    
    if (-not (Test-Path $scriptPath)) {
        return @{ Success = $false; Error = "Installation script not found: $($component.InstallScript)" }
    }
    
    try {
        # Execute installation script in a separate PowerShell process
        $processArgs = @{
            FilePath = "powershell.exe"
            ArgumentList = @("-ExecutionPolicy", "Bypass", "-File", $scriptPath)
            Wait = $true
            PassThru = $true
            NoNewWindow = $true
        }
        
        $process = Start-Process @processArgs
        
        if ($process.ExitCode -eq 0) {
            return @{ Success = $true; Error = $null }
        } else {
            return @{ Success = $false; Error = "Installation script exited with code: $($process.ExitCode)" }
        }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Test-ComponentInstallation {
    <#
    .SYNOPSIS
    Tests if a component is properly installed.
    #>
    param(
        [string]$ComponentKey
    )
    
    $component = $script:ServerRegistry[$ComponentKey]
    
    # Use SoftwareVerification module if available
    if (Get-Command Test-SoftwareInstallation -ErrorAction SilentlyContinue) {
        try {
            $result = Test-SoftwareInstallation -SoftwareName $ComponentKey
            return $result
        } catch {
            Write-InstallLog "SoftwareVerification failed for $ComponentKey, using fallback" -Level 'Debug'
        }
    }
    
    # Fallback verification
    if ($component.VerificationCommand) {
        try {
            $output = Invoke-Expression $component.VerificationCommand 2>$null
            return @{
                IsInstalled = $true
                Version = $output
                Status = "Verified"
                ErrorMessage = $null
            }
        } catch {
            return @{
                IsInstalled = $false
                Version = $null
                Status = "Not Found"
                ErrorMessage = $_.Exception.Message
            }
        }
    }
    
    return @{
        IsInstalled = $false
        Version = $null
        Status = "Cannot Verify"
        ErrorMessage = "No verification method available"
    }
}

function Start-ComponentVerification {
    <#
    .SYNOPSIS
    Starts component verification with Firebase-style display.
    #>
    param(
        [bool]$Detailed = $false
    )
    
    Show-FirebaseHeader -Title "Installation Verification" -Subtitle "Checking installed server components..."
    
    $verificationResults = @{}
    $totalComponents = $script:ServerRegistry.Keys.Count
    $currentIndex = 0
    
    foreach ($componentKey in $script:ServerRegistry.Keys) {
        $currentIndex++
        $component = $script:ServerRegistry[$componentKey]
        
        Show-FirebaseProgress -Message "Verifying $($component.Name)..." -Step $currentIndex -TotalSteps $totalComponents -Status 'info'
        
        $result = Test-ComponentInstallation -ComponentKey $componentKey
        $verificationResults[$componentKey] = $result
        
        if ($result.IsInstalled) {
            $status = if ($Detailed -and $result.Version) { "$($result.Version)" } else { "Installed" }
            Show-FirebaseProgress -Message "$($component.Name): $status" -Status 'success'
        } else {
            Show-FirebaseProgress -Message "$($component.Name): Not Found" -Status 'error'
        }
        
        Write-InstallLog "Verification - $($component.Name): $($result.Status)" -Level 'Info'
    }
    
    # Show summary
    $installedCount = ($verificationResults.Values | Where-Object { $_.IsInstalled }).Count
    $totalCount = $verificationResults.Count
    
    Write-Host ""
    Write-Host "📊 " -NoNewline -ForegroundColor Cyan
    Write-Host "Verification Summary:" -ForegroundColor Cyan
    Write-Host "   Installed: " -NoNewline -ForegroundColor DarkGray
    Write-Host "$installedCount/$totalCount components" -ForegroundColor White
    
    if ($installedCount -eq $totalCount) {
        Write-Host "   Status: " -NoNewline -ForegroundColor DarkGray
        Write-Host "All components verified ✅" -ForegroundColor Green
    } else {
        Write-Host "   Status: " -NoNewline -ForegroundColor DarkGray
        Write-Host "Some components missing ⚠️" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-HealthCheck {
    <#
    .SYNOPSIS
    Performs health checks on installed components.
    #>
    
    Show-FirebaseHeader -Title "Component Health Check" -Subtitle "Testing component functionality..."
    
    Write-Host "🏥 " -NoNewline -ForegroundColor Green
    Write-Host "Health check functionality coming soon!" -ForegroundColor White
    Write-Host "   This will test:" -ForegroundColor DarkGray
    Write-Host "   • Database connectivity" -ForegroundColor DarkGray
    Write-Host "   • Web server response" -ForegroundColor DarkGray
    Write-Host "   • Package manager functionality" -ForegroundColor DarkGray
    Write-Host "   • Development tool integration" -ForegroundColor DarkGray
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Generate-InstallationReport {
    <#
    .SYNOPSIS
    Generates a detailed installation report.
    #>
    
    Show-FirebaseHeader -Title "Installation Report" -Subtitle "Generating comprehensive system report..."
    
    Write-Host "📊 " -NoNewline -ForegroundColor Cyan
    Write-Host "Report generation functionality coming soon!" -ForegroundColor White
    Write-Host "   Report will include:" -ForegroundColor DarkGray
    Write-Host "   • Component installation status" -ForegroundColor DarkGray
    Write-Host "   • Version information" -ForegroundColor DarkGray
    Write-Host "   • Configuration details" -ForegroundColor DarkGray
    Write-Host "   • Performance metrics" -ForegroundColor DarkGray
    Write-Host "   • Recommendations" -ForegroundColor DarkGray
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Configuration functions (stubs for future implementation)
function Start-PostgreSQLConfiguration { 
    Show-FirebaseHeader -Title "PostgreSQL Configuration" -Subtitle "Database configuration coming soon..."
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-XAMPPConfiguration { 
    Show-FirebaseHeader -Title "XAMPP Configuration" -Subtitle "Web server configuration coming soon..."
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-NodeJSConfiguration { 
    Show-FirebaseHeader -Title "Node.js Configuration" -Subtitle "Runtime configuration coming soon..."
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-GitConfiguration { 
    Show-FirebaseHeader -Title "Git Configuration" -Subtitle "Version control configuration coming soon..."
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-EnvironmentConfiguration { 
    Show-FirebaseHeader -Title "Environment Configuration" -Subtitle "System environment configuration coming soon..."
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main execution logic
function Main {
    try {
        Initialize-ServerInstaller
        
        # Determine execution mode
        $hasParameters = $Components.Count -gt 0 -or $All -or $VerifyOnly
        $useInteractiveMode = $Interactive -or (-not $hasParameters -and -not $Silent)
        
        if ($useInteractiveMode) {
            Write-InstallLog "Starting Firebase-style interactive mode" -Level 'Info'
            Start-InteractiveMode
        } else {
            Write-InstallLog "Starting parameter-driven mode" -Level 'Info'
            
            # Handle parameter-driven execution
            if ($VerifyOnly) {
                Start-ComponentVerification -Detailed $Detailed
            } elseif ($All) {
                $allComponents = $script:ServerRegistry.Keys | Where-Object { $_ -ne 'serverstack' }
                Start-ComponentInstallation -ComponentKeys $allComponents -ShowProgress (-not $Silent)
            } elseif ($Components.Count -gt 0) {
                Start-ComponentInstallation -ComponentKeys $Components -ShowProgress (-not $Silent)
            } else {
                Write-InstallLog "No valid parameters provided. Use -Interactive to launch menu system." -Level 'Warning'
            }
        }
        
        # Final log entry
        $endTime = Get-Date
        $totalDuration = $endTime - $script:StartTime
        Write-InstallLog "Server installation session completed. Total duration: $($totalDuration.ToString('mm\:ss'))" -Level 'Info'
        
    } catch {
        Write-InstallLog "Fatal error in server installer: $($_.Exception.Message)" -Level 'Error'
        Write-InstallLog "Stack trace: $($_.ScriptStackTrace)" -Level 'Error'
        exit 1
    }
}

# Execute main function
Main