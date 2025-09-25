# Interactive Package Manager Installer - Firebase CLI Style
# This script provides a Firebase-like interactive menu for package manager installation

function Show-FirebaseStyleMenu {
    <#
    .SYNOPSIS
    Displays a Firebase CLI-style interactive main menu.
    
    .DESCRIPTION
    Shows a visual menu with arrow key navigation similar to Firebase CLI.
    #>
    param(
        [int]$SelectedIndex = 0
    )
    
    $menuItems = @(
        @{ Name = "Install All"; Description = "Install all three package managers (Chocolatey, Scoop, Winget)"; Icon = "[ALL]" },
        @{ Name = "Select Package Managers"; Description = "Choose which package managers to install"; Icon = "[SELECT]" },
        @{ Name = "Exit"; Description = "Exit the installer"; Icon = "[EXIT]" }
    )
    
    Clear-Host
    Write-Host ""
    Write-Host "     [FIRE] " -NoNewline -ForegroundColor Red
    Write-Host "Windows Package Manager Installer" -ForegroundColor White
    Write-Host ""
    Write-Host "? " -NoNewline -ForegroundColor Green
    Write-Host "What would you like to do? " -NoNewline -ForegroundColor White
    Write-Host "(Use arrow keys)" -ForegroundColor DarkGray
    Write-Host ""
    
    for ($i = 0; $i -lt $menuItems.Count; $i++) {
        $item = $menuItems[$i]
        
        if ($i -eq $SelectedIndex) {
            # Selected item - Firebase style with arrow and highlighting
            Write-Host "> " -NoNewline -ForegroundColor Cyan
            Write-Host "$($item.Icon) $($item.Name)" -ForegroundColor Cyan
            Write-Host "  $($item.Description)" -ForegroundColor DarkGray
        } else {
            # Unselected item
            Write-Host "  " -NoNewline
            Write-Host "$($item.Icon) $($item.Name)" -ForegroundColor White
            Write-Host "  $($item.Description)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
    
    Write-Host ""
    Write-Host "Press " -NoNewline -ForegroundColor DarkGray
    Write-Host "Up/Down" -NoNewline -ForegroundColor Yellow
    Write-Host " to navigate, " -NoNewline -ForegroundColor DarkGray
    Write-Host "Enter" -NoNewline -ForegroundColor Yellow
    Write-Host " to select, " -NoNewline -ForegroundColor DarkGray
    Write-Host "Ctrl+C" -NoNewline -ForegroundColor Yellow
    Write-Host " to exit" -ForegroundColor DarkGray
}

function Get-FirebaseStyleChoice {
    <#
    .SYNOPSIS
    Gets user selection using Firebase CLI-style arrow key navigation.
    
    .DESCRIPTION
    Provides interactive menu navigation with arrow keys, similar to Firebase CLI.
    #>
    $selectedIndex = 0
    $maxIndex = 2  # 0-2 for 3 menu items
    
    do {
        Show-FirebaseStyleMenu -SelectedIndex $selectedIndex
        
        # Get key press
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $selectedIndex = if ($selectedIndex -eq 0) { $maxIndex } else { $selectedIndex - 1 }
            }
            40 { # Down arrow
                $selectedIndex = if ($selectedIndex -eq $maxIndex) { 0 } else { $selectedIndex + 1 }
            }
            13 { # Enter
                return $selectedIndex + 1  # Return 1-3 instead of 0-2
            }
            3 { # Ctrl+C
                Write-Host "`n`nOperation cancelled by user." -ForegroundColor Yellow
                exit 0
            }
        }
    } while ($true)
}

