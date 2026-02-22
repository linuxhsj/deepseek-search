---
name: deepseek-search
description: Automate DeepSeek AI assistant search operations. Open DeepSeek chat page, input search query, wait for results, and extract content using AppleScript + JavaScript to bypass CDP restrictions.
---

# DeepSeek Search Automation

This skill automates search operations on DeepSeek AI assistant website. It provides a reliable way to extract search results from DeepSeek without relying on unstable CDP connections.

## When to Use This Skill

Use this skill when you need to:
- Search for information on DeepSeek (https://chat.deepseek.com/)
- Automatically extract DeepSeek's responses to specific queries
- Bypass CDP connection issues with DeepSeek's dynamic SPA application
- Get structured output from DeepSeek's AI-generated content

## Core Features

1. **CDP-Free Automation**: Uses AppleScript + JavaScript to bypass unstable CDP connections
2. **Reliable Content Extraction**: Precisely extracts DeepSeek's response content
3. **Cross-Tool Integration**: Combines macOS system APIs with browser JavaScript
4. **Structured Output**: Returns cleaned, formatted content

## Prerequisites

- macOS (for AppleScript support)
- Google Chrome installed
- DeepSeek page already open in Chrome (with OpenClaw browser extension attached)

## How It Works

### Technical Approach

Instead of relying on CDP (Chrome DevTools Protocol) which often disconnects with DeepSeek's dynamic SPA, this skill uses:

1. **AppleScript**: Controls Chrome at the system level to activate tabs and execute JavaScript
2. **JavaScript Injection**: Extracts content directly from the page DOM
3. **Content Targeting**: Locates search results by text patterns and context

### Implementation Steps

1. **Locate DeepSeek Tab**: Find the DeepSeek chat page in Chrome using AppleScript
2. **Execute Search**: Input query and trigger search (if not already done)
3. **Extract Content**: Use JavaScript to find and extract the response content
4. **Clean Output**: Remove navigation, sidebars, and irrelevant elements

## Usage Examples

### Basic Search
```bash
# Search DeepSeek for "2026年2月份 广州十大游玩地"
./scripts/deepseek_search.sh "2026年2月份 广州十大游玩地"
```

### Python Integration
```python
from scripts.deepseek_search import search_deepseek

result = search_deepseek("2026年2月份 广州十大游玩地")
print(result)
```

### OpenClaw Agent Integration
When used within OpenClaw, the skill activates automatically for keywords like "deepseek", "DeepSeek", "搜索DeepSeek". The agent will guide you through manual search steps then extract and clean the results.

**Typical workflow:**
1. User: "搜索DeepSeek获取广州旅游景点推荐"
2. Agent: Provides step-by-step manual search instructions
3. User: Completes manual search and confirms
4. Agent: Extracts, cleans, and presents results
5. Agent: Offers further processing (summarization, formatting, etc.)

## Available Scripts

### `scripts/deepseek_search.sh`
Main shell script that orchestrates the AppleScript + JavaScript workflow.

**Arguments:**
- `query`: Search query (optional if already searched)
- `--clean`: Clean output by removing non-content elements

**Example:**
```bash
./scripts/deepseek_search.sh "广州旅游景点推荐" --clean
```

### `scripts/deepseek_search.py`
Python module with functions for DeepSeek automation.

**Functions:**
- `search_deepseek(query)`: Main search function
- `extract_deepseek_content()`: Extract content from already-searched page
- `clean_content(raw_text)`: Clean and format extracted content

## Technical Details

### AppleScript Components
```applescript
tell application "Google Chrome"
    # Find DeepSeek tab by URL pattern
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

1. **Tab Not Found**: Returns error if DeepSeek tab not open in Chrome
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
1. Chrome is running with DeepSeek tab open
2. URL is exactly `https://chat.deepseek.com/`
3. OpenClaw browser extension is attached (badge shows ON)

**"No content extracted" error**: Try:
1. Wait longer for DeepSeek to generate response
2. Use `--clean` flag to filter non-content elements
3. Check if search query was properly entered

## Installation and Testing

### Quick Install
```bash
cd ~/.openclaw/workspace/skills/deepseek-search
./scripts/install.sh
```

### Basic Test
```bash
cd ~/.openclaw/workspace/skills/deepseek-search
./examples/test_basic.sh
```

### Manual Test Workflow
1. Open Chrome and navigate to `https://chat.deepseek.com/`
2. Manually search for something (e.g., "测试")
3. Run extraction:
   ```bash
   ./scripts/deepseek_search.sh --clean --verbose
   ```

## Files Structure

```
deepseek-search/
├── SKILL.md              # Skill definition (this file)
├── README.md             # Detailed documentation
├── config.example.yaml   # Example configuration
├── scripts/
│   ├── deepseek_search.sh  # Main shell script
│   ├── deepseek_search.py  # Python module
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
# Extract content from current DeepSeek page
./scripts/deepseek_search.sh

# Extract with cleaning
./scripts/deepseek_search.sh --clean

# Verbose output for debugging
./scripts/deepseek_search.sh --verbose

# Help
./scripts/deepseek_search.sh --help
```

### Successfully Validated Workflow (Background Execution)

Based on extensive testing, the following 6-step workflow has been proven to work reliably. **All operations are performed in the background without activating Chrome window**, keeping the user's current tab (e.g., OpenClaw interface) visible and focused.

#### ✅ 6-Step DeepSeek Search Workflow (Background Execution)

1. **New Tab, Open DeepSeek** (Background)
   ```applescript
   tell application "Google Chrome"
       tell window 1
           make new tab with properties {URL:"https://chat.deepseek.com/"}
       end tell
   end tell
   ```

2. **Wait for Page Load** (1 second)

3. **Input Query** (Background JavaScript)
   ```javascript
   var input = document.querySelector('textarea, [contenteditable=true], input[type=text]');
   input.focus();
   input.value = 'QUERY_TEXT';
   input.dispatchEvent(new Event('input', { bubbles: true }));
   ```

4. **Press Enter** (Background JavaScript)
   ```javascript
   var enterEvent = new KeyboardEvent('keydown', { 
     key: 'Enter', 
     code: 'Enter', 
     keyCode: 13, 
     bubbles: true 
   });
   input.dispatchEvent(enterEvent);
   ```

5. **Wait 5-10 Seconds** for DeepSeek to generate answer

6. **Extract Content** (Background JavaScript)
   ```javascript
   document.body.innerText;
   ```

#### 🎯 Key Optimization: No Window Activation
- **User experience preserved**: Chrome window is not activated, user stays on current tab (e.g., OpenClaw)
- **Background operations**: All search steps performed in background
- **Non-intrusive**: No disruptive window switching

#### 🔧 Key Success Factors

#### ✅ 6-Step DeepSeek Search Workflow

1. **New Tab, Open DeepSeek**
   ```bash
   osascript -e 'tell application "Google Chrome" to activate'
   osascript -e 'tell application "Google Chrome" to tell window 1 to make new tab with properties {URL:"https://chat.deepseek.com/"}'
   sleep 1
   ```

2. **Wait for Page Load** (1 second)

3. **Input Query** (JavaScript)
   ```javascript
   var input = document.querySelector('textarea, [contenteditable=true], input[type=text]');
   if (input) {
     input.focus();
     if (input.tagName === 'TEXTAREA' || input.tagName === 'INPUT') {
       input.value = 'QUERY_TEXT';
     } else {
       input.textContent = 'QUERY_TEXT';
     }
     var event = new Event('input', { bubbles: true });
     input.dispatchEvent(event);
   }
   ```

4. **Press Enter** (JavaScript)
   ```javascript
   var enterEvent = new KeyboardEvent('keydown', { 
     key: 'Enter', 
     code: 'Enter', 
     keyCode: 13, 
     bubbles: true 
   });
   input.dispatchEvent(enterEvent);
   ```

5. **Wait 5 Seconds** for DeepSeek to generate answer
   ```bash
   sleep 5
   ```

6. **Copy All Content** (JavaScript extraction is more reliable than system clipboard)
   ```javascript
   document.body.innerText;
   ```

#### 🔧 Key Success Factors
- **Always open new tab**: Avoids interference from previous searches
- **Sufficient wait time**: 5 seconds works for most queries (complex queries may need more)
- **JavaScript over system clipboard**: More reliable for extracting page content
- **Query type matters**: Factual queries work better than real-time news (which may need web search)

#### 📊 Tested & Working Query Examples
- "最近3年最火的工作前3名" (9秒生成时间，10个参考网页)
- "谷爱凌最喜欢吃什么" (8秒生成时间，10个参考网页)

#### ⚠️ Known Limitations
- **Real-time news queries** may require clicking "联网搜索" (web search) button
- **Complex queries** may need longer wait times (>10 seconds)
- **Page load time** can vary based on network conditions

### Common Issues & Solutions
| Issue | Solution |
|-------|----------|
| "Tab not found" | Open `https://chat.deepseek.com/` in Chrome |
| "No content extracted" | Wait for DeepSeek to finish generating response |
| Permission errors | Grant Accessibility permissions to Terminal/OpenClaw |
| Chrome not found | Install Google Chrome or ensure it's running |
| Only sidebar history extracted | Ensure query was successfully submitted (check for query in history) |
| Real-time news not returned | May need to enable "联网搜索" (web search) manually |

## Credits

Developed based on successful implementation of Doubao search automation using AppleScript + JavaScript to bypass CDP limitations. Adapted for DeepSeek by cloning and modifying the original doubao-search skill.

## Version History

### v1.0.0 (2026-02-22)
- Initial release (cloned from doubao-search v1.0.0)
- Adapted for DeepSeek (https://chat.deepseek.com/)
- AppleScript + JavaScript extraction
- Content cleaning and formatting
- Shell and Python interfaces
- OpenClaw integration examples
- Comprehensive documentation