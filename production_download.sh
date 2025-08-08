#!/bin/bash

# Production QQQ Puts Downloader - Full Range 2016-2025
BASE_URL="http://localhost:25503/v3/option/history/quote"
OUTPUT_DIR="/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08"
LOG_FILE="$OUTPUT_DIR/download_progress.log"

mkdir -p "$OUTPUT_DIR"

echo "QQQ Puts Production Download Started: $(date)" | tee "$LOG_FILE"
echo "Range: 2016-01-04 to 2025-08-07" | tee -a "$LOG_FILE"
echo "Output: $OUTPUT_DIR" | tee -a "$LOG_FILE"

# Counters
success=0
failed=0
skipped=0

# Download function
download_date() {
    local date="$1"
    local file="$OUTPUT_DIR/QQQ_P_${date}.json"
    
    if [ -f "$file" ] && [ -s "$file" ]; then
        echo "Skip $date (exists)" | tee -a "$LOG_FILE"
        ((skipped++))
        return 0
    fi
    
    echo "$(date '+%H:%M:%S') Downloading $date..." | tee -a "$LOG_FILE"
    local url="${BASE_URL}?symbol=QQQ&expiration=*&date=${date}&interval=1m&right=P"
    
    # Download with timeout
    curl -s "$url" --max-time 180 -o "$file"
    local result=$?
    
    if [ $result -eq 0 ] && [ -s "$file" ]; then
        local size=$(ls -lh "$file" | awk '{print $5}')
        echo "✓ $date complete ($size)" | tee -a "$LOG_FILE"
        ((success++))
        return 0
    else
        echo "✗ $date failed (exit:$result)" | tee -a "$LOG_FILE"
        rm -f "$file"
        ((failed++))
        return 1
    fi
}

# Generate business days from 2016 to 2025
current_year=2016
end_date="2025-08-07"

while [ $current_year -le 2025 ]; do
    echo "Processing year $current_year..." | tee -a "$LOG_FILE"
    
    # Process each month
    for month in {01..12}; do
        # Stop if we've reached August 2025
        if [ $current_year -eq 2025 ] && [ $month -gt 08 ]; then
            break
        fi
        
        # Get days in month
        if [ $month -eq 02 ]; then
            # February - check for leap year
            if [ $(( current_year % 4 )) -eq 0 ] && ([ $(( current_year % 100 )) -ne 0 ] || [ $(( current_year % 400 )) -eq 0 ]); then
                days=29
            else
                days=28
            fi
        elif [[ $month =~ ^(04|06|09|11)$ ]]; then
            days=30
        else
            days=31
        fi
        
        # Download each day
        for day in $(seq -w 1 $days); do
            # Stop if we've reached the end date
            current_date="${current_year}${month}${day}"
            if [ "$current_date" -gt "20250807" ]; then
                break 2
            fi
            
            # Skip if before start date
            if [ "$current_date" -lt "20160104" ]; then
                continue
            fi
            
            # Check if it's a weekday (basic check)
            dow=$(date -j -f "%Y%m%d" "$current_date" "+%u" 2>/dev/null || echo "1")
            if [ $dow -le 5 ]; then  # Monday=1, Friday=5
                download_date "$current_date"
                
                # Progress update every 20 downloads
                total=$((success + failed))
                if [ $((total % 20)) -eq 0 ] && [ $total -gt 0 ]; then
                    echo "Progress: $success success, $failed failed, $skipped skipped" | tee -a "$LOG_FILE"
                    echo "Current date: $current_date" | tee -a "$LOG_FILE"
                fi
                
                # Brief pause
                sleep 0.5
            fi
        done
    done
    
    ((current_year++))
done

echo "Download complete: $(date)" | tee -a "$LOG_FILE"
echo "Final stats: $success success, $failed failed, $skipped skipped" | tee -a "$LOG_FILE"

# Summary
echo -e "\nFile summary:" | tee -a "$LOG_FILE"
total_files=$(ls "$OUTPUT_DIR"/QQQ_P_*.json 2>/dev/null | wc -l)
total_size=$(du -sh "$OUTPUT_DIR" | cut -f1)
echo "Total files: $total_files" | tee -a "$LOG_FILE"
echo "Total size: $total_size" | tee -a "$LOG_FILE"
