$Repo = "simoneloru/docker-legioni"
$Branch = "main"
$GitHubRaw = "https://raw.githubusercontent.com/$Repo/$Branch"
$DefaultWorkspace = Join-Path $env:USERPROFILE "workspace"

# Ensure TLS 1.2 (fix for older PowerShell)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  $Repo -- setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Detect local mode
if (Test-Path "compose.yaml") {
    $Local = $true
    $Dir = "."
}
else {
    $Local = $false
    $Dir = "docker-legioni"
}

# Create directory
if (-not $Local) {
    if (Test-Path $Dir) {
        Write-Host "Directory $Dir already exists. Using it." -ForegroundColor Yellow
    }
    else {
        New-Item -ItemType Directory -Path $Dir | Out-Null
        Write-Host "Created $Dir" -ForegroundColor Green
    }
}

Set-Location $Dir

# Get workspace path
$input = Read-Host "Where are your projects? [$DefaultWorkspace]"
if ([string]::IsNullOrWhiteSpace($input)) {
    $WorkspacePath = $DefaultWorkspace
}
else {
    $WorkspacePath = $input
}
Write-Host ""

# Get compose.yaml
if ($Local) {
    Write-Host "Local mode: using existing compose.yaml" -ForegroundColor Cyan
}
else {
    Write-Host "Downloading compose.yaml..." -ForegroundColor Green
    Invoke-WebRequest -Uri "$GitHubRaw/compose.yaml" -OutFile "compose.yaml"
    Write-Host "Downloading .devcontainer/devcontainer.json..." -ForegroundColor Green
    New-Item -ItemType Directory -Path ".devcontainer" -Force | Out-Null
    Invoke-WebRequest -Uri "$GitHubRaw/.devcontainer/devcontainer.json" -OutFile ".devcontainer/devcontainer.json"
}

# Create .env
$gitName = if ($env:GIT_USER_NAME) { $env:GIT_USER_NAME } else { "Dev User" }
$gitEmail = if ($env:GIT_USER_EMAIL) { $env:GIT_USER_EMAIL } else { "dev@localhost" }
$envContent = @"
# Created by setup.ps1 -- you can edit this file later
WORKSPACE_PATH=$WorkspacePath
DOCKER_IMAGE=simoneloru/docker-legioni:latest
GIT_USER_NAME=$gitName
GIT_USER_EMAIL=$gitEmail
"@
Set-Content -Path ".env" -Value $envContent
Write-Host ".env created with WORKSPACE_PATH=$WorkspacePath" -ForegroundColor Green
Write-Host ""

# Pull image
Write-Host "Pulling Docker image..." -ForegroundColor Green
docker compose pull
Write-Host ""

# Done
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Setup complete!" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Daily use:" -ForegroundColor White
Write-Host "    cd $(Get-Location); docker compose run --rm dev" -ForegroundColor White
Write-Host ""
