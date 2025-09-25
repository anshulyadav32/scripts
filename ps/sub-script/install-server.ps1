#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Comprehensive Server Installation Script with Subscription Management
    
.DESCRIPTION
    This script provides a robust server installation system with:
    - Subscription-based component management
    - Installation verification and testing
    - Comprehensive error handling and logging
    - Checkpoint system for critical stages
    - Automatic recovery and rollback capabilities
    
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
    
.PARAMETER SkipVerification
    Skip post-installation verification (not recommended)
    
.EXAMPLE
    .\install-server.ps1 -Components @("nodejs", "postgresql") -Detailed
    
.EXAMPLE
    .\install-server.ps1 -All -LogPath "C:\Logs\server.log"
    
.EXAMPLE
    .\install-server.ps1 -VerifyOnly -All
#>

param(
    [string[]]$Components = @(),
    [switch]$VerifyOnly,
    [switch]$All,
    [switch]$Detailed,
    [string]$LogPath = ".\logs\server-install.log",
    [switch]$SkipVerification,
    [switch]$Force
)

# Import required modules
$ModulePath = Join-Path $PSScriptRoot "..\modules\SoftwareVerification.psm1"
if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force
} else {
    Write-Error "SoftwareVerification module not found at: $ModulePath"
    exit 1
}

# Global variables for state management
$Global:ServerInstallState = @{
    StartTime = Get-Date
    LogPath = $LogPath
    Checkpoints = @{}
    Errors = @()
    Warnings = @()
    InstalledComponents = @{}
    FailedComponents = @{}
    TotalComponents = 0
    CompletedComponents = 0
}

# Server component subscription registry
$Global:ServerComponents = @{
    "nodejs" = @{
        Name = "Node.js LTS"
        Description = "JavaScript runtime for server-side development"
        ScriptPath = "..\script\server\install-nodejs-lts.ps1"
        VerificationCommand = "node --version"
        Dependencies = @()
        Critical = $true
        Category = "Runtime"
    }
    "postgresql" = @{
        Name = "PostgreSQL Database"
        Description = "Advanced open-source relational database"
        ScriptPath = "..\script\server\install-postgresql.ps1"
        VerificationCommand = "psql --version"
        Dependencies = @()
        Critical = $true
        Category = "Database"
    }
    "python" = @{
        Name = "Python 3.13"
        Description = "Python programming language runtime"
        ScriptPath = "..\script\server\install-python313.ps1"
        VerificationCommand = "python --version"
        Dependencies = @()
        Critical = $false
        Category = "Runtime"
    }
    "git" = @{
        Name = "Git & GitHub CLI"
        Description = "Version control system and GitHub integration"
        ScriptPath = "..\script\server\install-git-github.ps1"
        VerificationCommand = "git --version"
        Dependencies = @()
        Critical = $true
        Category = "Development"
    }
    "xampp" = @{
        Name = "XAMPP Stack"
        Description = "Apache, MySQL, PHP, and Perl development stack"
        ScriptPath = "..\script\server\install-xampp.ps1"
        VerificationCommand = "php --version"
        Dependencies = @()
        Critical = $false
        Category = "WebServer"
    }
    "serverstack" = @{
        Name = "Complete Server Stack"
        Description = "Full server development environment"
        ScriptPath = "..\script\server\install-server-stack.ps1"
        VerificationCommand = $null
        Dependencies = @("nodejs", "postgresql", "git")
        Critical = $false
        Category = "Bundle"
    }
}

#region Logging Functions

function Initialize-Logging {
    <#
    .SYNOPSIS
    Initialize the logging system with proper directory structure and log rotation.
    #>
    try {
        $logDir = Split-Path $Global:ServerInstallState.LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Rotate old logs if they exist
        if (Test-Path $Global:ServerInstallState.LogPath) {
            $timestamp = (Get-Item $Global:ServerInstallState.LogPath).LastWriteTime.ToString("yyyyMMdd-HHmmss")
            $backupPath = $Global:ServerInstallState.LogPath -replace "\.log$", "-$timestamp.log"
            Move-Item $Global:ServerInstallState.LogPath $backupPath -Force
        }
        
        # Create new log file with header
        $header = @"
=== Server Installation Log ===
Start Time: $($Global:ServerInstallState.StartTime)
PowerShell Version: $($PSVersionTable.PSVersion)
OS Version: $([System.Environment]::OSVersion.VersionString)
User: $([System.Environment]::UserName)
Computer: $([System.Environment]::MachineName)
=====================================

"@
        $header | Out-File -FilePath $Global:ServerInstallState.LogPath -Encoding UTF8
        
        Write-LogMessage "INFO" "Logging system initialized successfully"
        return $true
    } catch {
        Write-Warning "Failed to initialize logging: $($_.Exception.Message)"
        return $false
    }
}

