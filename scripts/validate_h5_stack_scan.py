#!/usr/bin/env python3
"""Validate deterministic H5 stack scanner expectations."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def load_scanner(root: Path):
    path = root / "scripts" / "h5_stack_scan.py"
    spec = importlib.util.spec_from_file_location("h5_stack_scan", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load scanner: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def assert_signal(signals: dict[str, object], category: str, tool: str) -> str | None:
    if tool not in signals.get(category, {}):
        return f"missing signal {category}.{tool}"
    return None


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    scanner = load_scanner(root)
    result = scanner.scan(root / "tests" / "fixtures" / "h5_sample")
    errors: list[str] = []

    if not result["is_h5_project"]:
        errors.append("fixture should be detected as H5/Web project")

    for category, tool in (
        ("framework", "react"),
        ("framework", "vite"),
        ("state_management", "zustand"),
        ("routing", "react_router"),
        ("networking", "axios"),
        ("testing", "vitest"),
        ("testing", "testing_library"),
    ):
        error = assert_signal(result["signals"], category, tool)
        if error:
            errors.append(error)

    if errors:
        for error in errors:
            print(f"FAIL {error}")
        return 1

    print("PASS H5 stack scanner fixture")
    return 0


if __name__ == "__main__":
    sys.exit(main())
