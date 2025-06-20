#!/bin/bash

# Comprehensive Lambda Memory Performance Test
FUNCTION_NAME="bitnet-lambda-dev-function"
REGION="us-east-1"

# Memory configurations to test (in MB)
MEMORIES=(2048 4096 6144 8192 10240)

# Test configurations: n_predict values for cold start + 3 warm tests
N_PREDICT_VALUES=(10 10 50 100)
TEST_LABELS=("COLD_START" "WARM_1" "WARM_2" "WARM_3")

echo "Memory(MB),Test_Type,N_Predict,Response_Time(s),Response"
echo "========================================================"

for memory in "${MEMORIES[@]}"; do
    # Update Lambda memory
    aws lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION" \
        --memory-size "$memory" \
        --no-cli-pager > /dev/null
    
    # Wait for update to complete
    sleep 15
    
    # Force cold start by updating environment variable
    aws lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION" \
        --environment Variables="{COLD_START_TRIGGER=\"$(date +%s)\"}" \
        --no-cli-pager > /dev/null
    
    # Wait for cold start trigger
    sleep 10
    
    # Run 4 tests: 1 cold start + 3 warm starts
    for i in {0..3}; do
        n_predict=${N_PREDICT_VALUES[$i]}
        test_label=${TEST_LABELS[$i]}
        
        # Create test payload
        PROMPT='{"prompt":"User: What'\''s the difference between 1-bit and 8-bit quantization?\n\nAssistant:","n_predict":'$n_predict'}'
        
        # Run test
        start_time=$(date +%s)
        echo "$PROMPT" | base64 | aws lambda invoke \
            --function-name "$FUNCTION_NAME" \
            --region "$REGION" \
            --payload file:///dev/stdin \
            --cli-read-timeout 300 \
            response.json > /dev/null
        end_time=$(date +%s)
        
        duration=$((end_time - start_time))
        response=$(cat response.json | jq -r '.body' | jq -r '.content' | head -c 30 2>/dev/null || echo "ERROR")
        
        echo "${memory},${test_label},${n_predict},${duration},${response}..."
        
        rm -f response.json
        
        # Brief pause between tests (except after last test)
        if [ $i -lt 3 ]; then
            sleep 3
        fi
    done
    
    echo ""  # Empty line between memory configurations
done