function Show-PackageSelectionMenu {
    <#
    .SYNOPSIS
    Displays a Firebase CLI-style submenu for selecting individual package managers.
    
    .DESCRIPTION
    Shows a visual submenu with checkboxes for selecting multiple package managers.
    #>
    param(
        [int]$SelectedIndex = 0,
        [array]$SelectedPackages = @()
    )
    
    $menuItems = @(
        @{ Name = "Chocolatey"; Description = "The Package Manager for Windows - Great for desktop apps & dev tools"; Icon = "[CHOCO]"; Key = "choco" },
        @{ Name = "Scoop"; Description = "Command-line installer - Focuses on portable apps & dev tools"; Icon = "[SCOOP]"; Key = "scoop" },
        @{ Name = "Winget"; Description = "Microsoft's official package manager - Built into Windows 10/11"; Icon = "[WINGET]"; Key = "winget" },
        @{ Name = "Install Selected"; Description = "Install the selected package managers"; Icon = "[INSTALL]"; Key = "install" },
        @{ Name = "Back to Main Menu"; Description = "Return to the main menu"; Icon = "[BACK]"; Key = "back" }
    )
    
    Clear-Host
    Write-Host ""
    Write-Host "     [FIRE] " -NoNewline -ForegroundColor Red
    Write-Host "Select Package Managers" -ForegroundColor White
    Write-Host ""
    Write-Host "? " -NoNewline -ForegroundColor Green
    Write-Host "Which package managers would you like to install? " -NoNewline -ForegroundColor White
    Write-Host "(Use arrow keys, Space to toggle)" -ForegroundColor DarkGray
    Write-Host ""
    
    for ($i = 0; $i -lt $menuItems.Count; $i++) {
        $item = $menuItems[$i]
        $isSelected = $i -eq $SelectedIndex
        $isChecked = $SelectedPackages -contains $item.Key
        
        # Show selection indicator
        if ($isSelected) {
            Write-Host "> " -NoNewline -ForegroundColor Cyan
        } else {
            Write-Host "  " -NoNewline
        }
        
        # Show checkbox for package managers (first 3 items)
        if ($i -lt 3) {
            if ($isChecked) {
                Write-Host "[X] " -NoNewline -ForegroundColor Green
            } else {
                Write-Host "[ ] " -NoNewline -ForegroundColor DarkGray
            }
        }
        
        # Show item name and description
        if ($isSelected) {
            Write-Host "$($item.Icon) $($item.Name)" -ForegroundColor Cyan
            Write-Host "    $($item.Description)" -ForegroundColor DarkGray
        } else {
            Write-Host "$($item.Icon) $($item.Name)" -ForegroundColor White
            Write-Host "    $($item.Description)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
    
    Write-Host ""
    if ($SelectedPackages.Count -gt 0) {
        Write-Host "Selected: " -NoNewline -ForegroundColor Green
        Write-Host ($SelectedPackages -join ", ") -ForegroundColor Cyan
        Write-Host ""
    }
    Write-Host "Press " -NoNewline -ForegroundColor DarkGray
    Write-Host "Up/Down" -NoNewline -ForegroundColor Yellow
    Write-Host " to navigate, " -NoNewline -ForegroundColor DarkGray
    Write-Host "Space" -NoNewline -ForegroundColor Yellow
    Write-Host " to toggle, " -NoNewline -ForegroundColor DarkGray
    Write-Host "Enter" -NoNewline -ForegroundColor Yellow
    Write-Host " to select, " -NoNewline -ForegroundColor DarkGray
    Write-Host "Ctrl+C" -NoNewline -ForegroundColor Yellow
    Write-Host " to exit" -ForegroundColor DarkGray
}

function Get-PackageSelectionChoice {
    <#
    .SYNOPSIS
    Gets user selection for package managers with checkbox functionality.
    
    .DESCRIPTION
    Provides interactive menu navigation with checkboxes for multiple selection.
    #>
    $selectedIndex = 0
    $maxIndex = 4  # 0-4 for 5 menu items
    $selectedPackages = @()
    
    do {
        Show-PackageSelectionMenu -SelectedIndex $selectedIndex -SelectedPackages $selectedPackages
        
        # Get key press
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $selectedIndex = if ($selectedIndex -eq 0) { $maxIndex } else { $selectedIndex - 1 }
            }
            40 { # Down arrow
                $selectedIndex = if ($selectedIndex -eq $maxIndex) { 0 } else { $selectedIndex + 1 }
            }
            32 { # Space bar - toggle selection for package managers (first 3 items)
                if ($selectedIndex -lt 3) {
                    $packageKeys = @("choco", "scoop", "winget")
                    $packageKey = $packageKeys[$selectedIndex]
                    
                    if ($selectedPackages -contains $packageKey) {
                        $selectedPackages = $selectedPackages | Where-Object { $_ -ne $packageKey }
                    } else {
                        $selectedPackages += $packageKey
                    }
                }
            }
            13 { # Enter
                if ($selectedIndex -eq 3) { # Install Selected
                    return @{ Action = "install"; Packages = $selectedPackages }
                } elseif ($selectedIndex -eq 4) { # Back to Main Menu
                    return @{ Action = "back"; Packages = @() }
                } elseif ($selectedIndex -lt 3) { # Toggle package selection
                    $packageKeys = @("choco", "scoop", "winget")
                    $packageKey = $packageKeys[$selectedIndex]
                    
                    if ($selectedPackages -contains $packageKey) {
                        $selectedPackages = $selectedPackages | Where-Object { $_ -ne $packageKey }
                    } else {
                        $selectedPackages += $packageKey
                    }
                }
            }
            3 { # Ctrl+C
                Write-Host "`n`nOperation cancelled by user." -ForegroundColor Yellow
                exit 0
            }
        }
    } while ($true)
}

