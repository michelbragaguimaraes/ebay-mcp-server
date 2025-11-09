#!/usr/bin/env node

/**
 * Simple MCP server test script
 * Sends a tools/list request to verify server responds correctly
 */

import { spawn } from 'child_process';

const server = spawn('node', ['build/index.js'], {
  stdio: ['pipe', 'pipe', 'inherit']
});

// MCP initialization request
const initRequest = {
  jsonrpc: '2.0',
  id: 1,
  method: 'initialize',
  params: {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'test-client', version: '1.0.0' }
  }
};

// Tools list request
const toolsRequest = {
  jsonrpc: '2.0',
  id: 2,
  method: 'tools/list',
  params: {}
};

let buffer = '';

server.stdout.on('data', (data) => {
  buffer += data.toString();

  // Process complete JSON-RPC messages
  const lines = buffer.split('\n');
  buffer = lines.pop(); // Keep incomplete line in buffer

  for (const line of lines) {
    if (!line.trim()) continue;

    try {
      const response = JSON.parse(line);
      console.log('✓ Received response:', JSON.stringify(response, null, 2));

      // After init, send tools/list
      if (response.id === 1) {
        console.log('\n→ Requesting tools list...\n');
        server.stdin.write(JSON.stringify(toolsRequest) + '\n');
      }

      // After tools/list, exit
      if (response.id === 2) {
        if (response.result?.tools) {
          console.log(`\n✅ SUCCESS! Server has ${response.result.tools.length} tools`);
          console.log('First 3 tools:', response.result.tools.slice(0, 3).map(t => t.name));
        }
        server.kill();
        process.exit(0);
      }
    } catch (e) {
      // Ignore parsing errors for incomplete messages
    }
  }
});

server.on('error', (error) => {
  console.error('✗ Server error:', error);
  process.exit(1);
});

server.on('exit', (code) => {
  if (code !== 0) {
    console.error(`✗ Server exited with code ${code}`);
    process.exit(code);
  }
});

// Send initialization request
console.log('→ Initializing MCP server...\n');
server.stdin.write(JSON.stringify(initRequest) + '\n');

// Timeout after 5 seconds
setTimeout(() => {
  console.error('✗ Test timeout');
  server.kill();
  process.exit(1);
}, 5000);
