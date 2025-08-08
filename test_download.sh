#!/bin/bash

# QQQ Puts Test Download - Single Week
BASE_URL="http://localhost:25503/v3/option/history/quote"
OUTPUT_DIR="/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08"
mkdir -p "$OUTPUT_DIR"

echo "Testing Brian's endpoint format..."

# Test single day
DATE="20241104"
URL="${BASE_URL}?symbol=QQQ&expiration=*&date=${DATE}&interval=1m&right=P"
OUTPUT_FILE="$OUTPUT_DIR/test_${DATE}.json"

echo "URL: $URL"
echo "Downloading to: $OUTPUT_FILE"

# Download in background with timeout
(
    sleep 30
    echo "Timeout - killing curl"
    pkill -f "curl.*${DATE}"
) &
TIMEOUT_PID=$!

curl -s "$URL" -o "$OUTPUT_FILE" &
CURL_PID=$!

wait $CURL_PID
CURL_EXIT=$?

# Kill timeout process
kill $TIMEOUT_PID 2>/dev/null

if [ $CURL_EXIT -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
    echo "✓ Success! File size: $(wc -c < "$OUTPUT_FILE") bytes"
    echo "Sample content:"
    head -c 500 "$OUTPUT_FILE"
else
    echo "✗ Failed or empty file"
    ls -la "$OUTPUT_FILE" 2>/dev/null || echo "File not found"
fi
