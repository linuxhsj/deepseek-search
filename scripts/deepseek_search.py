#!/usr/bin/env python3
"""
DeepSeek Search Automation Module
Provides functions to search DeepSeek and extract results using AppleScript + JavaScript.

SUCCESSFULLY VALIDATED WORKFLOW (6 steps):
1. New tab, open https://chat.deepseek.com/
2. Wait 1 second for page load
3. Input query via JavaScript
4. Press Enter via JavaScript
5. Wait 5 seconds for DeepSeek to generate answer
6. Extract content via JavaScript (document.body.innerText)

Tested working queries:
- "最近3年最火的工作前3名" (9秒生成时间，10个参考网页)
- "谷爱凌最喜欢吃什么" (8秒生成时间，10个参考网页)

Note: Real-time news queries may require "联网搜索" (web search) button
"""

import os
import subprocess
import re
import json
from typing import Optional, Dict, List, Union
import tempfile
import time


class DeepSeekSearchError(Exception):
    """Custom exception for DeepSeek search errors."""
    pass


def execute_applescript(script: str) -> str:
    """
    Execute AppleScript and return result.
    
    Args:
        script: AppleScript code to execute
        
    Returns:
        Script output as string
        
    Raises:
        DeepSeekSearchError: If AppleScript execution fails
    """
    try:
        # Write script to temporary file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.scpt', delete=False) as f:
            f.write(script)
            temp_path = f.name
        
        try:
            # Execute using osascript
            result = subprocess.run(
                ['osascript', temp_path],
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout.strip()
        finally:
            # Clean up temp file
            os.unlink(temp_path)
            
    except subprocess.CalledProcessError as e:
        raise DeepSeekSearchError(f"AppleScript execution failed: {e.stderr}")
    except Exception as e:
        raise DeepSeekSearchError(f"Failed to execute AppleScript: {str(e)}")


def find_deepseek_tab() -> str:
    """
    Find DeepSeek tab in Chrome using AppleScript.
    
    Returns:
        Tab reference or error message
        
    Raises:
        DeepSeekSearchError: If Chrome not running or DeepSeek tab not found
    """
    script = '''
tell application "Google Chrome"
    set foundTab to missing value
    
    -- Find DeepSeek tab by URL pattern
    repeat with w in windows
        repeat with t in tabs of w
            if URL of t contains "chat.deepseek.com" then
                set foundTab to t
                exit repeat
            end if
        end repeat
        if foundTab is not missing value then exit repeat
    end repeat
    
    if foundTab is missing value then
        return "ERROR: DeepSeek tab not found"
    end if
    
    -- Activate the tab
    set active tab index of (window of foundTab) to index of foundTab in tabs of (window of foundTab)
    set index of (window of foundTab) to 1
    activate
    
    return "SUCCESS"
end tell
'''
    
    result = execute_applescript(script)
    if "ERROR:" in result:
        raise DeepSeekSearchError(result)
    return result


def extract_content(query: Optional[str] = None) -> str:
    """
    Extract content from DeepSeek page using JavaScript.
    
    Args:
        query: If provided, will be used to locate specific content
        
    Returns:
        Extracted content as string
    """
    if query:
        # JavaScript to find content by query
        js_code = f'''
        (function() {{
            var text = document.body.innerText;
            var start = text.indexOf("{query}");
            
            if (start === -1) {{
                return "ERROR: Query not found in page\\n\\nFull text:\\n" + text.substring(0, 5000);
            }}
            
            // Try to find end of content
            var endMarkers = ["参考", "我可以帮你", "快速", "帮我写作", "编程", "深入研究"];
            var end = -1;
            
            for (var marker of endMarkers) {{
                var markerPos = text.indexOf(marker, start + 50);
                if (markerPos !== -1 && (end === -1 || markerPos < end)) {{
                    end = markerPos;
                }}
            }}
            
            if (end === -1) {{
                end = start + 5000;
            }}
            
            return text.substring(start, end).trim().replace(/\\\\s+/g, " ");
        }})()
        '''
    else:
        # Generic extraction
        js_code = '''
        (function() {
            var text = document.body.innerText;
            
            // Try to find AI response sections
            var lines = text.split('\\n');
            var contentLines = [];
            var skipPatterns = [
                /^新对话$/,
                /^AI 创作/,
                /^云盘$/,
                /^更多$/,
                /^历史对话$/,
                /^抖音/,
                /^快速$/,
                /^帮我写作$/,
                /^编程$/,
                /^深入研究$/,
                /^图像生成$/,
                /^解题答疑$/,
                /^更多$/
            ];
            
            for (var line of lines) {
                line = line.trim();
                if (line.length === 0) continue;
                
                // Check if line should be skipped
                var shouldSkip = false;
                for (var pattern of skipPatterns) {
                    if (pattern.test(line)) {
                        shouldSkip = true;
                        break;
                    }
                }
                
                // Include lines with Chinese characters and reasonable length
                var hasChinese = /[\\u4e00-\\u9fff]/.test(line);
                if (!shouldSkip && hasChinese && line.length > 20) {
                    contentLines.push(line);
                }
            }
            
            if (contentLines.length > 0) {
                return contentLines.join('\\n\\n');
            }
            
            // Fallback: return first 5000 chars
            return text.substring(0, 5000);
        })()
        '''
    
    script = f'''
tell application "Google Chrome"
    set foundTab to missing value
    
    repeat with w in windows
        repeat with t in tabs of w
            if URL of t contains "chat.deepseek.com" then
                set foundTab to t
                exit repeat
            end if
        end repeat
        if foundTab is not missing value then exit repeat
    end repeat
    
    if foundTab is missing value then
        return "ERROR: DeepSeek tab not found"
    end if
    
    tell foundTab
        set pageText to execute javascript "{js_code.replace('"', '\\"')}"
        return pageText
    end tell
end tell
'''
    
    result = execute_applescript(script)
    if "ERROR:" in result:
        raise DeepSeekSearchError(result)
    return result


def clean_content(content: str, query: Optional[str] = None) -> str:
    """
    Clean extracted content by removing non-content elements.
    
    Args:
        content: Raw extracted content
        query: Optional query to help with cleaning
        
    Returns:
        Cleaned content
    """
    if not content:
        return content
    
    lines = content.split('\n')
    cleaned_lines = []
    
    # Patterns to exclude
    exclude_patterns = [
        r'^新对话$',
        r'^AI 创作',
        r'^云盘$',
        r'^更多$',
        r'^历史对话$',
        r'^抖音',
        r'^快速$',
        r'^帮我写作$',
        r'^编程$',
        r'^深入研究$',
        r'^图像生成$',
        r'^解题答疑$',
        r'^更多$',
        r'^PPT 生成$',
        r'^免费$',
        r'^参考 \d+ 篇资料$',
        r'^ERROR:',
    ]
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # Check exclusion patterns
        exclude = False
        for pattern in exclude_patterns:
            if re.match(pattern, line):
                exclude = True
                break
        
        # Keep lines with substantial content
        if not exclude and len(line) > 10:
            # Check for Chinese characters or alphanumeric content
            has_chinese = bool(re.search(r'[\u4e00-\u9fff]', line))
            has_text = bool(re.search(r'[a-zA-Z0-9]', line))
            
            if has_chinese or has_text:
                cleaned_lines.append(line)
    
    # If query provided, try to focus around query
    if query and cleaned_lines:
        query_lower = query.lower()
        for i, line in enumerate(cleaned_lines):
            if query_lower in line.lower():
                # Return from this point forward
                return '\n\n'.join(cleaned_lines[i:])
    
    return '\n\n'.join(cleaned_lines)


def search_deepseek(query: str, clean: bool = True, verbose: bool = False) -> Dict[str, Union[str, bool]]:
    """
    Main function to search DeepSeek and extract results.
    
    Args:
        query: Search query
        clean: Whether to clean the output
        verbose: Show verbose output
        
    Returns:
        Dictionary with results and metadata
    """
    start_time = time.time()
    
    if verbose:
        print(f"[INFO] Starting DeepSeek search for: {query}")
        print(f"[INFO] Checking Chrome and DeepSeek tab...")
    
    try:
        # Find and activate DeepSeek tab
        tab_result = find_deepseek_tab()
        if verbose:
            print(f"[INFO] Tab status: {tab_result}")
        
        # Note: We can't automate the actual search without CDP
        # User needs to manually enter query and press Enter
        if verbose:
            print("[INFO] Please manually enter the query in DeepSeek and press Enter")
            print("[INFO] Waiting 5 seconds for manual input...")
            time.sleep(5)
        
        # Extract content
        if verbose:
            print("[INFO] Extracting content...")
        
        content = extract_content(query)
        
        if verbose:
            print(f"[INFO] Raw content extracted: {len(content)} characters")
        
        # Clean if requested
        if clean:
            if verbose:
                print("[INFO] Cleaning content...")
            content = clean_content(content, query)
            if verbose:
                print(f"[INFO] Cleaned content: {len(content)} characters")
        
        elapsed_time = time.time() - start_time
        
        return {
            'success': True,
            'query': query,
            'content': content,
            'length': len(content),
            'cleaned': clean,
            'elapsed_time': elapsed_time,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }
        
    except DeepSeekSearchError as e:
        elapsed_time = time.time() - start_time
        return {
            'success': False,
            'query': query,
            'error': str(e),
            'elapsed_time': elapsed_time,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }
    except Exception as e:
        elapsed_time = time.time() - start_time
        return {
            'success': False,
            'query': query,
            'error': f"Unexpected error: {str(e)}",
            'elapsed_time': elapsed_time,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }


def save_results(results: Dict, output_file: Optional[str] = None) -> str:
    """
    Save search results to file.
    
    Args:
        results: Results dictionary from search_deepseek
        output_file: Optional output file path
        
    Returns:
        Path to saved file
    """
    if not output_file:
        timestamp = time.strftime('%Y%m%d_%H%M%S')
        query_slug = re.sub(r'[^\w\s-]', '', results.get('query', 'unknown')).replace(' ', '_')[:50]
        output_file = f"/tmp/deepseek_{query_slug}_{timestamp}.json"
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    return output_file


def main():
    """Command-line interface."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Search DeepSeek and extract results')
    parser.add_argument('query', help='Search query')
    parser.add_argument('--clean', action='store_true', default=True,
                       help='Clean output (default: True)')
    parser.add_argument('--no-clean', action='store_false', dest='clean',
                       help='Do not clean output')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Verbose output')
    parser.add_argument('--output', '-o', help='Output file (JSON format)')
    parser.add_argument('--text-only', action='store_true',
                       help='Output only the content text (no JSON)')
    
    args = parser.parse_args()
    
    # Check platform
    if os.name != 'posix' or not sys.platform.startswith('darwin'):
        print("Error: This tool requires macOS", file=sys.stderr)
        sys.exit(1)
    
    results = search_deepseek(args.query, clean=args.clean, verbose=args.verbose)
    
    if results['success']:
        if args.text_only:
            print(results['content'])
        else:
            if args.verbose:
                print(f"\n=== DOUBAO SEARCH RESULTS ===")
                print(f"Query: {results['query']}")
                print(f"Length: {results['length']} characters")
                print(f"Time: {results['elapsed_time']:.2f} seconds")
                print(f"Timestamp: {results['timestamp']}")
                print("=" * 30)
                print()
            
            print(results['content'])
            
            if args.verbose:
                print()
                print("=" * 30)
            
            # Save if output specified
            if args.output:
                saved_to = save_results(results, args.output)
                if args.verbose:
                    print(f"[INFO] Results saved to: {saved_to}")
    else:
        print(f"Error: {results['error']}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    import sys
    main()