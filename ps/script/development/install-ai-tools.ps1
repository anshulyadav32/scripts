# Install AI CLI Tools (Codex and Gemini CLI)
# This script installs AI-powered command line interfaces

param(
    [switch]$InstallCodex,
    [switch]$InstallGemini,
    [switch]$InstallOpenAI,
    [switch]$InstallAll,
    [switch]$Silent = $false,
    [switch]$Force = $false
)

Write-Host "AI CLI Tools Installation Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Set defaults if no specific tools selected
if (-not $InstallCodex -and -not $InstallGemini -and -not $InstallOpenAI -and -not $InstallAll) {
    $InstallAll = $true
}

if ($InstallAll) {
    $InstallCodex = $true
    $InstallGemini = $true
    $InstallOpenAI = $true
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check if Node.js is available (required for some AI tools)
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
$npmInstalled = Get-Command npm -ErrorAction SilentlyContinue

if (-not $nodeInstalled -or -not $npmInstalled) {
    Write-Host "Node.js and npm are required for AI CLI tools." -ForegroundColor Red
    Write-Host "Please install Node.js first using .\install-nodejs.ps1" -ForegroundColor Yellow
    exit 1
}

# Check if Python is available (required for some AI tools)
$pythonInstalled = Get-Command python -ErrorAction SilentlyContinue
$pipInstalled = Get-Command pip -ErrorAction SilentlyContinue

if (-not $pythonInstalled -or -not $pipInstalled) {
    Write-Host "Python and pip are required for some AI CLI tools." -ForegroundColor Yellow
    Write-Host "Consider installing Python using .\install-python.ps1" -ForegroundColor Cyan
}

# Install OpenAI CLI (official OpenAI command line interface)
if ($InstallOpenAI) {
    Write-Host "`nInstalling OpenAI CLI..." -ForegroundColor Yellow
    
    try {
        # Check if already installed
        $openaiInstalled = Get-Command openai -ErrorAction SilentlyContinue
        if ($openaiInstalled -and -not $Force) {
            Write-Host "OpenAI CLI is already installed. Use -Force to reinstall." -ForegroundColor Cyan
        } else {
            # Install OpenAI Python package which includes CLI
            Write-Host "Installing OpenAI Python package with CLI..." -ForegroundColor Cyan
            pip install openai --upgrade
            
            # Also install the newer openai CLI tool if available
            pip install openai-cli --upgrade 2>$null
            
            Write-Host "OpenAI CLI installed successfully!" -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to install OpenAI CLI: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Install GitHub Copilot CLI (if available)
if ($InstallCodex) {
    Write-Host "`nInstalling GitHub Copilot CLI..." -ForegroundColor Yellow
    
    try {
        # Check if GitHub CLI is installed first (required for Copilot CLI)
        $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
        if (-not $ghInstalled) {
            Write-Host "GitHub CLI is required for Copilot CLI. Installing GitHub CLI first..." -ForegroundColor Yellow
            
            # Install GitHub CLI via npm as fallback
            npm install -g @github/gh
            
            # Or suggest using the dedicated script
            Write-Host "For better GitHub CLI installation, use .\install-gh.ps1" -ForegroundColor Cyan
        }
        
        # Install Copilot CLI extension
        Write-Host "Installing GitHub Copilot CLI extension..." -ForegroundColor Cyan
        gh extension install github/gh-copilot
        
        Write-Host "GitHub Copilot CLI installed successfully!" -ForegroundColor Green
        Write-Host "Usage: gh copilot suggest 'your query'" -ForegroundColor Cyan
        
    } catch {
        Write-Host "Failed to install GitHub Copilot CLI: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Note: Copilot CLI requires GitHub Copilot subscription." -ForegroundColor Yellow
    }
}

# Install Google Gemini CLI (using Google AI CLI)
if ($InstallGemini) {
    Write-Host "`nInstalling Google Gemini CLI..." -ForegroundColor Yellow
    
    try {
        # Install Google Generative AI CLI
        Write-Host "Installing Google Generative AI Python package..." -ForegroundColor Cyan
        pip install google-generativeai --upgrade
        
        # Install additional AI CLI tools
        Write-Host "Installing AI CLI utilities..." -ForegroundColor Cyan
        pip install aicli --upgrade 2>$null
        
        # Install Google Cloud CLI AI components (if gcloud is available)
        $gcloudInstalled = Get-Command gcloud -ErrorAction SilentlyContinue
        if ($gcloudInstalled) {
            Write-Host "Installing Google Cloud AI components..." -ForegroundColor Cyan
            gcloud components install alpha beta --quiet 2>$null
        }
        
        Write-Host "Google Gemini CLI tools installed successfully!" -ForegroundColor Green
        
    } catch {
        Write-Host "Failed to install Gemini CLI: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Install additional AI CLI tools
Write-Host "`nInstalling additional AI CLI utilities..." -ForegroundColor Yellow

$additionalTools = @{
    "anthropic" = "Anthropic Claude CLI"
    "langchain-cli" = "LangChain CLI"
    "transformers" = "Hugging Face Transformers"
    "ollama" = "Ollama local AI models"
}

foreach ($tool in $additionalTools.Keys) {
    try {
        Write-Host "Installing $($additionalTools[$tool])..." -ForegroundColor Cyan
        
        switch ($tool) {
            "anthropic" {
                pip install anthropic --upgrade --quiet
            }
            "langchain-cli" {
                pip install langchain-cli --upgrade --quiet
            }
            "transformers" {
                pip install transformers --upgrade --quiet
            }
            "ollama" {
                # Ollama requires special installation
                $ollamaUrl = "https://ollama.ai/download/windows"
                Write-Host "  Note: Ollama requires manual installation from $ollamaUrl" -ForegroundColor Yellow
            }
        }
        
        if ($tool -ne "ollama") {
            Write-Host "  ✓ $($additionalTools[$tool]) installed" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ✗ Failed to install $($additionalTools[$tool])" -ForegroundColor Red
    }
}

# Create AI CLI usage script
Write-Host "`nCreating AI CLI helper script..." -ForegroundColor Yellow
$aiHelperScript = @"
#!/bin/bash
# AI CLI Helper Script - Quick access to AI tools

echo "AI CLI Tools Available:"
echo "======================"

# Check OpenAI CLI
if command -v openai &> /dev/null; then
    echo "✓ OpenAI CLI: openai <command>"
    echo "  Example: openai api completions.create -m text-davinci-003 -p 'Hello world'"
fi

# Check GitHub Copilot CLI
if command -v gh &> /dev/null && gh extension list | grep -q copilot; then
    echo "✓ GitHub Copilot CLI: gh copilot"
    echo "  Examples:"
    echo "    gh copilot suggest 'install git on ubuntu'"
    echo "    gh copilot explain 'git reset --hard HEAD~1'"
fi

# Check Python AI packages
if command -v python &> /dev/null; then
    echo "✓ Python AI packages available:"
    python -c "import google.generativeai; print('  - Google Gemini API')" 2>/dev/null
    python -c "import anthropic; print('  - Anthropic Claude API')" 2>/dev/null
    python -c "import openai; print('  - OpenAI Python API')" 2>/dev/null
    python -c "import transformers; print('  - Hugging Face Transformers')" 2>/dev/null
fi

echo ""
echo "Usage Examples:"
echo "==============="
echo "# OpenAI API (requires API key)"
echo "export OPENAI_API_KEY='your-api-key'"
echo "openai api chat.completions.create -m gpt-3.5-turbo --messages '[{\"role\":\"user\",\"content\":\"Hello!\"}]'"
echo ""
echo "# GitHub Copilot (requires subscription)"
echo "gh copilot suggest 'how to reverse a list in python'"
echo "gh copilot explain 'git rebase -i HEAD~3'"
echo ""
echo "# Google Gemini (requires API key)"
echo "python -c \"import google.generativeai as genai; genai.configure(api_key='your-key'); model = genai.GenerativeModel('gemini-pro'); response = model.generate_content('Hello'); print(response.text)\""
"@

$aiHelperPath = "$env:USERPROFILE\.ai-cli-helper.sh"
$aiHelperScript | Out-File -FilePath $aiHelperPath -Encoding UTF8

Write-Host "AI CLI installation completed!" -ForegroundColor Green

# Show installation summary
Write-Host "`nInstallation Summary:" -ForegroundColor Cyan

if ($InstallOpenAI) {
    Write-Host "✓ OpenAI CLI and Python API" -ForegroundColor Green
    Write-Host "  Setup: Set OPENAI_API_KEY environment variable" -ForegroundColor White
    Write-Host "  Usage: openai api --help" -ForegroundColor White
}

if ($InstallCodex) {
    Write-Host "✓ GitHub Copilot CLI" -ForegroundColor Green
    Write-Host "  Usage: gh copilot suggest 'your query'" -ForegroundColor White
    Write-Host "  Usage: gh copilot explain 'code or command'" -ForegroundColor White
}

if ($InstallGemini) {
    Write-Host "✓ Google Gemini API tools" -ForegroundColor Green
    Write-Host "  Setup: Get API key from https://makersuite.google.com/app/apikey" -ForegroundColor White
    Write-Host "  Usage: Use google.generativeai Python package" -ForegroundColor White
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Get API keys for the services you want to use:" -ForegroundColor White
Write-Host "   • OpenAI: https://platform.openai.com/api-keys" -ForegroundColor White
Write-Host "   • Google Gemini: https://makersuite.google.com/app/apikey" -ForegroundColor White
Write-Host "   • Anthropic: https://console.anthropic.com/" -ForegroundColor White
Write-Host "2. Set environment variables for your API keys" -ForegroundColor White
Write-Host "3. Use AI CLI helper: type '$aiHelperPath' for usage examples" -ForegroundColor White

# Usage examples
Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-ai-tools.ps1                    # Install all AI tools"
Write-Host "  .\install-ai-tools.ps1 -InstallOpenAI     # Install OpenAI CLI only"
Write-Host "  .\install-ai-tools.ps1 -InstallGemini     # Install Gemini tools only"
Write-Host "  .\install-ai-tools.ps1 -InstallCodex      # Install Copilot CLI only"
Write-Host "  .\install-ai-tools.ps1 -Silent            # Silent installation"