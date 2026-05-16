#!/usr/bin/env bash
# classify_task.sh — 路由预分类，用关键词+正则给出任务类型和执行策略预判
#
# 用法: scripts/classify_task.sh "用户输入文本"
#   或: echo "用户输入文本" | scripts/classify_task.sh
#
# 输出结构化 key-value，LLM 消费预判结果，仅在低置信度时二次判定。
#
# 输出字段:
#   mode       : 直通模式 | 轻量任务 | 中等任务 | UI 优化 | 架构级任务 | 功能开发 | 页面开发 | 新项目共创
#   confidence : high | medium | low
#   policy     : 标准 | 快速 | 全自动
#   matched_by : 命中的关键词类别（调试用）

set -euo pipefail

# 读取输入：参数或 stdin
if [ $# -ge 1 ]; then
  INPUT="$*"
else
  INPUT="$(cat)"
fi

# --- 执行策略判定 ---
policy="标准"
stripped="$(echo "$INPUT" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"

if echo "$stripped" | grep -qE '^h5f-a[ ]?|^h5f a'; then
  policy="全自动"
elif echo "$stripped" | grep -qE '^h5f-fast'; then
  policy="快速"
elif echo "$INPUT" | grep -qE '全自动|自动做完|不要反复确认|推荐方案自动'; then
  policy="全自动"
elif echo "$INPUT" | grep -qE '快速处理|轻量优先|先直接改'; then
  policy="快速"
fi

# --- 任务类型判定（按优先级顺序，命中即停） ---
mode=""
confidence="low"
matched_by=""

# 1. 直通模式：文档/环境/打包/CI/CD/闲聊
if echo "$INPUT" | grep -qE 'README|文档|安装说明|CHANGELOG|LICENSE|贡献指南|环境|打包|CI|CD|lint|格式化|git'; then
  mode="直通模式"
  confidence="high"
  matched_by="doc_keywords"
# 2. 新项目共创
elif echo "$INPUT" | grep -qE '新的 H5|新 H5|从 0 到 1|先共创|只有想法|先不要.*代码|先帮我.*收口'; then
  mode="新项目共创"
  confidence="high"
  matched_by="new_project_keywords"
# 3. UI 优化
elif echo "$INPUT" | grep -qE '优化' && echo "$INPUT" | grep -qE '视觉|样式|卡片|布局|动效|层级|间距|颜色|字体|圆角|阴影'; then
  mode="UI 优化"
  confidence="high"
  matched_by="ui_optimize_keywords"
# 4. 架构级任务
elif echo "$INPUT" | grep -qE '重构|迁移|依赖清理|性能优化|代码审查|i18n|a11y|国际化|无障碍'; then
  mode="架构级任务"
  confidence="high"
  matched_by="architecture_keywords"
# 5. 功能开发
elif echo "$INPUT" | grep -qE '跨页面|业务闭环|弹窗|提示栏|深链|授权|流程|状态联动|完整.*功能|整个.*模块'; then
  mode="功能开发"
  confidence="high"
  matched_by="feature_keywords"
# 6. 页面开发（新增模块）
elif echo "$INPUT" | grep -qE '新增.*模块|新建.*模块'; then
  mode="页面开发"
  confidence="high"
  matched_by="page_new_module"
# 7. 页面开发（新建页面）
elif echo "$INPUT" | grep -qE '新建|新增|详情页|列表页|设置页|个人中心|页面|模块'; then
  # 如果同时有中等线索且没有"新建"，降级为中等
  if echo "$INPUT" | grep -qE '筛选|先看相似实现|局部|增加' && ! echo "$INPUT" | grep -qE '新建'; then
    mode="中等任务"
    confidence="medium"
    matched_by="page_with_medium_hints"
  else
    mode="页面开发"
    confidence="high"
    matched_by="page_keywords"
  fi
# 8. 中等任务
elif echo "$INPUT" | grep -qE '筛选|先看相似实现|局部|增加|调整|修改.*逻辑|加.*功能|加.*字段'; then
  mode="中等任务"
  confidence="medium"
  matched_by="medium_hints"
# 9. 轻量任务
elif echo "$INPUT" | grep -qE '按钮|颜色|文案|字号|跳到|点击后|改一下|改成|换成|删掉|去掉'; then
  mode="轻量任务"
  confidence="high"
  matched_by="light_hints"
# 10. 兜底
else
  mode="中等任务"
  confidence="low"
  matched_by="fallback"
fi

# --- 输出 ---
echo "mode: $mode"
echo "confidence: $confidence"
echo "policy: $policy"
echo "matched_by: $matched_by"
