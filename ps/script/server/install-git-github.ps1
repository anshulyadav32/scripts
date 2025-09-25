# Install Git and GitHub CLI - Version Control and GitHub Integration

function Test-GitInstalled {
    $installed = $false
    
    try {
        $gitVersion = git --version 2>$null
        if ($gitVersion) {
            Write-Host "Git found: $gitVersion" -ForegroundColor Green
            $installed = $true
        }
    } catch {
        Write-Host "Git not found in PATH" -ForegroundColor Yellow
    }
    
    return $installed
}

function Test-GitHubCLIInstalled {
    $installed = $false
    
    try {
        $ghVersion = gh --version 2>$null
        if ($ghVersion) {
            Write-Host "GitHub CLI found: $($ghVersion.Split("`n")[0])" -ForegroundColor Green
            $installed = $true
        }
    } catch {
        Write-Host "GitHub CLI not found in PATH" -ForegroundColor Yellow
    }
    
    return $installed
}

function Test-GitFunctionality {
    Write-Host "Running Git functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        GitTest = $false
        ConfigTest = $false
        GHTest = $false
        AuthTest = $false
        OverallSuccess = $false
    }
    
    Write-Host "  Testing Git..." -ForegroundColor Yellow
    try {
        $gitVersion = git --version 2>$null
        if ($gitVersion) {
            Write-Host "     Git version: $gitVersion" -ForegroundColor Green
            $results.GitTest = $true
        }
    } catch {
        Write-Host "     Git test failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing Git configuration..." -ForegroundColor Yellow
    try {
        $gitUser = git config --global user.name 2>$null
        $gitEmail = git config --global user.email 2>$null
        
        if ($gitUser -and $gitEmail) {
            Write-Host "     Git configured: $gitUser <$gitEmail>" -ForegroundColor Green
            $results.ConfigTest = $true
        } else {
            Write-Host "     Git not configured (user/email missing)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "     Git config test failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing GitHub CLI..." -ForegroundColor Yellow
    try {
        $ghVersion = gh --version 2>$null
        if ($ghVersion) {
            Write-Host "     GitHub CLI available" -ForegroundColor Green
            $results.GHTest = $true
        }
    } catch {
        Write-Host "     GitHub CLI test failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing GitHub CLI authentication..." -ForegroundColor Yellow
    if ($results.GHTest) {
        try {
            $authStatus = gh auth status 2>$null
            if ($authStatus) {
                Write-Host "     GitHub CLI authenticated" -ForegroundColor Green
                $results.AuthTest = $true
            } else {
                Write-Host "     GitHub CLI not authenticated" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "     GitHub CLI auth not configured" -ForegroundColor Yellow
        }
    }
    
    $passedTests = ($results.GitTest + $results.ConfigTest + $results.GHTest + $results.AuthTest)
    $results.OverallSuccess = ($passedTests -ge 2)
    
    Write-Host "  Tests passed: $passedTests/4" -ForegroundColor Green
    
    return $results
}

function Update-Git {
    Write-Host "Updating Git and GitHub CLI..." -ForegroundColor Cyan
    
    $updated = $false
    
    try {
        # Try to update via Chocolatey if available
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Attempting to update via Chocolatey..." -ForegroundColor Yellow
            choco upgrade git -y
            choco upgrade gh -y
            $updated = $true
        }
        
        # Try WinGet update
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Attempting to update via WinGet..." -ForegroundColor Yellow
            winget upgrade Git.Git
            winget upgrade GitHub.cli
            $updated = $true
        }
        
        if (-not $updated) {
            Write-Host "For Git updates:" -ForegroundColor Yellow
            Write-Host "  1. Download latest from https://git-scm.com/" -ForegroundColor White
            Write-Host "  2. GitHub CLI: https://cli.github.com/" -ForegroundColor White
        }
        
        return $updated
        
    } catch {
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-GitPackageManager {
    Write-Host "Installing Git..." -ForegroundColor Cyan
    
    $installSuccess = $false
    
    # Method 1: Try Chocolatey first
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing via Chocolatey..." -ForegroundColor Yellow
        try {
            # Install Git
            choco install git -y
            $installSuccess = $true
            Write-Host "Git installed successfully via Chocolatey!" -ForegroundColor Green
        } catch {
            Write-Host "Chocolatey Git installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Method 2: Try WinGet if Chocolatey failed
    if (-not $installSuccess -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Installing via WinGet..." -ForegroundColor Yellow
        try {
            winget install --id Git.Git --source winget
            $installSuccess = $true
            Write-Host "Git installed successfully via WinGet!" -ForegroundColor Green
        } catch {
            Write-Host "WinGet installation failed, providing manual installation guidance..." -ForegroundColor Yellow
        }
    }
    
    return $installSuccess
}

function Install-GitHubCLIPackageManager {
    Write-Host "Installing GitHub CLI..." -ForegroundColor Cyan
    
    $installSuccess = $false
    
    # Method 1: Try Chocolatey first
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing GitHub CLI via Chocolatey..." -ForegroundColor Yellow
        try {
            choco install gh -y
            $installSuccess = $true
            Write-Host "GitHub CLI installed successfully via Chocolatey!" -ForegroundColor Green
        } catch {
            Write-Host "Chocolatey GitHub CLI installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Method 2: Try WinGet if Chocolatey failed
    if (-not $installSuccess -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Installing GitHub CLI via WinGet..." -ForegroundColor Yellow
        try {
            winget install --id GitHub.cli --source winget
            $installSuccess = $true
            Write-Host "GitHub CLI installed successfully via WinGet!" -ForegroundColor Green
        } catch {
            Write-Host "WinGet GitHub CLI installation failed..." -ForegroundColor Yellow
        }
    }
    
    return $installSuccess
}

function Configure-Git {
    Write-Host "Configuring Git..." -ForegroundColor Cyan
    
    try {
        # Check if Git is already configured
        $gitUser = git config --global user.name 2>$null
        $gitEmail = git config --global user.email 2>$null
        
        if (-not $gitUser -or -not $gitEmail) {
            Write-Host "Git user configuration needed..." -ForegroundColor Yellow
            Write-Host "You'll need to configure Git with your details:" -ForegroundColor Cyan
            Write-Host "  git config --global user.name `"Your Name`"" -ForegroundColor White
            Write-Host "  git config --global user.email `"your.email@example.com`"" -ForegroundColor White
        } else {
            Write-Host "Git already configured for: $gitUser <$gitEmail>" -ForegroundColor Green
        }
        
        # Set up useful Git configurations
        Write-Host "Setting up useful Git configurations..." -ForegroundColor Yellow
        
        # Set default branch name
        git config --global init.defaultBranch main
        
        # Set up better diff and merge tools
        git config --global diff.tool vimdiff
        git config --global merge.tool vimdiff
        
        # Enable color output
        git config --global color.ui auto
        
        # Set up useful aliases
        git config --global alias.st status
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.cm commit
        git config --global alias.lg "log --oneline --graph --decorate --all"
        
        # Set up line ending handling for Windows
        git config --global core.autocrlf true
        git config --global core.safecrlf warn
        
        Write-Host "Git configuration completed!" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "Git configuration failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Show-GitUsageInfo {
    Write-Host "`n=== Git & GitHub CLI Usage Guide ===" -ForegroundColor Magenta
    
    Write-Host "Basic Git Commands:" -ForegroundColor Yellow
    Write-Host "  git init                    # Initialize repository" -ForegroundColor White
    Write-Host "  git clone <url>             # Clone repository" -ForegroundColor White
    Write-Host "  git add .                   # Stage all changes" -ForegroundColor White
    Write-Host "  git commit -m 'message'     # Commit changes" -ForegroundColor White
    Write-Host "  git push                    # Push to remote" -ForegroundColor White
    Write-Host "  git pull                    # Pull from remote" -ForegroundColor White
    Write-Host "  git status                  # Check status" -ForegroundColor White
    Write-Host "  git log                     # View commit history" -ForegroundColor White
    
    Write-Host "`nBranching:" -ForegroundColor Yellow
    Write-Host "  git branch                  # List branches" -ForegroundColor White
    Write-Host "  git branch <name>           # Create branch" -ForegroundColor White
    Write-Host "  git checkout <branch>       # Switch branch" -ForegroundColor White
    Write-Host "  git checkout -b <branch>    # Create and switch" -ForegroundColor White
    Write-Host "  git merge <branch>          # Merge branch" -ForegroundColor White
    Write-Host "  git branch -d <branch>      # Delete branch" -ForegroundColor White
    
    Write-Host "`nGitHub CLI Commands:" -ForegroundColor Yellow
    Write-Host "  gh auth login               # Authenticate with GitHub" -ForegroundColor White
    Write-Host "  gh repo create              # Create repository" -ForegroundColor White
    Write-Host "  gh repo clone <repo>        # Clone repository" -ForegroundColor White
    Write-Host "  gh pr create                # Create pull request" -ForegroundColor White
    Write-Host "  gh pr list                  # List pull requests" -ForegroundColor White
    Write-Host "  gh issue create             # Create issue" -ForegroundColor White
    Write-Host "  gh issue list               # List issues" -ForegroundColor White
    Write-Host "  gh repo view                # View repository" -ForegroundColor White
    
    Write-Host "`nUseful Git Aliases (Configured):" -ForegroundColor Yellow
    Write-Host "  git st                      # git status" -ForegroundColor White
    Write-Host "  git co                      # git checkout" -ForegroundColor White
    Write-Host "  git br                      # git branch" -ForegroundColor White
    Write-Host "  git cm                      # git commit" -ForegroundColor White
    Write-Host "  git lg                      # pretty log graph" -ForegroundColor White
    
    Write-Host "`nConfiguration:" -ForegroundColor Yellow
    Write-Host "  git config --global user.name 'Your Name'" -ForegroundColor White
    Write-Host "  git config --global user.email 'email@example.com'" -ForegroundColor White
    Write-Host "  git config --list           # View all config" -ForegroundColor White
    
    Write-Host "`nGitHub CLI Authentication:" -ForegroundColor Yellow
    Write-Host "  1. Run: gh auth login" -ForegroundColor White
    Write-Host "  2. Choose authentication method" -ForegroundColor White
    Write-Host "  3. Follow browser/token instructions" -ForegroundColor White
    Write-Host "  4. Test with: gh auth status" -ForegroundColor White
    
    Write-Host "`nBest Practices:" -ForegroundColor Yellow
    Write-Host "  • Write meaningful commit messages" -ForegroundColor White
    Write-Host "  • Use .gitignore for unwanted files" -ForegroundColor White
    Write-Host "  • Create branches for features" -ForegroundColor White
    Write-Host "  • Pull before pushing" -ForegroundColor White
    Write-Host "  • Review changes before committing" -ForegroundColor White
    
    Write-Host "`nCommon .gitignore entries:" -ForegroundColor Yellow
    Write-Host "  node_modules/               # Node.js dependencies" -ForegroundColor White
    Write-Host "  __pycache__/                # Python cache" -ForegroundColor White
    Write-Host "  *.pyc                       # Python compiled" -ForegroundColor White
    Write-Host "  .env                        # Environment variables" -ForegroundColor White
    Write-Host "  .vscode/                    # VS Code settings" -ForegroundColor White
    Write-Host "  *.log                       # Log files" -ForegroundColor White
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git & GitHub CLI Installation Script" -ForegroundColor Cyan
Write-Host "Version Control + GitHub Integration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$gitInstalled = Test-GitInstalled
$ghInstalled = Test-GitHubCLIInstalled

if ($gitInstalled -and $ghInstalled) {
    Write-Host "Git and GitHub CLI are already installed!" -ForegroundColor Green
    
    # Test functionality
    $testResults = Test-GitFunctionality
    
    if ($testResults.OverallSuccess) {
        Write-Host "`n[SUCCESS] Git and GitHub CLI are working correctly!" -ForegroundColor Green
    } else {
        Write-Host "`n[WARNING] Git/GitHub CLI may need additional configuration." -ForegroundColor Yellow
        
        if (-not $testResults.ConfigTest) {
            Write-Host "  • Git user/email not configured" -ForegroundColor Yellow
        }
        if (-not $testResults.AuthTest) {
            Write-Host "  • GitHub CLI not authenticated" -ForegroundColor Yellow
        }
    }
    
    Configure-Git
    Show-GitUsageInfo
} else {
    Write-Host "Installing Git and GitHub CLI..." -ForegroundColor Yellow
    
    $gitSuccess = $true
    $ghSuccess = $true
    
    # Install Git if not present
    if (-not $gitInstalled) {
        $gitSuccess = Install-GitPackageManager
        if ($gitSuccess) {
            Write-Host "[SUCCESS] Git installation completed!" -ForegroundColor Green
        }
    }
    
    # Install GitHub CLI if not present
    if (-not $ghInstalled) {
        $ghSuccess = Install-GitHubCLIPackageManager
        if ($ghSuccess) {
            Write-Host "[SUCCESS] GitHub CLI installation completed!" -ForegroundColor Green
        }
    }
    
    if ($gitSuccess -and $ghSuccess) {
        Write-Host "`n[SUCCESS] All installations completed!" -ForegroundColor Green
        
        # Test the installation
        Start-Sleep -Seconds 5
        $testResults = Test-GitFunctionality
        
        if ($testResults.OverallSuccess) {
            Write-Host "[SUCCESS] Installation verified successfully!" -ForegroundColor Green
        }
        
        Configure-Git
        Show-GitUsageInfo
    } else {
        Write-Host "`n[INFO] Some installations may need manual completion." -ForegroundColor Yellow
        
        if (-not $gitSuccess) {
            Write-Host "Manual Git installation: https://git-scm.com/download/windows" -ForegroundColor Yellow
        }
        
        if (-not $ghSuccess) {
            Write-Host "Manual GitHub CLI installation: https://cli.github.com/" -ForegroundColor Yellow
        }
        
        Show-GitUsageInfo
    }
}

Write-Host "`n[OK] Git & GitHub CLI installation script completed!" -ForegroundColor Green