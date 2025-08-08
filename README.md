# Theta Data MCP Downloader

This project provides a complete setup for downloading historical options data from Theta Data using their Model Context Protocol (MCP) integration with VS Code.

## Setup Complete

✅ **Theta Terminal V3** - Running with authentication  
✅ **MCP Server** - Live at `http://localhost:25503/mcp/sse`  
✅ **VS Code Integration** - MCP client extension installed and configured  
✅ **Download Scripts** - Production-ready batch downloaders  

## Files

### Core Components
- `ThetaTerminalv3.jar` - Theta Terminal application
- `creds.txt` - Authentication credentials (secured)
- `config.toml` - Theta Terminal configuration

### VS Code Integration
- `.vscode/settings.json` - MCP server configuration
- `.vscode/tasks.json` - Start Theta Terminal task

### Download Scripts
- `production_download.sh` - Full range downloader (2016-2025)
- `simple_download.sh` - Basic downloader for testing
- `test_download.sh` - Single-day test downloader

### MCP Requests
- `mcp_request.json` - Natural language MCP request
- `mcp_request_jsonrpc.json` - JSON-RPC format request
- `theta_mcp_request.json` - Specific data request format

## Current Download

**Target:** QQQ Puts 1-minute historical data  
**Range:** 2016-01-04 to 2025-08-07  
**Format:** JSON with bid/ask/volume data  
**Storage:** `/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08/`  

### Data Schema
```
symbol,expiration,strike,right,timestamp,bid_size,bid_exchange,bid,bid_condition,ask_size,ask_exchange,ask,ask_condition
```

## Usage

### Start Theta Terminal
```bash
java -jar ThetaTerminalv3.jar --creds-file creds.txt
```

### Run Downloads
```bash
# Test single day
./test_download.sh

# Production download (all dates)
./production_download.sh
```

### Monitor Progress
```bash
# Watch log
tail -f "/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08/download_progress.log"

# Count files
ls "/Volumes/SSD 4TB/Theta Terminal/QQQ/2025-08-08"/QQQ_P_*.json | wc -l
```

## API Endpoints Used

Based on Brian from Theta Data's recommendation:
```
http://localhost:25503/v3/option/history/quote?symbol=QQQ&expiration=*&date=YYYYMMDD&interval=1m&right=P
```

## Credentials

- Email: ricardo@figment.com.mx
- Package: Standard (historical data from 2016 to today-1)

## Security

- `creds.txt` is excluded from git
- File permissions set to 600 (owner read/write only)
- Sensitive data not committed to repository
