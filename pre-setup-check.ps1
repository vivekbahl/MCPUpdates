# MCP Cluster Prerequisites Check
# Run this script before starting the cluster

Write-Host "🔍 Checking MCP Cluster Prerequisites..." -ForegroundColor Blue

$errors = @()
$warnings = @()

# Check Docker Desktop
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker found: $dockerVersion" -ForegroundColor Green
        
        # Check if Docker daemon is running
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker daemon is running" -ForegroundColor Green
        } else {
            $errors += "❌ Docker daemon is not running. Please start Docker Desktop."
        }
    } else {
        $errors += "❌ Docker not found. Please install Docker Desktop."
    }
} catch {
    $errors += "❌ Docker not accessible: $($_.Exception.Message)"
}

# Check Docker Compose
try {
    $composeVersion = docker-compose --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker Compose found: $composeVersion" -ForegroundColor Green
    } else {
        $errors += "❌ Docker Compose not found. Install Docker Desktop."
    }
} catch {
    $errors += "❌ Docker Compose not accessible"
}

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-Host "✅ PowerShell $($psVersion.Major).$($psVersion.Minor) found" -ForegroundColor Green
} else {
    $warnings += "⚠️  PowerShell version is old. Consider upgrading to PowerShell 7+"
}

# Check available ports
$requiredPorts = @(5173, 8811, 9090, 5432)
foreach ($port in $requiredPorts) {
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($connection) {
            $warnings += "⚠️  Port $port is already in use. May cause conflicts."
        } else {
            Write-Host "✅ Port $port is available" -ForegroundColor Green
        }
    } catch {
        Write-Host "✅ Port $port appears available" -ForegroundColor Green
    }
}

# Check available disk space (minimum 2GB)
$drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
if ($freeSpaceGB -ge 2) {
    Write-Host "✅ Disk space: ${freeSpaceGB}GB available" -ForegroundColor Green
} else {
    $errors += "❌ Insufficient disk space: ${freeSpaceGB}GB minimum 2GB required"
}

# Check available memory (minimum 4GB)
$totalMemoryGB = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
if ($totalMemoryGB -ge 4) {
    Write-Host "✅ System memory: ${totalMemoryGB}GB" -ForegroundColor Green
} else {
    $warnings += "Low system memory: ${totalMemoryGB}GB 4GB recommended"
}

# Summary
Write-Host "`n Prerequisites Summary:" -ForegroundColor Blue

if ($errors.Count -eq 0) {
    Write-Host "✅ All critical requirements met!" -ForegroundColor Green
    Write-Host "You can proceed with: .\start-cluster.ps1 -Build" -ForegroundColor Cyan
} else {
    Write-Host "❌ Critical issues found:" -ForegroundColor Red
    foreach ($serror in $errors) {
        Write-Host "   $serror" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   $warning" -ForegroundColor Yellow
    }
}

Write-Host "`n📚 Next Steps:" -ForegroundColor Blue
Write-Host "1. Fix any critical issues above" -ForegroundColor White
Write-Host "2. Run: .\start-cluster.ps1 -Build" -ForegroundColor White
Write-Host "3. Access MCP Inspector: http://localhost:5173" -ForegroundColor White 