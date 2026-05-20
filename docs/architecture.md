# MCP Server Architecture Guide

This guide explains how to implement a custom MCP server in any programming language. Follow these principles to create a new language implementation in this repository.

## What is MCP?

Model Context Protocol (MCP) enables AI agents to use external tools through a standardized interface. The agent communicates with the server via stdio (standard input/output), sending JSON-RPC messages.

## Core Components

### 1. Entry Point

The entry point initializes the server, loads configuration, and starts the transport layer.

**Responsibilities:**
- Load environment variables or config file
- Initialize database connections if needed
- Register all tools with the server
- Open stdio transport

**Example flow:**
```
1. Load config (env vars, .env file)
2. Create server instance with name/version
3. Define all tools (name, description, input schema)
4. Open stdio transport
5. Wait for connections
```

### 2. Tool Definition

Each tool needs:
- **Name** - Unique identifier (e.g., `db_query`, `file_read`)
- **Description** - Human-readable explanation of what the tool does
- **Input Schema** - JSON schema defining required/optional parameters

### 3. Tool Implementation

Each tool is a function/class that:
- Receives parameters as keyword arguments
- Returns `MCP::Tool::Response` with results
- Handles errors gracefully

### 4. Transport

MCP uses stdio transport:
- Messages are JSON-RPC formatted
- Agent sends requests via stdin
- Server responds via stdout

## Step-by-Step Implementation

### Step 1: Initialize Project

Create a new branch from `main`:

```bash
git checkout main
git checkout -b python  # or ruby, node, go, etc.
```

### Step 2: Create Entry Point

Create `bin/mcp_server` (or `bin/mcp_server.rb` for Ruby):

```python
#!/usr/bin/env python3
# Entry point for Python MCP server

import os
import json
from mcp_server import MCPServer

server = MCPServer(
    name=os.getenv('MCP_SERVER_NAME', 'python-mcp'),
    version='1.0.0',
    description='Custom MCP Server in Python'
)

# Define tools
@server.tool(name='file_read', description='Read file contents')
def file_read(path: str, limit: int = 100, offset: int = 0):
    # Implementation
    pass

# Start server
server.start(transport='stdio')
```

### Step 3: Define Tools

Group tools by category:

```
lib/
└── mcp_server/
    ├── server.py          # Main server class
    └── tools/
        ├── mysql_tools.py # If using MySQL
        ├── git_tools.py   # If using Git
        └── file_tools.py  # Universal file operations
```

### Step 4: Create Configuration Template

Create `.env.example`:

```bash
MCP_SERVER_NAME=python-mcp
MCP_SERVER_VERSION=1.0.0
ENABLE_MYSQL=true
ENABLE_GIT=true
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=test
```

Create `kilo.json.example`:

```json
{
  "mcp": {
    "python-mcp": {
      "type": "local",
      "command": ["python", "/path/to/bin/mcp_server"],
      "environment": {
        "ENABLE_MYSQL": "true"
      },
      "enabled": true,
      "timeout": 120000
    }
  }
}
```

### Step 5: Document Language-Specific Setup

Create a `docs/LANGUAGE_SETUP.md` with:
- Installation requirements
- How to run the server
- Testing instructions
- Any language-specific notes

## Tool Implementation Patterns

### File Operations (Universal)

```python
def file_read(path: str, limit: int = 100, offset: int = 0):
    """Read file contents with pagination."""
    try:
        with open(path, 'r') as f:
            lines = f.readlines()[offset:offset+limit]
            return {'text': ''.join(lines)}
    except FileNotFoundError:
        return {'error': f'File not found: {path}', 'is_error': True}
```

### Database Operations (MySQL Example)

```python
def db_query(query: str):
    """Execute SQL query (SELECT only)."""
    if not is_safe_query(query):
        return {'error': 'Unsafe query rejected', 'is_error': True}

    conn = get_db_connection()
    result = conn.execute(query)
    return {'text': json.dumps(result.fetchall())}
```

### Git Operations

```python
def git_log(count: int = 10):
    """Show recent commits."""
    result = run_command(f'git log --oneline -n {count}')
    return {'text': result.stdout}
```

## Environment Variables Convention

All MCP servers should respect these standard environment variables:

| Variable | Purpose |
|----------|---------|
| `MCP_SERVER_NAME` | Server identifier |
| `MCP_SERVER_VERSION` | Version string |
| `MCP_SERVER_DESCRIPTION` | Human-readable description |
| `ENABLE_MYSQL` | Enable MySQL tools (true/false) |
| `ENABLE_GIT` | Enable Git tools (true/false) |
| `DB_HOST` | Database host |
| `DB_PORT` | Database port |
| `DB_USER` | Database username |
| `DB_PASSWORD` | Database password |
| `DB_NAME` | Database name |

## Testing Your MCP Server

### Manual Test

Run the server and verify startup:

```bash
ruby bin/mcp_server.rb
# Should output:
# Starting MCP Server...
# Available Tools:
#   - db_query
#   - file_read
#   ...
```

### List Tools

The server should respond to `tools/list` requests with all available tools and their schemas.

### Integration Test

1. Start the server
2. Send a JSON-RPC request via stdin
3. Verify JSON-RPC response via stdout

## Checklist for New Language Implementation

- [ ] Branch created from `main`
- [ ] Entry point (`bin/mcp_server` or equivalent)
- [ ] Tool definitions registered
- [ ] File tools implemented
- [ ] MySQL tools implemented (if applicable)
- [ ] Git tools implemented (if applicable)
- [ ] `.env.example` created
- [ ] `kilo.json.example` created
- [ ] `docs/LANGUAGE_SETUP.md` created
- [ ] README updated with language quick reference
- [ ] Tests created

## Existing Implementations

| Language | Branch | Status |
|----------|--------|--------|
| Ruby | `ruby` | Active |
| Python | `python` | Planned |
| Node.js | `node` | Planned |
| Go | `go` | Planned |