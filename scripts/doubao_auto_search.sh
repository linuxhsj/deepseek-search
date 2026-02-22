#!/bin/bash
# Doubao Auto Search Script
# Attempts to automate the complete search process including typing and searching
# Note: This requires additional permissions and may not work reliably

set -e

QUERY=""
WAIT_TIME=5
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --query|-q)
            QUERY="$2"
            shift 2
            ;;
        --wait|-w)
            WAIT_TIME="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Attempt to automate Doubao search including typing and searching."
            echo "WARNING: This requires Accessibility permissions and may not work reliably."
            echo ""
            echo "Options:"
            echo "  --query, -q TEXT    Search query (required)"
            echo "  --wait, -w SECONDS  Wait time after search (default: 5)"
            echo "  --verbose, -v       Show verbose output"
            echo "  --help, -h          Show this help"
            echo ""
            echo "Example:"
            echo "  $0 --query \"广州旅游景点推荐\" --wait 10"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if query provided
if [ -z "$QUERY" ]; then
    echo "Error: --query is required"
    exit 1
fi

log() {
    if [ "$VERBOSE" = true ]; then
        echo "[$(date '+%H:%M:%S')] $1"
    fi
}

# Check platform
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This script requires macOS"
    exit 1
fi

log "Starting Doubao auto search for: '$QUERY'"

# Step 1: Open or focus Doubao page
log "Step 1: Opening/focusing Doubao page..."

OPEN_RESULT=$(osascript <<EOF
tell application "Google Chrome"
    set doubaoTab to missing value
    set doubaoURL to "https://www.doubao.com/chat/"
    
    -- Check if Doubao tab already exists
    repeat with w in windows
        repeat with t in tabs of w
            if URL of t contains "doubao.com/chat" then
                set doubaoTab to t
                exit repeat
            end if
        end repeat
        if doubaoTab is not missing value then exit repeat
    end repeat
    
    if doubaoTab is missing value then
        -- Open new tab
        tell window 1
            set newTab to make new tab with properties {URL:doubaoURL}
            set doubaoTab to newTab
        end tell
    end if
    
    -- Activate the tab
    set active tab index of (window of doubaoTab) to index of doubaoTab in tabs of (window of doubaoTab)
    set index of (window of doubaoTab) to 1
    activate
    
    -- Wait for page to load
    delay 2
    
    return "SUCCESS"
end tell
EOF
)

if [[ "$OPEN_RESULT" != "SUCCESS" ]]; then
    echo "Error: Failed to open/focus Doubao page"
    exit 1
fi

log "✓ Doubao page focused"

# Step 2: Attempt to type query using AppleScript
# WARNING: This requires Accessibility permissions
log "Step 2: Attempting to type query (requires Accessibility permissions)..."

# First, try to focus the input field by clicking somewhere in the page
# This is a best-effort attempt
osascript <<EOF > /dev/null 2>&1 || true
tell application "System Events"
    tell process "Google Chrome"
        -- Try to click near the input area (coordinates may vary)
        -- This is a heuristic approach
        click at {500, 700}
        delay 0.5
    end tell
end tell
EOF

log "Typing query: '$QUERY'"

# Try to type the query using AppleScript
# Note: This may fail if Chrome doesn't have focus or permissions aren't granted
TYPING_ATTEMPT=$(osascript <<EOF 2>&1 || true
tell application "System Events"
    keystroke "$QUERY"
    delay 0.5
    keystroke return
    return "TYPING_ATTEMPTED"
end tell
EOF
)

if [[ "$TYPING_ATTEMPT" != "TYPING_ATTEMPTED" ]]; then
    log "⚠️  Could not type query automatically (permissions likely needed)"
    log "   You need to:"
    log "   1. Grant Accessibility permissions to Terminal/OpenClaw"
    log "   2. Manually type the query in Chrome"
    log "   Waiting for manual input..."
    
    echo ""
    echo "========================================"
    echo "AUTO-TYPING FAILED - MANUAL INPUT REQUIRED"
    echo "========================================"
    echo "Please manually:"
    echo "1. Type in Chrome: $QUERY"
    echo "2. Press Enter"
    echo "3. Wait for Doubao to generate results"
    echo ""
    read -p "Press Enter when you have completed manual search..."
    echo ""
else
    log "✓ Query typed and Enter pressed"
    log "Waiting $WAIT_TIME seconds for results..."
    sleep "$WAIT_TIME"
fi

# Step 3: Extract results
log "Step 3: Extracting results..."

# Use the main extraction script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACTION_RESULT=$("$SCRIPT_DIR/doubao_search.sh" --clean 2>&1)

if [[ $? -eq 0 ]]; then
    echo "$EXTRACTION_RESULT"
    log "✓ Results extracted successfully"
else
    echo "Error: Failed to extract results"
    echo "$EXTRACTION_RESULT"
    exit 1
fi

# Step 4: Additional wait and retry if content seems short
CONTENT_LENGTH=$(echo "$EXTRACTION_RESULT" | wc -c)
if [[ $CONTENT_LENGTH -lt 500 ]]; then
    log "⚠️  Extracted content seems short ($CONTENT_LENGTH chars)"
    log "   Doubao might still be generating results..."
    log "   Waiting additional 5 seconds and retrying..."
    
    sleep 5
    
    EXTRACTION_RESULT=$("$SCRIPT_DIR/doubao_search.sh" --clean 2>&1)
    NEW_LENGTH=$(echo "$EXTRACTION_RESULT" | wc -c)
    
    log "   Retry extracted $NEW_LENGTH characters"
    echo "$EXTRACTION_RESULT"
fi

log "Auto search completed"