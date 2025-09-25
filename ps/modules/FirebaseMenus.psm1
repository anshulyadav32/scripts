#Requires -Version 5.1

<#
.SYNOPSIS
    Firebase CLI-Style Interactive Menu System for PowerShell
    
.DESCRIPTION
    This module provides Firebase CLI-style interactive menus with:
    - Arrow key navigation
    - Visual selection indicators
    - Progress displays
    - Styled headers and formatting
    - Multi-select capabilities
    
.NOTES
    Author: Server Installation System
    Version: 1.0.0
    Compatible with PowerShell 5.1+
#>

# Module variables
$script:FirebaseColors = @{
    Primary = 'Cyan'
    Secondary = 'DarkGray'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'White'
    Accent = 'Magenta'
}

function Show-FirebaseHeader {
    <#
    .SYNOPSIS
    Displays a Firebase-style header with title and subtitle.
    
    .PARAMETER Title
    Main title text
    
    .PARAMETER Subtitle
    Optional subtitle text
    
    .PARAMETER ClearScreen
    Whether to clear the screen before showing header
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [string]$Subtitle = "",
        
        [switch]$ClearScreen
    )
    
    if ($ClearScreen) {
        Clear-Host
    }
    
    Write-Host ""
    Write-Host "🔥 " -NoNewline -ForegroundColor $script:FirebaseColors.Primary
    Write-Host $Title -ForegroundColor $script:FirebaseColors.Primary
    
    if ($Subtitle) {
        Write-Host "   $Subtitle" -ForegroundColor $script:FirebaseColors.Secondary
    }
    
    Write-Host ""
}

function Show-FirebaseMenu {
    <#
    .SYNOPSIS
    Displays a Firebase-style menu with arrow key navigation.
    
    .PARAMETER MenuItems
    Array of menu items (strings or objects with Name and Description properties)
    
    .PARAMETER Title
    Menu title
    
    .PARAMETER Subtitle
    Menu subtitle
    
    .PARAMETER ShowIcons
    Whether to show icons for menu items
    
    .PARAMETER AllowCancel
    Whether to allow cancellation with Escape key
    #>
    param(
        [Parameter(Mandatory)]
        [array]$MenuItems,
        
        [string]$Title = "Select an option",
        
        [string]$Subtitle = "",
        
        [switch]$ShowIcons,
        
        [switch]$AllowCancel
    )
    
    $selectedIndex = 0
    $maxIndex = $MenuItems.Count - 1
    
    do {
        Clear-Host
        Show-FirebaseHeader -Title $Title -Subtitle $Subtitle
        
        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            $item = $MenuItems[$i]
            $isSelected = $i -eq $selectedIndex
            
            # Handle different item types
            if ($item -is [string]) {
                $displayName = $item
                $description = ""
                $icon = if ($ShowIcons) { "•" } else { "" }
            } else {
                $displayName = $item.Name
                $description = if ($item.Description) { $item.Description } else { "" }
                $icon = if ($ShowIcons -and $item.Icon) { $item.Icon } else { if ($ShowIcons) { "•" } else { "" } }
            }
            
            if ($isSelected) {
                Write-Host "  ❯ " -NoNewline -ForegroundColor $script:FirebaseColors.Primary
                if ($icon) {
                    Write-Host "$icon " -NoNewline -ForegroundColor $script:FirebaseColors.Primary
                }
                Write-Host $displayName -ForegroundColor $script:FirebaseColors.Info
                if ($description) {
                    Write-Host "    $description" -ForegroundColor $script:FirebaseColors.Secondary
                }
            } else {
                Write-Host "    " -NoNewline
                if ($icon) {
                    Write-Host "$icon " -NoNewline -ForegroundColor $script:FirebaseColors.Secondary
                }
                Write-Host $displayName -ForegroundColor $script:FirebaseColors.Secondary
                if ($description) {
                    Write-Host "    $description" -ForegroundColor $script:FirebaseColors.Secondary
                }
            }
        }
        
        Write-Host ""
        Write-Host "Use ↑↓ arrows to navigate" -NoNewline -ForegroundColor $script:FirebaseColors.Secondary
        if ($AllowCancel) {
            Write-Host ", ESC to cancel" -NoNewline -ForegroundColor $script:FirebaseColors.Secondary
        }
        Write-Host ", ENTER to select" -ForegroundColor $script:FirebaseColors.Secondary
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $selectedIndex = if ($selectedIndex -eq 0) { $maxIndex } else { $selectedIndex - 1 }
            }
            40 { # Down arrow
                $selectedIndex = if ($selectedIndex -eq $maxIndex) { 0 } else { $selectedIndex + 1 }
            }
            13 { # Enter
                return @{
                    SelectedIndex = $selectedIndex
                    SelectedItem = $MenuItems[$selectedIndex]
                    Action = 'select'
                }
            }
            27 { # Escape
                if ($AllowCancel) {
                    return @{
                        SelectedIndex = -1
                        SelectedItem = $null
                        Action = 'cancel'
                    }
                }
            }
        }
    } while ($true)
}

