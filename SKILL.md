---
name: doubao-search
description: Automate Doubao (ByteDance AI assistant) search operations. Open Doubao chat page, input search query, wait for results, and extract content using AppleScript + JavaScript to bypass CDP restrictions.
---

# Doubao Search Automation

This skill automates search operations on Doubao (ByteDance AI assistant) website. It provides a reliable way to extract search results from Doubao without relying on unstable CDP connections.

## When to Use This Skill

Use this skill when you need to:
- Search for information on Doubao (https://www.doubao.com/chat/)
- Automatically extract Doubao's responses to specific queries
- Bypass CDP connection issues with Doubao's dynamic SPA application
- Get structured output from Doubao's AI-generated content

## Core Features

1. **CDP-Free Automation**: Uses AppleScript + JavaScript to bypass unstable CDP connections
2. **Reliable Content Extraction**: Precisely extracts Doubao's response content
3. **Cross-Tool Integration**: Combines macOS system APIs with browser JavaScript
4. **Structured Output**: Returns cleaned, formatted content

## Prerequisites

- macOS (for AppleScript support)
- Google Chrome installed
- Doubao page already open in Chrome (with OpenClaw browser extension attached)

## How It Works

### Technical Approach

Instead of relying on CDP (Chrome DevTools Protocol) which often disconnects with Doubao's dynamic SPA, this skill uses:

1. **AppleScript**: Controls Chrome at the system level to activate tabs and execute JavaScript
2. **JavaScript Injection**: Extracts content directly from the page DOM
3. **Content Targeting**: Locates search results by text patterns and context

### Implementation Steps

1. **Locate Doubao Tab**: Find the Doubao chat page in Chrome using AppleScript
2. **Execute Search**: Input query and trigger search (if not already done)
3. **Extract Content**: Use JavaScript to find and extract the response content
4. **Clean Output**: Remove navigation, sidebars, and irrelevant elements

## Usage Examples

### Basic Search
```bash
# Search Doubao for "2026年2月份 广州十大游玩地"
./scripts/doubao_search.sh "2026年2月份 广州十大游玩地"
```

### Python Integration
```python
from scripts.doubao_search import search_doubao

result = search_doubao("2026年2月份 广州十大游玩地")
print(result)
```

### OpenClaw Agent Integration
When used within OpenClaw, the skill activates automatically for keywords like "doubao", "豆包", "搜索豆包". The agent will guide you through manual search steps then extract and clean the results.

**Typical workflow:**
1. User: "搜索豆包获取广州旅游景点推荐"
2. Agent: Provides step-by-step manual search instructions
3. User: Completes manual search and confirms
4. Agent: Extracts, cleans, and presents results
5. Agent: Offers further processing (summarization, formatting, etc.)

## Available Scripts

### `scripts/doubao_search.sh`
Main shell script that orchestrates the AppleScript + JavaScript workflow.

**Arguments:**
- `query`: Search query (optional if already searched)
- `--clean`: Clean output by removing non-content elements

**Example:**
```bash
./scripts/doubao_search.sh "广州旅游景点推荐" --clean
```

### `scripts/doubao_search.py`
Python module with functions for Doubao automation.

**Functions:**
- `search_doubao(query)`: Main search function
- `extract_doubao_content()`: Extract content from already-searched page
- `clean_content(raw_text)`: Clean and format extracted content

## Technical Details

### AppleScript Components
```applescript
tell application "Google Chrome"
    # Find Doubao tab by URL pattern
    # Execute JavaScript to extract content
    # Return extracted text
end tell
```

### JavaScript Extraction
```javascript
// Locate search results by text pattern
var text = document.body.innerText;
var start = text.indexOf("搜索关键词");
var end = text.indexOf("参考") || text.indexOf("我可以帮你");
return text.substring(start, end).trim();
```

## Error Handling

The skill includes error handling for:

1. **Tab Not Found**: Returns error if Doubao tab not open in Chrome
2. **No Results**: Returns message if search results not found
3. **JavaScript Error**: Falls back to alternative extraction methods

## Platform Limitations

- Currently macOS-only due to AppleScript dependency
- Requires Chrome browser (not tested with Safari/Firefox)
- Requires OpenClaw browser extension for initial tab attachment

## Future Enhancements

1. **Cross-Platform Support**: Add Windows/Linux alternatives
2. **Browser Independence**: Support for other browsers
3. **Enhanced Extraction**: Better content targeting algorithms
4. **Batch Processing**: Support for multiple searches

## Related Skills

- `browser-use`: General browser automation
- `websearch-deep`: Deep web research capabilities
- `exa-web-search-free`: Alternative search methods

## Troubleshooting

**"Tab not found" error**: Make sure:
1. Chrome is running with Doubao tab open
2. URL is exactly `https://www.doubao.com/chat/`
3. OpenClaw browser extension is attached (badge shows ON)

**"No content extracted" error**: Try:
1. Wait longer for Doubao to generate response
2. Use `--clean` flag to filter non-content elements
3. Check if search query was properly entered

## Installation and Testing

### Quick Install
```bash
cd ~/.openclaw/workspace/skills/doubao-search
./scripts/install.sh
```

### Basic Test
```bash
cd ~/.openclaw/workspace/skills/doubao-search
./examples/test_basic.sh
```

### Manual Test Workflow
1. Open Chrome and navigate to `https://www.doubao.com/chat/`
2. Manually search for something (e.g., "测试")
3. Run extraction:
   ```bash
   ./scripts/doubao_search.sh --clean --verbose
   ```

## Files Structure

```
doubao-search/
├── SKILL.md              # Skill definition (this file)
├── README.md             # Detailed documentation
├── config.example.yaml   # Example configuration
├── scripts/
│   ├── doubao_search.sh  # Main shell script
│   ├── doubao_search.py  # Python module
│   └── install.sh        # Installation script
├── examples/
│   ├── basic_usage.md    # Usage examples
│   ├── openclaw_integration.md  # OpenClaw integration guide
│   └── test_basic.sh     # Test script
└── config.yaml          # User configuration (created during install)
```

## Quick Reference

### Common Commands
```bash
# Extract content from current Doubao page
./scripts/doubao_search.sh

# Extract with cleaning
./scripts/doubao_search.sh --clean

# Verbose output for debugging
./scripts/doubao_search.sh --verbose

# Help
./scripts/doubao_search.sh --help
```

### Common Issues & Solutions
| Issue | Solution |
|-------|----------|
| "Tab not found" | Open `https://www.doubao.com/chat/` in Chrome |
| "No content extracted" | Wait for Doubao to finish generating response |
| Permission errors | Grant Accessibility permissions to Terminal/OpenClaw |
| Chrome not found | Install Google Chrome or ensure it's running |

## Credits

Developed based on successful implementation of Doubao search automation using AppleScript + JavaScript to bypass CDP limitations.

## Version History

### v1.0.0 (2026-02-22)
- Initial release
- AppleScript + JavaScript extraction
- Content cleaning and formatting
- Shell and Python interfaces
- OpenClaw integration examples
- Comprehensive documentation