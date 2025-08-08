#!/bin/bash

# Quick Progress Check
OUTPUT_DIR="/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08"
LOG_FILE="$OUTPUT_DIR/download_progress.log"

echo "🔄 QQQ Download Status - $(date '+%H:%M:%S')"
echo "----------------------------------------"

# Get latest progress
if [ -f "$LOG_FILE" ]; then
    latest_progress=$(grep "PROGRESS:" "$LOG_FILE" | tail -1)
    if [ -n "$latest_progress" ]; then
        echo "$latest_progress"
    else
        echo "Progress tracking not available yet"
    fi
else
    echo "Download not started"
fi

# File count and size
file_count=$(ls "$OUTPUT_DIR"/QQQ_P_*.json 2>/dev/null | wc -l)
total_size=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)

echo "Files: $file_count | Size: $total_size"

# Process status
if ps aux | grep -q "[p]roduction_download.sh"; then
    echo "Status: ✅ Running"
else
    echo "Status: ⚠️  Not running"
fi
