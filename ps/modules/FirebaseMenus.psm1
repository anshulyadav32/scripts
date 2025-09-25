#Requires -Version 5.1

<#
.SYNOPSIS
    Firebase CLI-Style Interactive Menu System for PowerShell
    
.DESCRIPTION
    This module provides Firebase CLI-style interactive menus with:
    - Arrow key navigation
    - Visual selection indicators
    - Multi-select capabilities
    - Progress displays
    - Styled headers and confirmations
    
.NOTES
    Author: Server Installation System
    Version: 1.0.0
    Compatible with PowerShell 5.1+
#>

# Define Firebase-style color scheme
$script:FirebaseColors = @{
    Primary = 'Yellow'
    Secondary = 'DarkGray'
    Success = 'Green'
    Error = 'Red'
    Warning = 'Yellow'
    Info = 'Cyan'
    Accent = 'Magenta'
}

function Show-FirebaseHeader {
    <#
    .SYNOPSIS
    Displays a Firebase-style header with title and optional subtitle.
    
    .PARAMETER Title
    Main title text
    
    .PARAMETER Subtitle
    Optional subtitle text
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [string]$Subtitle = ""
    )
    
    Clear-Host
    
    # Firebase-style header
    Write-Host "[FIRE] " -NoNewline -ForegroundColor $script:FirebaseColors.Primary
    Write-Host $Title -ForegroundColor $script:FirebaseColors.Primary
    
    if ($Subtitle) {
        Write-Host "   $Subtitle" -ForegroundColor $script:FirebaseColors.Secondary
    }
    
    Write-Host ""
}

function Show-FirebaseMenu {
    <#
    .SYNOPSIS
    Displays a Firebase-style interactive menu with arrow key navigation.
    
    .PARAMETER MenuItems
    Array of menu items created with New-FirebaseMenuItem
    
    .PARAMETER Title
    Menu title
    
    .PARAMETER Subtitle
    Optional subtitle
    
    .PARAMETER ShowIcons
    Whether to display icons
    
    .PARAMETER AllowCancel
    Whether ESC key cancels the menu
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
        Show-FirebaseHeader -Title $Title -Subtitle $Subtitle
        
        # Display menu items
        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            $item = $MenuItems[$i]
            $prefix = if ($i -eq $selectedIndex) { "> " } else { "  " }
            $color = if ($i -eq $selectedIndex) { $script:FirebaseColors.Primary } else { $script:FirebaseColors.Secondary }
            
            Write-Host $prefix -NoNewline -ForegroundColor $color
            
            if ($ShowIcons -and $item.Icon) {
                Write-Host "$($item.Icon) " -NoNewline -ForegroundColor $color
            }
            
            Write-Host $item.Name -NoNewline -ForegroundColor $color
            
            if ($item.Description) {
                Write-Host " - $($item.Description)" -ForegroundColor $script:FirebaseColors.Secondary
            } else {
                Write-Host ""
            }
        }
        
        Write-Host ""
        Write-Host "Use arrows to navigate" -NoNewline -ForegroundColor $script:FirebaseColors.Secondary
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
                    Action = $MenuItems[$selectedIndex].Action
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
    Optional subtitle
    
    .PARAMETER AllowSelectAll
    Whether to show Select All/Deselect All options
    #>
    param(
        [Parameter(Mandatory)]
        [array]$MenuItems,
        
        [string]$Title = "Select items",
        
        [string]$Subtitle = "",
        
        [switch]$AllowSelectAll
    )
    
    $checkedItems = @{}
    $selectedIndex = 0
    
    # Create menu with action items if AllowSelectAll is enabled
    $menuItemsWithActions = @()
    if ($AllowSelectAll) {
        $menuItemsWithActions += @{ Name = "Select All"; Action = "select_all"; IsAction = $true }
        $menuItemsWithActions += @{ Name = "Deselect All"; Action = "deselect_all"; IsAction = $true }
        $menuItemsWithActions += @{ Name = "Continue"; Action = "continue"; IsAction = $true }
    }
    
    # Add regular menu items
    for ($i = 0; $i -lt $MenuItems.Count; $i++) {
        $menuItemsWithActions += @{
            Name = $MenuItems[$i].Name
            Description = $MenuItems[$i].Description
            Action = $MenuItems[$i].Action
            Icon = $MenuItems[$i].Icon
            IsAction = $false
            OriginalIndex = $i
        }
    }
    
    $maxIndex = $menuItemsWithActions.Count - 1
    
    do {
        Show-FirebaseHeader -Title $Title -Subtitle $Subtitle
        
        # Display items
        for ($i = 0; $i -lt $menuItemsWithActions.Count; $i++) {
            $item = $menuItemsWithActions[$i]
            $prefix = if ($i -eq $selectedIndex) { "> " } else { "  " }
            $color = if ($i -eq $selectedIndex) { $script:FirebaseColors.Primary } else { $script:FirebaseColors.Secondary }
            
            Write-Host $prefix -NoNewline -ForegroundColor $color
            
            if ($item.IsAction) {
                # Action items (Select All, etc.)
                Write-Host "[$($item.Name)]" -ForegroundColor $color
            } else {
                # Regular selectable items
                $itemIndex = $item.OriginalIndex
                $checkbox = if ($checkedItems[$itemIndex] -eq $true) { "[X]" } else { "[ ]" }
                Write-Host "$checkbox " -NoNewline -ForegroundColor $color
                
                if ($item.Icon) {
                    Write-Host "$($item.Icon) " -NoNewline -ForegroundColor $color
                }
                
                Write-Host $item.Name -NoNewline -ForegroundColor $color
                
                if ($item.Description) {
                    Write-Host " - $($item.Description)" -ForegroundColor $script:FirebaseColors.Secondary
                } else {
                    Write-Host ""
                }
            }
        }
        
        Write-Host ""
        Write-Host "Use arrows to navigate, SPACE to toggle, ENTER to select action" -ForegroundColor $script:FirebaseColors.Secondary
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $selectedIndex = if ($selectedIndex -eq 0) { $maxIndex } else { $selectedIndex - 1 }
            }
            40 { # Down arrow
                $selectedIndex = if ($selectedIndex -eq $maxIndex) { 0 } else { $selectedIndex + 1 }
            }
            32 { # Space
                $item = $menuItemsWithActions[$selectedIndex]
                if (-not $item.IsAction) {
                    $itemIndex = $item.OriginalIndex
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
                            foreach ($key in $checkedItems.Keys) {
                                if ($checkedItems[$key] -eq $true) {
                                    $selectedItems += $MenuItems[$key]
                                }
                            }
                            return @{
                                SelectedItems = $selectedItems
                                Action = 'select'
                            }
                        }
                    }
                } else {
                    # Toggle item selection
                    $itemIndex = $item.OriginalIndex
                    $checkedItems[$itemIndex] = -not ($checkedItems[$itemIndex] -eq $true)
                }
            }
            27 { # Escape
                return @{
                    SelectedItems = @()
                    Action = 'cancel'
                }
            }
        }
    } while ($true)
}

