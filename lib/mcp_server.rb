require 'dotenv'
Dotenv.load(File.expand_path('../../.env', __FILE__))
require 'mcp'
require 'mysql2' if ENV['ENABLE_MYSQL'] == 'true'
require 'open3'

require_relative 'mcp_server/server'
require_relative 'mcp_server/tools/mysql_tools' if ENV['ENABLE_MYSQL'] == 'true'
require_relative 'mcp_server/tools/file_tools'
require_relative 'mcp_server/tools/git_tools' if ENV['ENABLE_GIT'] == 'true'