#!/bin/bash
# Basic test script for Doubao Search Skill

set -e

echo "🧪 Doubao Search Skill - Basic Test"
echo "========================================"

# Change to skill directory
cd "$(dirname "$0")/.." || exit 1

# Check if scripts exist
if [[ ! -f "scripts/doubao_search.sh" ]]; then
    echo "❌ Error: scripts/doubao_search.sh not found"
    exit 1
fi

# Make sure script is executable
chmod +x scripts/doubao_search.sh 2>/dev/null || true

echo "1. Testing script help..."
echo "----------------------------------------"
./scripts/doubao_search.sh --help | head -20
echo "----------------------------------------"
echo "✅ Help test passed"
echo ""

echo "2. Testing AppleScript connectivity..."
echo "----------------------------------------"
if osascript -e 'tell application "System Events" to get name of processes' 2>/dev/null | grep -q "."; then
    echo "✅ AppleScript is working"
else
    echo "❌ AppleScript failed. Check permissions."
    echo "   System Preferences → Security & Privacy → Privacy → Accessibility"
    exit 1
fi
echo ""

echo "3. Checking Chrome status..."
echo "----------------------------------------"
CHROME_PROCESSES=$(osascript -e 'tell application "System Events" to get name of processes' 2>/dev/null | grep -c "Google Chrome" || true)
if [[ $CHROME_PROCESSES -gt 0 ]]; then
    echo "✅ Chrome is running"
else
    echo "⚠️  Chrome is not running. Starting Chrome..."
    open -a "Google Chrome" --background
    sleep 2
fi
echo ""

echo "4. Testing tab detection..."
echo "----------------------------------------"
echo "Please open Chrome and navigate to:"
echo "  https://www.doubao.com/chat/"
echo ""
echo "Make sure:"
echo "  1. URL is exactly: https://www.doubao.com/chat/"
echo "  2. OpenClaw browser extension badge shows ON"
echo "  3. You have manually searched for something"
echo ""
read -p "Press Enter when ready to test extraction..."

echo "5. Testing content extraction..."
echo "----------------------------------------"
echo "Running: ./scripts/doubao_search.sh --verbose"
echo ""

# Run extraction with timeout
timeout 30s ./scripts/doubao_search.sh --verbose 2>&1 | tee /tmp/doubao_test_output.txt

EXIT_CODE=${PIPESTATUS[0]}

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✅ Content extraction test passed"
    
    # Check if we got actual content
    CONTENT_LENGTH=$(wc -c < /tmp/doubao_test_output.txt | tr -d ' ')
    if [[ $CONTENT_LENGTH -gt 100 ]]; then
        echo "✅ Extracted $CONTENT_LENGTH characters"
        
        # Show preview
        echo ""
        echo "Content preview:"
        echo "----------------------------------------"
        head -20 /tmp/doubao_test_output.txt
        echo "----------------------------------------"
    else
        echo "⚠️  Extracted only $CONTENT_LENGTH characters (may be empty)"
    fi
    
elif [[ $EXIT_CODE -eq 124 ]]; then
    echo "❌ Test timed out after 30 seconds"
else
    echo "❌ Test failed with exit code: $EXIT_CODE"
    echo "Last 10 lines of output:"
    tail -10 /tmp/doubao_test_output.txt
fi

echo ""
echo "6. Testing cleaning function..."
echo "----------------------------------------"
echo "Running: ./scripts/doubao_search.sh --clean"
echo ""

CLEAN_OUTPUT=$(timeout 10s ./scripts/doubao_search.sh --clean 2>&1 | tee /tmp/doubao_clean_output.txt || true)

if [[ -n "$CLEAN_OUTPUT" ]] && [[ ! "$CLEAN_OUTPUT" =~ "ERROR" ]]; then
    echo "✅ Cleaning test passed"
    
    # Count lines before and after (if we had raw output)
    if [[ -f /tmp/doubao_test_output.txt ]] && [[ -f /tmp/doubao_clean_output.txt ]]; then
        RAW_LINES=$(wc -l < /tmp/doubao_test_output.txt)
        CLEAN_LINES=$(wc -l < /tmp/doubao_clean_output.txt)
        echo "   Raw output: $RAW_LINES lines"
        echo "   Clean output: $CLEAN_LINES lines"
    fi
else
    echo "⚠️  Cleaning test may have issues"
fi

echo ""
echo "========================================"
echo "📊 Test Summary"
echo "----------------------------------------"

# Check for common issues
ISSUES=0

# Check Chrome
if ! osascript -e 'tell application "System Events" to get name of processes' 2>/dev/null | grep -q "Google Chrome"; then
    echo "❌ Chrome not running"
    ISSUES=$((ISSUES + 1))
else
    echo "✅ Chrome is running"
fi

# Check Doubao tab
DOUBAO_TAB=$(osascript 2>/dev/null <<'EOF'
tell application "Google Chrome"
    set found to false
    repeat with w in windows
        repeat with t in tabs of w
            if URL of t contains "doubao.com/chat" then
                set found to true
                exit repeat
            end if
        end repeat
        if found then exit repeat
    end repeat
    return found
end tell
EOF
)

if [[ "$DOUBAO_TAB" == "true" ]]; then
    echo "✅ Doubao tab found"
else
    echo "❌ Doubao tab not found"
    ISSUES=$((ISSUES + 1))
fi

# Check content extraction
if [[ -f /tmp/doubao_test_output.txt ]]; then
    CONTENT=$(cat /tmp/doubao_test_output.txt)
    if [[ "$CONTENT" =~ "ERROR" ]]; then
        echo "❌ Extraction error detected"
        ISSUES=$((ISSUES + 1))
    elif [[ ${#CONTENT} -lt 100 ]]; then
        echo "⚠️  Minimal content extracted (${#CONTENT} chars)"
    else
        echo "✅ Content extracted (${#CONTENT} chars)"
    fi
fi

echo "----------------------------------------"

if [[ $ISSUES -eq 0 ]]; then
    echo "🎉 All tests passed! Skill is ready to use."
    echo ""
    echo "Next steps:"
    echo "1. Try a real search:"
    echo "   ./scripts/doubao_search.sh --clean --verbose"
    echo "2. Check examples:"
    echo "   cat examples/basic_usage.md"
    echo "3. Install for easy access:"
    echo "   ./scripts/install.sh"
else
    echo "⚠️  Found $ISSUES issue(s). Skill may not work properly."
    echo ""
    echo "Troubleshooting:"
    echo "1. Make sure Chrome is running with Doubao tab open"
    echo "2. Check URL: https://www.doubao.com/chat/"
    echo "3. Ensure OpenClaw browser extension is attached"
    echo "4. Grant Accessibility permissions to Terminal"
fi

echo "========================================"

# Cleanup
rm -f /tmp/doubao_test_output.txt /tmp/doubao_clean_output.txt 2>/dev/null || true