function Show-FirebaseMultiSelect {
    <#
    .SYNOPSIS
    Displays a Firebase-style multi-select menu with checkboxes.
    
    .PARAMETER MenuItems
    Array of menu items
    
    .PARAMETER Title
    Menu title
    
    .PARAMETER Subtitle
    Menu subtitle
    
    .PARAMETER PreSelected
    Array of pre-selected item indices
    
    .PARAMETER AllowSelectAll
    Whether to show "Select All" option
    #>
    param(
        [Parameter(Mandatory)]
        [array]$MenuItems,
        
        [string]$Title = "Select options",
        
        [string]$Subtitle = "",
        
        [int[]]$PreSelected = @(),
        
        [switch]$AllowSelectAll
    )
    
    $selectedIndex = 0
    $checkedItems = @{}
    
    # Initialize pre-selected items
    foreach ($index in $PreSelected) {
        if ($index -ge 0 -and $index -lt $MenuItems.Count) {
            $checkedItems[$index] = $true
        }
    }
    
    $menuItemsWithActions = @()
    if ($AllowSelectAll) {
        $menuItemsWithActions += @{ Name = "Select All"; Action = "select_all"; IsAction = $true }
        $menuItemsWithActions += @{ Name = "Deselect All"; Action = "deselect_all"; IsAction = $true }
        $menuItemsWithActions += @{ Name = "---"; Action = "separator"; IsAction = $true }
    }
    
    $menuItemsWithActions += $MenuItems
    $menuItemsWithActions += @{ Name = "---"; Action = "separator"; IsAction = $true }
    $menuItemsWithActions += @{ Name = "Continue with Selection"; Action = "continue"; IsAction = $true }
    $menuItemsWithActions += @{ Name = "Cancel"; Action = "cancel"; IsAction = $true }
    
    $maxIndex = $menuItemsWithActions.Count - 1
    
    do {
        Clear-Host
        Show-FirebaseHeader -Title $Title -Subtitle $Subtitle
        
        $selectedCount = $checkedItems.Values | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
        Write-Host "Selected: $selectedCount items" -ForegroundColor $script:FirebaseColors.Info
        Write-Host ""
        
        for ($i = 0; $i -lt $menuItemsWithActions.Count; $i++) {
            $item = $menuItemsWithActions[$i]
            $isSelected = $i -eq $selectedIndex
            
            if ($item.Action -eq "separator") {
                Write-Host "    ────────────────────────" -ForegroundColor $script:FirebaseColors.Secondary
                continue
            }
            
            $displayName = if ($item -is [string]) { $item } else { $item.Name }
            $isAction = $item.IsAction -eq $true
            
            if ($isSelected) {
                Write-Host "  ❯ " -NoNewline -ForegroundColor $script:FirebaseColors.Primary
            } else {
                Write-Host "    " -NoNewline
            }
            
            if (-not $isAction) {
                # Regular menu item with checkbox
                $itemIndex = $i - ($AllowSelectAll ? 3 : 0)  # Adjust for action items
                $isChecked = $checkedItems[$itemIndex] -eq $true
                
                if ($isChecked) {
                    Write-Host "☑ " -NoNewline -ForegroundColor $script:FirebaseColors.Success
                } else {
                    Write-Host "☐ " -NoNewline -ForegroundColor $script:FirebaseColors.Secondary
                }
            }
            
            $color = if ($isSelected) { $script:FirebaseColors.Info } else { $script:FirebaseColors.Secondary }
            if ($isAction) {
                $color = if ($isSelected) { $script:FirebaseColors.Primary } else { $script:FirebaseColors.Secondary }
            }
            
            Write-Host $displayName -ForegroundColor $color
        }
        
        Write-Host ""
        Write-Host "Use ↑↓ to navigate, SPACE to toggle, ENTER to select action" -ForegroundColor $script:FirebaseColors.Secondary
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                do {
                    $selectedIndex = if ($selectedIndex -eq 0) { $maxIndex } else { $selectedIndex - 1 }
                } while ($menuItemsWithActions[$selectedIndex].Action -eq "separator")
            }
            40 { # Down arrow
                do {
                    $selectedIndex = if ($selectedIndex -eq $maxIndex) { 0 } else { $selectedIndex + 1 }
                } while ($menuItemsWithActions[$selectedIndex].Action -eq "separator")
            }
            32 { # Space
                $item = $menuItemsWithActions[$selectedIndex]
                if (-not $item.IsAction) {
                    $itemIndex = $selectedIndex - ($AllowSelectAll ? 3 : 0)
                    $checkedItems[$itemIndex] = -not ($checkedItems[$itemIndex] -eq $true)
                }
            }
            13 { # Enter
                $item = $menuItemsWithActions[$selectedIndex]
                
                if ($item.IsAction) {
                    switch ($item.Action) {
                        "select_all" {
                            for ($i = 0; $i -lt $MenuItems.Count; $i++) {
                                $checkedItems[$i] = $true
                            }
                        }
                        "deselect_all" {
                            $checkedItems.Clear()
                        }
                        "continue" {
                            $selectedItems = @()
                            for ($i = 0; $i -lt $MenuItems.Count; $i++) {
                                if ($checkedItems[$i] -eq $true) {
                                    $selectedItems += $MenuItems[$i]
                                }
                            }
                            return @{
                                SelectedItems = $selectedItems
                                SelectedIndices = ($checkedItems.Keys | Where-Object { $checkedItems[$_] })
                                Action = 'select'
                            }
                        }
                        "cancel" {
                            return @{
                                SelectedItems = @()
                                SelectedIndices = @()
                                Action = 'cancel'
                            }
                        }
                    }
                } else {
                    # Toggle item
                    $itemIndex = $selectedIndex - ($AllowSelectAll ? 3 : 0)
                    $checkedItems[$itemIndex] = -not ($checkedItems[$itemIndex] -eq $true)
                }
            }
            27 { # Escape
                return @{
                    SelectedItems = @()
                    SelectedIndices = @()
                    Action = 'cancel'
                }
            }
        }
    } while ($true)
}