function Show-InstallationSummary {
    <#
    .SYNOPSIS
    Displays a detailed summary of installation results.
    
    .DESCRIPTION
    Shows which package managers were successfully installed and which failed.
    #>
    param(
        [hashtable]$Results
    )
    
    Write-Host ""
    Write-Host "     [FIRE] " -NoNewline -ForegroundColor Red
    Write-Host "Installation Summary" -ForegroundColor White
    Write-Host ""
    
    $successCount = 0
    $failCount = 0
    
    foreach ($packageManager in $Results.Keys) {
        $status = $Results[$packageManager]
        if ($status) {
            Write-Host "[OK] " -NoNewline -ForegroundColor Green
            Write-Host "$packageManager " -NoNewline -ForegroundColor White
            Write-Host "- Successfully installed" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "[ERROR] " -NoNewline -ForegroundColor Red
            Write-Host "$packageManager " -NoNewline -ForegroundColor White
            Write-Host "- Installation failed or not available" -ForegroundColor Red
            $failCount++
        }
    }
    
    Write-Host ""
    Write-Host "[INFO] " -NoNewline -ForegroundColor Blue
    Write-Host "Summary: " -NoNewline -ForegroundColor White
    Write-Host "$successCount successful" -NoNewline -ForegroundColor Green
    if ($failCount -gt 0) {
        Write-Host ", $failCount failed" -NoNewline -ForegroundColor Red
    }
    Write-Host " installations" -ForegroundColor White
    
    if ($successCount -gt 0) {
        Write-Host ""
        Write-Host "[STAR] " -NoNewline -ForegroundColor Yellow
        Write-Host "Next Steps:" -ForegroundColor White
        Write-Host "  • Restart your terminal to use the new package manager(s)" -ForegroundColor Gray
        Write-Host "  • Test installation with commands like:" -ForegroundColor Gray
        
        foreach ($packageManager in $Results.Keys) {
            if ($Results[$packageManager]) {
                switch ($packageManager) {
                    "Chocolatey" { Write-Host "    - choco --version" -ForegroundColor DarkGray }
                    "Scoop" { Write-Host "    - scoop --version" -ForegroundColor DarkGray }
                    "WinGet" { Write-Host "    - winget --version" -ForegroundColor DarkGray }
                }
            }
        }
    }
    
    Write-Host ""
}

function Install-AllPackageManagers {
    <#
    .SYNOPSIS
    Installs all available package managers (Chocolatey, Scoop, and Winget).
    
    .DESCRIPTION
    Convenience function that installs all three package managers in sequence and returns installation results.
    #>
    $allPackages = @("choco", "scoop", "winget")
    return Install-SelectedPackageManager -SelectedPackages $allPackages
}

function Install-SelectedPackageManager {
    <#
    .SYNOPSIS
    Installs the selected package manager(s).
    
    .DESCRIPTION
    Executes the appropriate installation script based on user selection and tracks installation results.
    #>
    param(
        [array]$SelectedPackages
    )
    
    $scriptPath = Split-Path -Parent $PSScriptRoot
    $scriptFolder = Join-Path $scriptPath "script"
    
    # Track installation results
    $installationResults = @{}
    
    if ($SelectedPackages.Count -eq 0) {
        Write-Host "`nNo package managers selected." -ForegroundColor Yellow
        return $installationResults
    }
    
    Write-Host "`nInstalling selected package managers..." -ForegroundColor Green
    Write-Host "Selected: " -NoNewline -ForegroundColor Cyan
    Write-Host ($SelectedPackages -join ", ") -ForegroundColor White
    Write-Host ""
    
    foreach ($package in $SelectedPackages) {
        $packageName = ""
        $installSuccess = $false
        
        switch ($package) {
            "choco" {
                $packageName = "Chocolatey"
                Write-Host "`n--- Installing Chocolatey ---" -ForegroundColor Cyan
                $chocolateyScript = Join-Path $scriptFolder "install-chocolatey.ps1"
                if (Test-Path $chocolateyScript) {
                    try {
                        & $chocolateyScript
                        # Check if Chocolatey was installed successfully
                        $installSuccess = (Get-Command choco -ErrorAction SilentlyContinue) -ne $null
                    } catch {
                        $installSuccess = $false
                    }
                } else {
                    Write-Host "Chocolatey installation script not found at: $chocolateyScript" -ForegroundColor Red
                    $installSuccess = $false
                }
            }
            "scoop" {
                $packageName = "Scoop"
                Write-Host "`n--- Installing Scoop ---" -ForegroundColor Cyan
                $scoopScript = Join-Path $scriptFolder "install-scoop.ps1"
                if (Test-Path $scoopScript) {
                    try {
                        & $scoopScript
                        # Check if Scoop was installed successfully
                        $installSuccess = (Get-Command scoop -ErrorAction SilentlyContinue) -ne $null
                    } catch {
                        $installSuccess = $false
                    }
                } else {
                    Write-Host "Scoop installation script not found at: $scoopScript" -ForegroundColor Red
                    $installSuccess = $false
                }
            }
            "winget" {
                $packageName = "WinGet"
                Write-Host "`n--- Installing Winget ---" -ForegroundColor Cyan
                $wingetScript = Join-Path $scriptFolder "install-winget.ps1"
                if (Test-Path $wingetScript) {
                    try {
                        & $wingetScript
                        # Check if WinGet was installed successfully
                        $installSuccess = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null
                    } catch {
                        $installSuccess = $false
                    }
                } else {
                    Write-Host "Winget installation script not found at: $wingetScript" -ForegroundColor Red
                    $installSuccess = $false
                }
            }
        }
        
        # Store the result
        $installationResults[$packageName] = $installSuccess
    }
    
    Write-Host "`nInstallation process completed!" -ForegroundColor Green
    Write-Host "You may need to restart your terminal to use the new package manager(s)." -ForegroundColor Yellow
    
    Write-Host "`nPress any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    return $installationResults
}



