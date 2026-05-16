#!/usr/bin/env bash
# find_existing_rules.sh — 扫描项目中已有的规则文件
#
# 用法: scripts/find_existing_rules.sh <project_root>
#
# 扫描以下位置的规则文件：
#   1. .claude/rules/ 和 .claude/*.md
#   2. .trae/rules/
#   3. .agents/rules/
#   4. 项目根目录的 rules.md、analysis_rules.md、CONVENTIONS.md
#   5. analysis/ 目录下的文档
#
# 输出结构化结果：文件路径、大小、最后修改时间

set -euo pipefail

PROJECT_ROOT="${1:-.}"
found=0

# 扫描函数：检查路径是否存在且有文件
scan_dir() {
  local dir="$1"
  local label="$2"
  if [ -d "${PROJECT_ROOT}/${dir}" ]; then
    while IFS= read -r -d '' file; do
      local rel="${file#${PROJECT_ROOT}/}"
      local size
      size=$(wc -c < "$file" | xargs)
      local mtime
      mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || echo "unknown")
      echo "path: $rel | size: ${size}B | modified: $mtime | source: $label"
      found=$((found + 1))
    done < <(find "${PROJECT_ROOT}/${dir}" -type f -print0 2>/dev/null)
  fi
}

# 扫描单个文件
scan_file() {
  local file="$1"
  local label="$2"
  if [ -f "${PROJECT_ROOT}/${file}" ]; then
    local size
    size=$(wc -c < "${PROJECT_ROOT}/${file}" | xargs)
    local mtime
    mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "${PROJECT_ROOT}/${file}" 2>/dev/null || echo "unknown")
    echo "path: $file | size: ${size}B | modified: $mtime | source: $label"
    found=$((found + 1))
  fi
}

# 1. Claude Code 规则
scan_dir ".claude/rules" "claude_rules"

# .claude/*.md（仅 markdown 文件，不递归）
scan_md_dir() {
  local dir="$1"
  local label="$2"
  if [ -d "${PROJECT_ROOT}/${dir}" ]; then
    while IFS= read -r -d '' file; do
      local rel="${file#${PROJECT_ROOT}/}"
      local size
      size=$(wc -c < "$file" | xargs)
      local mtime
      mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || echo "unknown")
      echo "path: $rel | size: ${size}B | modified: $mtime | source: $label"
      found=$((found + 1))
    done < <(find "${PROJECT_ROOT}/${dir}" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
  fi
}
scan_md_dir ".claude" "claude_md"

# 2. Trae 规则
scan_dir ".trae/rules" "trae_rules"

# 3. 其他 Agent 规则
scan_dir ".agents/rules" "agents_rules"

# 4. 项目根目录规则文件
scan_file "rules.md" "root_rules"
scan_file "analysis_rules.md" "root_analysis"
scan_file "CONVENTIONS.md" "root_conventions"
scan_file "CLAUDE.md" "root_claude"
scan_file "AGENTS.md" "root_agents"

# 5. analysis 目录
scan_dir "analysis" "analysis_dir"

# 输出汇总
echo "---"
echo "total: $found file(s)"
if [ $found -eq 0 ]; then
  echo "status: no_existing_rules"
else
  echo "status: found"
fi
