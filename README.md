# MCP Local Cluster Setup

A secure, containerized local cluster for Model Context Protocol (MCP) development and testing.

## Overview

This setup provides a complete MCP environment with:
- **MCP Gateway**: Central security proxy with threat detection
- **Multiple MCP Servers**: Filesystem, Database, Git, and Web services
- **PostgreSQL Database**: For data persistence and testing
- **MCP Inspector**: Web-based debugging interface
- **Security Controls**: Container isolation, secrets management, and threat detection

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    MCP Cluster                          │
├─────────────────┬───────────────────────────────────────┤
│  MCP Gateway    │  ┌─────────────────────────────────┐  │
│  (Port 8811)    │  │        MCP Servers              │  │
│                 │  │  ┌─────────┐ ┌─────────────┐    │  │
│  ┌─────────────┐│  │  │Filesystem│ │   Database  │    │  │
│  │ Security    ││  │  │         │ │             │    │  │
│  │ Threat Det. ││  │  └─────────┘ └─────────────┘    │  │
│  │ Rate Limit  ││  │  ┌─────────┐ ┌─────────────┐    │  │
│  │ Auth        ││  │  │   Git   │ │     Web     │    │  │
│  └─────────────┘│  │  │         │ │             │    │  │
│                 │  │  └─────────┘ └─────────────┘    │  │
└─────────────────┴───┴─────────────────────────────────┴──┘
         │                          │
         ▼                          ▼
  ┌─────────────┐           ┌──────────────┐
  │MCP Inspector│           │ PostgreSQL   │
  │(Port 5173)  │           │ Database     │
  └─────────────┘           └──────────────┘
```

## Quick Start

### Prerequisites

- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- PowerShell (Windows) or Bash (Linux/Mac)
- 4GB+ available memory
- Ports 5173, 8811, 9090 available

### Windows Setup

1. **Clone or Download** this repository to `C:\vbahl\MCPSetup`

2. **Start the Cluster**:
   ```powershell
   .\start-cluster.ps1 -Build
   ```

3. **Access Services**:
   - MCP Gateway: http://localhost:8811
   - Inspector UI: http://localhost:5173
   - Management: http://localhost:9090

### Linux/Mac Setup

1. **Make scripts executable**:
   ```bash
   chmod +x start-cluster.sh
   ```

2. **Start the cluster**:
   ```bash
   ./start-cluster.sh --build
   ```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```env
# Gateway Configuration
GATEWAY_PORT=8811
MANAGEMENT_PORT=9090
LOG_LEVEL=info

# Database
POSTGRES_PASSWORD=your_secure_password

# API Keys (store in secrets/ directory)
GITHUB_TOKEN=your_token
SLACK_BOT_TOKEN=your_token
```

### Gateway Configuration

Edit `config/gateway.yaml` to:
- Enable/disable specific servers
- Configure security policies
- Set rate limits and resource constraints
- Define threat detection rules

### Secrets Management

Store sensitive data in the `secrets/` directory:
```
secrets/
├── db_password.txt
├── github-token.txt
├── slack-token.txt
└── api-keys/
    ├── openai.key
    └── other-services.key
