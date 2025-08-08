#!/bin/bash

# Production QQQ Puts Downloader - Full Range 2016-2025
BASE_URL="http://localhost:25503/v3/option/history/quote"
OUTPUT_DIR="/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08"
LOG_FILE="$OUTPUT_DIR/download_progress.log"

mkdir -p "$OUTPUT_DIR"

# Calculate total business days for progress tracking
calculate_business_days() {
    local start_year=2016
    local end_year=2025
    local total_days=0
    
    for year in $(seq $start_year $end_year); do
        if [ $year -eq 2025 ]; then
            # Only through August 7, 2025
            for month in {01..08}; do
                local days_in_month
                case $month in
                    02) days_in_month=28 ;;
                    04|06|09|11) days_in_month=30 ;;
                    *) days_in_month=31 ;;
                esac
                
                if [ $month -eq 08 ]; then
                    days_in_month=7  # Only through August 7
                fi
                
                # Estimate ~70% are business days
                total_days=$((total_days + (days_in_month * 70 / 100)))
            done
        else
            # Full year estimate: ~260 business days
            total_days=$((total_days + 260))
        fi
    done
    
    echo $total_days
}

TOTAL_ESTIMATED_DAYS=$(calculate_business_days)
START_TIME=$(date +%s)

echo "QQQ Puts Production Download Started: $(date)" | tee "$LOG_FILE"
echo "Range: 2016-01-04 to 2025-08-07" | tee -a "$LOG_FILE"
echo "Estimated business days: $TOTAL_ESTIMATED_DAYS" | tee -a "$LOG_FILE"
echo "Output: $OUTPUT_DIR" | tee -a "$LOG_FILE"

# Counters
success=0
failed=0
skipped=0

# Download function with progress tracking
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
        
        # Calculate and show progress
        show_progress
        return 0
    else
        echo "✗ $date failed (exit:$result)" | tee -a "$LOG_FILE"
        rm -f "$file"
        ((failed++))
        return 1
    fi
}

# Progress calculation function
show_progress() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local total_processed=$((success + failed + skipped))
    
    if [ $total_processed -gt 0 ] && [ $elapsed -gt 0 ]; then
        local percentage=$((total_processed * 100 / TOTAL_ESTIMATED_DAYS))
        local rate=$((total_processed * 3600 / elapsed))  # files per hour
        local remaining=$((TOTAL_ESTIMATED_DAYS - total_processed))
        local eta_hours=$((remaining * 3600 / rate))
        local eta_minutes=$((eta_hours / 60))
        
        # Format ETA
        local eta_text=""
        if [ $eta_minutes -gt 60 ]; then
            local hours=$((eta_minutes / 60))
            local mins=$((eta_minutes % 60))
            eta_text="${hours}h ${mins}m"
        else
            eta_text="${eta_minutes}m"
        fi
        
        echo "PROGRESS: ${percentage}% (${total_processed}/${TOTAL_ESTIMATED_DAYS}) | Rate: ${rate}/hr | ETA: ${eta_text}" | tee -a "$LOG_FILE"
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
