#!/usr/bin/env python3
"""Validate H5 Forge rule-card files without external dependencies."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REQUIRED_FIELDS = [
    "project_rule_card.project.name",
    "project_rule_card.project.status",
    "project_rule_card.team_rules.directory_structure.rule",
    "project_rule_card.team_rules.state_management.primary_pattern",
    "project_rule_card.team_rules.naming_conventions.pages",
]

RECOMMENDED_FIELDS = [
    "project_rule_card.team_rules.routing_and_navigation.route_definition_rule",
    "project_rule_card.team_rules.component_boundaries.shared_component_rule",
    "project_rule_card.team_rules.api_integration.request_layer_rule",
    "project_rule_card.team_rules.module_boundaries.rule",
]

VALID_CONFIDENCE = {"low", "medium", "high"}
PLACEHOLDER_VALUES = {"", '""', "''", "new|legacy", "new|existing", "low|medium|high"}


def strip_inline_comment(value: str) -> str:
    in_single = False
    in_double = False
    for index, char in enumerate(value):
        if char == "'" and not in_double:
            in_single = not in_single
        elif char == '"' and not in_single:
            in_double = not in_double
        elif char == "#" and not in_single and not in_double:
            return value[:index].strip()
    return value.strip()


def normalize_scalar(value: str) -> str:
    value = strip_inline_comment(value).strip()
    if (value.startswith('"') and value.endswith('"')) or (
        value.startswith("'") and value.endswith("'")
    ):
        return value[1:-1]
    return value


def parse_yaml_like(path: Path) -> tuple[dict[str, str], dict[str, int], list[str]]:
    values: dict[str, str] = {}
    list_counts: dict[str, int] = {}
    errors: list[str] = []
    stack: list[tuple[int, str]] = []

    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        if "\t" in raw_line[: len(raw_line) - len(raw_line.lstrip())]:
            errors.append(f"line {line_number}: indentation uses tabs")
            continue

        indent = len(raw_line) - len(raw_line.lstrip(" "))
        stripped = raw_line.strip()

        while stack and stack[-1][0] >= indent:
            stack.pop()

        if stripped.startswith("-"):
            if stack:
                parent = ".".join(key for _, key in stack)
                list_counts[parent] = list_counts.get(parent, 0) + 1
            continue

        match = re.match(r"^([A-Za-z0-9_]+):(?:\s*(.*))?$", stripped)
        if not match:
            errors.append(f"line {line_number}: unsupported YAML shape: {stripped}")
            continue

        key = match.group(1)
        raw_value = match.group(2) or ""
        current_path = ".".join([*(key for _, key in stack), key])
        values[current_path] = normalize_scalar(raw_value)

        if raw_value == "":
            stack.append((indent, key))

    return values, list_counts, errors


def is_missing(value: str, allow_placeholders: bool) -> bool:
    if allow_placeholders:
        return False
    return value.strip() in PLACEHOLDER_VALUES


def validate_file(path: Path, allow_placeholders: bool) -> list[str]:
    values, list_counts, errors = parse_yaml_like(path)

    if "project_rule_card" not in values:
        errors.append("missing root key: project_rule_card")

    for field in REQUIRED_FIELDS:
        if field not in values:
            errors.append(f"missing required field: {field}")
        elif is_missing(values[field], allow_placeholders):
            errors.append(f"required field is empty or placeholder: {field}")

    for field in RECOMMENDED_FIELDS:
        if field not in values:
            errors.append(f"missing recommended field: {field}")

    for field, value in values.items():
        if field.endswith(".confidence"):
            if allow_placeholders and value == "low|medium|high":
                continue
            if value not in VALID_CONFIDENCE:
                errors.append(f"invalid confidence value at {field}: {value!r}")
            elif value == "high":
                evidence_field = field.rsplit(".", 1)[0] + ".evidence"
                if list_counts.get(evidence_field, 0) < 3:
                    errors.append(f"high confidence needs at least 3 evidence items: {field}")

    if "project_rule_card.inferred_rules.conflicts_to_watch" not in values:
        errors.append("missing conflicts tracker: project_rule_card.inferred_rules.conflicts_to_watch")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--allow-placeholders", action="store_true")
    args = parser.parse_args()

    failed = False
    for path in args.files:
        errors = validate_file(path, args.allow_placeholders)
        if errors:
            failed = True
            print(f"FAIL {path}")
            for error in errors:
                print(f"  - {error}")
        else:
            print(f"PASS {path}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
