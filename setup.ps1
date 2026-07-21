$ErrorActionPreference = "Stop"

if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
}

docker compose up -d --build
docker compose ps

Write-Host "CodeArea executor is starting on port 2000. Runtime installation may take several minutes."