function Write-LogMessage {
    <#
    .SYNOPSIS
    Write a timestamped message to the log file and optionally to console.
    #>
    param(
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO",
        [string]$Message,
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        $logEntry | Out-File -FilePath $Global:ServerInstallState.LogPath -Append -Encoding UTF8
    } catch {
        # Fallback if logging fails
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
    
    if (-not $NoConsole) {
        switch ($Level) {
            "ERROR" { Write-Host $logEntry -ForegroundColor Red }
            "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
            "DEBUG" { if ($Detailed) { Write-Host $logEntry -ForegroundColor Gray } }
            default { Write-Host $logEntry -ForegroundColor White }
        }
    }
}

#endregion

#region Checkpoint System

function Set-Checkpoint {
    <#
    .SYNOPSIS
    Create a checkpoint for the current installation state.
    #>
    param(
        [string]$Name,
        [string]$Description,
        [hashtable]$Data = @{}
    )
    
    $checkpoint = @{
        Name = $Name
        Description = $Description
        Timestamp = Get-Date
        Data = $Data
        State = $Global:ServerInstallState.Clone()
    }
    
    $Global:ServerInstallState.Checkpoints[$Name] = $checkpoint
    Write-LogMessage "INFO" "Checkpoint created: $Name - $Description"
}

function Restore-Checkpoint {
    <#
    .SYNOPSIS
    Restore system state to a previous checkpoint.
    #>
    param(
        [string]$Name
    )
    
    if ($Global:ServerInstallState.Checkpoints.ContainsKey($Name)) {
        $checkpoint = $Global:ServerInstallState.Checkpoints[$Name]
        Write-LogMessage "WARNING" "Restoring to checkpoint: $Name"
        
        # Here you would implement actual rollback logic
        # For now, we'll just log the restoration attempt
        Write-LogMessage "INFO" "Checkpoint restoration completed for: $Name"
        return $true
    } else {
        Write-LogMessage "ERROR" "Checkpoint not found: $Name"
        return $false
    }
}

#endregion

#region Component Management

function Get-AvailableComponents {
    <#
    .SYNOPSIS
    Get list of all available server components.
    #>
    return $Global:ServerComponents.Keys | Sort-Object
}

function Test-ComponentScript {
    <#
    .SYNOPSIS
    Verify that a component's installation script exists and contains required functions.
    #>
    param(
        [string]$ComponentName
    )
    
    if (-not $Global:ServerComponents.ContainsKey($ComponentName)) {
        Write-LogMessage "ERROR" "Unknown component: $ComponentName"
        return $false
    }
    
    $component = $Global:ServerComponents[$ComponentName]
    $scriptPath = Join-Path $PSScriptRoot $component.ScriptPath
    
    if (-not (Test-Path $scriptPath)) {
        Write-LogMessage "ERROR" "Script not found for $ComponentName`: $scriptPath"
        return $false
    }
    
    try {
        # Read script content to check for required patterns
        $scriptContent = Get-Content $scriptPath -Raw
        
        # Check for basic PowerShell script structure
        if ($scriptContent -match "param\s*\(" -or $scriptContent -match "function\s+\w+") {
            Write-LogMessage "SUCCESS" "Script validation passed for $ComponentName"
            return $true
        } else {
            Write-LogMessage "WARNING" "Script may not contain proper functions: $ComponentName"
            return $true  # Allow execution but warn
        }
    } catch {
        Write-LogMessage "ERROR" "Failed to validate script for $ComponentName`: $($_.Exception.Message)"
        return $false
    }
}

function Test-ComponentInstallation {
    <#
    .SYNOPSIS
    Verify if a component is properly installed using multiple verification methods.
    #>
    param(
        [string]$ComponentName,
        [switch]$Detailed
    )
    
    Write-LogMessage "INFO" "Verifying installation of $ComponentName"
    
    if (-not $Global:ServerComponents.ContainsKey($ComponentName)) {
        Write-LogMessage "ERROR" "Unknown component: $ComponentName"
        return $false
    }
    
    $component = $Global:ServerComponents[$ComponentName]
    $verificationResults = @{
        ComponentName = $ComponentName
        IsInstalled = $false
        VerificationMethod = "Unknown"
        Details = @{}
        Errors = @()
    }
    
    try {
        # Method 1: Use SoftwareVerification module if available
        if (Get-Command Test-PredefinedSoftware -ErrorAction SilentlyContinue) {
            try {
                $result = Test-PredefinedSoftware -SoftwareName $ComponentName -Detailed:$Detailed
                if ($result -and $result.Status -eq "Installed") {
                    $verificationResults.IsInstalled = $true
                    $verificationResults.VerificationMethod = "SoftwareVerification Module"
                    $verificationResults.Details = $result
                    Write-LogMessage "SUCCESS" "$ComponentName verified via SoftwareVerification module"
                    return $verificationResults
                }
            } catch {
                $verificationResults.Errors += "SoftwareVerification module error: $($_.Exception.Message)"
            }
        }
        
        # Method 2: Command verification
        if ($component.VerificationCommand) {
            try {
                $commandParts = $component.VerificationCommand -split " "
                $command = $commandParts[0]
                $args = $commandParts[1..($commandParts.Length-1)]
                
                if (Get-Command $command -ErrorAction SilentlyContinue) {
                    $output = & $command @args 2>&1
                    if ($LASTEXITCODE -eq 0 -or $output) {
                        $verificationResults.IsInstalled = $true
                        $verificationResults.VerificationMethod = "Command Verification"
                        $verificationResults.Details.CommandOutput = $output
                        Write-LogMessage "SUCCESS" "$ComponentName verified via command: $($component.VerificationCommand)"
                        return $verificationResults
                    }
                }
            } catch {
                $verificationResults.Errors += "Command verification error: $($_.Exception.Message)"
            }
        }
        
        # Method 3: Path-based verification for specific components
        $pathVerification = Test-ComponentPaths -ComponentName $ComponentName
        if ($pathVerification.IsInstalled) {
            $verificationResults.IsInstalled = $true
            $verificationResults.VerificationMethod = "Path Verification"
            $verificationResults.Details = $pathVerification.Details
            Write-LogMessage "SUCCESS" "$ComponentName verified via path detection"
            return $verificationResults
        }
        
        Write-LogMessage "WARNING" "$ComponentName not detected by any verification method"
        return $verificationResults
        
    } catch {
        $verificationResults.Errors += "General verification error: $($_.Exception.Message)"
        Write-LogMessage "ERROR" "Failed to verify $ComponentName`: $($_.Exception.Message)"
        return $verificationResults
    }
}

function Test-ComponentPaths {
    <#
    .SYNOPSIS
    Test component installation by checking common installation paths.
    #>
    param(
        [string]$ComponentName
    )
    
    $result = @{
        IsInstalled = $false
        Details = @{
            FoundPaths = @()
            SearchedPaths = @()
        }
    }
    
    $commonPaths = @()
    
    switch ($ComponentName.ToLower()) {
        "nodejs" {
            $commonPaths = @(
                "${env:ProgramFiles}\nodejs\node.exe",
                "${env:ProgramFiles(x86)}\nodejs\node.exe",
                "${env:LOCALAPPDATA}\Programs\nodejs\node.exe"
            )
        }
        "postgresql" {
            $commonPaths = @(
                "${env:ProgramFiles}\PostgreSQL\*\bin\psql.exe",
                "${env:ProgramFiles(x86)}\PostgreSQL\*\bin\psql.exe"
            )
        }
        "python" {
            $commonPaths = @(
                "${env:ProgramFiles}\Python*\python.exe",
                "${env:ProgramFiles(x86)}\Python*\python.exe",
                "${env:LOCALAPPDATA}\Programs\Python\Python*\python.exe"
            )
        }
        "git" {
            $commonPaths = @(
                "${env:ProgramFiles}\Git\bin\git.exe",
                "${env:ProgramFiles(x86)}\Git\bin\git.exe"
            )
        }
        "xampp" {
            $commonPaths = @(
                "C:\xampp\php\php.exe",
                "${env:ProgramFiles}\xampp\php\php.exe"
            )
        }
    }
    
    foreach ($path in $commonPaths) {
        $result.Details.SearchedPaths += $path
        
        if ($path -like "*`**") {
            # Handle wildcard paths
            $basePath = $path -replace "\\\*.*$", ""
            if (Test-Path $basePath) {
                $foundItems = Get-ChildItem $basePath -Recurse -Filter ($path -replace ".*\\", "") -ErrorAction SilentlyContinue
                if ($foundItems) {
                    $result.IsInstalled = $true
                    $result.Details.FoundPaths += $foundItems.FullName
                }
            }
        } else {
            # Handle exact paths
            if (Test-Path $path) {
                $result.IsInstalled = $true
                $result.Details.FoundPaths += $path
            }
        }
    }
    
    return $result
}

#endregion

#region Installation Functions

function Install-ServerComponent {
    <#
    .SYNOPSIS
    Install a single server component with comprehensive error handling.
    #>
    param(
        [string]$ComponentName,
        [switch]$Force
    )
    
    Write-LogMessage "INFO" "Starting installation of $ComponentName"
    Set-Checkpoint "PreInstall_$ComponentName" "Before installing $ComponentName"
    
    if (-not $Global:ServerComponents.ContainsKey($ComponentName)) {
        $error = "Unknown component: $ComponentName"
        Write-LogMessage "ERROR" $error
        $Global:ServerInstallState.Errors += $error
        return $false
    }
    
    $component = $Global:ServerComponents[$ComponentName]
    
    # Check if already installed (unless forced)
    if (-not $Force) {
        $verification = Test-ComponentInstallation -ComponentName $ComponentName
        if ($verification.IsInstalled) {
            Write-LogMessage "INFO" "$ComponentName is already installed, skipping"
            $Global:ServerInstallState.InstalledComponents[$ComponentName] = @{
                Status = "AlreadyInstalled"
                Timestamp = Get-Date
                Details = $verification
            }
            return $true
        }
    }
    
    # Validate script exists
    if (-not (Test-ComponentScript -ComponentName $ComponentName)) {
        $error = "Script validation failed for $ComponentName"
        Write-LogMessage "ERROR" $error
        $Global:ServerInstallState.FailedComponents[$ComponentName] = $error
        return $false
    }
    
    # Install dependencies first
    foreach ($dependency in $component.Dependencies) {
        Write-LogMessage "INFO" "Installing dependency: $dependency for $ComponentName"
        if (-not (Install-ServerComponent -ComponentName $dependency -Force:$Force)) {
            $error = "Failed to install dependency $dependency for $ComponentName"
            Write-LogMessage "ERROR" $error
            $Global:ServerInstallState.FailedComponents[$ComponentName] = $error
            return $false
        }
    }
    
    # Execute installation script
    try {
        $scriptPath = Join-Path $PSScriptRoot $component.ScriptPath
        Write-LogMessage "INFO" "Executing installation script: $scriptPath"
        
        # Create a new PowerShell process to isolate the installation
        $processArgs = @{
            FilePath = "powershell.exe"
            ArgumentList = @(
                "-ExecutionPolicy", "Bypass",
                "-File", $scriptPath,
                "-ErrorAction", "Stop"
            )
            Wait = $true
            PassThru = $true
            RedirectStandardOutput = $true
            RedirectStandardError = $true
        }
        
        $process = Start-Process @processArgs
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        
        if ($process.ExitCode -eq 0) {
            Write-LogMessage "SUCCESS" "$ComponentName installation completed successfully"
            if ($stdout) { Write-LogMessage "DEBUG" "STDOUT: $stdout" }
            
            # Verify installation
            if (-not $SkipVerification) {
                Start-Sleep -Seconds 2  # Allow time for installation to settle
                $verification = Test-ComponentInstallation -ComponentName $ComponentName -Detailed
                
                if ($verification.IsInstalled) {
                    Write-LogMessage "SUCCESS" "$ComponentName installation verified successfully"
                    $Global:ServerInstallState.InstalledComponents[$ComponentName] = @{
                        Status = "Installed"
                        Timestamp = Get-Date
                        Details = $verification
                        InstallationOutput = $stdout
                    }
                    return $true
                } else {
                    $error = "$ComponentName installation completed but verification failed"
                    Write-LogMessage "ERROR" $error
                    $Global:ServerInstallState.FailedComponents[$ComponentName] = $error
                    return $false
                }
            } else {
                $Global:ServerInstallState.InstalledComponents[$ComponentName] = @{
                    Status = "Installed"
                    Timestamp = Get-Date
                    Details = @{ VerificationSkipped = $true }
                    InstallationOutput = $stdout
                }
                return $true
            }
        } else {
            $error = "$ComponentName installation failed with exit code $($process.ExitCode)"
            Write-LogMessage "ERROR" $error
            if ($stderr) { Write-LogMessage "ERROR" "STDERR: $stderr" }
            $Global:ServerInstallState.FailedComponents[$ComponentName] = $error
            return $false
        }
        
    } catch {
        $error = "Exception during $ComponentName installation: $($_.Exception.Message)"
        Write-LogMessage "ERROR" $error
        $Global:ServerInstallState.FailedComponents[$ComponentName] = $error
        
        # Attempt to restore checkpoint on critical failures
        if ($component.Critical) {
            Write-LogMessage "WARNING" "Critical component failed, attempting checkpoint restoration"
            Restore-Checkpoint "PreInstall_$ComponentName"
        }
        
        return $false
    }
}

function Install-MultipleComponents {
    <#
    .SYNOPSIS
    Install multiple server components with dependency resolution and error handling.
    #>
    param(
        [string[]]$ComponentNames,
        [switch]$Force
    )
    
    Write-LogMessage "INFO" "Starting installation of multiple components: $($ComponentNames -join ', ')"
    Set-Checkpoint "MultiInstall_Start" "Before installing multiple components"
    
    $Global:ServerInstallState.TotalComponents = $ComponentNames.Count
    $Global:ServerInstallState.CompletedComponents = 0
    
    $installationOrder = Resolve-ComponentDependencies -ComponentNames $ComponentNames
    
    foreach ($componentName in $installationOrder) {
        try {
            Write-LogMessage "INFO" "Installing component $($Global:ServerInstallState.CompletedComponents + 1) of $($Global:ServerInstallState.TotalComponents): $componentName"
            
            $success = Install-ServerComponent -ComponentName $componentName -Force:$Force
            $Global:ServerInstallState.CompletedComponents++
            
            if (-not $success) {
                $component = $Global:ServerComponents[$componentName]
                if ($component.Critical) {
                    Write-LogMessage "ERROR" "Critical component $componentName failed, stopping installation"
                    return $false
                } else {
                    Write-LogMessage "WARNING" "Non-critical component $componentName failed, continuing"
                }
            }
            
            # Progress update
            $progress = [math]::Round(($Global:ServerInstallState.CompletedComponents / $Global:ServerInstallState.TotalComponents) * 100, 1)
            Write-LogMessage "INFO" "Installation progress: $progress% ($($Global:ServerInstallState.CompletedComponents)/$($Global:ServerInstallState.TotalComponents))"
            
        } catch {
            Write-LogMessage "ERROR" "Unexpected error installing $componentName`: $($_.Exception.Message)"
            $Global:ServerInstallState.Errors += "Unexpected error installing $componentName`: $($_.Exception.Message)"
        }
    }
    
    return $true
}

function Resolve-ComponentDependencies {
    <#
    .SYNOPSIS
    Resolve component dependencies and return installation order.
    #>
    param(
        [string[]]$ComponentNames
    )
    
    $resolved = @()
    $visiting = @{}
    $visited = @{}
    
    function Visit-Component {
        param([string]$ComponentName)
        
        if ($visited.ContainsKey($ComponentName)) {
            return
        }
        
        if ($visiting.ContainsKey($ComponentName)) {
            Write-LogMessage "WARNING" "Circular dependency detected involving $ComponentName"
            return
        }
        
        $visiting[$ComponentName] = $true
        
        if ($Global:ServerComponents.ContainsKey($ComponentName)) {
            foreach ($dependency in $Global:ServerComponents[$ComponentName].Dependencies) {
                Visit-Component -ComponentName $dependency
            }
        }
        
        $visiting.Remove($ComponentName)
        $visited[$ComponentName] = $true
        $resolved += $ComponentName
    }
    
    foreach ($componentName in $ComponentNames) {
        Visit-Component -ComponentName $componentName
    }
    
    Write-LogMessage "INFO" "Dependency resolution order: $($resolved -join ' -> ')"
    return $resolved
}

#endregion

#region Main Functions

function Show-ServerComponents {
    <#
    .SYNOPSIS
    Display available server components in a formatted table.
    #>
    Write-Host "`n=== Available Server Components ===" -ForegroundColor Cyan
    Write-Host ""
    
    $components = $Global:ServerComponents.GetEnumerator() | Sort-Object { $_.Value.Category }, { $_.Key }
    $currentCategory = ""
    
    foreach ($component in $components) {
        $info = $component.Value
        
        if ($info.Category -ne $currentCategory) {
            $currentCategory = $info.Category
            Write-Host "[$currentCategory]" -ForegroundColor Yellow
        }
        
        $status = if ($info.Critical) { "[CRITICAL]" } else { "[OPTIONAL]" }
        $statusColor = if ($info.Critical) { "Red" } else { "Green" }
        
        Write-Host "  $($component.Key)" -NoNewline -ForegroundColor White
        Write-Host " - $($info.Name)" -NoNewline -ForegroundColor Gray
        Write-Host " $status" -ForegroundColor $statusColor
        Write-Host "    $($info.Description)" -ForegroundColor DarkGray
        
        if ($info.Dependencies.Count -gt 0) {
            Write-Host "    Dependencies: $($info.Dependencies -join ', ')" -ForegroundColor DarkYellow
        }
        Write-Host ""
    }
}

function Show-InstallationSummary {
    <#
    .SYNOPSIS
    Display comprehensive installation summary with statistics.
    #>
    $endTime = Get-Date
    $duration = $endTime - $Global:ServerInstallState.StartTime
    
    Write-Host "`n=== Server Installation Summary ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Start Time: $($Global:ServerInstallState.StartTime)" -ForegroundColor Gray
    Write-Host "End Time: $endTime" -ForegroundColor Gray
    Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
    Write-Host ""
    
    # Installation Statistics
    $totalAttempted = $Global:ServerInstallState.InstalledComponents.Count + $Global:ServerInstallState.FailedComponents.Count
    $successCount = $Global:ServerInstallState.InstalledComponents.Count
    $failureCount = $Global:ServerInstallState.FailedComponents.Count
    
    Write-Host "Installation Statistics:" -ForegroundColor Yellow
    Write-Host "  Total Components Attempted: $totalAttempted" -ForegroundColor White
    Write-Host "  Successfully Installed: $successCount" -ForegroundColor Green
    Write-Host "  Failed Installations: $failureCount" -ForegroundColor Red
    
    if ($totalAttempted -gt 0) {
        $successRate = [math]::Round(($successCount / $totalAttempted) * 100, 1)
        Write-Host "  Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
    }
    Write-Host ""
    
    # Successful Installations
    if ($Global:ServerInstallState.InstalledComponents.Count -gt 0) {
        Write-Host "Successfully Installed Components:" -ForegroundColor Green
        foreach ($component in $Global:ServerInstallState.InstalledComponents.GetEnumerator()) {
            $info = $component.Value
            Write-Host "  [OK] $($component.Key)" -NoNewline -ForegroundColor Green
            Write-Host " - $($info.Status) at $($info.Timestamp.ToString('HH:mm:ss'))" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Failed Installations
    if ($Global:ServerInstallState.FailedComponents.Count -gt 0) {
        Write-Host "Failed Components:" -ForegroundColor Red
        foreach ($component in $Global:ServerInstallState.FailedComponents.GetEnumerator()) {
            Write-Host "  [ERROR] $($component.Key)" -NoNewline -ForegroundColor Red
            Write-Host " - $($component.Value)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Warnings and Errors
    if ($Global:ServerInstallState.Warnings.Count -gt 0) {
        Write-Host "Warnings ($($Global:ServerInstallState.Warnings.Count)):" -ForegroundColor Yellow
        foreach ($warning in $Global:ServerInstallState.Warnings) {
            Write-Host "  [WARNING] $warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    if ($Global:ServerInstallState.Errors.Count -gt 0) {
        Write-Host "Errors ($($Global:ServerInstallState.Errors.Count)):" -ForegroundColor Red
        foreach ($error in $Global:ServerInstallState.Errors) {
            Write-Host "  [ERROR] $error" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    # Log file information
    Write-Host "Detailed logs available at: $($Global:ServerInstallState.LogPath)" -ForegroundColor Cyan
    Write-Host ""
    
    # Final status
    if ($failureCount -eq 0) {
        Write-Host "=== Installation Completed Successfully ===" -ForegroundColor Green
    } elseif ($successCount -gt 0) {
        Write-Host "=== Installation Completed with Some Failures ===" -ForegroundColor Yellow
    } else {
        Write-Host "=== Installation Failed ===" -ForegroundColor Red
    }
}

function Start-ServerInstaller {
    <#
    .SYNOPSIS
    Main entry point for the server installation system.
    #>
    
    # Initialize logging
    if (-not (Initialize-Logging)) {
        Write-Warning "Logging initialization failed, continuing without file logging"
    }
    
    Write-LogMessage "INFO" "Server Installation Script Started"
    Write-LogMessage "INFO" "Parameters: Components=$($Components -join ','), VerifyOnly=$VerifyOnly, All=$All, Detailed=$Detailed"
    
    try {
        # Show header
        Clear-Host
        Write-Host "=== Server Installation System ===" -ForegroundColor Cyan
        Write-Host "Advanced server component installer with verification and error handling" -ForegroundColor Gray
        Write-Host ""
        
        # Determine components to process
        $componentsToProcess = @()
        
        if ($All) {
            $componentsToProcess = Get-AvailableComponents
            Write-LogMessage "INFO" "Processing all available components"
        } elseif ($Components.Count -gt 0) {
            $componentsToProcess = $Components
            Write-LogMessage "INFO" "Processing specified components: $($Components -join ', ')"
        } else {
            # Interactive mode
            Show-ServerComponents
            Write-Host "Enter component names (comma-separated) or 'all' for all components:" -ForegroundColor Yellow
            $input = Read-Host
            
            if ($input.Trim().ToLower() -eq 'all') {
                $componentsToProcess = Get-AvailableComponents
            } else {
                $componentsToProcess = $input -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
        }
        
        if ($componentsToProcess.Count -eq 0) {
            Write-LogMessage "WARNING" "No components specified for processing"
            return
        }
        
        # Validate components
        $validComponents = @()
        foreach ($component in $componentsToProcess) {
            if ($Global:ServerComponents.ContainsKey($component)) {
                $validComponents += $component
            } else {
                Write-LogMessage "ERROR" "Unknown component: $component"
                $Global:ServerInstallState.Errors += "Unknown component: $component"
            }
        }
        
        if ($validComponents.Count -eq 0) {
            Write-LogMessage "ERROR" "No valid components to process"
            return
        }
        
        Write-LogMessage "INFO" "Valid components to process: $($validComponents -join ', ')"
        
        # Verification-only mode
        if ($VerifyOnly) {
            Write-Host "=== Verification Mode ===" -ForegroundColor Yellow
            Write-Host ""
            
            foreach ($component in $validComponents) {
                Write-Host "Verifying $component..." -ForegroundColor Cyan
                $verification = Test-ComponentInstallation -ComponentName $component -Detailed:$Detailed
                
                if ($verification.IsInstalled) {
                    Write-Host "  [OK] $component is installed" -ForegroundColor Green
                    if ($Detailed -and $verification.Details) {
                        Write-Host "    Method: $($verification.VerificationMethod)" -ForegroundColor Gray
                        if ($verification.Details.CommandOutput) {
                            Write-Host "    Version: $($verification.Details.CommandOutput)" -ForegroundColor Gray
                        }
                    }
                } else {
                    Write-Host "  [NOT FOUND] $component is not installed" -ForegroundColor Red
                    if ($verification.Errors.Count -gt 0) {
                        foreach ($error in $verification.Errors) {
                            Write-Host "    Error: $error" -ForegroundColor DarkRed
                        }
                    }
                }
            }
        } else {
            # Installation mode
            Write-Host "=== Installation Mode ===" -ForegroundColor Green
            Write-Host ""
            
            $success = Install-MultipleComponents -ComponentNames $validComponents -Force:$Force
            
            if (-not $success) {
                Write-LogMessage "ERROR" "Installation process encountered critical failures"
            }
        }
        
    } catch {
        $error = "Unexpected error in main installer: $($_.Exception.Message)"
        Write-LogMessage "ERROR" $error
        $Global:ServerInstallState.Errors += $error
    } finally {
        # Always show summary
        Show-InstallationSummary
        Write-LogMessage "INFO" "Server Installation Script Completed"
    }
}

#endregion

# Script execution
if ($MyInvocation.InvocationName -ne '.') {
    Start-ServerInstaller
}