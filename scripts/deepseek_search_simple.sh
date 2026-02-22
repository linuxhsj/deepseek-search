#!/bin/bash
# DeepSeek Search Automation Script (Simplified Background Version)
# Uses AppleScript + JavaScript to bypass CDP limitations
# All operations performed in background without activating Chrome window

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
            echo "Search DeepSeek and extract results (background execution)."
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
            echo "  $0 \"测试查询\""
            echo "  $0 \"最近3年最火的工作前3名\" --clean"
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
    log "Opening new DeepSeek tab in background..."
    
    # Step 1: Create new tab in background (no window activation)
    log "Creating new DeepSeek tab..."
    osascript <<'EOF' > /dev/null 2>&1
tell application "Google Chrome"
    -- Create new tab with DeepSeek (background operation)
    tell window 1
        make new tab with properties {URL:"https://chat.deepseek.com/"}
    end tell
end tell
EOF
    
    # Wait for page to load
    log "Waiting for page to load..."
    sleep 2
    
    # Step 2: Input query in background
    log "Inputting query in background..."
    osascript <<EOF > /dev/null 2>&1
tell application "Google Chrome"
    -- Find DeepSeek tab (most recent one)
    set deepseekTab to missing value
    set latestTime to 0
    
    repeat with w in windows
        repeat with t in tabs of w
            if URL of t contains "chat.deepseek.com" then
                -- Get tab's last accessed time (approximation)
                try
                    set tabTime to (execute javascript "Date.now();") of t
                    if tabTime > latestTime then
                        set latestTime to tabTime
                        set deepseekTab to t
                    end if
                on error
                    -- If can't get time, use first found
                    if deepseekTab is missing value then
                        set deepseekTab to t
                    end if
                end try
            end if
        end repeat
    end repeat
    
    if deepseekTab is missing value then
        error "DeepSeek tab not found"
    end if
    
    -- Input query using JavaScript (background)
    tell deepseekTab
        execute javascript "
            var input = document.querySelector('textarea, [contenteditable=true], input[type=text]');
            if (input) {
                input.focus();
                if (input.tagName === 'TEXTAREA' || input.tagName === 'INPUT') {
                    input.value = '$QUERY';
                } else {
                    input.textContent = '$QUERY';
                }
                var event = new Event('input', { bubbles: true });
                input.dispatchEvent(event);
                
                // Simulate Enter key after a short delay
                setTimeout(function() {
                    var enterEvent = new KeyboardEvent('keydown', { 
                        key: 'Enter', 
                        code: 'Enter', 
                        keyCode: 13, 
                        bubbles: true 
                    });
                    input.dispatchEvent(enterEvent);
                }, 100);
            }
        "
    end tell
end tell
EOF
    
    log "Search submitted. Waiting for DeepSeek to generate answer..."
    sleep 10  # Wait for DeepSeek to generate answer
    
    log "Proceeding to extract results..."
fi

log "Extracting content from DeepSeek page..."

# Extract content using JavaScript (background)
CONTENT=$(osascript <<'EOF'
tell application "Google Chrome"
    set foundTab to missing value
    set latestTime to 0
    
    -- Find most recent DeepSeek tab
    repeat with w in windows
        repeat with t in tabs of w
            if URL of t contains "chat.deepseek.com" then
                try
                    set tabTime to (execute javascript "Date.now();") of t
                    if tabTime > latestTime then
                        set latestTime to tabTime
                        set foundTab to t
                    end if
                on error
                    if foundTab is missing value then
                        set foundTab to t
                    end if
                end try
            end if
        end repeat
    end repeat
    
    if foundTab is missing value then
        return "ERROR: DeepSeek tab not found. Please open https://chat.deepseek.com/ in Chrome."
    end if
    
    -- Execute JavaScript to extract content (background)
    tell foundTab
        set pageText to execute javascript "document.body.innerText;"
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
    echo "Error: Failed to extract content from DeepSeek page"
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
echo "=== DEEPSEEK SEARCH RESULTS ==="
echo ""
echo "$CONTENT"
echo ""
echo "=== END RESULTS ==="

# Also save to file with timestamp
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
OUTPUT_FILE="/tmp/deepseek_result_${TIMESTAMP}.txt"
echo "$CONTENT" > "$OUTPUT_FILE"
log "Results saved to: $OUTPUT_FILE"