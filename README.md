# Doubao Search Automation Skill

A skill for automating search operations on Doubao (ByteDance AI assistant) using AppleScript + JavaScript to bypass CDP restrictions.

## Overview

This skill provides a reliable way to extract search results from Doubao (`https://www.doubao.com/chat/`) without relying on unstable CDP (Chrome DevTools Protocol) connections. It uses macOS system APIs combined with browser JavaScript injection to overcome the limitations of traditional browser automation tools when working with Doubao's dynamic SPA application.

## Problem Statement

Traditional browser automation tools (like Playwright, Puppeteer, or OpenClaw's browser tool) often fail with Doubao because:

1. **CDP Connection Instability**: Doubao's dynamic page updates frequently disconnect CDP sessions
2. **Security Restrictions**: Doubao may block remote debugging protocols
3. **Dynamic Content**: Search results are generated dynamically after page load

## Solution

This skill bypasses these issues by:

1. **Using AppleScript**: Controls Chrome at the macOS system level
2. **JavaScript Injection**: Extracts content directly from page DOM
3. **Content Pattern Matching**: Locates search results by text patterns
4. **System-Level Automation**: No dependency on CDP connections

## Installation

### Prerequisites

- macOS (requires AppleScript support)
- Google Chrome installed
- OpenClaw browser extension installed and attached to Doubao tab

### Skill Setup

1. Ensure the skill is in your OpenClaw skills directory:
   ```
   ~/.openclaw/workspace/skills/doubao-search/
   ```

2. Make scripts executable:
   ```bash
   chmod +x ~/.openclaw/workspace/skills/doubao-search/scripts/*.sh
   ```

## Usage

### From OpenClaw

When you need to search Doubao:

1. **Activate the skill**: Mention "doubao search" or similar keywords
2. **Follow the workflow**:
   - Skill will guide you to open Doubao page in Chrome
   - You'll manually enter the search query (due to CDP limitations)
   - Skill will extract and format the results

### Command Line Usage

#### Shell Script
```bash
# Extract content from already-searched Doubao page
./scripts/doubao_search.sh

# Extract with cleaning
./scripts/doubao_search.sh --clean

# Verbose output
./scripts/doubao_search.sh --verbose
```

#### Python Module
```python
from scripts.doubao_search import search_doubao

# Search and extract results
result = search_doubao("广州旅游景点推荐", clean=True, verbose=True)

if result['success']:
    print(result['content'])
    print(f"Extracted {result['length']} characters in {result['elapsed_time']:.2f} seconds")
else:
    print(f"Error: {result['error']}")
```

### Complete Workflow Example

1. **Manual Step**: Open Chrome, navigate to `https://www.doubao.com/chat/`
2. **Manual Step**: Enter your search query and press Enter
3. **Automated Step**: Run the skill to extract results:
   ```bash
   ./scripts/doubao_search.sh --clean --verbose
   ```

## How It Works

### Technical Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AppleScript   │    │   JavaScript    │    │   Content       │
│   (macOS)       │───▶│   (Chrome)      │───▶│   Processing    │
│                 │    │                 │    │   (Python)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
  Find Chrome tab       Extract page text      Clean & structure
  Activate window       Locate results         Format output
  Execute JS           Filter content
```

### Step-by-Step Process

1. **Tab Location**: AppleScript finds Chrome tab with Doubao URL
2. **Window Activation**: Brings Chrome window to foreground
3. **JavaScript Execution**: Injects script to extract page content
4. **Content Targeting**: Locates search results by text patterns
5. **Data Extraction**: Captures the relevant content section
6. **Cleaning**: Removes navigation, ads, and irrelevant elements
7. **Output**: Returns structured, cleaned content

### JavaScript Extraction Logic

The core extraction script:
```javascript
// 1. Get all text from page
var text = document.body.innerText;

// 2. Find search query in text
var start = text.indexOf("搜索关键词");

// 3. Find end of content (look for markers)
var end = text.indexOf("参考") || text.indexOf("我可以帮你");

// 4. Extract and clean
return text.substring(start, end).trim();
```

## API Reference

### Shell Script (`doubao_search.sh`)

**Arguments:**
- `--clean`: Remove navigation and non-content elements
- `--verbose`, `-v`: Show detailed progress information
- `--help`, `-h`: Show help message

**Environment Variables:**
- `DOUBAO_DEBUG`: Set to `1` for debug output
- `DOUBAO_OUTPUT_DIR`: Custom output directory (default: `/tmp`)

### Python Module (`doubao_search.py`)

**Main Functions:**
- `search_doubao(query, clean=True, verbose=False)`: Main search function
- `extract_content(query=None)`: Extract content from current page
- `clean_content(content, query=None)`: Clean and format extracted content
- `find_doubao_tab()`: Locate Doubao tab in Chrome

**Classes:**
- `DoubaoSearchError`: Custom exception for search errors

## Error Handling

The skill handles common errors:

1. **Tab Not Found**: Checks if Doubao page is open in Chrome
2. **No Content**: Verifies search results are present
3. **JavaScript Error**: Falls back to alternative extraction methods
4. **System Errors**: Checks macOS and Chrome availability

## Limitations

### Platform Restrictions
- **macOS Only**: Requires AppleScript (no Windows/Linux support)
- **Chrome Required**: Only tested with Google Chrome
- **Manual Input**: Cannot automate typing due to CDP limitations

### Functional Limitations
- Cannot automatically enter search queries (requires manual typing)
- May miss some content if page structure changes
- Requires OpenClaw browser extension for initial setup

## Future Enhancements

Planned improvements:

1. **Cross-Platform Support**: Add Windows (PowerShell) and Linux (DBus) alternatives
2. **Auto-Search**: Integrate with system automation to type queries
3. **Enhanced Extraction**: Better AI-powered content recognition
4. **Batch Processing**: Support multiple sequential searches
5. **API Server**: REST API for remote Doubao search

## Troubleshooting

### Common Issues

**"Doubao tab not found"**
- Ensure Chrome is running with Doubao tab open
- Verify URL is exactly `https://www.doubao.com/chat/`
- Check OpenClaw browser extension is attached (badge shows ON)

**"No content extracted"**
- Wait for Doubao to finish generating response
- Try `--clean` flag to filter non-content elements
- Check if search query was properly entered

**AppleScript permissions**
- Grant Accessibility permissions to Terminal/OpenClaw
- System Preferences → Security & Privacy → Privacy → Accessibility

### Debug Mode

Enable debug output:
```bash
DOUBAO_DEBUG=1 ./scripts/doubao_search.sh --verbose
```

## Related Skills

- `browser-use`: General browser automation
- `websearch-deep`: Deep web research capabilities  
- `exa-web-search-free`: Alternative search methods

## Contributing

1. Fork the repository
2. Create feature branch
3. Submit pull request

## License

MIT License

## Credits

Developed based on successful implementation of Doubao search automation that bypasses CDP limitations using AppleScript + JavaScript.

## Changelog

### v1.0.0 (2026-02-22)
- Initial release
- AppleScript + JavaScript extraction
- Content cleaning and formatting
- Shell and Python interfaces