#!/bin/bash

# BitNet Lambda Deployment Script
# This script deploys the BitNet Lambda function using AWS CDK

set -e

echo "🚀 Deploying BitNet Lambda Function..."

# Check if temp folder exists
if [ ! -d "temp" ]; then
    echo "❌ Error: temp folder not found."
    echo "   Please run the initialization script first:"
    echo "   ./scripts/1-initialize.sh"
    exit 1
fi

# Check if BitNet source exists
if [ ! -d "temp/BitNet" ]; then
    echo "❌ Error: BitNet source code not found."
    echo "   Please run the initialization script first:"
    echo "   ./scripts/1-initialize.sh"
    exit 1
fi

# Check if model file exists
if [ ! -f "temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf" ]; then
    echo "❌ Error: Model file not found."
    echo "   Please run the initialization script first:"
    echo "   ./scripts/1-initialize.sh"
    exit 1
fi

# Check if CDK is installed
if ! command -v cdk &> /dev/null; then
    echo "❌ Error: AWS CDK not found. Please install it:"
    echo "   npm install -g aws-cdk"
    exit 1
fi

# Navigate to CDK directory
cd cdk

# Activate virtual environment
if [ -f ".venv/bin/activate" ]; then
    echo "📦 Activating Python virtual environment..."
    source .venv/bin/activate
else
    echo "❌ Error: CDK virtual environment not found. Please run:"
    echo "   cd cdk && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

# Deploy with CDK
echo "🏗️  Deploying with AWS CDK..."
cdk deploy --require-approval never --outputs-file cdk-outputs.json

# Extract deployment information
if [ -f "cdk-outputs.json" ]; then
    # Try to extract function name from CDK outputs
    if command -v jq &> /dev/null; then
        # Use jq if available for robust JSON parsing
        LAMBDA_NAME=$(jq -r '.[] | .FunctionName // empty' cdk-outputs.json 2>/dev/null)
        LAMBDA_ARN=$(jq -r '.[] | .FunctionArn // empty' cdk-outputs.json 2>/dev/null)
        LOG_GROUP_NAME=$(jq -r '.[] | .LogGroupName // empty' cdk-outputs.json 2>/dev/null)
    else
        # Fallback to grep/sed parsing
        LAMBDA_NAME=$(grep -o '"FunctionName":"[^"]*' cdk-outputs.json 2>/dev/null | cut -d'"' -f4)
        LAMBDA_ARN=$(grep -o '"FunctionArn":"[^"]*' cdk-outputs.json 2>/dev/null | cut -d'"' -f4)
        LOG_GROUP_NAME=$(grep -o '"LogGroupName":"[^"]*' cdk-outputs.json 2>/dev/null | cut -d'"' -f4)
    fi
fi

# Get AWS region from CDK context or AWS CLI config
AWS_REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")

# Fallback values if extraction failed
if [ -z "$LAMBDA_NAME" ]; then
    LAMBDA_NAME="bitnet-lambda-dev-function"
fi
if [ -z "$LOG_GROUP_NAME" ]; then
    LOG_GROUP_NAME="/aws/lambda/${LAMBDA_NAME}"
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print formatted deployment summary
echo ""
echo -e "${GREEN}${BOLD}✅ DEPLOYMENT SUCCESSFUL!${NC}"
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Lambda Function Details
echo -e "${CYAN}${BOLD}🚀 Lambda Function Details:${NC}"
echo -e "${WHITE}   Function Name:${NC} ${YELLOW}${LAMBDA_NAME}${NC}"
echo -e "${WHITE}   Region:${NC}        ${YELLOW}${AWS_REGION}${NC}"
if [ -n "$LAMBDA_ARN" ]; then
    echo -e "${WHITE}   Function ARN:${NC}  ${YELLOW}${LAMBDA_ARN}${NC}"
fi
echo ""

# CloudWatch Logs
echo -e "${PURPLE}${BOLD}📊 CloudWatch Logs:${NC}"
LOGS_URL="https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#logsV2:log-groups/log-group/\$252Faws\$252Flambda\$252F${LAMBDA_NAME}"
echo -e "${WHITE}   Log Group:${NC}    ${YELLOW}${LOG_GROUP_NAME}${NC}"
echo -e "${WHITE}   View logs at:${NC} ${BLUE}${LOGS_URL}${NC}"
echo ""

# Sample Test Event
echo -e "${GREEN}${BOLD}🧪 Test Your Lambda Function:${NC}"
echo ""
echo -e "${WHITE}${BOLD}Option 1: Using AWS CLI${NC}"
echo -e "${CYAN}aws lambda invoke \\${NC}"
echo -e "${CYAN}  --function-name ${YELLOW}${LAMBDA_NAME}${CYAN} \\${NC}"
echo -e "${CYAN}  --region ${YELLOW}${AWS_REGION}${CYAN} \\${NC}"
echo -e "${CYAN}  --payload '${YELLOW}{\"prompt\":\"User: Hello! How are you today?\\\\n\\\\nAssistant:\",\"n_predict\":15}${CYAN}' \\${NC}"
echo -e "${CYAN}  response.json${NC}"
echo ""
echo -e "${WHITE}${BOLD}Option 2: Using our test script${NC}"
echo -e "${CYAN}./scripts/3-test-lambda.sh${NC}"
echo ""

# Sample Event JSON
echo -e "${YELLOW}${BOLD}📝 Sample Event JSON:${NC}"
echo -e "${WHITE}{${NC}"
echo -e "${WHITE}  \"prompt\": \"${GREEN}User: Tell me a joke about AI.\\\\n\\\\nAssistant:${WHITE}\",${NC}"
echo -e "${WHITE}  \"n_predict\": ${PURPLE}25${WHITE},${NC}"
echo -e "${WHITE}  \"temperature\": ${PURPLE}0.7${WHITE},${NC}"
echo -e "${WHITE}  \"top_p\": ${PURPLE}0.9${NC}"
echo -e "${WHITE}}${NC}"
echo ""

# Additional helpful information
echo -e "${BLUE}${BOLD}💡 Quick Tips:${NC}"
echo -e "${WHITE}   • First invocation may take 30-60 seconds (cold start)${NC}"
echo -e "${WHITE}   • Subsequent calls will be much faster${NC}"
echo -e "${WHITE}   • Monitor CloudWatch logs for debugging${NC}"
echo -e "${WHITE}   • Function timeout is set to 15 minutes${NC}"
echo ""

echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}🎉 Your BitNet Lambda is ready to serve 1-bit LLM inference!${NC}"
echo ""

# Clean up temporary files
rm -f cdk-outputs.json
