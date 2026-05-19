#!/usr/bin/env bash
# check_rule_card.sh — 快速判定当前项目的规则卡状态
#
# 用法:
#   scripts/check_rule_card.sh <project_root>                    # 完整检查 + 写状态文件 + 文本输出
#   scripts/check_rule_card.sh <project_root> --json             # 完整检查 + JSON 输出（不写状态文件）
#   scripts/check_rule_card.sh <project_root> --cached [ttl]     # 优先读缓存（默认 300s TTL），未命中回退完整检查
#   scripts/check_rule_card.sh <project_root> --increment-usage  # 草案无冲突使用计数 +1
#   scripts/check_rule_card.sh <project_root> --reset-usage      # 草案使用计数清零
#   scripts/check_rule_card.sh <project_root> --increment-reminder # 草案确认提醒计数 +1
#   scripts/check_rule_card.sh <project_root> --reset-reminder   # 草案确认提醒计数清零
#   scripts/check_rule_card.sh <project_root> --promote-draft    # 将草案转为正式规则卡
#
# 输出结构化 key-value 或 JSON，LLM 直接读取，无需自行搜索路径。
#
# 输出字段:
#   status       : found | draft | not_found
#   path         : 命中的规则卡相对路径（无则 -）
#   project_name : 项目名（目录名）
#   has_draft    : true | false
#   draft_path   : 草案相对路径（无则 -）
#   draft_usage_count    : 草案连续无冲突使用次数
#   draft_reminder_count : 草案确认提醒计数
#
# JSON 模式额外字段:
#   project_root : 项目根绝对路径（缓存校验用）
#   checked_at   : 检查时间戳（秒，缓存 TTL 用）
#
# --cached 模式额外字段:
#   cache_hit    : true（命中时）
#   cache_age    : 缓存年龄（秒）

set -euo pipefail

PROJECT_ROOT="${1:-.}"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

# --cached 模式：优先读取 status.json 缓存
# 用法: scripts/check_rule_card.sh <project_root> --cached [ttl_seconds]
# 缓存命中且未过期且 project_root 匹配时直接输出缓存内容并退出
# 缓存未命中、过期、或 project_root 不匹配时，回退到正常检查
if [[ "${2:-}" == "--cached" ]]; then
  TTL="${3:-300}"
  STATE_FILE="${PROJECT_ROOT}/.h5-forge/runtime/rule_card_status.json"
  PROJECT_ROOT_ABS="$(cd "$PROJECT_ROOT" && pwd)"
  if [ -f "$STATE_FILE" ]; then
    CACHED_OUTPUT="$(STATE_FILE="$STATE_FILE" PROJECT_ROOT_ABS="$PROJECT_ROOT_ABS" TTL="$TTL" python3 -c "
import json, os, sys, time
try:
    with open(os.environ['STATE_FILE']) as f:
        s = json.load(f)
    age = int(time.time()) - int(s.get('checked_at', 0))
    ttl = int(os.environ['TTL'])
    if s.get('project_root') == os.environ['PROJECT_ROOT_ABS'] and age <= ttl:
        s['cache_hit'] = True
        s['cache_age'] = age
        print(json.dumps(s, ensure_ascii=False))
        sys.exit(0)
except Exception:
    pass
sys.exit(1)
" 2>/dev/null)" || CACHED_OUTPUT=""
    if [ -n "$CACHED_OUTPUT" ]; then
      echo "$CACHED_OUTPUT"
      exit 0
    fi
  fi
  # 缓存失效或不存在，回退到正常检查（重新执行脚本，去掉 --cached）
  exec bash "$0" "$PROJECT_ROOT" --json
fi

# --increment-usage 模式：草案无冲突使用计数 +1
if [[ "${2:-}" == "--increment-usage" ]]; then
  STATE_FILE="${PROJECT_ROOT}/.h5-forge/runtime/rule_card_status.json"
  if [ -f "$STATE_FILE" ]; then
    STATE_FILE="$STATE_FILE" python3 -c "
import json, os, time
state_file = os.environ['STATE_FILE']
with open(state_file) as f:
    s = json.load(f)
count = s.get('draft_usage_count', 0) + 1
s['draft_usage_count'] = count
s['checked_at'] = int(time.time())
with open(state_file, 'w') as f:
    json.dump(s, f, ensure_ascii=False, indent=2)
print(f'draft_usage_count: {count}')
" 2>/dev/null
  else
    echo "draft_usage_count: 0"
  fi
  exit 0
fi

