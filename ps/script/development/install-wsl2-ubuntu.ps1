# Install WSL2 with Ubuntu and Auto-Setup User
# This script installs WSL2, Ubuntu, and automatically configures the specified user

param(
    [string]$Username = "darkprompt",
    [securestring]$Password,
    [string]$Distribution = "Ubuntu",
    [switch]$Silent = $false,
    [switch]$SkipUserSetup = $false
)

Write-Host "WSL2 Ubuntu Auto-Setup Script" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

# Check Windows version compatibility
$windowsVersion = [System.Environment]::OSVersion.Version
if ($windowsVersion.Major -lt 10 -or ($windowsVersion.Major -eq 10 -and $windowsVersion.Build -lt 18362)) {
    Write-Host "WSL2 requires Windows 10 version 1903 (build 18362) or higher." -ForegroundColor Red
    Write-Host "Current version: $($windowsVersion)" -ForegroundColor Yellow
    exit 1
}

# Check if WSL is already installed
$wslInstalled = Get-Command wsl -ErrorAction SilentlyContinue
if ($wslInstalled) {
    Write-Host "WSL is already available." -ForegroundColor Yellow
    wsl --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "WSL2 is available." -ForegroundColor Green
    }
} else {
    Write-Host "Installing WSL and required features..." -ForegroundColor Yellow
    
    # Enable WSL feature
    try {
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to enable WSL feature"
        }
        Write-Host "WSL feature enabled." -ForegroundColor Green
    } catch {
        Write-Host "Failed to enable WSL: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    # Enable Virtual Machine Platform for WSL2
    try {
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to enable Virtual Machine Platform"
        }
        Write-Host "Virtual Machine Platform enabled." -ForegroundColor Green
    } catch {
        Write-Host "Failed to enable Virtual Machine Platform: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    # Download and install WSL2 Linux kernel update
    Write-Host "Installing WSL2 kernel update..." -ForegroundColor Yellow
    $kernelUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $kernelUpdatePath = "$env:TEMP\wsl_update_x64.msi"

    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $kernelUpdateUrl -OutFile $kernelUpdatePath -UseBasicParsing
        Start-Process msiexec.exe -ArgumentList "/i", $kernelUpdatePath, "/quiet" -Wait
        Write-Host "WSL2 kernel update installed." -ForegroundColor Green
        Remove-Item $kernelUpdatePath -Force
    } catch {
        Write-Host "Warning: Could not install WSL2 kernel update: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Set WSL2 as default version
Write-Host "Setting WSL2 as default version..." -ForegroundColor Yellow
try {
    wsl --set-default-version 2
    Write-Host "WSL2 set as default version." -ForegroundColor Green
} catch {
    Write-Host "Could not set WSL2 as default. Will set after installation." -ForegroundColor Yellow
}

# Check if Ubuntu is already installed
$ubuntuExists = wsl -l -q | Select-String -Pattern "Ubuntu" -Quiet
if ($ubuntuExists -and -not $SkipUserSetup) {
    Write-Host "Ubuntu is already installed in WSL." -ForegroundColor Yellow
    $continue = Read-Host "Continue with user setup? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 0
    }
} else {
    # Install Ubuntu
    Write-Host "Installing Ubuntu distribution..." -ForegroundColor Yellow
    try {
        wsl --install -d Ubuntu --no-launch
        Write-Host "Ubuntu installation initiated." -ForegroundColor Green
        
        # Wait for installation to complete
        Write-Host "Waiting for Ubuntu installation to complete..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
        # Ensure it's running on WSL2
        wsl --set-version Ubuntu 2
        Write-Host "Ubuntu set to WSL2." -ForegroundColor Green
    } catch {
        Write-Host "Ubuntu installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You may need to install Ubuntu manually from Microsoft Store." -ForegroundColor Yellow
        exit 1
    }
}

# Handle password parameter
if (-not $Password) {
    Write-Host "No password provided, using default password '2002'..." -ForegroundColor Yellow
    $Password = ConvertTo-SecureString "2002" -AsPlainText -Force
}
$PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

