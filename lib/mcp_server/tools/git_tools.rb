require 'open3'

module MCPServer
  module Tools
    class GitCommandRunner
      def self.run(cmd, cwd = nil)
        stdout, stderr, status = Open3.capture3(cmd, chdir: cwd || Dir.pwd)
        { stdout: stdout, stderr: stderr, status: status.success?, exit_code: status.exitstatus }
      rescue StandardError => e
        { error: e.message }
      end
    end

    class GitLogTool < MCP::Tool
      description 'Show recent commit history. Useful for understanding code evolution and recent changes.'

      input_schema(
        properties: {
          count: { type: 'integer', description: 'Number of commits to show (default: 10)' },
          format: { type: 'string', description: "Log format (default: '%h - %s (%an)')" }
        }
      )

      def self.call(count: 10, format: '%h - %s (%an)', **_kwargs)
        cmd = "git log --pretty=format:'#{format}' -n #{count}"
        result = GitCommandRunner.run(cmd)

        if result[:error]
          return MCP::Tool::Response.new([{ type: 'text', text: "Error: #{result[:error]}" }], error: true)
        end

        MCP::Tool::Response.new([{ type: 'text', text: result[:stdout] }])
      end
    end

    class GitDiffTool < MCP::Tool
      description 'Show differences in modified files or between commits. Useful for reviewing changes before commit.'

      input_schema(
        properties: {
          staged: { type: 'boolean', description: 'Show only staged changes' },
          file: { type: 'string', description: 'Specific file to review' },
          summary: { type: 'boolean', description: 'Show only summary (stats)' }
        }
      )

      def self.call(staged: false, file: nil, summary: false, **_kwargs)
        cmd = 'git diff'
        cmd += ' --cached' if staged
        cmd += ' --stat' if summary
        cmd += " -- #{file}" if !file.nil? && !file.empty?

        result = GitCommandRunner.run(cmd)

        if result[:error]
          return MCP::Tool::Response.new([{ type: 'text', text: "Error: #{result[:error]}" }], error: true)
        end

        truncated = MCPServer::Tools.truncate_output(result[:stdout])

        if result[:stdout].empty?
          return MCP::Tool::Response.new([{ type: 'text', text: staged ? 'No staged changes.' : 'No unstaged changes.' }])
        end

        MCP::Tool::Response.new([{ type: 'text', text: truncated }])
      end
    end

    class GitShowTool < MCP::Tool
      description 'Show changes from a specific commit. Useful for reviewing what changed in a commit.'

      input_schema(
        properties: {
          commit: { type: 'string', description: 'Commit hash or reference' },
          file: { type: 'string', description: 'Specific file to review' }
        },
        required: ['commit']
      )

      def self.call(commit:, file: nil, **_kwargs)
        cmd = 'git show'
        cmd += " #{commit}"
        cmd += " -- #{file}" if !file.nil? && !file.empty?

        result = GitCommandRunner.run(cmd)

        if result[:error]
          return MCP::Tool::Response.new([{ type: 'text', text: "Error: #{result[:error]}" }], error: true)
        end

        MCP::Tool::Response.new([{ type: 'text', text: result[:stdout] }])
      end
    end

    class GitBranchesTool < MCP::Tool
      description 'List all local and remote branches.'

      def self.call(**_kwargs)
        local_result = GitCommandRunner.run('git branch')
        remote_result = GitCommandRunner.run('git branch -r')

        output = "=== Local Branches ===\n#{local_result[:stdout] || 'None'}"
        output += "\n\n=== Remote Branches ===\n#{remote_result[:stdout] || 'None'}"

        MCP::Tool::Response.new([{ type: 'text', text: output }])
      end
    end

    class GitFilesTool < MCP::Tool
      description 'List files in the repository. Useful for exploring project structure.'

      input_schema(
        properties: {
          path: { type: 'string', description: 'Base directory (default: root)' },
          pattern: { type: 'string', description: "Glob pattern to filter files" }
        }
      )

      def self.call(path: '.', pattern: nil, **_kwargs)
        cmd = 'git ls-files'
        cmd += ' -- . ":(exclude)public/" ":(exclude)node_modules/" ":(exclude)dist/" ":(exclude)build/"'
        cmd += " #{pattern}" if pattern
        cmd += " #{path}" if path != '.'

        result = GitCommandRunner.run(cmd)

        if result[:error]
          return MCP::Tool::Response.new([{ type: 'text', text: "Error: #{result[:error]}" }], error: true)
        end

        files = result[:stdout].split("\n").reject(&:empty?)
        if pattern
          require 'pathname'
          files = files.select { |f| Pathname.new(f).fnmatch?(pattern, File::FNM_PATHNAME) }
        end

        MCP::Tool::Response.new([{ type: 'text', text: files.join("\n") }])
      end
    end

    class GitSearchTool < MCP::Tool
      description 'Search text in repository files using grep. Useful for finding specific code.'

      input_schema(
        properties: {
          pattern: { type: 'string', description: 'Search pattern (regex supported)' },
          path: { type: 'string', description: 'Directory to search in (default: root)' },
          extensions: { type: 'string', description: "File extensions to search, comma-separated" }
        },
        required: ['pattern']
      )

      def self.call(pattern:, path: '.', extensions: nil, **_kwargs)
        cmd = 'git grep -n'
        if !extensions.nil? && !extensions.empty?
          cmd += " -- '#{extensions.split(',').map(&:strip).map { |e| "*.#{e.strip}" }.join(' ')}'"
        end
        cmd += " '#{pattern}' -- #{path}"

        result = GitCommandRunner.run(cmd)

        if result[:error]
          return MCP::Tool::Response.new([{ type: 'text', text: "Error: #{result[:error]}" }], error: true)
        end

        MCP::Tool::Response.new([{ type: 'text', text: result[:stdout].empty? ? 'No matches found.' : result[:stdout] }])
      end
    end

    class GitBlameTool < MCP::Tool
      description 'Show authorship information per line of a file.'

      input_schema(
        properties: {
          file: { type: 'string', description: 'File to review' },
          line: { type: 'integer', description: 'Specific line number' }
        },
        required: ['file']
      )

      def self.call(file:, line: nil, **_kwargs)
        cmd = 'git blame'
        cmd += " -L #{line},#{line}" if !line.nil? && !line.empty?
        cmd += " -- #{file}"

        result = GitCommandRunner.run(cmd)

        if result[:error]
          return MCP::Tool::Response.new([{ type: 'text', text: "Error: #{result[:error]}" }], error: true)
        end

        MCP::Tool::Response.new([{ type: 'text', text: result[:stdout] }])
      end
    end
  end
end