#!/bin/bash
# Installation script for Doubao Search Skill

set -e

echo "📦 Installing Doubao Search Skill..."
echo "========================================"

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ Error: This skill requires macOS (AppleScript support)"
    echo "   Windows and Linux support is planned for future versions."
    exit 1
fi

# Check if Chrome is installed
if ! osascript -e 'tell application "System Events" to get name of processes' 2>/dev/null | grep -qi "Google Chrome"; then
    echo "⚠️  Warning: Google Chrome not found or not running"
    echo "   Please install Chrome from https://www.google.com/chrome/"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if osascript is available
if ! command -v osascript &> /dev/null; then
    echo "❌ Error: osascript not found. This is required for AppleScript."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Make scripts executable
echo "🔧 Setting up scripts..."
chmod +x "$(dirname "$0")/doubao_search.sh"
chmod +x "$(dirname "$0")/../examples/test_basic.sh" 2>/dev/null || true

# Create symlink to scripts directory in PATH if requested
echo ""
read -p "Create symlink to /usr/local/bin for easy access? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -w /usr/local/bin ]]; then
        ln -sf "$(dirname "$0")/doubao_search.sh" /usr/local/bin/doubao-search
        echo "✅ Created symlink: /usr/local/bin/doubao-search"
    else
        echo "⚠️  Cannot write to /usr/local/bin. Try with sudo or skip."
        read -p "Try with sudo? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo ln -sf "$(dirname "$0")/doubao_search.sh" /usr/local/bin/doubao-search
            echo "✅ Created symlink with sudo: /usr/local/bin/doubao-search"
        fi
    fi
fi

# Create configuration file
echo "📝 Setting up configuration..."
CONFIG_FILE="$(dirname "$0")/../config.yaml"
if [[ ! -f "$CONFIG_FILE" ]]; then
    cp "$(dirname "$0")/../config.example.yaml" "$CONFIG_FILE"
    echo "✅ Created config.yaml from example"
else
    echo "✅ config.yaml already exists"
fi

# Create output directory
OUTPUT_DIR="/tmp/doubao_results"
mkdir -p "$OUTPUT_DIR"
echo "✅ Created output directory: $OUTPUT_DIR"

# Test AppleScript permissions
echo "🔐 Checking AppleScript permissions..."
echo "   Note: You may need to grant Accessibility permissions to Terminal/OpenClaw"
echo "   System Preferences → Security & Privacy → Privacy → Accessibility"

# Run a simple test
echo "🧪 Running basic test..."
TEST_RESULT=$(osascript -e 'tell application "System Events" to get name of processes' 2>&1 | head -5)
if [[ $? -eq 0 ]]; then
    echo "✅ AppleScript is working"
else
    echo "⚠️  AppleScript may have permission issues:"
    echo "   $TEST_RESULT"
fi

echo ""
echo "========================================"
echo "🎉 Installation complete!"
echo ""
echo "Quick start:"
echo "1. Open Chrome and go to https://www.doubao.com/chat/"
echo "2. Make sure OpenClaw browser extension is attached (badge shows ON)"
echo "3. Manually search for something in Doubao"
echo "4. Run: ./scripts/doubao_search.sh --clean"
echo ""
echo "Or if you created symlink:"
echo "   doubao-search --clean"
echo ""
echo "For more examples, see:"
echo "   ./examples/basic_usage.md"
echo ""
echo "Need help? Check the README.md file or run:"
echo "   ./scripts/doubao_search.sh --help"
echo "========================================"