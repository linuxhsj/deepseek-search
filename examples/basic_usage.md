# DeepSeek Search Skill - Basic Usage Examples

## Scenario 1: Basic Search Extraction

**Goal**: Extract search results from an already-searched DeepSeek page.

**Steps**:
1. Open Chrome and navigate to DeepSeek page
2. Manually type your query (e.g., "广州旅游景点推荐")
3. Press Enter and wait for DeepSeek to generate response
4. Run the skill to extract results:

```bash
# From the skill directory
cd ~/.openclaw/workspace/skills/deepseek-search

# Basic extraction
./scripts/deepseek_search.sh

# With cleaning and verbose output
./scripts/deepseek_search.sh --clean --verbose
```

**Expected Output**:
```
=== DEEPSEEK SEARCH RESULTS ===

广州旅游景点推荐
这里为你推荐几个广州经典与新兴的旅游景点，涵盖地标、文化、自然与亲子等不同类型，方便你根据兴趣选择：

1. 广州塔（小蛮腰）
广州地标建筑，可登塔观光、体验摩天轮与极速云霄项目，傍晚时分看日落与夜景尤为震撼。交通：地铁 3 号线 / APM 线广州塔站。

2. 越秀公园（含五羊石像）
羊城象征五羊石像所在地，公园内绿树成荫，适合散步、拍照，还可参观广州博物馆（镇海楼）。交通：地铁 2 号线越秀公园站。

...

=== END RESULTS ===
```

## Scenario 2: Python Integration

**Goal**: Use DeepSeek search within a Python script or OpenClaw agent.

**Python Code**:
```python
import sys
sys.path.append(os.path.expanduser('~/.openclaw/workspace/skills/deepseek-search/scripts'))

from deepseek_search import search_deepseek

# Search for specific query
results = search_deepseek(
    query="2026年2月份 广州十大游玩地",
    clean=True,
    verbose=True
)

if results['success']:
    print(f"Success! Extracted {results['length']} characters")
    print("\n" + "="*50)
    print(results['content'])
    print("="*50)
    
    # Save to file
    import json
    with open('deepseek_results.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
else:
    print(f"Error: {results['error']}")
```

## Scenario 3: OpenClaw Agent Integration

**Goal**: Call DeepSeek search from within OpenClaw agent workflow.

**Agent Workflow**:
```python
# In your OpenClaw agent code
def search_deepseek_from_agent(query):
    """
    Search DeepSeek and return formatted results.
    """
    import subprocess
    
    # Run the shell script
    script_path = os.path.expanduser("~/.openclaw/workspace/skills/deepseek-search/scripts/deepseek_search.sh")
    
    result = subprocess.run(
        [script_path, "--clean"],
        capture_output=True,
        text=True,
        encoding='utf-8'
    )
    
    if result.returncode == 0:
        # Parse and return content
        output = result.stdout
        
        # Extract just the content between markers
        if "=== DEEPSEEK SEARCH RESULTS ===" in output:
            parts = output.split("=== DEEPSEEK SEARCH RESULTS ===")
            if len(parts) > 1:
                content = parts[1].split("=== END RESULTS ===")[0].strip()
                return content
        
        return output
    else:
        return f"Error: {result.stderr}"

# Usage in agent
query = "广州美食推荐"
print(f"Searching DeepSeek for: {query}")
print("Please manually enter this query in DeepSeek and press Enter")
print("Waiting for you to complete manual step...")

# After user completes manual step
results = search_deepseek_from_agent(query)
print(f"Extracted results:\n{results}")
```

## Scenario 4: Batch Processing

**Goal**: Extract results from multiple pre-searched DeepSeek tabs.

**Batch Script** (`batch_extract.sh`):
```bash
#!/bin/bash
# Extract from multiple queries

QUERIES=(
    "广州旅游景点推荐"
    "广州美食排行榜"
    "广州历史文化遗址"
    "广州购物中心推荐"
)

for query in "${QUERIES[@]}"; do
    echo "Processing: $query"
    echo "========================================"
    
    # Note: User needs to manually search each query first
    read -p "Please search '$query' in DeepSeek and press Enter to continue..."
    
    ./scripts/deepseek_search.sh --clean > "results_${query}.txt"
    
    echo "Saved to: results_${query}.txt"
    echo ""
done
```

