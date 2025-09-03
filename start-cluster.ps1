# MCP Cluster Startup Script for Windows
# This script starts the local MCP cluster with proper configuration

param(
    [switch]$Build,
    [switch]$Clean,
    [string]$Profile = "development"
)

Write-Host "Starting MCP Cluster..." -ForegroundColor Green

# Set environment variables
$env:COMPOSE_PROJECT_NAME = "mcp-cluster"
$env:DOCKER_BUILDKIT = "1"

try {
    # Check if Docker is running
    docker version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running. Please start Docker Desktop first."
    }

    # Clean up if requested
    if ($Clean) {
        Write-Host "Cleaning up existing containers and volumes..." -ForegroundColor Yellow
        docker-compose -f docker-compose.yml down -v --remove-orphans
        docker system prune -f
    }

    # Build containers if requested or if they don't exist
    if ($Build) {
        Write-Host "Building MCP containers..." -ForegroundColor Blue
        docker-compose -f docker-compose.yml build --no-cache
    }

    # Check if .env file exists
    if (-not (Test-Path ".env")) {
        Write-Host "Creating .env file from .env.example..." -ForegroundColor Yellow
        Copy-Item ".env.example" ".env"
        Write-Host "Please edit .env file with your actual configuration values" -ForegroundColor Red
    }

    # Create workspace directory if it doesn't exist
    if (-not (Test-Path "workspace")) {
        New-Item -ItemType Directory -Path "workspace" -Force | Out-Null
        Write-Host "Created workspace directory" -ForegroundColor Green
    }

    # Start the cluster
    Write-Host "Starting MCP cluster containers..." -ForegroundColor Blue
    docker-compose -f docker-compose.yml up -d

    # Wait for services to be ready
    Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    # Check service health
    Write-Host "`nService Status:" -ForegroundColor Green
    docker-compose -f docker-compose.yml ps

    # Display access information
    Write-Host "`n=== MCP Cluster Ready ===" -ForegroundColor Green
    Write-Host "MCP Gateway: http://localhost:8811" -ForegroundColor Cyan
    Write-Host "Gateway Management: http://localhost:9090" -ForegroundColor Cyan
    Write-Host "MCP Inspector: http://localhost:5173" -ForegroundColor Cyan
    Write-Host "`nLogs: docker-compose logs -f [service-name]" -ForegroundColor Yellow
    Write-Host "Stop: docker-compose down" -ForegroundColor Yellow
    Write-Host "Rebuild: .\start-cluster.ps1 -Build" -ForegroundColor Yellow

} catch {
    Write-Host "Error starting MCP cluster: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 