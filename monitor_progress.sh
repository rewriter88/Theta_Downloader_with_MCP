#!/bin/bash

# Real-time Progress Monitor for QQQ Download
OUTPUT_DIR="/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08"
LOG_FILE="$OUTPUT_DIR/download_progress.log"

echo "=== QQQ DOWNLOAD PROGRESS MONITOR ==="
echo "Monitoring: $OUTPUT_DIR"
echo "Log file: $LOG_FILE"
echo "Press Ctrl+C to exit"
echo ""

# Initial check
if [ ! -f "$LOG_FILE" ]; then
    echo "Download not started yet (log file not found)"
    exit 1
fi

while true; do
    clear
    echo "=== QQQ PUTS DOWNLOAD PROGRESS ==="
    echo "Time: $(date)"
    echo ""
    
    # Show latest progress line
    if [ -f "$LOG_FILE" ]; then
        echo "Latest Progress:"
        grep "PROGRESS:" "$LOG_FILE" | tail -1
        echo ""
        
        # Show recent activity
        echo "Recent Activity (last 5 lines):"
        tail -5 "$LOG_FILE"
        echo ""
    fi
    
    # File count and size
    file_count=$(ls "$OUTPUT_DIR"/QQQ_P_*.json 2>/dev/null | wc -l)
    total_size=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)
    
    echo "Files Downloaded: $file_count"
    echo "Total Size: $total_size"
    echo ""
    
    # Check if process is still running
    if ps aux | grep -q "[p]roduction_download.sh"; then
        echo "Status: ✅ Download process is running"
    else
        echo "Status: ⚠️  Download process not detected"
    fi
    
    echo ""
    echo "Refreshing in 10 seconds... (Ctrl+C to exit)"
    
    # Wait with interrupt capability
    for i in {10..1}; do
        echo -ne "\rNext update in: $i seconds "
        sleep 1
    done
    echo ""
done