function Start-PackageManagerInstaller {
    <#
    .SYNOPSIS
    Main function that orchestrates the Firebase-style interactive installation process.
    
    .DESCRIPTION
    Shows Firebase-style menu, gets user choice with arrow keys, and handles the new hierarchical menu system.
    #>
    do {
        $choice = Get-FirebaseStyleChoice
        
        # Show selection confirmation in Firebase style
        Clear-Host
        Write-Host ""
        Write-Host "     [FIRE] " -NoNewline -ForegroundColor Red
        Write-Host "Windows Package Manager Installer" -ForegroundColor White
        Write-Host ""
        
        $selectedOption = switch ($choice) {
            1 { "[ALL] Install All" }
            2 { "[SELECT] Select Package Managers" }
            3 { "[EXIT] Exit" }
        }
        
        Write-Host "[OK] " -NoNewline -ForegroundColor Green
        Write-Host "Selected: " -NoNewline -ForegroundColor White
        Write-Host "$selectedOption" -ForegroundColor Cyan
        Write-Host ""
        
        switch ($choice) {
            1 { # Install All
                $installResults = Install-AllPackageManagers
                Show-InstallationSummary -Results $installResults
            }
            2 { # Select Package Managers
                do {
                    $selectionResult = Get-PackageSelectionChoice
                    
                    if ($selectionResult.Action -eq "install") {
                        if ($selectionResult.Packages.Count -gt 0) {
                            $installResults = Install-SelectedPackageManager -SelectedPackages $selectionResult.Packages
                            Show-InstallationSummary -Results $installResults
                        } else {
                            Write-Host "`nNo package managers selected. Please select at least one package manager." -ForegroundColor Yellow
                            Write-Host "Press any key to continue..." -ForegroundColor Gray
                            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            continue
                        }
                    }
                    break
                } while ($selectionResult.Action -ne "back")
            }
            3 { # Exit
                Write-Host "`nExiting..." -ForegroundColor Yellow
                break
            }
        }
        
        if ($choice -eq 3) {
            break
        }
        
        # Auto-exit after installation (no prompt)
        Write-Host ""
        Write-Host "? " -NoNewline -ForegroundColor Green
        Write-Host "Would you like to install more package managers? " -NoNewline -ForegroundColor White
        Write-Host "(y/N): " -NoNewline -ForegroundColor DarkGray
        Write-Host "N" -ForegroundColor Yellow
        Write-Host "Auto-exiting..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        break
    } while ($true)
    
    # Firebase-style goodbye message with detailed results
    Clear-Host
    Write-Host ""
    Write-Host "     [FIRE] " -NoNewline -ForegroundColor Red
    Write-Host "Installation Complete!" -ForegroundColor White
    Write-Host ""
    Write-Host "[STAR] " -NoNewline -ForegroundColor Yellow
    Write-Host "Thank you for using the Package Manager Installer!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] " -NoNewline -ForegroundColor Blue
    Write-Host "All package managers have been processed." -ForegroundColor White
    Write-Host "[INFO] " -NoNewline -ForegroundColor Blue
    Write-Host "Check the installation summary above for detailed results." -ForegroundColor White
    Write-Host ""
}

# Start the interactive installer
Start-PackageManagerInstaller