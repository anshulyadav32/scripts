# Install Cloud CLI Tools (AWS, Google Cloud, Azure)
# This script downloads and installs major cloud provider CLI tools

param(
    [switch]$InstallAWS,
    [switch]$InstallGCloud,
    [switch]$InstallAzure,
    [switch]$InstallAll,
    [switch]$Silent = $false,
    [switch]$Force = $false
)

Write-Host "Cloud CLI Tools Installation Script" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

# Set defaults if no specific tools selected
if (-not $InstallAWS -and -not $InstallGCloud -and -not $InstallAzure -and -not $InstallAll) {
    $InstallAll = $true
}

if ($InstallAll) {
    $InstallAWS = $true
    $InstallGCloud = $true
    $InstallAzure = $true
}

# Install AWS CLI
if ($InstallAWS) {
    Write-Host "`nInstalling AWS CLI..." -ForegroundColor Yellow
    
    $awsInstalled = Get-Command aws -ErrorAction SilentlyContinue
    if ($awsInstalled -and -not $Force) {
        Write-Host "AWS CLI is already installed:" -ForegroundColor Cyan
        aws --version
    } else {
        try {
            # Download AWS CLI v2 for Windows
            $awsUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"
            $awsPath = "$env:TEMP\AWSCLIV2.msi"
            
            Write-Host "Downloading AWS CLI v2..." -ForegroundColor Cyan
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $awsUrl -OutFile $awsPath -UseBasicParsing
            
            Write-Host "Installing AWS CLI..." -ForegroundColor Cyan
            if ($Silent) {
                $installArgs = "/i", $awsPath, "/quiet", "/norestart"
            } else {
                $installArgs = "/i", $awsPath, "/passive", "/norestart"
            }
            
            $process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "AWS CLI installed successfully!" -ForegroundColor Green
                
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                
                # Verify installation
                Start-Sleep -Seconds 3
                try {
                    $awsVersion = aws --version
                    Write-Host "AWS CLI version: $awsVersion" -ForegroundColor Green
                } catch {
                    Write-Host "AWS CLI installed but may need terminal restart for PATH update." -ForegroundColor Yellow
                }
            } else {
                Write-Host "AWS CLI installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            }
            
            Remove-Item $awsPath -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Failed to install AWS CLI: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Install Google Cloud CLI
if ($InstallGCloud) {
    Write-Host "`nInstalling Google Cloud CLI..." -ForegroundColor Yellow
    
    $gcloudInstalled = Get-Command gcloud -ErrorAction SilentlyContinue
    if ($gcloudInstalled -and -not $Force) {
        Write-Host "Google Cloud CLI is already installed:" -ForegroundColor Cyan
        gcloud version
    } else {
        try {
            # Download Google Cloud CLI installer
            $gcloudUrl = "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe"
            $gcloudPath = "$env:TEMP\GoogleCloudSDKInstaller.exe"
            
            Write-Host "Downloading Google Cloud SDK..." -ForegroundColor Cyan
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $gcloudUrl -OutFile $gcloudPath -UseBasicParsing
            
            Write-Host "Installing Google Cloud SDK..." -ForegroundColor Cyan
            if ($Silent) {
                # Silent installation with default components
                Start-Process -FilePath $gcloudPath -ArgumentList "/S", "/allusers", "/D=C:\Program Files\Google\Cloud SDK" -Wait
            } else {
                # Interactive installation
                Start-Process -FilePath $gcloudPath -Wait
            }
            
            Write-Host "Google Cloud CLI installed successfully!" -ForegroundColor Green
            
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Verify installation
            Start-Sleep -Seconds 3
            try {
                gcloud version
                Write-Host "Google Cloud CLI is ready!" -ForegroundColor Green
            } catch {
                Write-Host "Google Cloud CLI installed but may need terminal restart." -ForegroundColor Yellow
            }
            
            Remove-Item $gcloudPath -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Failed to install Google Cloud CLI: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Install Azure CLI
if ($InstallAzure) {
    Write-Host "`nInstalling Azure CLI..." -ForegroundColor Yellow
    
    $azInstalled = Get-Command az -ErrorAction SilentlyContinue
    if ($azInstalled -and -not $Force) {
        Write-Host "Azure CLI is already installed:" -ForegroundColor Cyan
        az version
    } else {
        try {
            # Download Azure CLI MSI installer
            $azureUrl = "https://aka.ms/installazurecliwindows"
            $azurePath = "$env:TEMP\AzureCLI.msi"
            
            Write-Host "Downloading Azure CLI..." -ForegroundColor Cyan
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $azureUrl -OutFile $azurePath -UseBasicParsing
            
            Write-Host "Installing Azure CLI..." -ForegroundColor Cyan
            if ($Silent) {
                $installArgs = "/i", $azurePath, "/quiet", "/norestart"
            } else {
                $installArgs = "/i", $azurePath, "/passive", "/norestart"
            }
            
            $process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "Azure CLI installed successfully!" -ForegroundColor Green
                
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                
                # Verify installation
                Start-Sleep -Seconds 3
                try {
                    $azVersion = az version --output table
                    Write-Host "Azure CLI is ready!" -ForegroundColor Green
                } catch {
                    Write-Host "Azure CLI installed but may need terminal restart." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Azure CLI installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            }
            
            Remove-Item $azurePath -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Failed to install Azure CLI: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Install additional cloud tools via package managers if available
Write-Host "`nInstalling additional cloud tools..." -ForegroundColor Yellow

# Check if package managers are available
$chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
$scoopInstalled = Get-Command scoop -ErrorAction SilentlyContinue

if ($chocoInstalled -or $scoopInstalled) {
    $cloudTools = @{
        "terraform" = "Infrastructure as Code tool"
        "kubectl" = "Kubernetes command-line tool"
        "helm" = "Kubernetes package manager"
        "docker" = "Container platform CLI"
    }
    
    foreach ($tool in $cloudTools.Keys) {
        try {
            $toolInstalled = Get-Command $tool -ErrorAction SilentlyContinue
            if (-not $toolInstalled) {
                Write-Host "Installing $tool ($($cloudTools[$tool]))..." -ForegroundColor Cyan
                
                if ($chocoInstalled) {
                    choco install $tool -y --limit-output
                } elseif ($scoopInstalled) {
                    scoop install $tool
                }
                
                Write-Host "  ✓ $tool installed" -ForegroundColor Green
            } else {
                Write-Host "  ✓ $tool already available" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  ✗ Failed to install $tool" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Package managers not available. Install Chocolatey or Scoop for additional tools." -ForegroundColor Yellow
}

Write-Host "`nCloud CLI Tools installation completed!" -ForegroundColor Green

# Show installation summary and setup instructions
Write-Host "`nInstallation Summary:" -ForegroundColor Cyan

if ($InstallAWS) {
    Write-Host "✓ AWS CLI v2" -ForegroundColor Green
    Write-Host "  Setup: aws configure" -ForegroundColor White
    Write-Host "  Login: aws sso login --profile myprofile" -ForegroundColor White
    Write-Host "  Test: aws sts get-caller-identity" -ForegroundColor White
}

if ($InstallGCloud) {
    Write-Host "✓ Google Cloud CLI" -ForegroundColor Green
    Write-Host "  Setup: gcloud init" -ForegroundColor White
    Write-Host "  Login: gcloud auth login" -ForegroundColor White
    Write-Host "  Test: gcloud projects list" -ForegroundColor White
}

if ($InstallAzure) {
    Write-Host "✓ Azure CLI" -ForegroundColor Green
    Write-Host "  Setup: az login" -ForegroundColor White
    Write-Host "  Config: az account set --subscription <subscription-id>" -ForegroundColor White
    Write-Host "  Test: az account show" -ForegroundColor White
}

Write-Host "`nCommon Cloud Commands:" -ForegroundColor Cyan
Write-Host "AWS CLI:" -ForegroundColor Yellow
Write-Host "  aws s3 ls                        # List S3 buckets"
Write-Host "  aws ec2 describe-instances       # List EC2 instances"
Write-Host "  aws lambda list-functions        # List Lambda functions"

Write-Host "`nGoogle Cloud CLI:" -ForegroundColor Yellow
Write-Host "  gcloud compute instances list    # List VM instances"
Write-Host "  gcloud storage ls               # List Cloud Storage buckets"
Write-Host "  gcloud functions list          # List Cloud Functions"

Write-Host "`nAzure CLI:" -ForegroundColor Yellow
Write-Host "  az vm list                      # List virtual machines"
Write-Host "  az storage account list         # List storage accounts"
Write-Host "  az functionapp list             # List function apps"

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Configure authentication for each cloud provider" -ForegroundColor White
Write-Host "2. Set up your default regions and configurations" -ForegroundColor White
Write-Host "3. Install cloud-specific extensions and plugins as needed" -ForegroundColor White

# Usage examples
Write-Host "`nScript Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\install-cloud-cli.ps1                   # Install all cloud CLIs"
Write-Host "  .\install-cloud-cli.ps1 -InstallAWS       # Install AWS CLI only"
Write-Host "  .\install-cloud-cli.ps1 -InstallGCloud    # Install Google Cloud CLI only"
Write-Host "  .\install-cloud-cli.ps1 -InstallAzure     # Install Azure CLI only"
Write-Host "  .\install-cloud-cli.ps1 -Silent           # Silent installation"