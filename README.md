# MCP Server - Ruby Implementation

A Ruby MCP (Model Context Protocol) server with optional MySQL, Git, and file tools.

**Note:** This is part of a multi-language MCP server template. See [main branch](https://github.com/MatiAlevMe/mcp-server) for the full architecture documentation.

## Features

### File Tools (always available)
- `file_read` - Read file contents with pagination
- `file_search` - Search files using grep patterns
- `file_list` - List directory contents

### MySQL Tools (optional, enable via `ENABLE_MYSQL=true`)
- `db_query` - Execute SQL queries
- `db_list_tables` - List all tables with row counts
- `db_describe_table` - Show table structure
- `db_schema_info` - Full schema overview

### Git Tools (optional, enable via `ENABLE_GIT=true`)
- `git_log` - Show commit history
- `git_diff` - Show file differences
- `git_show` - Show commit details
- `git_branches` - List branches
- `git_files` - List repository files
- `git_search` - Search in files
- `git_blame` - Show line authorship

## Requirements

- Ruby >= 3.0
- `mcp` gem
- `mysql2` gem (for database tools)
- `dotenv` gem

## Quick Start

### 1. Install Dependencies

```bash
gem install mcp mysql2 dotenv
```

Or if using Bundler:

```bash
bundle install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
```

### 3. Test the Server

```bash
ruby bin/mcp_server.rb
```

The server runs on stdio, waiting for MCP connections.

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MCP_SERVER_NAME` | `custom-mcp-server` | Server name |
| `MCP_SERVER_VERSION` | `1.0.0` | Server version |
| `MCP_SERVER_DESCRIPTION` | `Custom MCP Server` | Server description |
| `ENABLE_MYSQL` | `false` | Enable MySQL tools |
| `ENABLE_GIT` | `false` | Enable Git tools |
| `DB_HOST` | `127.0.0.1` | Database host |
| `DB_PORT` | `3306` | Database port |
| `DB_USER` | `root` | Database user |
| `DB_PASSWORD` | `` | Database password |
| `DB_NAME` | `test` | Database name |

### Enable MySQL Tools

```bash
ENABLE_MYSQL=true
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=your_database
```

### Enable Git Tools

```bash
ENABLE_GIT=true
```

Git tools are useful when the server runs inside a Git repository. They provide:
- Formatted output with truncation
- Automatic exclusion of large directories (node_modules, public/, etc.)
- Consistent interface for AI agents

### Kilo Configuration

Copy `kilo.json.example` to your project's `.kilo/kilo.json` and adjust paths:

```json
{
  "mcp": {
    "my-custom-mcp": {
      "type": "local",
      "command": ["ruby", "/absolute/path/to/bin/mcp_server.rb"],
      "environment": {
        "ENABLE_MYSQL": "true",
        "ENABLE_GIT": "true",
        "DB_HOST": "127.0.0.1",
        "DB_PORT": "3306",
        "DB_USER": "root",
        "DB_NAME": "my_database"
      },
      "enabled": true,
      "timeout": 120000
    }
  }
}
```

## Extending the Server

### Adding New Tools

1. Create a new file in `lib/mcp_server/tools/`
2. Define your tool class:

```ruby
class MyTool < MCP::Tool
  description "Description of what the tool does"

  input_schema(
    properties: {
      param1: { type: "string", description: "Parameter description" }
    },
    required: ["param1"]
  )

  def self.call(param1:, **kwargs)
    # Your tool logic here
    MCP::Tool::Response.new([{
      type: "text",
      text: "Result"
    }])
  end
end
```

3. Register in `lib/mcp_server/server.rb`:

```ruby
server.define_tool(
  name: "my_tool",
  description: MyTool.description,
  input_schema: { ... }
) do |**kwargs|
  MyTool.call(**kwargs)
end
```

4. Add requires to `lib/mcp_server.rb` and wrap in ENV check

```ruby
require_relative 'mcp_server/tools/my_tool' if ENV['ENABLE_MY_TOOL'] == 'true'
```

### Using with Docker

```dockerfile
FROM ruby:3.1-slim

WORKDIR /app
COPY Gemfile* ./
RUN bundle install

COPY . .
CMD ["ruby", "bin/mcp_server.rb"]
```

## Project Structure

```
mcp-server/
├── bin/
│   └── mcp_server.rb        # Entry point
├── lib/
│   ├── mcp_server.rb         # Main requires
│   └── mcp_server/
│       ├── server.rb         # Tool definitions
│       └── tools/
│           ├── mysql_tools.rb
│           ├── git_tools.rb
│           └── file_tools.rb
├── .env.example              # Environment template
├── .gitignore
├── Gemfile
├── kilo.json.example         # Kilo config template
└── README.md
```

## License

MIT