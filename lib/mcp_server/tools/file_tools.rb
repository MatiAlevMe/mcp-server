require 'open3'

module MCPServer
  module Tools
    MAX_OUTPUT_BYTES = 64 * 1024

    def self.truncate_output(stdout)
      if stdout.bytesize > MAX_OUTPUT_BYTES
        truncated = stdout.byteslice(0, MAX_OUTPUT_BYTES)
        "#{truncated}\n\n[Output truncated to #{MAX_OUTPUT_BYTES} bytes]"
      else
        stdout
      end
    end

    class FileReadTool < MCP::Tool
      description "Read the contents of a file. Useful for examining source code, configuration files, or any text-based file."

      input_schema(
        properties: {
          path: { type: "string", description: "File path to read" },
          limit: { type: "integer", description: "Maximum number of lines to read (default: 100)" },
          offset: { type: "integer", description: "Line number to start from (default: 0)" }
        },
        required: ["path"]
      )

      def self.call(path:, limit: 100, offset: 0, **kwargs)
        return MCP::Tool::Response.new([{ type: "text", text: "Error: Path is required" }], error: true) if path.nil? || path.empty?

        begin
          content = File.read(path)
          lines = content.split("\n")
          lines = lines[offset..-1] if offset > 0
          lines = lines[0...limit] if limit > 0

          truncated = lines.join("\n")
          truncated += "\n\n[File truncated to #{MAX_OUTPUT_BYTES} bytes]" if content.bytesize > MAX_OUTPUT_BYTES

          MCP::Tool::Response.new([{ type: "text", text: truncated }])
        rescue Errno::ENOENT => e
          MCP::Tool::Response.new([{ type: "text", text: "Error: File not found - #{path}" }], error: true)
        rescue => e
          MCP::Tool::Response.new([{ type: "text", text: "Error: #{e.message}" }], error: true)
        end
      end
    end

    class FileSearchTool < MCP::Tool
      description "Search for text pattern in files using grep. Useful for finding specific code, strings, or patterns across the codebase."

      input_schema(
        properties: {
          pattern: { type: "string", description: "Search pattern (regex supported)" },
          path: { type: "string", description: "Directory to search in (default: current directory)" },
          extensions: { type: "string", description: "File extensions to search (comma-separated, e.g., 'rb,erb')" }
        },
        required: ["pattern"]
      )

      def self.call(pattern:, path: '.', extensions: nil, **kwargs)
        return MCP::Tool::Response.new([{ type: "text", text: "Error: Pattern is required" }], error: true) if pattern.nil? || pattern.empty?

        begin
          cmd = 'git grep -n'
          if !extensions.nil? && !extensions.empty?
            ext_args = extensions.split(',').map(&:strip).map { |e| "*#{e}" }.join(' ')
            cmd += " -- '#{ext_args}'"
          end
          cmd += " '#{pattern}' -- #{path}"

          stdout, stderr, status = Open3.capture3(cmd)

          if !status.success? && !stderr.empty?
            return MCP::Tool::Response.new([{ type: "text", text: "Error: #{stderr}" }], error: true)
          end

          MCP::Tool::Response.new([{ type: "text", text: stdout.empty? ? 'No matches found.' : stdout }])
        rescue => e
          MCP::Tool::Response.new([{ type: "text", text: "Error: #{e.message}" }], error: true)
        end
      end
    end

    class FileListTool < MCP::Tool
      description "List files in a directory. Useful for exploring project structure."

      input_schema(
        properties: {
          path: { type: "string", description: "Directory path (default: current directory)" },
          recursive: { type: "boolean", description: "Search recursively (default: false)" }
        }
      )

      def self.call(path: '.', recursive: false, **kwargs)
        begin
          base_path = path.nil? || path.empty? ? '.' : path

          cmd = recursive ? "find #{base_path} -type f 2>/dev/null | head -500" : "ls -1 #{base_path} 2>/dev/null"

          stdout, stderr, status = Open3.capture3(cmd)

          if !status.success?
            return MCP::Tool::Response.new([{ type: "text", text: "Error: Could not list directory - #{stderr}" }], error: true)
          end

          files = stdout.split("\n").reject(&:empty?)[0...500]
          truncated = files.join("\n")
          truncated += "\n\n[Output limited to 500 files]" if files.length >= 500

          MCP::Tool::Response.new([{ type: "text", text: truncated }])
        rescue => e
          MCP::Tool::Response.new([{ type: "text", text: "Error: #{e.message}" }], error: true)
        end
      end
    end
  end
end