# --reset-usage 模式：草案使用计数清零（发现冲突时调用）
if [[ "${2:-}" == "--reset-usage" ]]; then
  STATE_FILE="${PROJECT_ROOT}/.h5-forge/runtime/rule_card_status.json"
  if [ -f "$STATE_FILE" ]; then
    STATE_FILE="$STATE_FILE" python3 -c "
import json, os
state_file = os.environ['STATE_FILE']
with open(state_file) as f:
    s = json.load(f)
s['draft_usage_count'] = 0
with open(state_file, 'w') as f:
    json.dump(s, f, ensure_ascii=False, indent=2)
print('draft_usage_count: 0')
" 2>/dev/null
  else
    echo "draft_usage_count: 0"
  fi
  exit 0
fi

# --increment-reminder 模式：草案确认提醒计数 +1
if [[ "${2:-}" == "--increment-reminder" ]]; then
  STATE_FILE="${PROJECT_ROOT}/.h5-forge/runtime/rule_card_status.json"
  if [ -f "$STATE_FILE" ]; then
    STATE_FILE="$STATE_FILE" python3 -c "
import json, os, time
state_file = os.environ['STATE_FILE']
with open(state_file) as f:
    s = json.load(f)
count = s.get('draft_reminder_count', 0) + 1
s['draft_reminder_count'] = count
s['checked_at'] = int(time.time())
with open(state_file, 'w') as f:
    json.dump(s, f, ensure_ascii=False, indent=2)
print(f'draft_reminder_count: {count}')
" 2>/dev/null
  else
    echo "draft_reminder_count: 0"
  fi
  exit 0
fi

# --reset-reminder 模式：草案确认提醒计数清零
if [[ "${2:-}" == "--reset-reminder" ]]; then
  STATE_FILE="${PROJECT_ROOT}/.h5-forge/runtime/rule_card_status.json"
  if [ -f "$STATE_FILE" ]; then
    STATE_FILE="$STATE_FILE" python3 -c "
import json, os
state_file = os.environ['STATE_FILE']
with open(state_file) as f:
    s = json.load(f)
s['draft_reminder_count'] = 0
with open(state_file, 'w') as f:
    json.dump(s, f, ensure_ascii=False, indent=2)
print('draft_reminder_count: 0')
" 2>/dev/null
  else
    echo "draft_reminder_count: 0"
  fi
  exit 0
fi

# --promote-draft 模式：将草案转为正式规则卡
if [[ "${2:-}" == "--promote-draft" ]]; then
  STATE_FILE="${PROJECT_ROOT}/.h5-forge/runtime/rule_card_status.json"
  if [ -f "$STATE_FILE" ]; then
    RESULT="$(STATE_FILE="$STATE_FILE" PROJECT_ROOT="$PROJECT_ROOT" python3 -c "
import json, os
state_file = os.environ['STATE_FILE']
project_root = os.environ['PROJECT_ROOT']
with open(state_file) as f:
    s = json.load(f)
draft_path = s.get('draft_path', '')
if not draft_path or draft_path == '-':
    print('error: no draft to promote')
    raise SystemExit(1)
full_draft = os.path.join(project_root, draft_path)
if not os.path.isfile(full_draft):
    print(f'error: draft file not found: {draft_path}')
    raise SystemExit(1)
# 去掉 _draft 后缀
formal_path = draft_path.replace('_draft.yaml', '.yaml')
full_formal = os.path.join(project_root, formal_path)
os.rename(full_draft, full_formal)
# 更新状态文件
s['status'] = 'found'
s['path'] = formal_path
s['has_draft'] = False
s['draft_path'] = '-'
s['draft_usage_count'] = 0
s['draft_reminder_count'] = 0
import time
s['checked_at'] = int(time.time())
with open(state_file, 'w') as f:
    json.dump(s, f, ensure_ascii=False, indent=2)
print(f'promoted: {formal_path}')
" 2>/dev/null)"
    echo "$RESULT"
  else
    echo "error: no status file"
    exit 1
  fi
  exit 0
fi

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
  status="found"
  card_path="$found_card"
elif [ -n "$found_draft" ]; then
  status="draft"
  card_path="$found_draft"
else
  status="not_found"
  card_path="-"
fi

if [ -n "$found_draft" ]; then
  has_draft_py="True"
else
  has_draft_py="False"
fi

# --json 模式：输出 JSON 供 hook / 自动化消费
if [[ "${2:-}" == "--json" ]]; then
  # 读取已有的草案计数
  STATE_FILE_PATH="${PROJECT_ROOT}/.h5-forge/runtime/rule_card_status.json"
  EXISTING_COUNT=0
  EXISTING_REMINDER_COUNT=0
  if [ -f "$STATE_FILE_PATH" ]; then
    EXISTING_COUNTS="$(python3 -c "
