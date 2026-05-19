#!/usr/bin/env bash
# classify_task.sh — 路由预分类，用关键词+正则给出任务类型和执行策略预判
#
# 用法: scripts/classify_task.sh "用户输入文本"
#   或: echo "用户输入文本" | scripts/classify_task.sh
#   或: scripts/classify_task.sh --project-root /path/to/project --write-gate "用户输入文本"
#
# 输出结构化 key-value，LLM 消费预判结果，仅在低置信度时二次判定。
#
# 输出字段:
#   mode       : 等待态 | 启动握手 | 直通模式 | 轻量任务 | 中等任务 | UI 优化 | 架构级任务 | 功能开发 | 页面开发 | 新项目共创
#   confidence : high | medium | low
#   policy     : 标准 | 快速 | 全自动
#   matched_by : 命中的关键词类别（调试用）
#   should_load_rule_card : true | false
#   rule_card_check       : required | skip | on_demand | skip_unless_upgraded | wait_for_task
#   required_phases       : 预期阶段列表
#   upgrade_signals       : 预判可能的升级信号

set -euo pipefail

PROJECT_ROOT=""
WRITE_GATE="false"
ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --project-root)
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    --write-gate)
      WRITE_GATE="true"
      shift
      ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        ARGS+=("$1")
        shift
      done
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

# 读取输入：参数或 stdin
if [ ${#ARGS[@]} -ge 1 ]; then
  INPUT="${ARGS[*]}"
else
  INPUT="$(cat)"
fi

# --- 执行策略判定 ---
policy="标准"
stripped="$(echo "$INPUT" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
TASK_TEXT="$stripped"

# 去掉触发词前缀，提取纯任务文本
case "$TASK_TEXT" in
  h5f-fast) TASK_TEXT="" ;;
  h5f-fast[[:space:]]*) TASK_TEXT="${TASK_TEXT#h5f-fast}" ;;
  h5f-a) TASK_TEXT="" ;;
  h5f-a[[:space:]]*) TASK_TEXT="${TASK_TEXT#h5f-a}" ;;
  h5f[[:space:]]a) TASK_TEXT="" ;;
  h5f[[:space:]]a[[:space:]]*) TASK_TEXT="$(printf '%s' "$TASK_TEXT" | sed -E 's/^h5f[[:space:]]+a//')" ;;
  h5f-) TASK_TEXT="" ;;
  h5f-[[:space:]]*) TASK_TEXT="${TASK_TEXT#h5f-}" ;;
  /h5-forge) TASK_TEXT="" ;;
  /h5-forge[[:space:]]*) TASK_TEXT="${TASK_TEXT#/h5-forge}" ;;
esac
TASK_TEXT="$(echo "$TASK_TEXT" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"

if echo "$stripped" | grep -qE '^h5f-a([[:space:]]|$)|^h5f[[:space:]]+a([[:space:]]|$)'; then
  policy="全自动"
elif echo "$stripped" | grep -qE '^h5f-fast([[:space:]]|$)'; then
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

# 0. 等待态：触发词后没有可执行任务
if [ -z "$TASK_TEXT" ]; then
  mode="等待态"
  confidence="high"
  matched_by="empty_trigger"
# 1. 启动握手 / 首次接入
elif echo "$INPUT" | grep -qE '迭代中.*项目|已有.*项目|先扫描.*项目结构|生成规则卡草案|输出规则卡草案|识别项目结构和规则卡'; then
  mode="启动握手"
  confidence="high"
  matched_by="startup_handshake_keywords"
# 2. 直通模式：文档/环境/打包/CI/CD/闲聊
elif echo "$INPUT" | grep -qE 'README|文档|安装说明|CHANGELOG|LICENSE|贡献指南|环境|打包|CI|CD|lint|格式化|git'; then
  mode="直通模式"
  confidence="high"
  matched_by="doc_keywords"
