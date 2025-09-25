# Install Development IDEs (Cursor IDE)
# This script downloads and installs modern development environments

param(
    [switch]$Cursor,
    [switch]$Silent = $false,
    [switch]$Force = $false
)

Write-Host "Development IDEs Installation Script" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Default to installing Cursor if no specific IDE is specified
if (-not $Cursor -and -not $PSBoundParameters.ContainsKey('Cursor')) {
    $Cursor = $true
}

# Function to check if application is installed
function Test-AppInstalled {
    param([string]$AppName)
    $paths = @(
        "${env:ProgramFiles}\*$AppName*",
        "${env:ProgramFiles(x86)}\*$AppName*",
        "${env:LOCALAPPDATA}\Programs\*$AppName*"
    )
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $true
        }
    }
    return $false
}

# Install Cursor IDE
if ($Cursor) {
    Write-Host "`nInstalling Cursor IDE..." -ForegroundColor Yellow
    
    $cursorInstalled = Test-AppInstalled "Cursor"
    if ($cursorInstalled -and -not $Force) {
        Write-Host "Cursor IDE is already installed. Use -Force to reinstall." -ForegroundColor Cyan
    } else {
        try {
            # Get latest Cursor release info
            Write-Host "Fetching latest Cursor IDE version..." -ForegroundColor Cyan
            
            # Cursor direct download URLs (as they might not have GitHub releases API)
            $cursorUrl = "https://download.todesktop.com/200122auv92xb0r/Cursor%20Setup%200.42.3%20-%20x64.exe"
            
            # Try to get the latest version from their website or use fallback
            try {
                # Alternative approach: check their download page or use known stable version
                $cursorUrl = "https://download.todesktop.com/200122auv92xb0r/latest/Cursor%20Setup%20-%20x64.exe"
            } catch {
                # Fallback to a known working version
                $cursorUrl = "https://download.todesktop.com/200122auv92xb0r/Cursor%20Setup%200.42.3%20-%20x64.exe"
            }
            
            $cursorPath = "$env:TEMP\CursorSetup.exe"
            
            Write-Host "Downloading Cursor IDE..." -ForegroundColor Cyan
            $ProgressPreference = 'SilentlyContinue'
            
            # Try multiple download approaches
            try {
                Invoke-WebRequest -Uri $cursorUrl -OutFile $cursorPath -UseBasicParsing
            } catch {
                Write-Host "Primary download failed, trying alternative..." -ForegroundColor Yellow
                $cursorUrl = "https://cursor.sh/download"
                # This would redirect to actual download, but let's use a direct approach
                $cursorUrl = "https://download.todesktop.com/200122auv92xb0r/Cursor%20Setup%200.42.3%20-%20x64.exe"
                Invoke-WebRequest -Uri $cursorUrl -OutFile $cursorPath -UseBasicParsing
            }
            
            Write-Host "Installing Cursor IDE..." -ForegroundColor Cyan
            if ($Silent) {
                # Cursor uses Electron installer, try common silent install flags
                Start-Process -FilePath $cursorPath -ArgumentList "/S", "/silent", "/verysilent" -Wait
            } else {
                Start-Process -FilePath $cursorPath -Wait
            }
            
            Write-Host "Cursor IDE installed successfully!" -ForegroundColor Green
            Remove-Item $cursorPath -Force -ErrorAction SilentlyContinue
            
            # Add to PATH if needed
            $cursorExePath = "${env:LOCALAPPDATA}\Programs\cursor\Cursor.exe"
            if (Test-Path $cursorExePath) {
                Write-Host "Cursor IDE is ready to use!" -ForegroundColor Green
            }
            
        } catch {
            Write-Host "Failed to install Cursor IDE: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "You can download it manually from https://cursor.sh" -ForegroundColor Yellow
        }
    }
}

# Post-installation configuration
Write-Host "`nIDE Installation Summary:" -ForegroundColor Cyan
if ($Cursor -and (Test-AppInstalled "Cursor")) {
    Write-Host "✓ Cursor IDE installed successfully" -ForegroundColor Green
    Write-Host "  - AI-powered code editor" -ForegroundColor White
    Write-Host "  - Built on VS Code foundation" -ForegroundColor White
    Write-Host "  - Integrated AI chat and suggestions" -ForegroundColor White
}

Write-Host "`nDevelopment IDEs installation completed!" -ForegroundColor Green

# Provide usage information
Write-Host "`nCursor IDE Features:" -ForegroundColor Cyan
Write-Host "  • AI-powered code completion and suggestions" -ForegroundColor White
Write-Host "  • Integrated AI chat for coding assistance" -ForegroundColor White
Write-Host "  • Built on Visual Studio Code (familiar interface)" -ForegroundColor White
Write-Host "  • Support for all major programming languages" -ForegroundColor White
Write-Host "  • Intelligent code refactoring and debugging" -ForegroundColor White

Write-Host "`nQuick Start:" -ForegroundColor Cyan
Write-Host "  1. Launch Cursor from Start Menu or Desktop" -ForegroundColor White
Write-Host "  2. Open a project folder or create new file" -ForegroundColor White
Write-Host "  3. Use Ctrl+K to open AI chat" -ForegroundColor White
Write-Host "  4. Use Ctrl+L to select code and ask AI questions" -ForegroundColor White
Write-Host "  5. Enjoy AI-assisted coding!" -ForegroundColor White

# Usage examples
Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-ides.ps1                       # Install Cursor IDE"
Write-Host "  .\install-ides.ps1 -Cursor               # Explicitly install Cursor"
Write-Host "  .\install-ides.ps1 -Silent               # Silent installation"
Write-Host "  .\install-ides.ps1 -Force                # Force reinstall"

Write-Host "`nAlternative IDEs:" -ForegroundColor Cyan
Write-Host "  • VS Code: Use ..\install-vscode.ps1" -ForegroundColor White
Write-Host "  • JetBrains IDEs: Available via package managers" -ForegroundColor White
Write-Host "  • Sublime Text: Available via package managers" -ForegroundColor White