## Scenario 5: Content Analysis Pipeline

**Goal**: Extract DeepSeek results and perform additional analysis.

**Pipeline Script**:
```python
import re
from typing import List, Dict

def analyze_deepseek_content(content: str) -> Dict:
    """
    Analyze extracted DeepSeek content.
    """
    # Extract numbered list items
    items = re.findall(r'\d+\.\s+([^\n]+(?:\n\s+[^\n]+)*)', content)
    
    # Extract locations mentioned
    locations = re.findall(r'[位于|在|到]\s*([\u4e00-\u9fff]+(?:区|市|站|公园|塔|山|岛))', content)
    
    # Extract transportation info
    transport = re.findall(r'交通[：:]\s*([^\n]+)', content)
    
    # Count recommendations
    lines = content.split('\n')
    recommendation_lines = [line for line in lines if '推荐' in line or '建议' in line]
    
    return {
        'total_items': len(items),
        'items': items,
        'locations': list(set(locations)),
        'transport_options': transport,
        'recommendations': len(recommendation_lines),
        'content_preview': content[:500] + '...' if len(content) > 500 else content
    }

# Usage
from deepseek_search import search_deepseek

results = search_deepseek("广州周末好去处", clean=True)
if results['success']:
    analysis = analyze_deepseek_content(results['content'])
    
    print(f"Analysis Results:")
    print(f"Found {analysis['total_items']} recommendation items")
    print(f"Mentioned locations: {', '.join(analysis['locations'])}")
    print(f"Transport options: {analysis['transport_options']}")
    
    print("\nTop recommendations:")
    for i, item in enumerate(analysis['items'][:3], 1):
        print(f"{i}. {item[:100]}...")
```

## Troubleshooting Examples

### Example 1: Handling "Tab not found" error
```bash
# Error: DeepSeek tab not found
# Solution: Open DeepSeek in Chrome first
open -a "Google Chrome"
```

### Example 2: Handling empty results
```bash
# If results are empty, try without cleaning
./scripts/deepseek_search.sh  # No --clean flag

# Or increase wait time before extraction
echo "Waiting for DeepSeek to generate response..."
sleep 10
./scripts/deepseek_search.sh --clean
```

### Example 3: Saving results with timestamp
```bash
# Custom output filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
./scripts/deepseek_search.sh --clean > "deepseek_results_${TIMESTAMP}.md"

# Also save raw output
./scripts/deepseek_search.sh > "deepseek_raw_${TIMESTAMP}.txt"
```

## Integration with Other Tools

### With `jq` for JSON processing:
```bash
# Convert output to JSON
./scripts/deepseek_search.sh --clean | \
python3 -c "import sys, json; print(json.dumps({'content': sys.stdin.read()}, ensure_ascii=False))" | \
jq '.'
```

### With `pandoc` for format conversion:
```bash
# Convert to HTML
./scripts/deepseek_search.sh --clean | pandoc -f markdown -t html -o results.html

# Convert to PDF (requires LaTeX)
./scripts/deepseek_search.sh --clean | pandoc -f markdown -t latex -o results.pdf
```

### With `grep` for specific content:
```bash
# Find all mentions of transportation
./scripts/deepseek_search.sh --clean | grep -i "交通"

# Find numbered items
./scripts/deepseek_search.sh --clean | grep -E "^\d+\."

# Count recommendations
./scripts/deepseek_search.sh --clean | grep -c "推荐"
```

## Best Practices

1. **Always clean output**: Use `--clean` flag to remove navigation elements
2. **Save raw results**: Keep raw extraction for debugging
3. **Add timestamps**: Include timestamp in output filenames
4. **Verify content**: Check that extracted content makes sense
5. **Handle errors**: Always check return codes and error messages
6. **Document queries**: Keep record of search queries used
7. **Respect rate limits**: Don't make too many requests in short time