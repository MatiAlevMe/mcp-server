# MCP Server Template

Multi-language MCP (Model Context Protocol) server templates and architecture guide. This repository provides a starting point for creating custom MCP servers for AI agents in any programming language.

## Vision

Different projects use different tech stacks. This repository unifies custom MCP server implementations across languages, making it easy to extend AI agent capabilities with project-specific tools.

**Current Implementation:**
- **Ruby** - `ruby` branch

**Planned:**
- Python
- Node.js
- Go

## Repository Structure

```
mcp-server/
├── main                      # Documentation & architecture guide
│   ├── README.md             # This file
│   └── docs/
│       └── architecture.md   # How to create MCP in any language
│
├── ruby                      # Ruby implementation
│   ├── bin/
│   ├── lib/
│   └── ...
│
└── python                    # Future: Python implementation
    └── ...
```

## Quick Reference by Language

### Ruby

```bash
git checkout ruby
cp .env.example .env
bundle install
bundle exec ruby bin/mcp_server.rb
```

See [ruby branch](https://github.com/MatiAlevMe/mcp-server/tree/ruby) for full documentation.

### Python (Coming Soon)

## Architecture

All MCP servers follow the same core principles regardless of language:

1. **Entry Point** - Executable script that initializes the server
2. **Tool Definition** - Register tools with name, description, input schema
3. **Tool Implementation** - Actual logic for each tool
4. **Transport** - stdio communication with the AI agent

See [docs/architecture.md](docs/architecture.md) for detailed implementation guide.

## Contributing a New Language

1. Create a new branch from `main`: `git checkout -b python`
2. Implement your MCP server following `docs/architecture.md`
3. Add language-specific templates (requirements.txt, package.json, go.mod, etc.)
4. Update this README with quick reference for your language

## MCP Tools Overview

### File Tools (Universal)
- `file_read` - Read file contents with pagination
- `file_search` - Search files using patterns
- `file_list` - List directory contents

### MySQL Tools (when enabled)
- `db_query` - Execute SQL queries
- `db_list_tables` - List tables with row counts
- `db_describe_table` - Show table structure
- `db_schema_info` - Full schema overview

### Git Tools (when enabled)
- `git_log` - Show commit history
- `git_diff` - Show file differences
- `git_show` - Show commit details
- `git_branches` - List branches
- `git_files` - List repository files
- `git_search` - Search in files
- `git_blame` - Show line authorship

## License

MIT