import json
try:
    with open('$STATE_FILE_PATH') as f:
        s = json.load(f)
        print(s.get('draft_usage_count', 0))
        print(s.get('draft_reminder_count', 0))
except Exception:
    print(0)
    print(0)
" 2>/dev/null || echo 0)"
    EXISTING_COUNT="$(printf '%s\n' "$EXISTING_COUNTS" | sed -n '1p')"
    EXISTING_REMINDER_COUNT="$(printf '%s\n' "$EXISTING_COUNTS" | sed -n '2p')"
  fi
  STATUS="$status" CARD_PATH="$card_path" PROJ_NAME="$PROJECT_NAME" \
  HAS_DRAFT_PY="$has_draft_py" DRAFT_PATH="${found_draft:--}" \
  PROJECT_ROOT_ABS="$(cd "$PROJECT_ROOT" && pwd)" \
  EXISTING_COUNT="$EXISTING_COUNT" EXISTING_REMINDER_COUNT="$EXISTING_REMINDER_COUNT" \
  python3 -c "
import json, os, time
st = os.environ['STATUS']
state = {
    'status': st,
    'path': os.environ['CARD_PATH'],
    'project_name': os.environ['PROJ_NAME'],
    'has_draft': os.environ['HAS_DRAFT_PY'] == 'True',
    'draft_path': os.environ['DRAFT_PATH'],
    'project_root': os.environ['PROJECT_ROOT_ABS'],
    'checked_at': int(time.time()),
    'draft_usage_count': int(os.environ.get('EXISTING_COUNT') or 0) if st == 'draft' else 0,
    'draft_reminder_count': int(os.environ.get('EXISTING_REMINDER_COUNT') or 0) if st == 'draft' else 0,
}
print(json.dumps(state, ensure_ascii=False))
"
  exit 0
fi

# 写入状态文件供 hook 读取
STATE_DIR="${PROJECT_ROOT}/.h5-forge/runtime"
mkdir -p "$STATE_DIR" 2>/dev/null || true
STATUS="$status" CARD_PATH="$card_path" PROJ_NAME="$PROJECT_NAME" \
HAS_DRAFT_PY="$has_draft_py" DRAFT_PATH="${found_draft:--}" \
PROJECT_ROOT_ABS="$(cd "$PROJECT_ROOT" && pwd)" \
STATE_DIR="$STATE_DIR" \
python3 -c "
import json, os, time
state_file = os.path.join(os.environ['STATE_DIR'], 'rule_card_status.json')
# 保留已有的草案计数
existing_count = 0
existing_reminder_count = 0
try:
    with open(state_file) as f:
        old = json.load(f)
    existing_count = old.get('draft_usage_count', 0)
    existing_reminder_count = old.get('draft_reminder_count', 0)
except Exception:
    pass
status = os.environ['STATUS']
state = {
    'status': status,
    'path': os.environ['CARD_PATH'],
    'project_name': os.environ['PROJ_NAME'],
    'has_draft': os.environ['HAS_DRAFT_PY'] == 'True',
    'draft_path': os.environ['DRAFT_PATH'],
    'project_root': os.environ['PROJECT_ROOT_ABS'],
    'checked_at': int(time.time()),
    'draft_usage_count': existing_count if status == 'draft' else 0,
    'draft_reminder_count': existing_reminder_count if status == 'draft' else 0,
}
with open(state_file, 'w') as f:
    json.dump(state, f, ensure_ascii=False, indent=2)
" 2>/dev/null || true

echo "status: $status"
echo "path: $card_path"
echo "project_name: $PROJECT_NAME"
echo "has_draft: $([ -n "$found_draft" ] && echo true || echo false)"
echo "draft_path: ${found_draft:--}"
if [ "$status" = "draft" ]; then
  STATE_FILE_PATH="${PROJECT_ROOT}/.h5-forge/runtime/rule_card_status.json"
  python3 -c "
import json
try:
    with open('$STATE_FILE_PATH') as f:
        s = json.load(f)
    print(f\"draft_usage_count: {s.get('draft_usage_count', 0)}\")
    print(f\"draft_reminder_count: {s.get('draft_reminder_count', 0)}\")
except Exception:
    print('draft_usage_count: 0')
    print('draft_reminder_count: 0')
" 2>/dev/null || true
fi
