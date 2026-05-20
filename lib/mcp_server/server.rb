require_relative 'tools/mysql_tools'
require_relative 'tools/file_tools'
require_relative 'tools/git_tools'

module MCPServer
  class Server
    def self.create
      server_name = ENV['MCP_SERVER_NAME'] || 'custom-mcp-server'
      server_version = ENV['MCP_SERVER_VERSION'] || '1.0.0'

      server = MCP::Server.new(
        name: server_name,
        version: server_version,
        description: ENV['MCP_SERVER_DESCRIPTION'] || 'Custom MCP Server'
      )

      if ENV['ENABLE_MYSQL'] == 'true'
        server.define_tool(
          name: "db_query",
          description: MCPServer::Tools::QueryTool.description,
          input_schema: {
            type: "object",
            properties: {
              query: { type: "string", description: "SQL query to execute (SELECT, SHOW, DESCRIBE, EXPLAIN only)" }
            },
            required: ["query"]
          }
        ) do |**kwargs|
          MCPServer::Tools::QueryTool.call(**kwargs)
        end

        server.define_tool(
          name: "db_list_tables",
          description: MCPServer::Tools::ListTablesTool.description,
          input_schema: { type: "object", properties: {} }
        ) do |**kwargs|
          MCPServer::Tools::ListTablesTool.call(**kwargs)
        end

        server.define_tool(
          name: "db_describe_table",
          description: MCPServer::Tools::DescribeTableTool.description,
          input_schema: {
            type: "object",
            properties: { table: { type: "string", description: "Table name to describe" } },
            required: ["table"]
          }
        ) do |**kwargs|
          MCPServer::Tools::DescribeTableTool.call(**kwargs)
        end

        server.define_tool(
          name: "db_schema_info",
          description: MCPServer::Tools::SchemaInfoTool.description,
          input_schema: { type: "object", properties: {} }
        ) do |**kwargs|
          MCPServer::Tools::SchemaInfoTool.call(**kwargs)
        end
      end

      if ENV['ENABLE_GIT'] == 'true'
        server.define_tool(name: "git_log", description: MCPServer::Tools::GitLogTool.description,
          input_schema: { type: "object", properties: { count: { type: "integer" }, format: { type: "string" } } }
        ) { |**kwargs| MCPServer::Tools::GitLogTool.call(**kwargs) }

        server.define_tool(name: "git_diff", description: MCPServer::Tools::GitDiffTool.description,
          input_schema: { type: "object", properties: { staged: { type: "boolean" }, file: { type: "string" }, summary: { type: "boolean" } } }
        ) { |**kwargs| MCPServer::Tools::GitDiffTool.call(**kwargs) }

        server.define_tool(name: "git_show", description: MCPServer::Tools::GitShowTool.description,
          input_schema: { type: "object", properties: { commit: { type: "string" }, file: { type: "string" } }, required: ["commit"] }
        ) { |**kwargs| MCPServer::Tools::GitShowTool.call(**kwargs) }

        server.define_tool(name: "git_branches", description: MCPServer::Tools::GitBranchesTool.description,
          input_schema: { type: "object", properties: {} }
        ) { |**kwargs| MCPServer::Tools::GitBranchesTool.call(**kwargs) }

        server.define_tool(name: "git_files", description: MCPServer::Tools::GitFilesTool.description,
          input_schema: { type: "object", properties: { path: { type: "string" }, pattern: { type: "string" } } }
        ) { |**kwargs| MCPServer::Tools::GitFilesTool.call(**kwargs) }

        server.define_tool(name: "git_search", description: MCPServer::Tools::GitSearchTool.description,
          input_schema: { type: "object", properties: { pattern: { type: "string" }, path: { type: "string" }, extensions: { type: "string" } }, required: ["pattern"] }
        ) { |**kwargs| MCPServer::Tools::GitSearchTool.call(**kwargs) }

        server.define_tool(name: "git_blame", description: MCPServer::Tools::GitBlameTool.description,
          input_schema: { type: "object", properties: { file: { type: "string" }, line: { type: "integer" } }, required: ["file"] }
        ) { |**kwargs| MCPServer::Tools::GitBlameTool.call(**kwargs) }
      end

      server.define_tool(name: "file_read", description: MCPServer::Tools::FileReadTool.description,
        input_schema: { type: "object", properties: { path: { type: "string" }, limit: { type: "integer" }, offset: { type: "integer" } }, required: ["path"] }
      ) { |**kwargs| MCPServer::Tools::FileReadTool.call(**kwargs) }

      server.define_tool(name: "file_search", description: MCPServer::Tools::FileSearchTool.description,
        input_schema: { type: "object", properties: { pattern: { type: "string" }, path: { type: "string" }, extensions: { type: "string" } }, required: ["pattern"] }
      ) { |**kwargs| MCPServer::Tools::FileSearchTool.call(**kwargs) }

      server.define_tool(name: "file_list", description: MCPServer::Tools::FileListTool.description,
        input_schema: { type: "object", properties: { path: { type: "string" }, recursive: { type: "boolean" } } }
      ) { |**kwargs| MCPServer::Tools::FileListTool.call(**kwargs) }

      server
    end
  end
end