# 3. 新项目共创
elif echo "$INPUT" | grep -qE '新的 H5|新 H5|新项目|从 0 到 1|先共创|只有想法|先不要.*代码|先帮我.*收口'; then
  mode="新项目共创"
  confidence="high"
  matched_by="new_project_keywords"
# 4. UI 优化
elif echo "$INPUT" | grep -qE '优化' && echo "$INPUT" | grep -qE '视觉|样式|卡片|布局|动效|层级|间距|颜色|字体|圆角|阴影'; then
  mode="UI 优化"
  confidence="high"
  matched_by="ui_optimize_keywords"
# 4b. UI 优化（截图/文字化 UI 规则驱动）
elif echo "$INPUT" | grep -qE '截图|设计图|参考图|UI|视觉|样式|布局|头像|尺寸|叠放|压住|间距|圆角' \
  && echo "$INPUT" | grep -qE '头像|布局|叠放|压住|尺寸|[0-9]+x[0-9]+|文案|卡片|按钮'; then
  mode="UI 优化"
  confidence="high"
  matched_by="ui_visual_spec_keywords"
# 5. 架构级任务（简化/抽取/复用类链路改造）
elif echo "$INPUT" | grep -qE '简化|抽出|抽取|复用|减少分支|统一入口|重复点|重复逻辑|收敛' \
  && echo "$INPUT" | grep -qE '弹窗|链路|流程|状态|入口|逻辑|handler|utils|shared|core|公共|模块'; then
  mode="架构级任务"
  confidence="high"
  matched_by="structural_refactor_keywords"
# 5b. 架构级任务
elif echo "$INPUT" | grep -qE '重构|迁移|依赖清理|性能优化|代码审查|i18n|a11y|国际化|无障碍'; then
  mode="架构级任务"
  confidence="high"
  matched_by="architecture_keywords"
# 6. 功能开发
elif echo "$INPUT" | grep -qE '跨页面|业务闭环|弹窗|提示栏|深链|授权|流程|状态联动|完整.*功能|整个.*模块'; then
  mode="功能开发"
  confidence="high"
  matched_by="feature_keywords"
# 7. 页面开发（新增模块）
elif echo "$INPUT" | grep -qE '新增.*模块|新建.*模块'; then
  mode="页面开发"
  confidence="high"
  matched_by="page_new_module"
# 8. 页面开发（新建页面）
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
# 9. 中等任务
elif echo "$INPUT" | grep -qE '筛选|先看相似实现|局部|增加|调整|修改.*逻辑|加.*功能|加.*字段'; then
  mode="中等任务"
  confidence="medium"
  matched_by="medium_hints"
# 10. 轻量任务
elif echo "$INPUT" | grep -qE '按钮|颜色|文案|字号|跳到|点击后|改一下|改成|换成|删掉|去掉'; then
  mode="轻量任务"
  confidence="high"
  matched_by="light_hints"
# 11. 兜底
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

# --- 扩展字段：路由辅助 ---

# should_load_rule_card: 与运行时规则卡分级表保持一致。
# 直通、轻量启动、高置信中等任务跳过启动检查；重流程必须检查。
should_load_rule_card="true"
rule_card_check="required"
case "$mode" in
  "等待态")
    should_load_rule_card="false"
    rule_card_check="wait_for_task"
    ;;
  "直通模式")
    should_load_rule_card="false"
    rule_card_check="skip"
    ;;
  "轻量任务")
    should_load_rule_card="false"
    rule_card_check="on_demand"
    ;;
  "中等任务")
    if [ "$confidence" = "low" ]; then
      should_load_rule_card="true"
      rule_card_check="before_impl"
    else
      should_load_rule_card="false"
      rule_card_check="skip_unless_upgraded"
    fi
    ;;
  *)
    should_load_rule_card="true"
    rule_card_check="required"
    ;;
esac
echo "should_load_rule_card: $should_load_rule_card"
echo "rule_card_check: $rule_card_check"

