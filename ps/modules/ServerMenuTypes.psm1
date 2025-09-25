# Server Installation Menu Types Module
# Provides specialized Firebase-style menus for server component installation

# Import the Firebase menu module
$firebaseMenuPath = Join-Path $PSScriptRoot "FirebaseMenus.psm1"
if (Test-Path $firebaseMenuPath) {
    Import-Module $firebaseMenuPath -Force
} else {
    Write-Error "FirebaseMenus module not found at: $firebaseMenuPath"
}

function Show-ServerMainMenu {
    <#
    .SYNOPSIS
    Shows the main server installation menu.
    
    .DESCRIPTION
    Displays the primary menu for server installation with options for different installation modes.
    #>
    
    $menuItems = @(
        (New-FirebaseMenuItem -Name "Install All Server Components" -Description "Install complete server stack (Node.js, PostgreSQL, Python, Git, XAMPP)" -Action "install_all" -Icon "[ALL]"),
        (New-FirebaseMenuItem -Name "Select Components" -Description "Choose specific server components to install" -Action "select_components" -Icon "[SELECT]"),
        (New-FirebaseMenuItem -Name "Verify Installation" -Description "Check which server components are already installed" -Action "verify_only" -Icon "[CHECK]"),
        (New-FirebaseMenuItem -Name "Configuration Mode" -Description "Configure installed server components" -Action "configure" -Icon "[CONFIG]"),
        (New-FirebaseMenuItem -Name "Exit" -Description "Exit the server installer" -Action "exit" -Icon "[EXIT]")
    )
    
    return Show-FirebaseMenu -MenuItems $menuItems -Title "Server Installation Suite" -ShowIcons
}

function Show-ComponentSelectionMenu {
    <#
    .SYNOPSIS
    Shows the component selection menu with multi-select functionality.
    
    .DESCRIPTION
    Displays a menu for selecting multiple server components to install.
    #>
    
    $menuItems = @(
        (New-FirebaseMenuItem -Name "Node.js LTS" -Description "JavaScript runtime environment (Critical for web development)" -Action "nodejs" -Icon "[NODE]"),
        (New-FirebaseMenuItem -Name "PostgreSQL" -Description "Advanced open-source relational database (Critical for data storage)" -Action "postgresql" -Icon "[PSQL]"),
        (New-FirebaseMenuItem -Name "Python 3.13" -Description "Python programming language and pip package manager" -Action "python" -Icon "[PY]"),
        (New-FirebaseMenuItem -Name "Git and GitHub CLI" -Description "Version control system and GitHub integration (Critical)" -Action "git" -Icon "[GIT]"),
        (New-FirebaseMenuItem -Name "XAMPP Stack" -Description "Apache, MySQL, PHP, and phpMyAdmin web development stack" -Action "xampp" -Icon "[WEB]"),
        (New-FirebaseMenuItem -Name "Complete Server Stack" -Description "All components with optimized configuration" -Action "serverstack" -Icon "[STACK]"),
        (New-FirebaseMenuItem -Name "Install Selected" -Description "Install the selected components" -Action "install" -Icon "[INSTALL]"),
        (New-FirebaseMenuItem -Name "Back to Main Menu" -Description "Return to the main menu" -Action "back" -Icon "[BACK]")
    )
    
    return Show-FirebaseMultiSelect -MenuItems $menuItems -Title "Server Component Selection" -AllowSelectAll
}

function Show-ConfigurationMenu {
    <#
    .SYNOPSIS
    Shows the configuration menu for installed components.
    
    .DESCRIPTION
    Displays options for configuring already installed server components.
    #>
    
    $menuItems = @(
        (New-FirebaseMenuItem -Name "Configure PostgreSQL" -Description "Set up database users, permissions, and sample data" -Action "config_postgresql" -Icon "[PSQL]"),
        (New-FirebaseMenuItem -Name "Configure XAMPP" -Description "Set up virtual hosts, PHP settings, and security" -Action "config_xampp" -Icon "[WEB]"),
        (New-FirebaseMenuItem -Name "Configure Node.js" -Description "Set up global packages and development environment" -Action "config_nodejs" -Icon "[NODE]"),
        (New-FirebaseMenuItem -Name "Configure Git" -Description "Set up user credentials and SSH keys" -Action "config_git" -Icon "[GIT]"),
        (New-FirebaseMenuItem -Name "Environment Variables" -Description "Configure system PATH and environment variables" -Action "config_env" -Icon "[ENV]"),
        (New-FirebaseMenuItem -Name "Back to Main Menu" -Description "Return to the main menu" -Action "back" -Icon "[BACK]")
    )
    
    return Show-FirebaseMenu -MenuItems $menuItems -Title "Server Configuration" -ShowIcons
}

