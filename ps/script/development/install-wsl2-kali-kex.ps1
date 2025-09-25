# Install WSL2 with Kali Linux and Kex Desktop Environment
# This script installs WSL2, Kali Linux, and sets up the Kex desktop environment

param(
    [string]$Username = "kali",
    [securestring]$Password,
    [switch]$Silent = $false,
    [switch]$SkipKexSetup = $false,
    [switch]$InstallKexWin
)

Write-Host "WSL2 Kali Linux with Kex Desktop Setup" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

# Handle password parameter
if (-not $Password) {
    Write-Host "No password provided, using default password..." -ForegroundColor Yellow
    $Password = ConvertTo-SecureString "kali" -AsPlainText -Force
}

$PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

# Check Windows version compatibility
$windowsVersion = [System.Environment]::OSVersion.Version
if ($windowsVersion.Major -lt 10 -or ($windowsVersion.Major -eq 10 -and $windowsVersion.Build -lt 18362)) {
    Write-Host "WSL2 requires Windows 10 version 1903 (build 18362) or higher." -ForegroundColor Red
    Write-Host "Current version: $($windowsVersion)" -ForegroundColor Yellow
    exit 1
}

# Check if WSL is installed
$wslInstalled = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wslInstalled) {
    Write-Host "WSL is not installed. Please run install-wsl.ps1 first." -ForegroundColor Red
    Write-Host "Or run: wsl --install" -ForegroundColor Yellow
    exit 1
}

# Ensure WSL2 is set as default
Write-Host "Ensuring WSL2 is set as default version..." -ForegroundColor Yellow
try {
    wsl --set-default-version 2
    Write-Host "WSL2 set as default version." -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not set WSL2 as default." -ForegroundColor Yellow
}

# Check if Kali Linux is already installed
$kaliExists = wsl -l -q | Select-String -Pattern "kali-linux" -Quiet
if ($kaliExists) {
    Write-Host "Kali Linux is already installed in WSL." -ForegroundColor Yellow
    if (-not $Silent) {
        $continue = Read-Host "Continue with Kex setup? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 0
        }
    }
} else {
    # Install Kali Linux
    Write-Host "Installing Kali Linux distribution..." -ForegroundColor Yellow
    try {
        # Download and install Kali Linux from Microsoft Store or direct install
        wsl --install -d kali-linux --no-launch
        Write-Host "Kali Linux installation initiated." -ForegroundColor Green
        
        # Wait for installation to complete
        Write-Host "Waiting for Kali Linux installation to complete..." -ForegroundColor Yellow
        Start-Sleep -Seconds 45
        
        # Ensure it's running on WSL2
        wsl --set-version kali-linux 2
        Write-Host "Kali Linux set to WSL2." -ForegroundColor Green
    } catch {
        Write-Host "Kali Linux installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Trying alternative installation method..." -ForegroundColor Yellow
        
        # Alternative: Try to install via appx package
        try {
            $kaliUrl = "https://aka.ms/wsl-kali-linux-new"
            $kaliAppx = "$env:TEMP\kali-linux.appx"
            Write-Host "Downloading Kali Linux appx package..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $kaliUrl -OutFile $kaliAppx -UseBasicParsing
            Add-AppxPackage -Path $kaliAppx
            Remove-Item $kaliAppx -Force
            Write-Host "Kali Linux installed via appx package." -ForegroundColor Green
        } catch {
            Write-Host "Could not install Kali Linux automatically." -ForegroundColor Red
            Write-Host "Please install Kali Linux from Microsoft Store manually." -ForegroundColor Yellow
            exit 1
        }
    }
}