# Auto-configure Ubuntu user
if (-not $SkipUserSetup) {
    Write-Host "`nConfiguring Ubuntu with user: $Username" -ForegroundColor Yellow
    
    # Create user setup script
    $setupScript = @"
#!/bin/bash
# Auto-setup script for Ubuntu WSL2

echo "Setting up user: $Username"

# Create user with home directory
sudo useradd -m -s /bin/bash $Username

# Set password
echo '${Username}:${PlainPassword}' | sudo chpasswd

# Add user to sudo group
sudo usermod -aG sudo $Username

# Update package lists
sudo apt update

# Install essential packages
sudo apt install -y curl wget git vim nano htop neofetch

# Set up basic bash profile for user
sudo -u $Username bash -c 'echo "alias ll=\"ls -la\"" >> /home/$Username/.bashrc'
sudo -u $Username bash -c 'echo "alias la=\"ls -A\"" >> /home/$Username/.bashrc'
sudo -u $Username bash -c 'echo "alias l=\"ls -CF\"" >> /home/$Username/.bashrc'
sudo -u $Username bash -c 'echo "export EDITOR=nano" >> /home/$Username/.bashrc'

# Set the new user as default
echo "User $Username has been created and configured."
echo "Password: $Password"
echo "The user has sudo privileges."

# Switch to new user
sudo su - $Username
"@

    $setupScriptPath = "$env:TEMP\ubuntu_setup.sh"
    $setupScript | Out-File -FilePath $setupScriptPath -Encoding UTF8

    try {
        # Copy setup script to WSL and execute
        wsl -d Ubuntu -- sudo mkdir -p /tmp/setup
        wsl -d Ubuntu -- sudo chmod 777 /tmp/setup
        
        # Convert Windows path to WSL path and copy file
        $wslSetupPath = "/tmp/setup/ubuntu_setup.sh"
        Get-Content $setupScriptPath | wsl -d Ubuntu -- sudo tee $wslSetupPath > $null
        wsl -d Ubuntu -- sudo chmod +x $wslSetupPath
        
        Write-Host "Executing Ubuntu setup script..." -ForegroundColor Cyan
        wsl -d Ubuntu -- sudo bash $wslSetupPath
        
        # Set default user for Ubuntu
        Write-Host "Setting $Username as default user..." -ForegroundColor Yellow
        ubuntu config --default-user $Username
        
        Write-Host "Ubuntu user setup completed!" -ForegroundColor Green
        
        # Clean up
        Remove-Item $setupScriptPath -Force -ErrorAction SilentlyContinue
        wsl -d Ubuntu -- sudo rm -f $wslSetupPath
        
    } catch {
        Write-Host "Warning: Could not complete automatic user setup: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "You may need to configure the user manually." -ForegroundColor Cyan
    }
}

Write-Host "`nWSL2 Ubuntu installation completed!" -ForegroundColor Green
Write-Host "`nConfiguration Summary:" -ForegroundColor Cyan
Write-Host "  Distribution: Ubuntu on WSL2" -ForegroundColor White
Write-Host "  Username: $Username" -ForegroundColor White
Write-Host "  Password: [SecureString - Default: 2002]" -ForegroundColor White
Write-Host "  Sudo Access: Yes" -ForegroundColor White

Write-Host "`nUsage Commands:" -ForegroundColor Cyan
Write-Host "  wsl                          # Start Ubuntu with default user"
Write-Host "  wsl -d Ubuntu                # Start Ubuntu specifically"
Write-Host "  wsl -d Ubuntu -u $Username   # Start as specific user"
Write-Host "  wsl --shutdown               # Shutdown all WSL instances"
Write-Host "  ubuntu                       # Launch Ubuntu directly"

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Run 'wsl' to start your Ubuntu environment" -ForegroundColor White
Write-Host "  2. Your user '$Username' is ready with sudo access" -ForegroundColor White  
Write-Host "  3. Password is configured as specified" -ForegroundColor White
Write-Host "  4. Essential packages (git, vim, curl, etc.) are installed" -ForegroundColor White

# Usage examples
Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-wsl2-ubuntu.ps1                                    # Default setup"
Write-Host "  .\install-wsl2-ubuntu.ps1 -Username 'myuser' -Password '1234' # Custom credentials"
Write-Host "  .\install-wsl2-ubuntu.ps1 -SkipUserSetup                     # Skip user configuration"
Write-Host "  .\install-wsl2-ubuntu.ps1 -Silent                           # Silent installation"