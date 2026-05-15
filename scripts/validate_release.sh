#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

info() {
  printf 'PASS %s\n' "$1"
}

version="$(tr -d '[:space:]' < VERSION)"
skillhub_version="$(python3 - <<'PY'
import json
print(json.load(open(".skillhub.json", encoding="utf-8"))["version"])
PY
)"
readme_version="$(python3 - <<'PY'
import re
text = open("README.md", encoding="utf-8").read()
match = re.search(r"当前版本：\*\*([^*]+)\*\*", text)
print(match.group(1) if match else "")
PY
)"
changelog_has_version="$(grep -c "^## ${version}$" CHANGELOG.md || true)"
top_changelog_version="$(python3 - <<'PY'
import re
text = open("CHANGELOG.md", encoding="utf-8").read()
match = re.search(r"^## (v?[0-9]+\.[0-9]+\.[0-9]+)\s*$", text, re.M)
print(match.group(1) if match else "")
PY
)"

[[ "$version" == "$skillhub_version" ]] || fail "VERSION ($version) != .skillhub.json ($skillhub_version)"
[[ "$version" == "$readme_version" ]] || fail "VERSION ($version) != README current version ($readme_version)"
[[ "$changelog_has_version" != "0" ]] || fail "CHANGELOG.md has no section for $version"

if [[ -n "$top_changelog_version" && "$top_changelog_version" != "$version" ]]; then
  fail "top CHANGELOG section is $top_changelog_version but VERSION is $version"
fi

info "version metadata is consistent: $version"

tracked_local_files="$(git ls-files | grep -E '(^|/)(\.DS_Store|\.h5-forge/|\.claude/|memory/runtime/current_task\.yaml$)' || true)"
if [[ -n "$tracked_local_files" ]]; then
  printf '%s\n' "$tracked_local_files" >&2
  fail "local-only files are tracked"
fi
info "no tracked local-only files"

python3 scripts/validate_rule_card.py --allow-placeholders \
  references/rule_card_template.yaml \
  memory/projects/example_project.rule_card.yaml

python3 scripts/validate_h5_stack_scan.py
python3 scripts/validate_rule_card_resolution.py
python3 scripts/project_snapshot.py tests/fixtures/h5_sample >/dev/null
tmp_rule_card="$(mktemp -t h5-forge-rule-card.XXXXXX.yaml)"
python3 scripts/init_rule_card.py tests/fixtures/h5_sample --output "$tmp_rule_card" >/dev/null
grep -q 'recommended_profile: "zustand_feature_profile"' "$tmp_rule_card" || fail "init_rule_card did not auto-detect zustand profile"
python3 scripts/validate_rule_card.py "$tmp_rule_card" >/dev/null
rm -f "$tmp_rule_card"
python3 scripts/route_golden_tests.py
python3 scripts/validate_docs_sync.py

info "release validation completed"
