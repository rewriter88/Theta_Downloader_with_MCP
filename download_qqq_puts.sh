#!/bin/bash

# QQQ Puts Download Script using Brian's suggested endpoint
# Downloads 1-minute option quote data for QQQ puts from 2016-2025

BASE_URL="http://localhost:25503/v3/option/history/quote"
SYMBOL="QQQ"
OUTPUT_DIR="/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08"
START_DATE="2016-01-04"  # Monday to avoid weekends
END_DATE="2025-08-07"

echo "Starting QQQ Puts download from $START_DATE to $END_DATE"
echo "Output directory: $OUTPUT_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to convert date format
date_to_api_format() {
    date -j -f "%Y-%m-%d" "$1" "+%Y%m%d" 2>/dev/null || echo ""
}

# Function to add days to date
add_days() {
    local base_date="$1"
    local days="$2"
    date -j -v+"${days}d" -f "%Y-%m-%d" "$base_date" "+%Y-%m-%d" 2>/dev/null || echo ""
}

# Function to download single day
download_day() {
    local date_str="$1"
    local api_date=$(date_to_api_format "$date_str")
    
    if [ -z "$api_date" ]; then
        echo "Invalid date: $date_str"
        return 1
    fi
    
    local output_file="$OUTPUT_DIR/QQQ_P_${date_str}_minute_quotes.json"
    
    # Skip if file already exists and is not empty
    if [ -s "$output_file" ]; then
        echo "Skipping $date_str - file exists"
        return 0
    fi
    
    echo "Downloading $date_str ($api_date)..."
    
    # Brian's suggested format: expiration=* gets all expirations for that date
    local url="${BASE_URL}?symbol=${SYMBOL}&expiration=*&date=${api_date}&interval=1m&right=P"
    
    curl -s "$url" \
        --connect-timeout 10 \
        --max-time 120 \
        -o "$output_file"
    
    # Check if download was successful
    if [ $? -eq 0 ] && [ -s "$output_file" ]; then
        local size=$(wc -c < "$output_file")
        echo "✓ Downloaded $date_str ($size bytes)"
        return 0
    else
        echo "✗ Failed to download $date_str"
        rm -f "$output_file"
        return 1
    fi
}

# Test connection first
echo "Testing connection..."
test_response=$(curl -s "${BASE_URL}?symbol=QQQ&expiration=*&date=20241104&interval=1m&right=P" --connect-timeout 5 --max-time 10)
if [ $? -ne 0 ]; then
    echo "ERROR: Cannot connect to Theta Terminal at $BASE_URL"
    exit 1
fi

echo "Connection OK. Starting bulk download..."

# Generate date range and download
current_date="$START_DATE"
success_count=0
fail_count=0

while [ "$current_date" != "$END_DATE" ] && [ -n "$current_date" ]; do
    # Skip weekends (basic check)
    day_of_week=$(date -j -f "%Y-%m-%d" "$current_date" "+%u" 2>/dev/null || echo "1")
    
    if [ "$day_of_week" -le 5 ]; then  # Monday=1, Friday=5
        if download_day "$current_date"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        
        # Brief pause to avoid overwhelming the server
        sleep 0.1
    fi
    
    # Move to next day
    current_date=$(add_days "$current_date" 1)
    
    # Progress update every 50 days
    if [ $((($success_count + $fail_count) % 50)) -eq 0 ]; then
        echo "Progress: $success_count successful, $fail_count failed"
    fi
done

echo "Download complete!"
echo "Total successful: $success_count"
echo "Total failed: $fail_count"
echo "Files saved to: $OUTPUT_DIR"

# Show summary
echo -e "\nFile summary:"
ls -lh "$OUTPUT_DIR" | grep QQQ_P | wc -l | xargs echo "Total files:"
du -sh "$OUTPUT_DIR" | cut -f1 | xargs echo "Total size:"
    # Clean up quotes from CSV
    exp_clean=$(echo "$expiration" | tr -d '"')
    
    # Download minute quotes for this expiration
    output_file="$TARGET_DIR/QQQ_P_${exp_clean}_minute_quotes.csv"
    url="$BASE_URL/option/history/quotes/minute?symbol=$SYMBOL&right=$RIGHT&expiration=$exp_clean&start_date=$START_DATE&end_date=$END_DATE&format=csv"
    
    download_with_timeout "$url" "$output_file"
    
    # Small delay to avoid rate limiting
    sleep 1
done

echo "Sample download complete. Check $TARGET_DIR for files."
ls -lah "$TARGET_DIR"