function Show-FirebaseProgress {
    <#
    .SYNOPSIS
    Displays a Firebase-style progress or status message.
    
    .PARAMETER Message
    Progress message
    
    .PARAMETER Status
    Status type: 'info', 'success', 'error', 'warning'
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('info', 'success', 'error', 'warning')]
        [string]$Status = 'info'
    )
    
    $icon = switch ($Status) {
        'success' { "[OK]" }
        'error' { "[ERR]" }
        'warning' { "[WARN]" }
        default { "[INFO]" }
    }
    
    $color = switch ($Status) {
        'success' { $script:FirebaseColors.Success }
        'error' { $script:FirebaseColors.Error }
        'warning' { $script:FirebaseColors.Warning }
        default { $script:FirebaseColors.Info }
    }
    
    Write-Host "$icon " -NoNewline -ForegroundColor $color
    Write-Host $Message -ForegroundColor $color
}

function New-FirebaseMenuItem {
    <#
    .SYNOPSIS
    Creates a new Firebase-style menu item.
    
    .PARAMETER Name
    Display name
    
    .PARAMETER Description
    Optional description
    
    .PARAMETER Action
    Action identifier
    
    .PARAMETER Icon
    Optional icon
    
    .PARAMETER Data
    Optional additional data
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
        # Display options
        for ($i = 0; $i -lt $options.Count; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host "  > " -NoNewline -ForegroundColor $script:FirebaseColors.Primary
                Write-Host $options[$i].Name -ForegroundColor $script:FirebaseColors.Primary
            } else {
                Write-Host "    " -NoNewline
                Write-Host $options[$i].Name -ForegroundColor $script:FirebaseColors.Secondary
            }
        }
        
        Write-Host ""
        Write-Host "Use arrows to navigate, ENTER to confirm" -ForegroundColor $script:FirebaseColors.Secondary
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            { $_ -in 38, 40 } { # Up/Down arrow
                $selectedIndex = 1 - $selectedIndex  # Toggle between 0 and 1
                # Clear and redraw
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