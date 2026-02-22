# OpenClaw Integration Guide

This document explains how to use the Doubao Search Skill within OpenClaw agent sessions.

## Skill Activation

The skill will be automatically activated when OpenClaw detects keywords related to Doubao search:

**Activation Keywords**:
- "doubao"
- "豆包" 
- "搜索豆包"
- "doubao search"
- "豆包搜索"
- "从豆包获取"

## Usage Patterns

### Pattern 1: Direct Skill Invocation

**User**: "搜索豆包获取广州旅游景点推荐"

**Agent Response**:
```
我将使用豆包搜索技能帮你获取广州旅游景点推荐。

请按照以下步骤操作：
1. 确保Chrome浏览器已打开，并访问 https://www.doubao.com/chat/
2. 手动输入搜索词："广州旅游景点推荐"
3. 按Enter键等待豆包生成结果
4. 完成后告诉我，我将提取搜索结果

需要我继续吗？
```

### Pattern 2: Multi-step Workflow

**User**: "我需要从豆包获取2026年2月份广州十大游玩地，然后整理成行程表"

**Agent Workflow**:
1. Activate Doubao Search skill
2. Guide user through manual search steps
3. Extract and clean content
4. Process content into structured itinerary
5. Present final results

## Agent Implementation Examples

### Example 1: Basic Integration

```python
# In OpenClaw agent code
def handle_doubao_search(query):
    """
    Handle Doubao search request.
    """
    # Step 1: Instructions for manual search
    instructions = f"""
我将帮你从豆包搜索: "{query}"

**请手动完成以下步骤:**
1. 打开Chrome浏览器 (如果未打开)
2. 访问: https://www.doubao.com/chat/
3. 输入搜索词: "{query}"
4. 按Enter键等待豆包生成结果
5. 确保OpenClaw浏览器扩展已附加 (徽章显示ON)

完成后请告诉我"已完成搜索"，我将提取结果。
"""
    
    # Return instructions to user
    return instructions

def extract_doubao_results():
    """
    Extract results after user completes manual search.
    """
    import subprocess
    import os
    
    # Path to skill script
    skill_dir = os.path.expanduser("~/.openclaw/workspace/skills/doubao-search")
    script_path = os.path.join(skill_dir, "scripts", "doubao_search.sh")
    
    if not os.path.exists(script_path):
        return "错误: 豆包搜索技能未安装"
    
    try:
        # Run extraction
        result = subprocess.run(
            [script_path, "--clean"],
            capture_output=True,
            text=True,
            encoding='utf-8',
            timeout=30
        )
        
        if result.returncode == 0:
            # Parse output
            output = result.stdout
            
            # Extract content between markers
            if "=== DOUBAO SEARCH RESULTS ===" in output:
                parts = output.split("=== DOUBAO SEARCH RESULTS ===")
                content = parts[1].split("=== END RESULTS ===")[0].strip()
                return content
            else:
                return output
        else:
            return f"提取失败: {result.stderr}"
            
    except subprocess.TimeoutExpired:
        return "错误: 提取超时，请检查豆包页面是否正常"
    except Exception as e:
        return f"错误: {str(e)}"
```

### Example 2: Advanced Integration with Error Handling

```python
import re
from typing import Optional, Dict, Tuple

class DoubaoSearchIntegration:
    """Integration class for Doubao Search skill."""
    
    def __init__(self, skill_path: str = None):
        self.skill_path = skill_path or os.path.expanduser("~/.openclaw/workspace/skills/doubao-search")
        self.script_path = f"{self.skill_path}/scripts/doubao_search.sh"
    
    def get_search_instructions(self, query: str) -> Dict[str, str]:
        """Generate search instructions for user."""
        return {
            "title": "豆包搜索指南",
            "steps": [
                f"1. 打开Chrome浏览器，访问 https://www.doubao.com/chat/",
                f"2. 在输入框中输入: {query}",
                "3. 按Enter键开始搜索",
                "4. 等待豆包生成完整回答",
                "5. 确保OpenClaw浏览器扩展徽章显示ON",
                "6. 完成后回复'搜索完成'"
            ],
            "notes": [
                "如果页面需要登录，请先登录豆包账号",
                "确保网络连接正常",
                "如果豆包响应慢，请等待10-20秒"
            ]
        }
    
    def extract_results(self, verbose: bool = False) -> Tuple[bool, str]:
        """Extract results from Doubao page."""
        import subprocess
        
        if not os.path.exists(self.script_path):
            return False, "技能脚本未找到"
        
        try:
            cmd = [self.script_path, "--clean"]
            if verbose:
                cmd.append("--verbose")
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                encoding='utf-8',
                timeout=45
            )
            
            if result.returncode != 0:
                error_msg = result.stderr or "未知错误"
                return False, f"提取失败: {error_msg}"
            
            # Process output
            output = result.stdout
            
            # Check for error messages in output
            if "ERROR:" in output:
                error_line = [line for line in output.split('\n') if "ERROR:" in line][0]
                return False, error_line
            
            # Extract content
            content_match = re.search(
                r'=== DOUBAO SEARCH RESULTS ===\n(.*?)\n=== END RESULTS ===',
                output,
                re.DOTALL
            )
            
            if content_match:
                content = content_match.group(1).strip()
                return True, content
            else:
                # Fallback: use entire output
                return True, output.strip()
                
        except subprocess.TimeoutExpired:
            return False, "提取超时，请检查豆包页面"
        except Exception as e:
            return False, f"系统错误: {str(e)}"
    
    def format_results(self, content: str, query: str) -> Dict:
        """Format extracted results for presentation."""
        # Simple analysis
        lines = [line.strip() for line in content.split('\n') if line.strip()]
        
        # Find numbered items
        numbered_items = []
        for line in lines:
            match = re.match(r'^(\d+)\.\s+(.+)', line)
            if match:
                numbered_items.append({
                    'number': int(match.group(1)),
                    'text': match.group(2)
                })
        
        # Find recommendations
        recommendations = [line for line in lines if any(word in line for word in ['推荐', '建议', '适合', '最佳'])]
        
        # Find locations
        locations = []
        for line in lines:
            loc_matches = re.findall(r'([\u4e00-\u9fff]+(?:区|市|站|公园|塔|山|岛|广场|中心))', line)
            locations.extend(loc_matches)
        
        return {
            'query': query,
            'total_lines': len(lines),
            'numbered_items_count': len(numbered_items),
            'recommendations_count': len(recommendations),
            'unique_locations': list(set(locations))[:10],
            'content_preview': content[:500] + '...' if len(content) > 500 else content,
            'full_content': content
        }
```