```

## Services

### MCP Gateway (Port 8811)

The central security proxy that:
- Routes MCP messages between clients and servers
- Implements threat detection (Tool Poisoning, MCP Rug Pull, Shadowing)
- Enforces rate limiting and access controls
- Provides centralized logging and monitoring

**Key Features:**
- JSON-RPC 2.0 compliant
- WebSocket and HTTP support
- Real-time threat detection
- Session management
- Security audit logging

### MCP Servers

#### Filesystem Server
- **Purpose**: File operations within allowed directories
- **Security**: Path restrictions, size limits, read/write controls
- **Tools**: `read_file`, `write_file`, `list_directory`, `create_directory`

#### Database Server  
- **Purpose**: PostgreSQL database operations
- **Security**: Query validation, operation restrictions, connection pooling
- **Tools**: `query`, `insert`, `update`, `get_schema`

#### Git Server
- **Purpose**: Git repository operations
- **Security**: Safe directory restrictions, operation allowlists
- **Tools**: `git_status`, `git_diff`, `git_commit`, `git_log`

#### Web Server
- **Purpose**: HTTP API interactions
- **Security**: Domain allowlists, method restrictions, response size limits
- **Tools**: `http_get`, `http_post`, `fetch_api`

### PostgreSQL Database

Pre-configured with:
- Sample data tables (`tasks`, `files_metadata`)
- MCP operation logging (`mcp_logs.operation_logs`)
- Resource caching (`mcp_cache.resource_cache`)
- Performance indexes and views

### MCP Inspector (Port 5173)

Web-based debugging interface for:
- Testing MCP server connections
- Viewing available tools and resources
- Debugging JSON-RPC messages
- Monitoring server capabilities

## Security Features

### Container Security
- Non-root users in all containers
- Capability dropping (`CAP_DROP: ALL`)
- No new privileges (`no-new-privileges:true`)
- Process isolation with Tini init system

### Network Security
- Internal network isolation
- External access only for web services
- CORS configuration
- Rate limiting

### Threat Detection
- **Tool Poisoning**: Detects malicious tool descriptions
- **MCP Rug Pull**: Prevents tools from changing after authorization
- **MCP Shadowing**: Identifies conflicting or similar tools
- **Input Validation**: SQL injection and path traversal protection

### Secrets Management
- Docker secrets for sensitive data
- Environment variable isolation
- Read-only secret mounting
- Credential rotation support

## Usage Examples

### Testing with MCP Inspector

1. Open http://localhost:5173
2. Connect to `ws://localhost:8811`
3. Initialize the connection
4. Browse available tools and resources
5. Test tool execution

### Direct MCP Client Connection

```javascript
// Connect to MCP Gateway
const client = new MCPClient();
await client.connect('ws://localhost:8811');

// Initialize
await client.initialize({
  capabilities: {
    tools: { listChanged: true },
    resources: { subscribe: true }
  }
});

// List available tools
const tools = await client.listTools();

// Call a tool
const result = await client.callTool('filesystem.read_file', {
  path: '/workspace/example.txt'
});
```

### Database Operations

```sql
-- Connect to PostgreSQL
psql -h localhost -U mcpuser -d mcpdata

-- Query sample data
SELECT * FROM tasks WHERE status = 'pending';

-- View MCP operation logs
SELECT * FROM mcp_logs.recent_operations LIMIT 10;
```

## Development

### Adding New MCP Servers

1. Create server directory: `servers/my-server/`
2. Add Dockerfile and package.json
3. Implement MCP server using `@modelcontextprotocol/sdk`
4. Update `docker-compose.yml`
5. Configure in `config/gateway.yaml`

### Custom Configuration

Edit `config/gateway.yaml` to:
- Add new server definitions
- Modify security policies
- Configure threat detection rules
- Set resource limits

### Debugging

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f mcp-gateway

# Check service health
docker-compose ps

# Restart a service
docker-compose restart mcp-gateway
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Change ports in docker-compose.yml
2. **Memory issues**: Increase Docker memory allocation
3. **Permission errors**: Check file ownership and permissions
4. **Connection timeouts**: Verify network configuration

### Health Checks

```bash
# Gateway health
curl http://localhost:9090/health

# Server status
curl http://localhost:9090/servers

# Database connection
docker-compose exec postgres pg_isready -U mcpuser
```

### Reset Environment

```powershell
# Clean everything and restart
.\start-cluster.ps1 -Clean -Build
```

## Security Considerations

### Production Deployment

- Change all default passwords
- Use proper certificate management
- Implement proper authentication
- Enable audit logging
- Regular security updates
- Network segmentation

### Monitoring

- Gateway access logs
- MCP operation audit trail
- Resource usage monitoring
- Security event alerting

## Contributing

1. Fork the repository
2. Create feature branch
3. Test with the local cluster
4. Submit pull request

## License

MIT License - see LICENSE file for details

## Support

- Check logs: `docker-compose logs`
- Health endpoints: `/health` on each service
- MCP Inspector for debugging
- GitHub Issues for bug reports 