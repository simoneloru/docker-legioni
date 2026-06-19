# Setup script for Windows (PowerShell)

$ErrorActionPreference = "Stop"

$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$envFile = Join-Path $repoDir ".env"
$envExample = Join-Path $repoDir ".env.example"

if (-not (Test-Path $envFile)) {
    Write-Host "Creating .env from .env.example..." -ForegroundColor Green
    Copy-Item -Path $envExample -Destination $envFile

    $documents = Join-Path $env:USERPROFILE "Documents"
    (Get-Content $envFile) -replace 'C:\\Users\\YourName\\Documents', $documents | Set-Content $envFile

    Write-Host ".env created. Please review and update it if needed." -ForegroundColor Yellow
} else {
    Write-Host ".env already exists. Skipping." -ForegroundColor Cyan
}

Write-Host "Building Docker image..." -ForegroundColor Green
docker compose build

Write-Host "`nSetup complete. Run the container with:" -ForegroundColor Green
Write-Host "  docker compose run --rm dev" -ForegroundColor White