## Complete Workflow Example

### Step 1: User Request
**User**: "帮我从豆包搜索'Python学习路线图'"

### Step 2: Agent Response
```
我将使用豆包搜索技能帮你获取Python学习路线图。

**请先完成以下手动步骤：**
1. 打开Chrome浏览器
2. 访问: https://www.doubao.com/chat/
3. 输入: "Python学习路线图"
4. 按Enter键搜索
5. 等待豆包生成完整回答
6. 确保OpenClaw浏览器扩展已附加

完成后请回复"已搜索完成"，我将提取并整理结果。

需要我开始吗？
```

### Step 3: User Confirmation
**User**: "已搜索完成"

### Step 4: Agent Extraction
```python
# Agent executes extraction
integration = DoubaoSearchIntegration()
success, content = integration.extract_results(verbose=True)

if success:
    formatted = integration.format_results(content, "Python学习路线图")
    
    # Present to user
    response = f"""
✅ 成功从豆包提取到Python学习路线图！

**摘要信息：**
- 共提取 {formatted['total_lines']} 行内容
- 找到 {formatted['numbered_items_count']} 个学习阶段/要点
- 包含 {formatted['recommendations_count']} 条具体建议

**主要内容预览：**
{formatted['content_preview']}

**需要我：**
1. 整理成详细的学习路线图？
2. 提取关键学习阶段？
3. 生成学习时间规划？
"""
else:
    response = f"❌ 提取失败: {content}\n\n请检查豆包页面是否正常显示结果。"
```

## Error Handling in OpenClaw

### Common Errors and Solutions

**Error**: "Doubao tab not found"
```python
response = """
未找到豆包页面，请检查：

1. Chrome是否已打开？
2. 是否访问了正确的URL: https://www.doubao.com/chat/
3. 页面是否加载完成？

请重新打开豆包页面并重试。
"""
```

**Error**: "No content extracted"
```python
response = """
未提取到内容，可能原因：

1. 豆包还未生成完整回答（请等待10秒）
2. 搜索词未正确输入
3. 页面内容结构有变化

请确认已看到豆包的回答，然后重试。
"""
```

**Error**: "AppleScript permission denied"
```python
response = """
需要授予AppleScript权限：

1. 打开系统偏好设置 → 安全性与隐私 → 隐私
2. 选择"辅助功能"
3. 解锁并添加终端/OpenClaw到允许列表
4. 重启OpenClaw后重试
"""
```

## Best Practices for OpenClaw Integration

### 1. Clear User Instructions
- Use numbered steps for manual operations
- Include specific URLs and exact search terms
- Set clear completion criteria

### 2. Progress Feedback
- Acknowledge user actions
- Provide status updates during extraction
- Report success/failure clearly

### 3. Result Presentation
- Show summary statistics first
- Include content preview
- Offer follow-up actions

### 4. Error Recovery
- Provide specific troubleshooting steps
- Suggest alternative approaches
- Allow retry with adjusted parameters

### 5. Skill State Management
- Track whether manual search was completed
- Remember previous search queries
- Cache successful results

## Sample Conversation Flow

```
User: 我想知道从豆包获取广州美食推荐
Agent: 我将帮你从豆包搜索广州美食推荐。请先手动操作...
User: 已完成搜索
Agent: 正在提取结果... ✅ 成功提取到15条美食推荐！
User: 整理成Top 10列表
Agent: 已整理为Top 10广州美食推荐列表...
User: 添加地址信息
Agent: 正在从结果中提取地址信息...
```

## Configuration for OpenClaw

Add to OpenClaw configuration:

```yaml
skills:
  doubao-search:
    enabled: true
    path: ~/.openclaw/workspace/skills/doubao-search
    auto_activate: true
    activation_keywords:
      - "doubao"
      - "豆包"
      - "搜索豆包"
    permissions:
      - execute_scripts
      - access_browser
```

## Testing the Integration

Run test script from OpenClaw:

```bash
cd ~/.openclaw/workspace/skills/doubao-search
./examples/test_basic.sh
```

Or test manually:

```python
# In OpenClaw Python console
from examples.openclaw_integration import DoubaoSearchIntegration

integration = DoubaoSearchIntegration()
print(integration.get_search_instructions("测试查询"))
```

## Performance Considerations

1. **Timeout Settings**: Set appropriate timeouts for extraction
2. **Content Limits**: Limit extracted content to avoid memory issues  
3. **Caching**: Cache successful extractions for repeated queries
4. **Concurrency**: Only one Doubao search at a time (browser limitation)