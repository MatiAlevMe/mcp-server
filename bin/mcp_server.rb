#!/usr/bin/env ruby

Dir.chdir(File.expand_path('..', __FILE__))

require 'bundler/setup'
require 'dotenv'

Dotenv.load('.env')

$stderr.puts "Starting MCP Server..."
$stderr.puts "Loading environment variables from .env..."

require_relative '../lib/mcp_server'

begin
  require 'mysql2'
  client = Mysql2::Client.new(
    host: ENV['DB_HOST'] || '127.0.0.1',
    port: ENV['DB_PORT'] || 3306,
    username: ENV['DB_USER'] || 'root',
    password: ENV['DB_PASSWORD'] || '',
    database: ENV['DB_NAME'] || 'test'
  )
  $stderr.puts "MySQL connection successful! Database: #{ENV['DB_NAME'] || 'test'}"
  client.close
rescue LoadError
  $stderr.puts "MySQL gem not installed. Database tools will not be available."
rescue Mysql2::Error => e
  $stderr.puts "Warning: Could not connect to MySQL: #{e.message}"
rescue => e
  $stderr.puts "Warning: Database connection skipped: #{e.message}"
end

$stderr.puts "
==========================================="
$stderr.puts "  MCP Server - #{ENV['MCP_SERVER_NAME'] || 'custom-mcp'}"
$stderr.puts "==========================================="

$stderr.puts "
Available Tools:"
MCP::Server.list_tools.each do |name, tool|
  $stderr.puts "  - #{name}"
end

$stderr.puts "
Waiting for MCP connections (stdio)...
"

server = MCPServer::Server.create
transport = MCP::Server::Transports::StdioTransport.new(server)
transport.open