# Configure Kali Linux user and install Kex
if (-not $SkipKexSetup) {
    Write-Host "`nConfiguring Kali Linux with Kex desktop environment..." -ForegroundColor Yellow
    
    # Create comprehensive setup script for Kali
    $kaliSetupScript = @"
#!/bin/bash
# Auto-setup script for Kali Linux WSL2 with Kex

echo "=== Kali Linux WSL2 Setup with Kex ==="

# Update package repository
echo "Updating package repositories..."
sudo apt update && sudo apt upgrade -y

# Install essential packages first
echo "Installing essential packages..."
sudo apt install -y curl wget git vim nano htop neofetch

# Create user if it doesn't exist
if ! id "$Username" &>/dev/null; then
    echo "Creating user: $Username"
    sudo useradd -m -s /bin/bash $Username
    echo "$Username`:$PlainPassword" | sudo chpasswd
    sudo usermod -aG sudo $Username
    echo "User $Username created with sudo privileges."
else
    echo "User $Username already exists."
    # Update password anyway
    echo "$Username`:$PlainPassword" | sudo chpasswd
fi

# Install Kex desktop environment
echo "Installing Kali Linux Kex desktop environment..."
sudo apt install -y kali-win-kex

# Install additional useful tools
echo "Installing additional penetration testing tools..."
sudo apt install -y \
    kali-linux-default \
    kali-desktop-xfce \
    firefox-esr \
    code-oss \
    terminator

# Install development tools and languages
echo "Installing development tools and programming languages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    php \
    php-cli \
    php-curl \
    php-json \
    php-mbstring \
    php-xml \
    composer

# Install Node.js LTS via NodeSource repository
echo "Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Install additional Node.js tools
echo "Installing Node.js package managers and tools..."
sudo npm install -g npm@latest
sudo npm install -g yarn
sudo npm install -g pnpm
sudo npm install -g nodemon
sudo npm install -g pm2

# Install Python development packages
echo "Installing Python development packages..."
pip3 install --user --upgrade pip
pip3 install --user virtualenv
pip3 install --user pipenv
pip3 install --user requests
pip3 install --user flask
pip3 install --user django
pip3 install --user numpy
pip3 install --user pandas
pip3 install --user matplotlib
pip3 install --user jupyter

# Install GitHub CLI
echo "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh

# Configure development environment
echo "Configuring development environment..."
# Add local bin to PATH for pip user installs
echo 'export PATH="\$HOME/.local/bin:\$PATH"' >> /home/$Username/.bashrc

# Create common development directories
sudo -u $Username mkdir -p /home/$Username/projects
sudo -u $Username mkdir -p /home/$Username/scripts
sudo -u $Username mkdir -p /home/$Username/.local/bin

# Configure Kex for the user
echo "Configuring Kex desktop for user $Username..."
sudo -u $Username kex --passwd
echo "Kex password configuration completed."

# Set up user environment
sudo -u $Username bash -c 'cat >> /home/$Username/.bashrc << EOF

# Kali Linux aliases and functions
alias kex-start="kex --win -s"
alias kex-stop="kex --stop"
alias kex-status="kex --status" 
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"
export EDITOR=nano

# Development environment aliases
alias python="python3"
alias pip="pip3"
alias node-version="node --version"
alias npm-version="npm --version"
alias php-version="php --version"
alias gcc-version="gcc --version"
alias git-version="git --version"

# Project shortcuts
alias projects="cd ~/projects"
alias scripts="cd ~/scripts"

# Development server shortcuts
alias serve-php="php -S localhost:8000"
alias serve-python="python3 -m http.server 8080"
alias serve-node="npx http-server -p 3000"

# Git shortcuts
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline"

# GitHub CLI shortcuts  
alias ghauth="gh auth login"
alias ghrepo="gh repo create"
alias ghclone="gh repo clone"

# Kex desktop functions
function kex-help() {
    echo "Kex Desktop Commands:"
    echo "  kex --win -s        # Start Kex in seamless mode"
    echo "  kex --win           # Start Kex in window mode" 
    echo "  kex --esm           # Start Kex in enhanced session mode"
    echo "  kex --stop          # Stop Kex session"
    echo "  kex --status        # Check Kex status"
    echo "  kex --passwd        # Set VNC password"
}

# Development tools help
function dev-help() {
    echo "Development Tools Installed:"
    echo "Languages & Runtimes:"
    echo "  node --version      # Node.js LTS"
    echo "  python3 --version   # Python 3"
    echo "  php --version       # PHP"
    echo "  gcc --version       # C++ Compiler"
    echo ""
    echo "Package Managers:"
    echo "  npm, yarn, pnpm     # Node.js package managers"
    echo "  pip3, pipenv        # Python package managers"
    echo "  composer            # PHP package manager"
    echo ""
    echo "Tools & CLI:"
    echo "  gh                  # GitHub CLI"
    echo "  git                 # Git version control"
    echo "  code                # VS Code (code-oss)"
    echo ""
    echo "Quick Servers:"
    echo "  serve-php           # PHP dev server on :8000"
    echo "  serve-python        # Python HTTP server on :8080"
    echo "  serve-node          # Node HTTP server on :3000"
}

# Version check function
function dev-versions() {
    echo "Development Environment Versions:"
    echo "=================================="
    node --version 2>/dev/null && echo "Node.js: \$(node --version)" || echo "Node.js: Not installed"
    npm --version 2>/dev/null && echo "npm: \$(npm --version)" || echo "npm: Not installed"
    python3 --version 2>/dev/null && echo "Python: \$(python3 --version)" || echo "Python: Not installed"
    pip3 --version 2>/dev/null && echo "pip: \$(pip3 --version)" || echo "pip: Not installed"
    php --version 2>/dev/null | head -1 && echo "PHP: \$(php --version | head -1)" || echo "PHP: Not installed"
    gcc --version 2>/dev/null | head -1 && echo "GCC: \$(gcc --version | head -1)" || echo "GCC: Not installed"
    git --version 2>/dev/null && echo "Git: \$(git --version)" || echo "Git: Not installed"
    gh --version 2>/dev/null | head -1 && echo "GitHub CLI: \$(gh --version | head -1)" || echo "GitHub CLI: Not installed"
}

echo "Kali Linux WSL2 with Kex and Development Environment is ready!"
echo "Run 'kex-help' for desktop commands."
echo "Run 'dev-help' for development tools info."
echo "Run 'dev-versions' to check installed versions."
EOF'

# Set default user for Kali
echo "Setting $Username as default user for Kali..."

echo "=== Setup Complete ==="
echo "User: $Username"
echo "Password: $PlainPassword"
echo "Desktop: Kex (available)"
echo ""
echo "To start Kex desktop:"
echo "  kex --win -s     # Seamless mode (recommended)"
echo "  kex --win        # Window mode"
echo "  kex --esm        # Enhanced session mode"
"@

    $setupScriptPath = "$env:TEMP\kali_kex_setup.sh"
    $kaliSetupScript | Out-File -FilePath $setupScriptPath -Encoding UTF8

    try {
        # Execute setup script in Kali
        Write-Host "Executing Kali Linux and Kex setup..." -ForegroundColor Cyan
        
        # Copy and run setup script
        wsl -d kali-linux -- sudo mkdir -p /tmp/setup
        wsl -d kali-linux -- sudo chmod 777 /tmp/setup
        
        $wslSetupPath = "/tmp/setup/kali_kex_setup.sh"
        Get-Content $setupScriptPath | wsl -d kali-linux -- sudo tee $wslSetupPath > $null
        wsl -d kali-linux -- sudo chmod +x $wslSetupPath
        
        # Run the setup script
        wsl -d kali-linux -- sudo bash $wslSetupPath
        
        # Configure default user
        Write-Host "Setting default user for Kali Linux..." -ForegroundColor Yellow
        try {
            # Method varies by Kali version, try multiple approaches
            wsl -d kali-linux -- sudo bash -c "echo '[user]' > /etc/wsl.conf"
            wsl -d kali-linux -- sudo bash -c "echo 'default=$Username' >> /etc/wsl.conf"
        } catch {
            Write-Host "Note: You may need to set default user manually." -ForegroundColor Yellow
        }
        
        Write-Host "Kali Linux with Kex setup completed!" -ForegroundColor Green
        
        # Clean up
        Remove-Item $setupScriptPath -Force -ErrorAction SilentlyContinue
        wsl -d kali-linux -- sudo rm -f $wslSetupPath
        
    } catch {
        Write-Host "Warning: Could not complete automatic Kex setup: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "You may need to configure Kex manually." -ForegroundColor Cyan
    }
}

