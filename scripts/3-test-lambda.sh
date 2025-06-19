#!/bin/bash

# BitNet Lambda Test Script
# This script tests the deployed Lambda function

set -e

FUNCTION_NAME="bitnet-lambda-dev-function"
REGION="us-east-1"

echo "🧪 Testing BitNet Lambda Function..."

# Test 1: Simple prompt
echo "📝 Test 1: Simple greeting"
echo '{"prompt": "User: Hello! How are you today?\n\nAssistant:", "n_predict": 15}' | base64 | aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload file:///dev/stdin \
    --region $REGION \
    response1.json

if [ $? -eq 0 ]; then
    echo "✅ Test 1 passed"
    echo "Response: $(cat response1.json | jq -r '.body' | jq -r '.content')"
else
    echo "❌ Test 1 failed"
fi

echo ""

# Test 2: Creative prompt
echo "📝 Test 2: Creative writing"
echo '{"prompt": "User: Tell me a joke about programming.\n\nAssistant:", "n_predict": 25}' | base64 | aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload file:///dev/stdin \
    --region $REGION \
    response2.json

if [ $? -eq 0 ]; then
    echo "✅ Test 2 passed"
    echo "Response: $(cat response2.json | jq -r '.body' | jq -r '.content')"
else
    echo "❌ Test 2 failed"
fi

echo ""

# Test 3: Code generation
echo "📝 Test 3: Code generation"
echo '{"prompt": "User: Write a Python function to calculate fibonacci numbers.\n\nAssistant:", "n_predict": 30}' | base64 | aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload file:///dev/stdin \
    --region $REGION \
    response3.json

if [ $? -eq 0 ]; then
    echo "✅ Test 3 passed"
    echo "Response: $(cat response3.json | jq -r '.body' | jq -r '.content')"
else
    echo "❌ Test 3 failed"
fi

echo ""
echo "🎉 Testing complete!"

# Clean up response files
rm -f response1.json response2.json response3.json
