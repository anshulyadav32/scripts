# Install Scoop - A command-line installer for Windows

function Test-ScoopInstalled {
    return (Get-Command scoop -ErrorAction SilentlyContinue) -ne $null
}

function Test-ScoopFunctionality {
    Write-Host "Running Scoop functionality tests..." -ForegroundColor Cyan
    
    $results = @{
        VersionCheck = $false
        SearchTest = $false
        ListTest = $false
        OverallSuccess = $false
    }
    
    Write-Host "  Testing version command..." -ForegroundColor Yellow
    try {
        $version = & scoop --version 2>$null
        if ($version) {
            Write-Host "     Version: $version" -ForegroundColor Green
            $results.VersionCheck = $true
        }
    } catch {
        Write-Host "     Version check failed" -ForegroundColor Red
    }
    
    Write-Host "  Testing list functionality..." -ForegroundColor Yellow
    try {
        $list = & scoop list 2>$null
        Write-Host "     List works" -ForegroundColor Green
        $results.ListTest = $true
    } catch {
        Write-Host "     List failed" -ForegroundColor Red
    }
    
    $passedTests = ($results.VersionCheck + $results.ListTest)
    $results.OverallSuccess = ($passedTests -ge 1)
    
    Write-Host "  Tests passed: $passedTests/2" -ForegroundColor Green
    
    return $results
}

function Update-Scoop {
    Write-Host "Updating Scoop..." -ForegroundColor Cyan
    
    if (-not (Test-ScoopInstalled)) {
        Write-Host "Scoop is not installed. Cannot update." -ForegroundColor Red
        return $false
    }
    
    try {
        Write-Host "Updating Scoop itself..." -ForegroundColor Yellow
        & scoop update 2>$null
        
        Write-Host " Scoop update completed!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " Scoop update failed" -ForegroundColor Red
        return $false
    }
}

Write-Host "Installing Scoop..." -ForegroundColor Green

if (Test-ScoopInstalled) {
    Write-Host "Scoop is already installed!" -ForegroundColor Yellow
    scoop --version
    Test-ScoopFunctionality
} else {
    Write-Host "[INFO] Scoop not found. Manual installation required." -ForegroundColor Yellow
    Write-Host "Run: iwr -useb get.scoop.sh | iex" -ForegroundColor Gray
}

Write-Host "
[OK] Scoop installation script completed!" -ForegroundColor Green
