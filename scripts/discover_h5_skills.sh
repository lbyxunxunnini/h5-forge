#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_STATE_DIR="${PROJECT_ROOT}/.h5-forge"
LOCAL_MAPPING_FILE="${LOCAL_STATE_DIR}/skill_mapping.local.env"

mkdir -p "${LOCAL_STATE_DIR}"

echo "[h5-forge] 正在查询需要协作的 H5/Web skill..."

COMMON_ROOTS=(
  "${PROJECT_ROOT}/.claude/skills"
  "${PROJECT_ROOT}/.agents/skills"
  "${PROJECT_ROOT}/.cc-switch/skills"
  "${PROJECT_ROOT}/.trae/skills"
  "${HOME}/.claude/skills"
  "${HOME}/.agents/skills"
  "${HOME}/.cc-switch/skills"
  "${HOME}/.trae/skills"
)

declare -a FOUND_ROOTS=()
declare -a FOUND_SUMMARIES=()
declare -a FOUND_TYPES=()

for root in "${COMMON_ROOTS[@]}"; do
  if [[ -d "${root}" ]]; then
    filtered=()
    while IFS= read -r skill; do
      [[ -z "${skill}" ]] && continue
      if [[ "${skill}" != "h5-forge" ]]; then
        filtered+=("${skill}")
      fi
    done < <(find "${root}" -maxdepth 1 -mindepth 1 -type d \( -name 'h5-*' -o -name 'web-*' -o -name 'frontend-*' -o -name 'react-*' -o -name 'vue-*' -o -name 'next-*' -o -name 'vite-*' \) -exec basename {} \; | sort)
    if [[ "${#filtered[@]}" -gt 0 ]]; then
      FOUND_ROOTS+=("${root}")
      case "${root}" in
        "${PROJECT_ROOT}/.claude/skills"|\
        "${PROJECT_ROOT}/.agents/skills"|\
        "${PROJECT_ROOT}/.cc-switch/skills"|\
        "${PROJECT_ROOT}/.trae/skills")
          FOUND_TYPES+=("项目内技能目录")
          ;;
        *)
          FOUND_TYPES+=("宿主根技能目录")
          ;;
      esac
      preview="$(printf '%s, ' "${filtered[@]:0:5}")"
      preview="${preview%, }"
      FOUND_SUMMARIES+=("${#filtered[@]} 个 前端协作 skills（例如：${preview}）")
    fi
  fi
done

if [[ "${#FOUND_ROOTS[@]}" -eq 0 ]]; then
  cat <<'EOF'
[h5-forge] 未在常见目录中检测到可协作的 前端协作 skills。
你可以继续使用 H5 Forge 内置流程，但将无法直接映射等价前端协作 skills。

可选做法：
  安装或放置 React/Vue/Next/Vite/front-end 相关 skills 后，重新运行本脚本选择协作目录
EOF
  exit 0
fi

echo
echo "[h5-forge] 已找到以下可选协作技能目录："
for i in "${!FOUND_ROOTS[@]}"; do
  idx=$((i + 1))
  echo "  ${idx}. ${FOUND_ROOTS[$i]}"
  echo "     类型：${FOUND_TYPES[$i]}"
  echo "     ${FOUND_SUMMARIES[$i]}"
done

echo
printf "请选择 h5-forge 的协作技能映射路径 [1-%d]（直接回车默认 1）： " "${#FOUND_ROOTS[@]}"
read -r choice

if [[ -z "${choice}" ]]; then
  choice=1
fi

if ! [[ "${choice}" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#FOUND_ROOTS[@]} )); then
  echo "[h5-forge] 输入无效，取消写入映射配置。"
  exit 1
fi

selected_root="${FOUND_ROOTS[$((choice - 1))]}"
selected_type="${FOUND_TYPES[$((choice - 1))]}"

cat > "${LOCAL_MAPPING_FILE}" <<EOF
# local only, ignored by git
H5_FORGE_SKILL_SOURCE="${selected_root}"
H5_FORGE_SKILL_SOURCE_TYPE="${selected_type}"
H5_FORGE_SKILL_SOURCE_SET_AT="$(date '+%Y-%m-%d %H:%M:%S')"
EOF

echo
echo "[h5-forge] 已写入本地协作技能映射："
echo "  ${LOCAL_MAPPING_FILE}"
echo "[h5-forge] 当前选定类型："
echo "  ${selected_type}"
echo "[h5-forge] 当前选定目录："
echo "  ${selected_root}"