function Show-FirebaseProgress {
    <#
    .SYNOPSIS
    Displays Firebase-style progress information.
    
    .PARAMETER Message
    Progress message
    
    .PARAMETER Step
    Current step number
    
    .PARAMETER TotalSteps
    Total number of steps
    
    .PARAMETER Status
    Status type (info, success, warning, error)
    
    .PARAMETER ShowSpinner
    Whether to show a spinner animation
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [int]$Step = 0,
        
        [int]$TotalSteps = 0,
        
        [ValidateSet('info', 'success', 'warning', 'error')]
        [string]$Status = 'info',
        
        [switch]$ShowSpinner
    )
    
    $icon = switch ($Status) {
        'info' { "ℹ" }
        'success' { "✅" }
        'warning' { "⚠" }
        'error' { "❌" }
    }
    
    $color = switch ($Status) {
        'info' { $script:FirebaseColors.Info }
        'success' { $script:FirebaseColors.Success }
        'warning' { $script:FirebaseColors.Warning }
        'error' { $script:FirebaseColors.Error }
    }
    
    if ($TotalSteps -gt 0) {
        $progressText = "[$Step/$TotalSteps]"
        Write-Host "$icon $progressText " -NoNewline -ForegroundColor $color
    } else {
        Write-Host "$icon " -NoNewline -ForegroundColor $color
    }
    
    Write-Host $Message -ForegroundColor $color
}

function New-FirebaseMenuItem {
    <#
    .SYNOPSIS
    Creates a new Firebase menu item object.
    
    .PARAMETER Name
    Display name of the menu item
    
    .PARAMETER Description
    Optional description
    
    .PARAMETER Action
    Action identifier
    
    .PARAMETER Icon
    Optional icon
    
    .PARAMETER Data
    Additional data to associate with the item
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$Description = "",
        
        [string]$Action = "",
        
        [string]$Icon = "",
        
        [hashtable]$Data = @{}
    )
    
    return @{
        Name = $Name
        Description = $Description
        Action = $Action
        Icon = $Icon
        Data = $Data
    }
}

function Show-FirebaseConfirmation {
    <#
    .SYNOPSIS
    Shows a Firebase-style confirmation dialog.
    
    .PARAMETER Message
    Confirmation message
    
    .PARAMETER Title
    Dialog title
    
    .PARAMETER DefaultYes
    Whether "Yes" is the default option
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [string]$Title = "Confirm Action",
        
        [switch]$DefaultYes
    )
    
    Clear-Host
    Show-FirebaseHeader -Title $Title
    
    Write-Host $Message -ForegroundColor $script:FirebaseColors.Info
    Write-Host ""
    
    $options = @(
        @{ Name = "Yes"; Action = "yes" }
        @{ Name = "No"; Action = "no" }
    )
    
    $selectedIndex = if ($DefaultYes) { 0 } else { 1 }
    
    do {
        # Clear previous selection display
        Write-Host "`r" -NoNewline
        
        for ($i = 0; $i -lt $options.Count; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host "  ❯ " -NoNewline -ForegroundColor $script:FirebaseColors.Primary
                Write-Host $options[$i].Name -ForegroundColor $script:FirebaseColors.Primary
            } else {
                Write-Host "    " -NoNewline
                Write-Host $options[$i].Name -ForegroundColor $script:FirebaseColors.Secondary
            }
        }
        
        Write-Host ""
        Write-Host "Use ↑↓ arrows to navigate, ENTER to confirm" -ForegroundColor $script:FirebaseColors.Secondary
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38, 40 { # Up/Down arrow
                $selectedIndex = 1 - $selectedIndex  # Toggle between 0 and 1
                # Move cursor up to redraw
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 4)
            }
            13 { # Enter
                return $options[$selectedIndex].Action -eq "yes"
            }
            27 { # Escape
                return $false
            }
        }
    } while ($true)
}

# Export functions
Export-ModuleMember -Function @(
    'Show-FirebaseHeader',
    'Show-FirebaseMenu',
    'Show-FirebaseMultiSelect',
    'Show-FirebaseProgress',
    'New-FirebaseMenuItem',
    'Show-FirebaseConfirmation'
)