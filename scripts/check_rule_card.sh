#!/usr/bin/env bash
# check_rule_card.sh — 快速判定当前项目的规则卡状态
#
# 用法: scripts/check_rule_card.sh <project_root>
#
# 输出结构化 key-value，LLM 直接读取，无需自行搜索路径。
#
# 输出字段:
#   status       : found | draft | not_found
#   path         : 命中的规则卡相对路径（无则 -）
#   project_name : 项目名（目录名）
#   has_draft    : true | false
#   draft_path   : 草案相对路径（无则 -）

set -euo pipefail

PROJECT_ROOT="${1:-.}"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

# 按优先级排列的查找路径（相对项目根目录）
SEARCH_PATHS=(
  ".claude/.h5-forge/projects/${PROJECT_NAME}.rule_card.yaml"
  ".trae/.h5-forge/projects/${PROJECT_NAME}.rule_card.yaml"
  ".agent/.h5-forge/projects/${PROJECT_NAME}.rule_card.yaml"
  ".h5-forge/projects/${PROJECT_NAME}.rule_card.yaml"
)

# 草案路径（与正式卡同目录，_draft 后缀）
DRAFT_PATHS=(
  ".claude/.h5-forge/projects/${PROJECT_NAME}.rule_card_draft.yaml"
  ".trae/.h5-forge/projects/${PROJECT_NAME}.rule_card_draft.yaml"
  ".agent/.h5-forge/projects/${PROJECT_NAME}.rule_card_draft.yaml"
  ".h5-forge/projects/${PROJECT_NAME}.rule_card_draft.yaml"
)

found_card=""
found_draft=""

# 查找正式规则卡（命中即停）
for p in "${SEARCH_PATHS[@]}"; do
  if [ -f "${PROJECT_ROOT}/${p}" ]; then
    found_card="$p"
    break
  fi
done

# 查找草案（命中即停）
for p in "${DRAFT_PATHS[@]}"; do
  if [ -f "${PROJECT_ROOT}/${p}" ]; then
    found_draft="$p"
    break
  fi
done

# 输出结果
if [ -n "$found_card" ]; then
  echo "status: found"
  echo "path: $found_card"
elif [ -n "$found_draft" ]; then
  echo "status: draft"
  echo "path: $found_draft"
else
  echo "status: not_found"
  echo "path: -"
fi

echo "project_name: $PROJECT_NAME"
echo "has_draft: $([ -n "$found_draft" ] && echo true || echo false)"
echo "draft_path: ${found_draft:--}"
