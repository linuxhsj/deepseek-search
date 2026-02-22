#!/bin/bash
# Doubao Search Automation Script
# Uses AppleScript + JavaScript to bypass CDP limitations

set -e

# Default values
QUERY=""
CLEAN=false
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [query] [options]"
            echo ""
            echo "Search Doubao and extract results."
            echo ""
            echo "Arguments:"
            echo "  query               Search query (optional if already searched)"
            echo ""
            echo "Options:"
            echo "  --clean             Clean output by removing non-content elements"
            echo "  --verbose, -v       Show verbose output"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 \"广州旅游景点推荐\""
            echo "  $0 \"2026年2月份 广州十大游玩地\" --clean"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            QUERY="$1"
            shift
            ;;
    esac
done

# Log function
log() {
    if [ "$VERBOSE" = true ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    fi
}

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This script requires macOS (AppleScript support)"
    exit 1
fi

# Check if Chrome is installed
if ! osascript -e 'tell application "System Events" to get name of processes' | grep -qi "Google Chrome"; then
    echo "Error: Google Chrome is not running"
    exit 1
fi

# If query provided, we need to enter it and search
if [ -n "$QUERY" ]; then
    log "Query provided: '$QUERY'"
    log "Note: Auto-searching not yet implemented. Please manually search first."
    log "Opening Doubao page and focusing tab..."
    
    # Just focus the tab for now (auto-search would require CDP)
    osascript -e 'tell application "Google Chrome"
        activate
        delay 0.5
    end tell' > /dev/null 2>&1
    
    echo "Please manually enter query and press Enter, then re-run without query to extract results."
    exit 0
fi

log "Extracting content from Doubao page..."

# Extract content using JavaScript
CONTENT=$(osascript <<'EOF'
tell application "Google Chrome"
    set foundTab to missing value
    
    -- Find Doubao tab
    repeat with w in windows
        repeat with t in tabs of w
            if URL of t contains "doubao.com/chat" then
                set foundTab to t
                exit repeat
            end if
        end repeat
        if foundTab is not missing value then exit repeat
    end repeat
    
    if foundTab is missing value then
        return "ERROR: Doubao tab not found. Please open https://www.doubao.com/chat/ in Chrome."
    end if
    
    -- Execute JavaScript to extract content
    tell foundTab
        set jsCode to "(function() {
            // Get all text
            var text = document.body.innerText;
            
            // Try to find any substantial response content
            // Look for sections with multiple lines and Chinese text
            var lines = text.split('\\n');
            var contentLines = [];
            var inContent = false;
            
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.length === 0) continue;
                
                // Heuristic: content lines typically have Chinese characters and reasonable length
                var hasChinese = /[\\u4e00-\\u9fff]/.test(line);
                var isNavigation = line.includes('新对话') || line.includes('AI 创作') || 
                                 line.includes('云盘') || line.includes('更多') ||
                                 line.includes('历史对话') || line.includes('抖音');
                
                if (hasChinese && !isNavigation && line.length > 20) {
                    contentLines.push(line);
                }
            }
            
            // If we found content lines, return them
            if (contentLines.length > 5) {
                return contentLines.join('\\n\\n');
            }
            
            // Fallback: return everything and let the shell script clean it
            return text;
        })()"
        
        set pageText to execute javascript jsCode
        return pageText
    end tell
end tell
EOF
)

# Check for errors
if [[ "$CONTENT" == ERROR:* ]]; then
    echo "$CONTENT"
    exit 1
fi

if [ -z "$CONTENT" ] || [ "$CONTENT" = "missing value" ]; then
    echo "Error: Failed to extract content from Doubao page"
    exit 1
fi

log "Raw content extracted: ${#CONTENT} characters"

# Clean content if requested
if [ "$CLEAN" = true ]; then
    log "Cleaning content..."
    
    # Remove common navigation elements
    CLEANED=$(echo "$CONTENT" | grep -v -E '^(新对话|AI 创作|云盘|更多|历史对话|抖音)' | \
        grep -v -E '^(快速|帮我写作|编程|深入研究|图像生成|解题答疑|更多)' | \
        grep -v -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
        sed '/^$/d' | \
        awk 'length($0) > 20 || /[[:alnum:]]/{print}' | \
        head -100)
    
    CONTENT="$CLEANED"
    log "Cleaned content: ${#CONTENT} characters"
fi

# Output result
echo "=== DOUBAO SEARCH RESULTS ==="
echo ""
echo "$CONTENT"
echo ""
echo "=== END RESULTS ==="

# Also save to file with timestamp
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
OUTPUT_FILE="/tmp/doubao_result_${TIMESTAMP}.txt"
echo "$CONTENT" > "$OUTPUT_FILE"
log "Results saved to: $OUTPUT_FILE"