# Install Kex Win integration by default (unless explicitly disabled)
if ($InstallKexWin -or (-not $PSBoundParameters.ContainsKey('InstallKexWin'))) {
    Write-Host "`nSetting up Kex Windows integration..." -ForegroundColor Yellow
    try {
        # Create Windows shortcuts for Kex
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $kexShortcut = "$desktopPath\Kali Kex Desktop.lnk"
        
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($kexShortcut)
        $Shortcut.TargetPath = "wsl"
        $Shortcut.Arguments = "-d kali-linux kex --win -s"
        $Shortcut.WorkingDirectory = "$env:USERPROFILE"
        $Shortcut.Description = "Launch Kali Linux Kex Desktop"
        $Shortcut.Save()
        
        Write-Host "Kex desktop shortcut created on Desktop." -ForegroundColor Green
    } catch {
        Write-Host "Could not create desktop shortcuts." -ForegroundColor Yellow
    }
}

Write-Host "`nKali Linux WSL2 with Kex and Development Environment installation completed!" -ForegroundColor Green
Write-Host "`nConfiguration Summary:" -ForegroundColor Cyan
Write-Host "  Distribution: Kali Linux on WSL2" -ForegroundColor White
Write-Host "  Username: $Username" -ForegroundColor White
Write-Host "  Desktop Environment: Kex (Win-Kex)" -ForegroundColor White
Write-Host "  Security Tools: Kali Linux toolkit installed" -ForegroundColor White
Write-Host "  Development Tools: Node.js LTS, Python, C++, PHP, GitHub CLI" -ForegroundColor White

