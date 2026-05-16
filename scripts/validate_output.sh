#!/usr/bin/env bash
# validate_output.sh — 校验 LLM 输出是否符合 [h5-forge] 可见性协议
#
# 用法: scripts/validate_output.sh < <llm_output>
#   或: scripts/validate_output.sh "llm output text"
#   或: scripts/validate_output.sh /path/to/output_file
#
# 校验规则：
#   1. 含 [h5-forge] 的行必须以 [h5-forge] 开头
#   2. 模式日志中的模式名必须在允许列表中
#   3. 阶段日志中的阶段编号必须合法
#   4. 角色名必须在允许列表中
#
# 输出: PASS 或 FAIL + 具体违规行和原因

set -euo pipefail

# 允许的模式名
ALLOWED_MODES="直通模式|轻量任务|中等任务|UI 优化|架构级任务|功能开发|页面开发|新项目共创|启动握手"

# 允许的阶段编号
ALLOWED_PHASES="C0|C1|C2|C3|S0|S1|S2|S3|S4|S5|S6"

# 允许的角色名
ALLOWED_ROLES="需求分析师|UI 设计师|架构设计师|页面工程师|验证工程师|主控"

# 读取输入
if [ $# -ge 1 ]; then
  if [ -f "$1" ]; then
    INPUT="$(cat "$1")"
  else
    INPUT="$*"
  fi
else
  INPUT="$(cat)"
fi

errors=0
line_num=0

while IFS= read -r line; do
  line_num=$((line_num + 1))

  # 跳过空行和非 [h5-forge] 行
  if [ -z "$line" ]; then
    continue
  fi

  # 如果整段输出中没有任何 [h5-forge] 行，跳过（可能是纯代码输出）
  if ! echo "$INPUT" | grep -q '\[h5-forge\]'; then
    continue
  fi

  # 只检查含 [h5-forge] 的行
  if echo "$line" | grep -q '\[h5-forge\]'; then
    # 规则1: 必须以 [h5-forge] 开头（允许前导空格）
    if ! echo "$line" | grep -qE '^[[:space:]]*\[h5-forge\]'; then
      echo "FAIL line $line_num: [h5-forge] not at line start: $line"
      errors=$((errors + 1))
    fi

    # 规则2: 模式日志中的模式名校验
    if echo "$line" | grep -qE '\[h5-forge\] *(模式：|页面工程师：.*任务|直通模式|页面工程师：h5f-fast|全自动：)'; then
      # 提取模式名部分进行校验
      mode_part=$(echo "$line" | sed -E 's/.*\[h5-forge\][[:space:]]*//' | sed -E 's/：.*//')
      # 对于 "模式：XXX" 格式，提取 XXX
      if echo "$line" | grep -qE '模式：'; then
        mode_name=$(echo "$line" | sed -E 's/.*模式：//' | sed -E 's/[[:space:]]*$//' | sed -E 's/[^一-龥a-zA-Z ]*$//')
        if ! echo "$mode_name" | grep -qE "^($ALLOWED_MODES)$"; then
          echo "FAIL line $line_num: invalid mode name '$mode_name'"
          errors=$((errors + 1))
        fi
      fi
    fi

    # 规则3: 阶段日志中的阶段编号校验
    if echo "$line" | grep -qE '阶段：'; then
      phase=$(echo "$line" | sed -E 's/.*阶段：//' | sed -E 's/[[:space:]]*$//' | sed -E 's/ .*//')
      if ! echo "$phase" | grep -qE "^($ALLOWED_PHASES)$"; then
        echo "FAIL line $line_num: invalid phase '$phase'"
        errors=$((errors + 1))
      fi
    fi

    # 规则4: 角色名校验（[h5-forge] 后面紧跟的角色名）
    if echo "$line" | grep -qE '\[h5-forge\][[:space:]]+[^：]+：'; then
      role=$(echo "$line" | sed -E 's/.*\[h5-forge\][[:space:]]*//' | sed -E 's/：.*//')
      # 跳过 "模式"、"阶段"、"全自动" 等非角色前缀
      if ! echo "$role" | grep -qE '^(模式|阶段|全自动|本轮完成)'; then
        if ! echo "$role" | grep -qE "^($ALLOWED_ROLES)$"; then
          echo "FAIL line $line_num: invalid role name '$role'"
          errors=$((errors + 1))
        fi
      fi
    fi
  fi
done <<< "$INPUT"

if [ $errors -eq 0 ]; then
  echo "PASS"
  exit 0
else
  echo "FAILED with $errors error(s)"
  exit 1
fi