function Show-VerificationMenu {
    <#
    .SYNOPSIS
    Shows the verification menu with different verification options.
    
    .DESCRIPTION
    Displays options for verifying server component installations.
    #>
    
    $menuItems = @(
        (New-FirebaseMenuItem -Name "Quick Verification" -Description "Basic check for installed components" -Action "verify_quick" -Icon "[QUICK]"),
        (New-FirebaseMenuItem -Name "Detailed Verification" -Description "Comprehensive verification with version information" -Action "verify_detailed" -Icon "[DETAIL]"),
        (New-FirebaseMenuItem -Name "Component Health Check" -Description "Test component functionality and connectivity" -Action "verify_health" -Icon "[HEALTH]"),
        (New-FirebaseMenuItem -Name "Generate Report" -Description "Create detailed installation report" -Action "verify_report" -Icon "[REPORT]"),
        (New-FirebaseMenuItem -Name "Back to Main Menu" -Description "Return to the main menu" -Action "back" -Icon "[BACK]")
    )
    
    return Show-FirebaseMenu -MenuItems $menuItems -Title "Installation Verification" -ShowIcons
}

function Show-InstallationProgressMenu {
    <#
    .SYNOPSIS
    Shows installation progress with component status.
    
    .DESCRIPTION
    Displays real-time installation progress for selected components.
    
    .PARAMETER Components
    Array of components being installed
    
    .PARAMETER CurrentComponent
    Currently installing component
    
    .PARAMETER CompletedComponents
    Array of completed components
    
    .PARAMETER FailedComponents
    Array of failed components
    #>
    param(
        [array]$Components = @(),
        [string]$CurrentComponent = "",
        [array]$CompletedComponents = @(),
        [array]$FailedComponents = @()
    )
    
    Show-FirebaseHeader -Title "Server Installation Progress" -Subtitle "Installing selected components..."
    
    Write-Host ""
    
    foreach ($component in $Components) {
        $status = "pending"
        $icon = "[WAIT]"
        $color = "DarkGray"
        
        if ($CompletedComponents -contains $component) {
            $status = "completed"
            $icon = "[OK]"
            $color = "Green"
        } elseif ($FailedComponents -contains $component) {
            $status = "failed"
            $icon = "[FAIL]"
            $color = "Red"
        } elseif ($component -eq $CurrentComponent) {
            $status = "installing"
            $icon = "[WORK]"
            $color = "Yellow"
        }
        
        Write-Host "  $icon " -NoNewline -ForegroundColor $color
        Write-Host $component -ForegroundColor White
        
        if ($status -eq "installing") {
            Write-Host "    Installing..." -ForegroundColor Yellow
        } elseif ($status -eq "completed") {
            Write-Host "    Installation completed successfully" -ForegroundColor Green
        } elseif ($status -eq "failed") {
            Write-Host "    Installation failed" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    
    # Show overall progress
    $totalComponents = $Components.Count
    $completedCount = $CompletedComponents.Count
    $failedCount = $FailedComponents.Count
    $progressPercent = if ($totalComponents -gt 0) { [math]::Round(($completedCount + $failedCount) / $totalComponents * 100) } else { 0 }
    
    Write-Host "Progress: " -NoNewline -ForegroundColor Cyan
    Write-Host "$progressPercent% " -NoNewline -ForegroundColor White
    Write-Host "($completedCount completed, $failedCount failed, $totalComponents total)" -ForegroundColor DarkGray
}

function Show-InstallationSummary {
    <#
    .SYNOPSIS
    Shows installation summary with results.
    
    .DESCRIPTION
    Displays final installation results with success/failure status.
    
    .PARAMETER CompletedComponents
    Array of successfully installed components
    
    .PARAMETER FailedComponents
    Array of failed components with error details
    
    .PARAMETER Duration
    Total installation duration
    #>
    param(
        [array]$CompletedComponents = @(),
        [array]$FailedComponents = @(),
        [string]$Duration = "0 seconds"
    )
    
    Show-FirebaseHeader -Title "Installation Complete" -Subtitle "Server installation summary"
    
    if ($CompletedComponents.Count -gt 0) {
        Write-Host "[OK] " -NoNewline -ForegroundColor Green
        Write-Host "Successfully Installed ($($CompletedComponents.Count)):" -ForegroundColor Green
        foreach ($component in $CompletedComponents) {
            Write-Host "   • $component" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($FailedComponents.Count -gt 0) {
        Write-Host "[FAIL] " -NoNewline -ForegroundColor Red
        Write-Host "Failed Installations ($($FailedComponents.Count)):" -ForegroundColor Red
        foreach ($component in $FailedComponents) {
            Write-Host "   • $($component.Name)" -ForegroundColor White
            if ($component.Error) {
                Write-Host "     Error: $($component.Error)" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }
    
    Write-Host "[TIME] " -NoNewline -ForegroundColor Cyan
    Write-Host "Total Duration: $Duration" -ForegroundColor White
    Write-Host ""
    
    # Show next steps
    if ($CompletedComponents.Count -gt 0) {
        Write-Host "[NEXT] " -NoNewline -ForegroundColor Yellow
        Write-Host "Next Steps:" -ForegroundColor Yellow
        Write-Host "   • Restart your terminal to use new PATH variables" -ForegroundColor White
        Write-Host "   • Run verification to test component functionality" -ForegroundColor White
        Write-Host "   • Configure components using the Configuration menu" -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-ComponentDetailsMenu {
    <#
    .SYNOPSIS
    Shows detailed information about a specific component.
    
    .DESCRIPTION
    Displays component details, installation options, and configuration settings.
    
    .PARAMETER ComponentKey
    The key identifier for the component
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ComponentKey
    )
    
    $componentDetails = @{
        'nodejs' = @{
            Name = "Node.js LTS"
            Description = "JavaScript runtime built on Chrome's V8 JavaScript engine"
            Version = "Latest LTS"
            Dependencies = @()
            PostInstall = @("npm install -g npm@latest", "npm install -g yarn")
            Ports = @("3000 (default dev server)")
            ConfigFiles = @("~/.npmrc", "package.json")
        }
        'postgresql' = @{
            Name = "PostgreSQL"
            Description = "Advanced open-source relational database system"
            Version = "Latest stable"
            Dependencies = @()
            PostInstall = @("Create default database", "Set up authentication")
            Ports = @("5432 (default)")
            ConfigFiles = @("postgresql.conf", "pg_hba.conf")
        }
        'python' = @{
            Name = "Python 3.13"
            Description = "High-level programming language with extensive libraries"
            Version = "3.13.x"
            Dependencies = @("pip", "setuptools")
            PostInstall = @("pip install --upgrade pip", "Install common packages")
            Ports = @("8000 (dev server)")
            ConfigFiles = @("pip.conf", "requirements.txt")
        }
        'git' = @{
            Name = "Git & GitHub CLI"
            Description = "Distributed version control system with GitHub integration"
            Version = "Latest stable"
            Dependencies = @()
            PostInstall = @("Configure user.name and user.email", "Set up SSH keys")
            Ports = @("22 (SSH)", "443 (HTTPS)")
            ConfigFiles = @("~/.gitconfig", "~/.ssh/config")
        }
        'xampp' = @{
            Name = "XAMPP Stack"
            Description = "Apache, MySQL, PHP, and phpMyAdmin web development environment"
            Version = "Latest stable"
            Dependencies = @()
            PostInstall = @("Start Apache and MySQL services", "Configure virtual hosts")
            Ports = @("80 (Apache)", "443 (SSL)", "3306 (MySQL)")
            ConfigFiles = @("httpd.conf", "php.ini", "my.ini")
        }
        'serverstack' = @{
            Name = "Complete Server Stack"
            Description = "All server components with optimized configuration"
            Version = "Bundle"
            Dependencies = @("nodejs", "postgresql", "python", "git", "xampp")
            PostInstall = @("Configure component integration", "Set up development environment")
            Ports = @("Multiple - see individual components")
            ConfigFiles = @("Various - see individual components")
        }
    }
    
    $details = $componentDetails[$ComponentKey]
    if (-not $details) {
        Write-Error "Component details not found for: $ComponentKey"
        return
    }
    
    Show-FirebaseHeader -Title $details.Name -Subtitle $details.Description
    
    Write-Host "[INFO] " -NoNewline -ForegroundColor Cyan
    Write-Host "Component Details:" -ForegroundColor Cyan
    Write-Host "   Version: " -NoNewline -ForegroundColor DarkGray
    Write-Host $details.Version -ForegroundColor White
    
    if ($details.Dependencies.Count -gt 0) {
        Write-Host "   Dependencies: " -NoNewline -ForegroundColor DarkGray
        Write-Host ($details.Dependencies -join ", ") -ForegroundColor White
    }
    
    Write-Host "   Ports: " -NoNewline -ForegroundColor DarkGray
    Write-Host ($details.Ports -join ", ") -ForegroundColor White
    Write-Host ""
    
    if ($details.PostInstall.Count -gt 0) {
        Write-Host "[SETUP] " -NoNewline -ForegroundColor Yellow
        Write-Host "Post-Installation Steps:" -ForegroundColor Yellow
        foreach ($step in $details.PostInstall) {
            Write-Host "   • $step" -ForegroundColor White
        }
        Write-Host ""
    }
    
    Write-Host "[FILES] " -NoNewline -ForegroundColor Magenta
    Write-Host "Configuration Files:" -ForegroundColor Magenta
    foreach ($file in $details.ConfigFiles) {
        Write-Host "   • $file" -ForegroundColor White
    }
    Write-Host ""
    
    $menuItems = @(
        (New-FirebaseMenuItem -Name "Install This Component" -Description "Install $($details.Name)" -Action "install" -Icon "[INSTALL]"),
        (New-FirebaseMenuItem -Name "View Installation Script" -Description "Show the installation commands" -Action "view_script" -Icon "[SCRIPT]"),
        (New-FirebaseMenuItem -Name "Back to Selection" -Description "Return to component selection" -Action "back" -Icon "[BACK]")
    )
    
    return Show-FirebaseMenu -MenuItems $menuItems -Title "Component Actions" -ShowIcons
}

# Export module functions
Export-ModuleMember -Function @(
    'Show-ServerMainMenu',
    'Show-ComponentSelectionMenu',
    'Show-ConfigurationMenu',
    'Show-VerificationMenu',
    'Show-InstallationProgressMenu',
    'Show-InstallationSummary',
    'Show-ComponentDetailsMenu'
)