Write-Host "`nKex Desktop Commands:" -ForegroundColor Cyan
Write-Host "  kex --win -s        # Start Kex in seamless mode (recommended)" -ForegroundColor White
Write-Host "  kex --win           # Start Kex in window mode" -ForegroundColor White
Write-Host "  kex --esm           # Start Kex in enhanced session mode" -ForegroundColor White
Write-Host "  kex --stop          # Stop Kex desktop session" -ForegroundColor White
Write-Host "  kex --status        # Check Kex session status" -ForegroundColor White

Write-Host "`nAccess Commands:" -ForegroundColor Cyan
Write-Host "  wsl -d kali-linux                    # Start Kali terminal" -ForegroundColor White
Write-Host "  wsl -d kali-linux -u $Username       # Start as specific user" -ForegroundColor White
Write-Host "  wsl -d kali-linux kex --win -s       # Launch Kex desktop directly" -ForegroundColor White

Write-Host "`nDevelopment Environment:" -ForegroundColor Cyan
Write-Host "  Node.js LTS with npm, yarn, pnpm" -ForegroundColor White
Write-Host "  Python 3 with pip, virtualenv, common packages" -ForegroundColor White
Write-Host "  C++ with GCC compiler and build tools" -ForegroundColor White
Write-Host "  PHP with CLI and Composer package manager" -ForegroundColor White
Write-Host "  GitHub CLI (gh) for repository management" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Run 'wsl -d kali-linux' to start Kali terminal" -ForegroundColor White
Write-Host "  2. Run 'kex --win -s' to start the desktop environment" -ForegroundColor White
Write-Host "  3. Use the desktop shortcut for quick access" -ForegroundColor White
Write-Host "  4. Run 'dev-help' for development tools information" -ForegroundColor White
Write-Host "  5. Run 'dev-versions' to check installed versions" -ForegroundColor White

# Usage examples
Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-wsl2-kali-kex.ps1                           # Default setup"
Write-Host "  .\install-wsl2-kali-kex.ps1 -Username 'user'          # Custom username"
Write-Host "  .\install-wsl2-kali-kex.ps1 -SkipKexSetup            # Skip Kex installation"
Write-Host "  .\install-wsl2-kali-kex.ps1 -Silent                  # Silent installation"