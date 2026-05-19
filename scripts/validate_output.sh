#!/usr/bin/env bash
# validate_output.sh — 校验 LLM 输出是否符合 [h5-forge] 可见性协议
#
# 用法: scripts/validate_output.sh [--require-complete] [--require-s4] < <llm_output>
#   或: scripts/validate_output.sh [--require-complete] [--require-s4] "llm output text"
#   或: scripts/validate_output.sh [--require-complete] [--require-s4] /path/to/output_file
#
# 校验规则：
#   1. 含 [h5-forge] 的行必须以 [h5-forge] 开头
#   2. 第一条 [h5-forge] 行必须是进入日志或模式日志
#   3. 模式日志必须出现在阶段日志之前
#   4. 模式日志中的模式名必须在允许列表中
#   5. 阶段日志中的阶段编号必须合法
#   6. 角色名必须在允许列表中
#   7. --require-complete 时必须包含完成日志
#   8. 阶段日志中的完整阶段名必须合法（如 S1 需求确认）
#   9. --require-s4 时，UI 优化/架构级任务/页面开发/功能开发必须包含 S2 和 S4 阶段日志
#   10. --require-s4 时，S2 到 S4 之间必须有角色结果日志
#   11. --require-complete 时，中等及以上任务必须包含非模式/非完成的角色结果日志
#   12. --require-complete 时，非豁免写代码任务必须包含写前改动契约
#   13. --require-complete/--require-s4 时，非豁免改动契约必须已由用户确认
#
# 输出: PASS 或 FAIL + 具体违规行和原因

set -euo pipefail

# 允许的模式名
ALLOWED_MODES="直通模式|轻量任务|中等任务|UI 优化|架构级任务|功能开发|页面开发|新项目共创|启动握手"

# 允许的阶段编号
ALLOWED_PHASES="C0|C1|C2|C3|S0|S1|S2|S3|S4|S5|S6"

# 允许的角色名
ALLOWED_ROLES="需求分析师|UI 设计师|架构设计师|页面工程师|验证工程师|主控"

# 需要 [h5-forge] 角色前缀的裸结论行
BARE_CONCLUSION_PREFIXES="分析结论|结论|方案结论|需求结论|UI 结论|架构结论|实现结论|验证结论"

# 需要 S2→S4 阶段日志的模式
MODES_NEEDING_S2_S4="UI 优化|架构级任务|功能开发|页面开发"

# 收口时必须有角色结果日志的模式
MODES_NEEDING_ROLE_RESULT="中等任务|UI 优化|架构级任务|功能开发|页面开发|新项目共创|启动握手"

# 写代码前必须有改动契约的模式
MODES_NEEDING_WRITE_CONTRACT="中等任务|UI 优化|架构级任务|功能开发|页面开发"

require_complete=false
require_s4=false
input_args=()

while [ $# -gt 0 ]; do
  case "$1" in
    --require-complete)
      require_complete=true
      shift
      ;;
    --require-s4)
      require_s4=true
      shift
      ;;
    --)
      shift
      input_args+=("$@")
      break
      ;;
    -*)
      echo "ERROR: unknown option: $1"
      exit 2
      ;;
    *)
      input_args+=("$1")
      shift
      ;;
  esac
done