# required_phases: 根据模式给出预期阶段
case "$mode" in
  "直通模式")       echo "required_phases: none" ;;
  "等待态")         echo "required_phases: ask" ;;
  "启动握手")       echo "required_phases: handshake,init_rule_card" ;;
  "轻量任务")       echo "required_phases: impl,verify_minimal" ;;
  "中等任务")       echo "required_phases: scan,impl,verify_necessary" ;;
  "UI 优化")        echo "required_phases: S2,S4,S5" ;;
  "架构级任务")     echo "required_phases: S2,S4,S5" ;;
  "功能开发")       echo "required_phases: S1,S2,S4,S5" ;;
  "页面开发")       echo "required_phases: S1,S2,S4,S5" ;;
  "新项目共创")     echo "required_phases: C0,C1,C2,C3,S3,S4,S5" ;;
  *)                echo "required_phases: S1,S2,S4,S5" ;;
esac

# upgrade_signals: 预判可能的升级信号
upgrade_signals=""
if echo "$INPUT" | grep -qE '路由|状态管理|Redux|Zustand|Pinia|Vuex|MobX|Context'; then
  upgrade_signals="${upgrade_signals}architecture_boundary,"
fi
if echo "$INPUT" | grep -qE '简化|抽出|抽取|复用|减少分支|统一入口|重复点|重复逻辑|收敛'; then
  upgrade_signals="${upgrade_signals}architecture_boundary,"
fi
if echo "$INPUT" | grep -qE '新增.*组件|新增.*区块|布局.*调整|结构.*调整'; then
  upgrade_signals="${upgrade_signals}ui_structure,"
fi
if echo "$INPUT" | grep -qE '需求|PRD|产品|业务.*目标|用户.*路径'; then
  upgrade_signals="${upgrade_signals}requirement_gap,"
fi
# 去掉末尾逗号
upgrade_signals="${upgrade_signals%,}"
echo "upgrade_signals: ${upgrade_signals:-none}"

# --- 写入 task_gate.json ---
if [ "$WRITE_GATE" = "true" ]; then
  if [ -z "$PROJECT_ROOT" ]; then
    echo "task_gate_written: false"
    echo "task_gate_reason: missing_project_root"
  else
    PROJECT_ROOT_ABS="$(cd "$PROJECT_ROOT" && pwd)"
    GATE_DIR="$PROJECT_ROOT_ABS/.h5-forge/runtime"
    mkdir -p "$GATE_DIR" 2>/dev/null || true
    MODE="$mode" CONFIDENCE="$confidence" POLICY="$policy" MATCHED_BY="$matched_by" \
    SHOULD_LOAD_RULE_CARD="$should_load_rule_card" RULE_CARD_CHECK="$rule_card_check" \
    PROJECT_ROOT_ABS="$PROJECT_ROOT_ABS" GATE_DIR="$GATE_DIR" python3 -c "
import json, os, time

allow_without_rule_card = os.environ['RULE_CARD_CHECK'] in {
    'skip',
    'on_demand',
    'skip_unless_upgraded',
}
state = {
    'project_root': os.environ['PROJECT_ROOT_ABS'],
    'mode': os.environ['MODE'],
    'confidence': os.environ['CONFIDENCE'],
    'policy': os.environ['POLICY'],
    'matched_by': os.environ['MATCHED_BY'],
    'should_load_rule_card': os.environ['SHOULD_LOAD_RULE_CARD'] == 'true',
    'rule_card_check': os.environ['RULE_CARD_CHECK'],
    'allow_write_without_rule_card': allow_without_rule_card,
    'checked_at': int(time.time()),
}
path = os.path.join(os.environ['GATE_DIR'], 'task_gate.json')
with open(path, 'w', encoding='utf-8') as f:
    json.dump(state, f, ensure_ascii=False, indent=2)
print(f'task_gate_written: {path}')
"
  fi
fi
