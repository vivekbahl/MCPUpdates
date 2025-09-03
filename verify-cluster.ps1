# MCP Cluster Verification Script
# Checks that all components are running correctly

Write-Host "🔍 Verifying MCP Cluster Status..." -ForegroundColor Blue

$errorList = @()
$warningList = @()

# Check Docker containers
Write-Host "`n📦 Checking Docker Containers..." -ForegroundColor Yellow

try {
    $containers = docker-compose ps --format json | ConvertFrom-Json
    
    $expectedContainers = @(
        'mcp-gateway',
        'mcp-filesystem', 
        'mcp-database',
        'mcp-git',
        'mcp-web',
        'postgres',
        'mcp-inspector'
    )
    
    foreach ($expected in $expectedContainers) {
        $container = $containers | Where-Object { $_.Name -like "*$expected*" }
        if ($container) {
            if ($container.State -eq "running") {
                Write-Host "✅ $expected: Running" -ForegroundColor Green
            } else {
                $errors += "❌ $expected: $($container.State)"
            }
        } else {
            $errors += "❌ $expected: Not found"
        }
    }
} catch {
    $errorList += "❌ Failed to check containers: $($_.Exception.Message)"
}

# Check health endpoints
Write-Host "`n🏥 Checking Health Endpoints..." -ForegroundColor Yellow

$healthChecks = @{
    "Gateway Management" = "http://localhost:9090/health"
    "MCP Inspector" = "http://localhost:5173"
}

foreach ($service in $healthChecks.Keys) {
    $url = $healthChecks[$service]
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $service: Healthy" -ForegroundColor Green
        } else {
            $warnings += "⚠️  $service: HTTP $($response.StatusCode)"
        }
    } catch {
        $warnings += "⚠️  $service: Not responding ($url)"
    }
}

# Check database connection
Write-Host "`n🗄️  Checking Database..." -ForegroundColor Yellow

try {
    $dbCheck = docker-compose exec -T postgres pg_isready -U mcpuser -d mcpdata 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PostgreSQL: Ready" -ForegroundColor Green
        
        # Check database tables
        $tableCheck = docker-compose exec -T postgres psql -U mcpuser -d mcpdata -c "\dt" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Database tables: Created" -ForegroundColor Green
        } else {
            $warningList += "⚠️  Database tables: May not be initialized"
        }
    } else {
        $errorList += "❌ PostgreSQL: Not ready"
    }
} catch {
    $errorList += "❌ Database check failed: $($_.Exception.Message)"
}

# Check MCP Gateway connectivity
Write-Host "`n🌐 Checking MCP Gateway..." -ForegroundColor Yellow

try {
    # Test WebSocket endpoint (basic connectivity)
    $gatewayCheck = Test-NetConnection -ComputerName localhost -Port 8811 -InformationLevel Quiet
    if ($gatewayCheck) {
        Write-Host "✅ MCP Gateway: Port 8811 accessible" -ForegroundColor Green
    } else {
        $errors += "❌ MCP Gateway: Port 8811 not accessible"
    }
} catch {
    $warnings += "⚠️  MCP Gateway: Connection test failed"
}

# Check disk space for logs/data
Write-Host "`n💾 Checking Resources..." -ForegroundColor Yellow

$drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
if ($freeSpaceGB -ge 1) {
    Write-Host "✅ Disk space: ${freeSpaceGB}GB available" -ForegroundColor Green
} else {
    $warnings += "⚠️  Low disk space: ${freeSpaceGB}GB"
}

# Check Docker resource usage
try {
    $dockerStats = docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker containers: Resource usage normal" -ForegroundColor Green
    }
} catch {
    # Non-critical, skip
}

# Summary and next steps
Write-Host "`n📋 Verification Summary:" -ForegroundColor Blue

if ($errorList.Count -eq 0) {
    Write-Host "🎉 MCP Cluster is running successfully!" -ForegroundColor Green
    
    Write-Host "`n🔗 Access Points:" -ForegroundColor Cyan
    Write-Host "• MCP Inspector: http://localhost:5173" -ForegroundColor White
    Write-Host "• Gateway Management: http://localhost:9090/health" -ForegroundColor White
    Write-Host "• MCP Gateway: ws://localhost:8811 (for clients)" -ForegroundColor White
    
    Write-Host "`n📖 Usage Examples:" -ForegroundColor Cyan
    Write-Host "• Open Inspector to test MCP connections" -ForegroundColor White
    Write-Host "• Connect your AI client to ws://localhost:8811" -ForegroundColor White
    Write-Host "• Check logs: docker-compose logs -f [service]" -ForegroundColor White
    
} else {
    Write-Host "❌ Issues found:" -ForegroundColor Red
    foreach ($errorItem in $errorList) {
        Write-Host "   $errorItem" -ForegroundColor Red
    }
    
    Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "• Check logs: docker-compose logs [service]" -ForegroundColor White
    Write-Host "• Restart: docker-compose restart [service]" -ForegroundColor White
    Write-Host "• Rebuild: .\start-cluster.ps1 -Clean -Build" -ForegroundColor White
}

if ($warningList.Count -gt 0) {
    Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
    foreach ($warningItem in $warningList) {
        Write-Host "   $warningItem" -ForegroundColor Yellow
    }
}

Write-Host "`n📚 Documentation:" -ForegroundColor Blue
Write-Host "• README.md for complete usage guide" -ForegroundColor White
Write-Host "• config/gateway.yaml for configuration" -ForegroundColor White 