# 读取输入
if [ ${#input_args[@]} -ge 1 ]; then
  if [ ${#input_args[@]} -eq 1 ] && [ -f "${input_args[0]}" ]; then
    INPUT="$(cat "${input_args[0]}")"
  else
    INPUT="${input_args[*]}"
  fi
else
  INPUT="$(cat)"
fi

errors=0
line_num=0
has_forge=false
first_forge_seen=false
mode_seen=false
detected_mode=""
stage_seen=false
s2_seen=false
s4_seen=false
role_result_after_s2=false
role_result_seen=false
write_contract_seen=false
write_contract_before_s4=false
write_contract_confirmed=false
write_contract_confirmed_before_s4=false
completion_seen=false
waiting_seen=false
exit_seen=false
autonomous_seen=false
phase_lines=""

while IFS= read -r line; do
  line_num=$((line_num + 1))

  # 跳过空行
  if [ -z "$line" ]; then
    continue
  fi

  # 如果整段输出中没有任何 [h5-forge] 行，跳过（可能是纯代码输出）
  if ! echo "$INPUT" | grep -q '\[h5-forge\]'; then
    continue
  fi

  if ! echo "$line" | grep -q '\[h5-forge\]'; then
    if echo "$line" | grep -qE "^[[:space:]]*($ALLOWED_ROLES)："; then
      echo "FAIL line $line_num: role result missing [h5-forge] prefix: $line"
      errors=$((errors + 1))
    elif echo "$line" | grep -qE "^[[:space:]]*($BARE_CONCLUSION_PREFIXES)："; then
      echo "FAIL line $line_num: conclusion line must use '[h5-forge] 角色名：' prefix: $line"
      errors=$((errors + 1))
    fi
    continue
  fi

  # 只检查含 [h5-forge] 的行
  if echo "$line" | grep -q '\[h5-forge\]'; then
    has_forge=true
    # 规则1: 必须以 [h5-forge] 开头（允许前导空格）
    if ! echo "$line" | grep -qE '^[[:space:]]*\[h5-forge\]'; then
      echo "FAIL line $line_num: [h5-forge] not at line start: $line"
      errors=$((errors + 1))
    fi

    # 检测模式名
    if echo "$line" | grep -qE '\[h5-forge\][[:space:]]*模式：'; then
      mode_seen=true
      detected_mode=$(echo "$line" | sed -E 's/.*模式：//' | sed -E 's/[[:space:]]*$//' | sed -E 's/[^一-龥a-zA-Z ]*$//')
    elif echo "$line" | grep -qE '\[h5-forge\][[:space:]]*页面工程师：.*任务'; then
      mode_seen=true
      if echo "$line" | grep -qE '轻量任务'; then
        detected_mode="轻量任务"
      elif echo "$line" | grep -qE '中等任务'; then
        detected_mode="中等任务"
      fi
    elif echo "$line" | grep -qE '\[h5-forge\][[:space:]]*直通模式：'; then
      mode_seen=true
      detected_mode="直通模式"
    fi

    is_completion_line=false
    if echo "$line" | grep -qE '\[h5-forge\][[:space:]]*(本轮完成：|直通模式：完成|页面工程师：已完成|页面工程师：已按 h5f-fast 完成)'; then
      completion_seen=true
      is_completion_line=true
    fi

    if echo "$line" | grep -qE '\[h5-forge\][[:space:]]*主控：任务描述不明确'; then
      waiting_seen=true
    fi

    if echo "$line" | grep -qE '\[h5-forge\][[:space:]]*误触发，退出'; then
      exit_seen=true
    fi

    if echo "$line" | grep -qE '\[h5-forge\][[:space:]]*全自动：已启用 h5f-a'; then
      autonomous_seen=true
    fi

    # 规则2: 模式日志中的模式名校验
    if echo "$line" | grep -qE '\[h5-forge\] *(模式：|页面工程师：.*任务|直通模式|页面工程师：h5f-fast|全自动：)'; then
      if echo "$line" | grep -qE '模式：'; then
        mode_name=$(echo "$line" | sed -E 's/.*模式：//' | sed -E 's/[[:space:]]*$//' | sed -E 's/[^一-龥a-zA-Z ]*$//')
        if ! echo "$mode_name" | grep -qE "^($ALLOWED_MODES)$"; then
          echo "FAIL line $line_num: invalid mode name '$mode_name'"
          errors=$((errors + 1))
        fi
      fi
    fi

    # 规则3: 阶段日志中的阶段编号+名称校验
    if echo "$line" | grep -qE '阶段：'; then
      stage_seen=true
      if [ "$mode_seen" = false ]; then
        echo "FAIL line $line_num: phase log appears before mode log: $line"
        errors=$((errors + 1))
      fi
      # 提取阶段编号
      phase=$(echo "$line" | sed -E 's/.*阶段：//' | sed -E 's/[[:space:]]*$//' | sed -E 's/ .*//')
      if ! echo "$phase" | grep -qE "^($ALLOWED_PHASES)$"; then
        echo "FAIL line $line_num: invalid phase '$phase'"
        errors=$((errors + 1))
      fi
      # 提取完整阶段名（编号+中文名）并校验
      full_phase=$(echo "$line" | sed -E 's/.*阶段：//' | sed -E 's/[[:space:]]*$//')
      # 允许的完整阶段名
      case "$phase" in
        S0) allowed_full="S0 未收口" ;;
        S1) allowed_full="S1 需求确认" ;;
        S2) allowed_full="S2 方案确认" ;;
        S3) allowed_full="S3 拆包冻结" ;;
        S4) allowed_full="S4 实现中" ;;
        S5) allowed_full="S5 验证中" ;;
        C0) allowed_full="C0 想法收口" ;;
        C1) allowed_full="C1 方向共创" ;;
        C2) allowed_full="C2 工程定型" ;;
        C3) allowed_full="C3 首批范围冻结" ;;
        *) allowed_full="" ;;
      esac
      if [ -n "$allowed_full" ] && [ "$full_phase" != "$allowed_full" ]; then
        echo "FAIL line $line_num: invalid phase name '$full_phase' (should be '$allowed_full')"
        errors=$((errors + 1))
      fi
      # 记录阶段出现顺序
      phase_lines="$phase_lines $phase"
      # 跟踪 S2 和 S4
      if [ "$phase" = "S2" ]; then
        s2_seen=true
      fi
      if [ "$phase" = "S4" ]; then
        s4_seen=true
      fi
    fi

    # 规则4: 角色名校验（[h5-forge] 后面紧跟的角色名）
    if echo "$line" | grep -qE '\[h5-forge\][[:space:]]+[^：]+：'; then
      role=$(echo "$line" | sed -E 's/.*\[h5-forge\][[:space:]]*//' | sed -E 's/：.*//')
      # 跳过 "模式"、"阶段"、"全自动" 等非角色前缀
      if ! echo "$role" | grep -qE '^(模式|阶段|全自动|本轮完成|直通模式)'; then
        if ! echo "$role" | grep -qE "^($ALLOWED_ROLES)$"; then
          echo "FAIL line $line_num: invalid role name '$role'"
          errors=$((errors + 1))
        else
          is_mode_role_line=false
          if echo "$line" | grep -qE '\[h5-forge\][[:space:]]*页面工程师：.*任务'; then
            is_mode_role_line=true
          elif echo "$line" | grep -qE '\[h5-forge\][[:space:]]*页面工程师：h5f-fast 快速策略'; then
            is_mode_role_line=true
          fi

          if [ "$is_mode_role_line" = false ] && [ "$is_completion_line" = false ]; then
            role_result_seen=true
            if echo "$line" | grep -qE '改动契约：'; then
              write_contract_seen=true
              if echo "$line" | grep -qE '确认状态：用户已确认'; then
                write_contract_confirmed=true
              fi
              if [ "$s4_seen" = false ]; then
                write_contract_before_s4=true
                if echo "$line" | grep -qE '确认状态：用户已确认'; then
                  write_contract_confirmed_before_s4=true
                fi
              fi
            fi
            if [ "$s2_seen" = true ] && [ "$s4_seen" = false ]; then
              role_result_after_s2=true
            fi
          fi
        fi
      fi
    fi
  fi
