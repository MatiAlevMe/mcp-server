require 'mysql2'
require 'dotenv'

module MCPServer
  module Tools
    class DatabaseConnection
      def self.client
        @client ||= Mysql2::Client.new(
          host: ENV['DB_HOST'] || '127.0.0.1',
          port: ENV['DB_PORT'] || 3306,
          username: ENV['DB_USER'] || 'root',
          password: ENV['DB_PASSWORD'] || '',
          database: ENV['DB_NAME'] || 'test',
          encoding: 'utf8mb4'
        )
      end

      def self.with_connection
        yield client
      rescue Mysql2::Error => e
        { error: e.message }
      end
    end

    class QueryTool < MCP::Tool
      description "Execute a SQL query on the database. Use for reading data, listing tables, describing structures, or performing SELECT queries. DO NOT use for destructive operations like INSERT, UPDATE, DELETE without explicit confirmation."

      input_schema(
        properties: {
          query: { type: "string", description: "SQL query to execute. Use only SELECT, SHOW, DESCRIBE, EXPLAIN for read operations." }
        },
        required: ["query"]
      )

      def self.call(query:, **kwargs)
        result = DatabaseConnection.with_connection do |client|
          client.query(query)
        end

        if result.is_a?(Hash) && result[:error]
          MCP::Tool::Response.new([{ type: "text", text: "Error: #{result[:error]}" }], error: true)
        else
          data = result.to_a
          MCP::Tool::Response.new([{
            type: "text",
            text: data.any? ? JSON.pretty_generate(data) : "Query executed successfully. #{result.num_rows} rows affected."
          }])
        end
      rescue => e
        MCP::Tool::Response.new([{ type: "text", text: "Error: #{e.message}" }], error: true)
      end
    end

    class ListTablesTool < MCP::Tool
      description "List all tables in the database with their row count. Useful for exploring the database structure."

      def self.call(**kwargs)
        result = DatabaseConnection.with_connection do |client|
          client.query("SHOW TABLES")
        end

        tables = result.map { |row| row.values.first }
        table_info = tables.map do |table|
          count = DatabaseConnection.with_connection do |client|
            client.query("SELECT COUNT(*) as count FROM `#{table}`").first&.dig('count') || 0
          end
          { table: table, count: count }
        end

        MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(table_info) }])
      rescue => e
        MCP::Tool::Response.new([{ type: "text", text: "Error: #{e.message}" }], error: true)
      end
    end

    class DescribeTableTool < MCP::Tool
      description "Show the structure of a specific table (columns, types, nullable, etc.). Useful for understanding model structure."

      input_schema(
        properties: { table: { type: "string", description: "Table name to describe" } },
        required: ["table"]
      )

      def self.call(table:, **kwargs)
        result = DatabaseConnection.with_connection do |client|
          client.query("DESCRIBE `#{table}`")
        end

        MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(result.to_a) }])
      rescue => e
        MCP::Tool::Response.new([{ type: "text", text: "Error: #{e.message}" }], error: true)
      end
    end

    class SchemaInfoTool < MCP::Tool
      description "Show information about the current database schema (tables, columns, indexes). Useful for understanding the overall database structure."

      def self.call(**kwargs)
        result = DatabaseConnection.with_connection do |client|
          client.query("SELECT table_name, column_name, data_type, is_nullable, column_default, column_key
                        FROM information_schema.columns
                        WHERE table_schema = DATABASE()
                        ORDER BY table_name, ordinal_position")
        end

        MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(result.to_a) }])
      rescue => e
        MCP::Tool::Response.new([{ type: "text", text: "Error: #{e.message}" }], error: true)
      end
    end
  end
end