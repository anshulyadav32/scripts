# Windows Development Tools Installation Scripts

## Overview
Complete PowerShell automation scripts for setting up comprehensive development environments on Windows, including both native Windows installations and WSL2 configurations.

## Scripts Available

### 1. install-dev-tools-windows.ps1
**Windows Native Development Environment**
- **Purpose**: Install complete development toolchain natively on Windows
- **Package Managers**: Auto-detects and uses Chocolatey, Scoop, or Winget
- **Development Tools**: Git, cURL, Wget, Python, pip, PHP, Composer, Node.js LTS, npm, CMake
- **REST Testing**: HTTPie, Postman, Insomnia, jq (JSON processor)
- **Database**: PostgreSQL with full configuration
- **Features**: Silent installation, force reinstall, selective tool skipping

### 2. install-wsl2-kali-kex.ps1
**WSL2 Kali Linux Development Environment**
- **Purpose**: Complete Kali Linux development environment with KEX desktop
- **Tools**: Node.js LTS, Python, C++ build tools, PHP, Git, development libraries
- **REST Testing**: curl, HTTPie, jq, Postman (AppImage), Insomnia (AppImage)
- **Database**: PostgreSQL with authentication and sample database
- **Desktop**: Kali KEX (XFCE desktop environment)
- **Aliases**: Comprehensive command shortcuts for development workflows

## Usage Examples

### Windows Native Installation
```powershell
# Install all development tools
.\install-dev-tools-windows.ps1

# Use specific package manager
.\install-dev-tools-windows.ps1 -PackageManager Chocolatey

# Skip specific tools
.\install-dev-tools-windows.ps1 -SkipRESTTools -SkipPostgreSQL

# Force reinstall everything
.\install-dev-tools-windows.ps1 -Force

# Silent installation (no prompts)
.\install-dev-tools-windows.ps1 -Silent
```

### WSL2 Kali Installation
```powershell
# Install WSL2 Kali with KEX and development tools
.\install-wsl2-kali-kex.ps1

# Force reinstall WSL2 components
.\install-wsl2-kali-kex.ps1 -Force

# Skip desktop environment (KEX)
.\install-wsl2-kali-kex.ps1 -SkipKEX
```

## REST API Testing Tools

### Windows Native
- **HTTPie**: `http GET api.example.com`
- **Postman**: Full GUI application
- **Insomnia**: REST client with GraphQL support
- **jq**: JSON processor for command line

### WSL2 Kali
- **curl**: `curl -X GET https://api.example.com`
- **HTTPie**: `http GET api.example.com`
- **jq**: `curl api.example.com | jq '.data'`
- **Postman**: AppImage installation
- **Insomnia**: AppImage installation

## Database Access

### PostgreSQL (Windows)
```powershell
# Connect to database
psql -U postgres -h localhost

# Start PostgreSQL service
pg_ctl -D "C:\Program Files\PostgreSQL\*\data" start
```

### PostgreSQL (WSL2 Kali)
```bash
# Connect to database
psql -U postgres -h localhost

# Start PostgreSQL service
sudo service postgresql start

# Access sample database
psql -U postgres -d devdb
```

## Cross-Platform Development Workflow

1. **Windows Native**: Direct installation, Windows PATH integration, Windows services
2. **WSL2 Kali**: Linux environment, package managers (apt), systemd services
3. **Hybrid Approach**: Use WSL2 for Linux-specific development, Windows for GUI applications

## Tool Verification

Both scripts include comprehensive verification:
- Version checks for all installed tools
- Green checkmarks for successful installations
- Red X marks for missing or failed installations
- Environment variable validation

## Prerequisites

- Windows 10 version 2004+ or Windows 11
- Administrative privileges
- Internet connection
- For WSL2: Virtualization enabled in BIOS

## Features

### Multi-Package Manager Support
- **Chocolatey**: Windows package manager
- **Scoop**: Command-line installer for Windows
- **Winget**: Microsoft's official package manager
- **Fallback**: Manual installation if package managers fail

### Error Handling
- Graceful fallbacks for failed installations
- Comprehensive logging and status reporting
- Silent installation options for automation
- Force reinstall capabilities

### Customization Options
- Selective tool installation/skipping
- Package manager preferences
- Silent vs interactive modes
- Development environment profiles

This comprehensive setup provides equivalent functionality across both Windows native and WSL2 environments, ensuring developers can work effectively in their preferred platform while maintaining tool consistency.