done <<< "$INPUT"

# 基础校验
if [ "$has_forge" = true ] && [ "$mode_seen" = false ] && [ "$waiting_seen" = false ] && [ "$exit_seen" = false ]; then
  echo "FAIL: missing [h5-forge] mode log"
  errors=$((errors + 1))
fi

if [ "$has_forge" = true ] && [ "$require_complete" = true ] && [ "$completion_seen" = false ]; then
  echo "FAIL: missing [h5-forge] completion log"
  errors=$((errors + 1))
fi

if [ "$has_forge" = true ] && [ "$require_complete" = true ] && [ "$role_result_seen" = false ]; then
  if echo "$detected_mode" | grep -qE "^($MODES_NEEDING_ROLE_RESULT)$"; then
    echo "FAIL: missing role result log before completion for mode '$detected_mode'"
    errors=$((errors + 1))
  fi
fi

if [ "$has_forge" = true ] && [ "$require_complete" = true ] && [ "$autonomous_seen" = false ] && [ "$write_contract_seen" = false ]; then
  if echo "$detected_mode" | grep -qE "^($MODES_NEEDING_WRITE_CONTRACT)$"; then
    echo "FAIL: missing pre-write change contract for mode '$detected_mode'"
    errors=$((errors + 1))
  fi
fi

if [ "$has_forge" = true ] && [ "$require_complete" = true ] && [ "$autonomous_seen" = false ] && [ "$write_contract_seen" = true ] && [ "$write_contract_confirmed" = false ]; then
  if echo "$detected_mode" | grep -qE "^($MODES_NEEDING_WRITE_CONTRACT)$"; then
    echo "FAIL: pre-write change contract is not user-confirmed for mode '$detected_mode'"
    errors=$((errors + 1))
  fi
fi

# 规则9: --require-s4 校验
if [ "$require_s4" = true ] && [ "$has_forge" = true ]; then
  if [ -z "$detected_mode" ] || echo "$detected_mode" | grep -qE "^($MODES_NEEDING_S2_S4)$"; then
    if [ "$s4_seen" = true ] && [ "$s2_seen" = false ]; then
      echo "FAIL: S4 phase seen but S2 phase missing; S2→S4 hard blocker violated"
      errors=$((errors + 1))
    fi
    if [ "$s2_seen" = true ] && [ "$s4_seen" = false ]; then
      echo "FAIL: S2 phase seen but S4 phase missing; S2→S4 hard blocker violated"
      errors=$((errors + 1))
    fi
    if [ "$s2_seen" = true ] && [ "$s4_seen" = true ] && [ "$role_result_after_s2" = false ]; then
      echo "FAIL: S2→S4 missing role result log between phases"
      errors=$((errors + 1))
    fi
    if [ "$autonomous_seen" = false ] && [ "$s4_seen" = true ] && [ "$write_contract_before_s4" = false ]; then
      echo "FAIL: S4 reached before pre-write change contract"
      errors=$((errors + 1))
    fi
    if [ "$autonomous_seen" = false ] && [ "$s4_seen" = true ] && [ "$write_contract_confirmed_before_s4" = false ]; then
      echo "FAIL: S4 reached before user-confirmed change contract"
      errors=$((errors + 1))
    fi
  fi
fi

if [ $errors -eq 0 ]; then
  echo "PASS"
  exit 0
else
  echo "FAILED with $errors error(s)"
  exit 1
fi
