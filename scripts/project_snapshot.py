#!/usr/bin/env python3
"""Generate a compact H5/Web project snapshot for fast-mode cold starts."""

from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path


def load_stack_scanner(repo: Path):
    path = repo / "scripts" / "h5_stack_scan.py"
    spec = importlib.util.spec_from_file_location("h5_stack_scan", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load scanner: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def first_existing(root: Path, patterns: list[str], limit: int = 5) -> list[str]:
    results: list[str] = []
    for pattern in patterns:
        for path in root.glob(pattern):
            if path.is_file():
                results.append(str(path.relative_to(root)))
            elif path.is_dir():
                results.append(str(path.relative_to(root)) + "/")
            if len(results) >= limit:
                return results
    return results


def top_dirs(root: Path) -> list[str]:
    for dirname in ("src", "app", "pages"):
        directory = root / dirname
        if directory.exists():
            return sorted(str(path.relative_to(root)) + "/" for path in directory.iterdir() if path.is_dir())[:12]
    return []


def find_rule_cards(root: Path) -> list[str]:
    project_name = root.name
    patterns = [
        f".claude/.h5-forge/projects/{project_name}.rule_card.yaml",
        f".trae/.h5-forge/projects/{project_name}.rule_card.yaml",
        f".agent/.h5-forge/projects/{project_name}.rule_card.yaml",
        f".h5-forge/projects/{project_name}.rule_card.yaml",
    ]
    cards: list[str] = []
    for pattern in patterns:
        cards.extend(str(path.relative_to(root)) for path in root.glob(pattern))
    return cards


def snapshot(root: Path) -> dict[str, object]:
    repo = Path(__file__).resolve().parents[1]
    scanner = load_stack_scanner(repo)
    stack = scanner.scan(root)

    return {
        "project_root": str(root),
        "is_h5_project": stack["is_h5_project"],
        "package_json": "package.json" if (root / "package.json").exists() else None,
        "src_top_dirs": top_dirs(root),
        "rule_cards": find_rule_cards(root),
        "routing_entries": first_existing(root, ["src/**/*router*.*", "src/**/*route*.*", "app/**/*page.*", "pages/**/*.*"]),
        "state_entries": first_existing(
            root,
            [
                "src/**/*store*.*",
                "src/**/*slice*.*",
                "src/**/*context*.*",
                "src/**/*provider*.*",
                "src/**/*composable*.*",
            ],
        ),
        "network_entries": first_existing(root, ["src/**/*api*.*", "src/**/*request*.*", "src/**/*http*.*", "src/**/*client*.*"]),
        "test_entries": first_existing(root, ["src/**/*.test.*", "src/**/*.spec.*", "tests/**/*.*", "e2e/**/*.*"]),
        "stack_signals": stack["signals"],
    }


def print_text(data: dict[str, object]) -> None:
    print(f"project_root: {data['project_root']}")
    print(f"is_h5_project: {str(data['is_h5_project']).lower()}")
    print(f"package_json: {data['package_json']}")
    print(f"rule_cards: {', '.join(data['rule_cards']) if data['rule_cards'] else 'none'}")
    print(f"src_top_dirs: {', '.join(data['src_top_dirs']) if data['src_top_dirs'] else 'none'}")
    print(f"routing_entries: {', '.join(data['routing_entries']) if data['routing_entries'] else 'none'}")
    print(f"state_entries: {', '.join(data['state_entries']) if data['state_entries'] else 'none'}")
    print(f"network_entries: {', '.join(data['network_entries']) if data['network_entries'] else 'none'}")
    print(f"test_entries: {', '.join(data['test_entries']) if data['test_entries'] else 'none'}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project_root", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    root = args.project_root.resolve()
    data = snapshot(root)
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print_text(data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
