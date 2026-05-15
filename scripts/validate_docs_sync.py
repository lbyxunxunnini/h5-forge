#!/usr/bin/env python3
"""Validate cross-document references that commonly drift."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REFERENCE_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
REQUIRED_README_LINKS = [
    "QUICKSTART.md",
    "CHEATSHEET.md",
    "references/validation_log.md",
    "references/demo_transcript.md",
    "references/mode_test_cases.md",
]
REQUIRED_LOAD_MAP_LINKS = [
    "fast_mode.md",
    "autonomous_mode.md",
    "stack_profiles.md",
    "h5_stack_detection.md",
    "release_playbook.md",
    "validation_log.md",
    "demo_transcript.md",
]


def markdown_links(path: Path) -> list[str]:
    links: list[str] = []
    for _, target in REFERENCE_LINK_RE.findall(path.read_text(encoding="utf-8")):
        if target.startswith(("http://", "https://", "#")):
            continue
        links.append(target.split("#", 1)[0])
    return links


def validate_links(root: Path, path: Path) -> list[str]:
    errors: list[str] = []
    base = path.parent
    for target in markdown_links(path):
        resolved = (base / target).resolve()
        try:
            resolved.relative_to(root)
        except ValueError:
            continue
        if not resolved.exists():
            errors.append(f"{path.relative_to(root)} links to missing file: {target}")
    return errors


def contains(path: Path, needle: str) -> bool:
    return needle in path.read_text(encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()

    root = args.root.resolve()
    errors: list[str] = []

    docs = [
        root / "README.md",
        root / "CONTRIBUTING.md",
        root / "OPEN_SOURCE_CHECKLIST.md",
        root / "references" / "load_map.md",
    ]
    docs.extend((root / "references").glob("*.md"))
    docs.extend((root / "references" / "roles").glob("*.md"))
    docs.extend((root / "references" / "shared_workflow_gates").glob("*.md"))

    for path in docs:
        if path.exists():
            errors.extend(validate_links(root, path))

    readme = root / "README.md"
    for required in REQUIRED_README_LINKS:
        if not contains(readme, required):
            errors.append(f"README.md does not reference {required}")

    load_map = root / "references" / "load_map.md"
    for required in REQUIRED_LOAD_MAP_LINKS:
        if not contains(load_map, required):
            errors.append(f"references/load_map.md does not reference {required}")

    if errors:
        for error in errors:
            print(f"FAIL {error}")
        return 1

    print("PASS documentation links and required references are synchronized")
    return 0


if __name__ == "__main__":
    sys.exit(main())
