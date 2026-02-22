# Doubao Search Skill - 快速开始指南

## 🚀 30秒上手

### 前提条件
- ✅ macOS 系统
- ✅ Google Chrome 浏览器
- ✅ OpenClaw 浏览器扩展

### 基本使用流程
1. **手动操作**：打开豆包页面并搜索
2. **自动提取**：运行脚本获取结果
3. **后处理**：整理、格式化、分析结果

## 📋 核心命令

### 安装与设置
```bash
cd ~/.openclaw/workspace/skills/doubao-search
./scripts/install.sh        # 安装技能
./examples/test_basic.sh    # 测试功能
```

### 内容提取
```bash
# 基础提取（当前豆包页面）
./scripts/doubao_search.sh

# 清理后的输出
./scripts/doubao_search.sh --clean

# 详细模式（调试用）
./scripts/doubao_search.sh --verbose

# 帮助信息
./scripts/doubao_search.sh --help
```

### Python接口
```python
from scripts.doubao_search import search_doubao

result = search_doubao("搜索词", clean=True, verbose=False)
if result['success']:
    print(result['content'])
```

## 🔧 工作流程示例

### 场景：获取旅游推荐
```bash
# 1. 手动：打开 https://www.doubao.com/chat/
# 2. 手动：输入"广州旅游景点推荐"并回车
# 3. 自动：运行提取脚本
./scripts/doubao_search.sh --clean

# 4. 可选：保存结果
./scripts/doubao_search.sh --clean > 广州旅游推荐.txt
```

### 场景：批量处理多个主题
```bash
# 创建搜索词列表
echo "广州美食推荐" > queries.txt
echo "广州历史文化" >> queries.txt
echo "广州购物指南" >> queries.txt

# 手动搜索每个词，然后分别提取
for query in $(cat queries.txt); do
    echo "处理: $query"
    # 手动搜索后运行
    ./scripts/doubao_search.sh --clean > "${query}.txt"
done
```

## 🐛 常见问题解决

### 问题1：找不到豆包标签页
```
错误：Doubao tab not found
```
**解决方案**：
1. 打开Chrome，访问 `https://www.doubao.com/chat/`
2. 确保URL完全匹配
3. 刷新页面重试

### 问题2：提取内容为空
```
错误：No content extracted
```
**解决方案**：
1. 等待豆包生成完整回答（5-10秒）
2. 检查页面是否显示搜索结果
3. 尝试不使用`--clean`参数

### 问题3：AppleScript权限错误
```
错误：AppleScript权限被拒绝
```
**解决方案**：
1. 系统偏好设置 → 安全性与隐私 → 隐私
2. 选择"辅助功能"
3. 添加终端/Terminal到允许列表
4. 重启终端后重试

### 问题4：Chrome未运行
```
错误：Google Chrome is not running
```
**解决方案**：
```bash
open -a "Google Chrome" "https://www.doubao.com/chat/"
```

## 📊 输出示例

### 原始提取
```
=== DOUBAO SEARCH RESULTS ===

[完整的豆包回答内容...]

=== END RESULTS ===
```

### 清理后输出
```
广州三日游经典路线
以下是为您规划的广州三日游经典路线...

第一天：老城文化之旅
上午：陈家祠 → 上下九步行街
下午：永庆坊 → 沙面岛
晚上：珠江夜游

第二天：现代地标之旅
...
```

## 🎯 OpenClaw集成提示

### 激活关键词
- "doubao"、"豆包"、"搜索豆包"
- "从豆包获取XXX"、"豆包搜索XXX"

### 标准响应流程
```
用户：搜索豆包获取XXX
助手：提供手动搜索指南 → 用户确认 → 提取结果 → 后处理
```

### 示例对话
```
用户：帮我从豆包搜索Python学习路线
助手：请先手动搜索"Python学习路线"...
用户：已搜索完成  
助手：✅ 成功提取！找到5个学习阶段...
```

## ⚡ 性能优化提示

### 提高成功率
1. **等待充分**：豆包生成回答需要5-10秒
2. **页面稳定**：提取时不切换标签页
3. **网络良好**：确保网络连接稳定
4. **扩展就绪**：确认OpenClaw扩展已附加

### 处理大量内容
```bash
# 分段提取（避免超时）
./scripts/doubao_search.sh > raw.txt
./scripts/doubao_search.sh --clean > clean.txt

# 内容分析
grep -c "推荐" clean.txt           # 统计推荐数量
grep -E "^[0-9]+\." clean.txt     # 提取编号列表
head -50 clean.txt                # 预览前50行
```

## 🔄 高级功能

### 自动搜索（实验性）
```bash
# 尝试自动输入和搜索（需要辅助功能权限）
./scripts/doubao_auto_search.sh --query "测试搜索词"
```

### 配置定制
```bash
# 复制并编辑配置文件
cp config.example.yaml config.yaml
# 编辑config.yaml调整设置
```

### 结果后处理
```bash
# 转换为JSON格式
python3 -c "
import json, sys
content = sys.stdin.read()
print(json.dumps({'content': content}, ensure_ascii=False))
" < 广州旅游推荐.txt > result.json

# 提取关键信息
grep -E "(上午|下午|晚上|推荐|建议)" clean.txt
```

## 📞 获取帮助

### 文档资源
- `README.md` - 完整文档
- `examples/` - 使用示例
- `SKILL.md` - 技能定义

### 测试功能
```bash
# 运行完整测试
./examples/test_basic.sh

# 检查脚本语法
bash -n scripts/doubao_search.sh
python3 -m py_compile scripts/doubao_search.py
```

### 查看日志
```bash
# 启用详细模式查看过程
./scripts/doubao_search.sh --verbose 2>&1 | tee debug.log

# 查看AppleScript错误
osascript -e 'tell application "Google Chrome" to get URL of active tab' 2>&1
```

## 🎨 实用技巧

### 组合使用其他工具
```bash
# 提取后使用pandoc转换格式
./scripts/doubao_search.sh --clean | pandoc -f markdown -t html -o output.html

# 使用jq处理JSON输出
./scripts/doubao_search.sh --clean | python3 to_json.py | jq '.content'

# 统计关键词频率
./scripts/doubao_search.sh --clean | tr ' ' '\n' | sort | uniq -c | sort -nr | head -20
```

### 创建快捷方式
```bash
# 添加到PATH
ln -s $(pwd)/scripts/doubao_search.sh /usr/local/bin/doubao

# 使用别名
alias doubao-search='cd ~/.openclaw/workspace/skills/doubao-search && ./scripts/doubao_search.sh'

# 现在可以直接运行
doubao-search --clean
```

## ⏱️ 时间预估

| 步骤 | 时间 | 说明 |
|------|------|------|
| 手动打开页面 | 10-30秒 | 首次使用或页面未打开 |
| 手动输入搜索 | 5-10秒 | 打字时间 |
| 豆包生成回答 | 5-15秒 | 取决于查询复杂度 |
| 自动提取内容 | 2-5秒 | 脚本执行时间 |
| 结果后处理 | 可变 | 取决于处理复杂度 |

**总时间**：通常30-60秒完成完整流程

## ✅ 完成检查清单

- [ ] Chrome已安装并运行
- [ ] 豆包页面已打开：`https://www.doubao.com/chat/`
- [ ] 已完成手动搜索并看到结果
- [ ] OpenClaw扩展已附加（徽章ON）
- [ ] AppleScript权限已授予
- [ ] 网络连接正常

现在开始使用吧！ 🚀