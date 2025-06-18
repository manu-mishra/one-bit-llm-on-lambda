#!/bin/bash

# curl.test.local.sh - Test script for BitNet local API
API_URL="http://localhost:8080/completion"

echo "=== BitNet API Test Script ==="
echo "Testing API at: ${API_URL}"
echo

# Test 1: Simple completion
echo "Test 1: Simple completion"
echo "Prompt: 'Hello, world'"
curl -X POST $API_URL \
  -H 'Content-Type: application/json' \
  -d '{"prompt": "Hello, world", "n_predict": 10}'
echo
echo "-------------------------------------"
echo

# Test 2: Short poem
echo "Test 2: Short poem"
echo "Prompt: 'Write a short poem about AI'"
curl -X POST $API_URL \
  -H 'Content-Type: application/json' \
  -d '{"prompt": "Write a short poem about AI", "n_predict": 30}'
echo
echo "-------------------------------------"
echo

echo "All tests completed!"
