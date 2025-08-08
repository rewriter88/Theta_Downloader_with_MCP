#!/bin/bash

# Simple QQQ Puts Downloader
BASE_URL="http://localhost:25503/v3/option/history/quote"
OUTPUT_DIR="/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08"
mkdir -p "$OUTPUT_DIR"

echo "Starting QQQ puts download..."
echo "Output: $OUTPUT_DIR"

# Download function
download_date() {
    local date="$1"
    local file="$OUTPUT_DIR/QQQ_P_${date}.json"
    
    if [ -f "$file" ]; then
        echo "Skip $date (exists)"
        return 0
    fi
    
    echo "Downloading $date..."
    local url="${BASE_URL}?symbol=QQQ&expiration=*&date=${date}&interval=1m&right=P"
    
    # Download with 2 minute timeout
    curl -s "$url" --max-time 120 -o "$file" &
    local pid=$!
    
    # Wait for completion
    wait $pid
    local result=$?
    
    if [ $result -eq 0 ] && [ -s "$file" ]; then
        local size=$(ls -lh "$file" | awk '{print $5}')
        echo "✓ $date complete ($size)"
        return 0
    else
        echo "✗ $date failed"
        rm -f "$file"
        return 1
    fi
}

# Test with recent dates first
echo "Testing recent dates..."
download_date "20241104"
download_date "20241105"
download_date "20241106"

echo "Recent test complete. Check files:"
ls -lh "$OUTPUT_DIR"/QQQ_P_*.json 2>/dev/null | tail -5
