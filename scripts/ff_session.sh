#!/usr/bin/env bash
# ff_session.sh — session.md 结构化管理
#
# 用法:
#   scripts/ff_session.sh read                           # 读取当前 session
#   scripts/ff_session.sh update --phase S4 --mode 页面开发  # 更新指定字段
#   scripts/ff_session.sh reset                          # 重置 session（任务完成时）
#   scripts/ff_session.sh init --track execution         # 初始化新 session
#
# 支持的 update 字段:
#   --track <cocreation|execution>
#   --phase <C0-C3|S0-S6>
#   --mode <模式名>
#   --decision_version <v1|v2|v3>
#   --rule_card <已加载|未加载>
#   --rule_card_summary <摘要文本>
#   --active_agents <agent列表>
#   --work_packages <P1/P2/P3|无>
#   --stale_results <结果列表|无>
#   --recent_action <操作描述>
#
# session 路径: .h5-forge/session.md（相对于 cwd 或指定 project_root）

set -euo pipefail

SESSION_DIR=".h5-forge"
SESSION_FILE="${SESSION_DIR}/session.md"

# 解析 project_root 参数
PROJECT_ROOT=""
if [ "${1:-}" = "--project-root" ] && [ "${2:-}" != "" ]; then
  PROJECT_ROOT="$2"
  shift 2
fi

if [ -n "$PROJECT_ROOT" ]; then
  SESSION_FILE="${PROJECT_ROOT}/${SESSION_DIR}/session.md"
fi

ACTION="${1:-read}"
shift || true

# --- read ---
cmd_read() {
  if [ ! -f "$SESSION_FILE" ]; then
    echo "status: no_session"
    echo "path: -"
    exit 0
  fi
  echo "status: has_session"
  echo "path: $SESSION_FILE"
  echo "---"
  cat "$SESSION_FILE"
}

# --- init ---
cmd_init() {
  local track="execution"
  local phase="S0"
  local mode="未定"
  local rule_card="未加载"

  while [ $# -gt 0 ]; do
    case "$1" in
      --track) track="$2"; shift 2 ;;
      --phase) phase="$2"; shift 2 ;;
      --mode) mode="$2"; shift 2 ;;
      --rule_card) rule_card="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  mkdir -p "$(dirname "$SESSION_FILE")"
  cat > "$SESSION_FILE" <<EOF
# H5 Forge Session

- 轨道：${track}
- 当前阶段：${phase}
- 当前模式：${mode}
- 决策版本：v1
- 规则卡：${rule_card}
- 规则卡摘要：-
- 活跃代理：controller
- 工作包：无
- 失效结果：无
- 最近操作：初始化
- 更新时间：$(date +"%Y-%m-%d %H:%M")
EOF
  echo "status: initialized"
  echo "path: $SESSION_FILE"
}

# --- update ---
cmd_update() {
  if [ ! -f "$SESSION_FILE" ]; then
    echo "ERROR: no session file. Run 'init' first."
    exit 1
  fi

  # 解析参数
  while [ $# -gt 0 ]; do
    case "$1" in
      --track) sed -i '' "s/^- 轨道：.*/- 轨道：$2/" "$SESSION_FILE"; shift 2 ;;
      --phase) sed -i '' "s/^- 当前阶段：.*/- 当前阶段：$2/" "$SESSION_FILE"; shift 2 ;;
      --mode) sed -i '' "s/^- 当前模式：.*/- 当前模式：$2/" "$SESSION_FILE"; shift 2 ;;
      --decision_version) sed -i '' "s/^- 决策版本：.*/- 决策版本：$2/" "$SESSION_FILE"; shift 2 ;;
      --rule_card) sed -i '' "s/^- 规则卡：.*/- 规则卡：$2/" "$SESSION_FILE"; shift 2 ;;
      --rule_card_summary) sed -i '' "s/^- 规则卡摘要：.*/- 规则卡摘要：$2/" "$SESSION_FILE"; shift 2 ;;
      --active_agents) sed -i '' "s/^- 活跃代理：.*/- 活跃代理：$2/" "$SESSION_FILE"; shift 2 ;;
      --work_packages) sed -i '' "s/^- 工作包：.*/- 工作包：$2/" "$SESSION_FILE"; shift 2 ;;
      --stale_results) sed -i '' "s/^- 失效结果：.*/- 失效结果：$2/" "$SESSION_FILE"; shift 2 ;;
      --recent_action) sed -i '' "s/^- 最近操作：.*/- 最近操作：$2/" "$SESSION_FILE"; shift 2 ;;
      *) shift ;;
    esac
  done

  # 更新时间戳
  sed -i '' "s/^- 更新时间：.*/- 更新时间：$(date +"%Y-%m-%d %H:%M")/" "$SESSION_FILE"

  echo "status: updated"
  echo "path: $SESSION_FILE"
}

# --- reset ---
cmd_reset() {
  if [ -f "$SESSION_FILE" ]; then
    rm "$SESSION_FILE"
    echo "status: reset"
    echo "path: $SESSION_FILE"
  else
    echo "status: no_session_to_reset"
  fi
}

# --- 校验 session 字段完整性 ---
cmd_validate() {
  if [ ! -f "$SESSION_FILE" ]; then
    echo "status: no_session"
    exit 0
  fi

  errors=0
  required_fields=("轨道" "当前阶段" "当前模式" "决策版本" "规则卡" "活跃代理" "工作包" "失效结果" "最近操作" "更新时间")

  for field in "${required_fields[@]}"; do
    if ! grep -q "^- ${field}：" "$SESSION_FILE"; then
      echo "FAIL missing field: $field"
      errors=$((errors + 1))
    fi
  done

  # 校验阶段值
  phase=$(grep "^- 当前阶段：" "$SESSION_FILE" | sed 's/^- 当前阶段：//' | xargs)
  if ! echo "$phase" | grep -qE '^(C[0-3]|S[0-6])$'; then
    echo "FAIL invalid phase: $phase"
    errors=$((errors + 1))
  fi

  if [ $errors -eq 0 ]; then
    echo "PASS session valid"
  else
    echo "FAILED with $errors error(s)"
    exit 1
  fi
}

# --- main ---
case "$ACTION" in
  read) cmd_read ;;
  init) cmd_init "$@" ;;
  update) cmd_update "$@" ;;
  reset) cmd_reset ;;
  validate) cmd_validate ;;
  *)
    echo "Usage: ff_session.sh {read|init|update|reset|validate} [options]"
    exit 1
    ;;
esac
