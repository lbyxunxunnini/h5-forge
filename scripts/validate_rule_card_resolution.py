#!/usr/bin/env python3
"""Validate that rule cards resolve only from the current project directory."""

from __future__ import annotations

import importlib.util
import os
import tempfile
from pathlib import Path


def load_snapshot(repo: Path):
    path = repo / "scripts" / "project_snapshot.py"
    spec = importlib.util.spec_from_file_location("project_snapshot", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load snapshot script: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_minimal_h5_project(root: Path) -> None:
    (root / "src").mkdir(parents=True)
    (root / "package.json").write_text(
        '{"name":"current-app","dependencies":{"react":"latest"}}\n',
        encoding="utf-8",
    )


def write_card(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "project_rule_card:\n"
        "  project:\n"
        "    name: test\n"
        "    status: existing\n",
        encoding="utf-8",
    )


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    snapshot = load_snapshot(repo)
    errors: list[str] = []

    with tempfile.TemporaryDirectory() as tmp:
        temp_root = Path(tmp)
        project = temp_root / "current_app"
        project.mkdir()
        write_minimal_h5_project(project)

        # Simulate Claude Code global project memory. It must never count as a
        # H5 Forge rule card for the current target project.
        fake_home = temp_root / "home"
        os.environ["HOME"] = str(fake_home)
        write_card(fake_home / ".claude/projects/other/memory/facesong_project_rule_card.yaml")

        data = snapshot.snapshot(project)
        if data["rule_cards"]:
            errors.append(f"global memory was incorrectly loaded: {data['rule_cards']}")

        write_card(project / ".h5-forge/projects/facesong.rule_card.yaml")
        data = snapshot.snapshot(project)
        if data["rule_cards"]:
            errors.append(f"unrelated local project card was incorrectly loaded: {data['rule_cards']}")

        write_card(project / ".h5-forge/projects/current_app.rule_card.yaml")
        data = snapshot.snapshot(project)
        expected = [".h5-forge/projects/current_app.rule_card.yaml"]
        if data["rule_cards"] != expected:
            errors.append(f"current project card was not resolved exactly: {data['rule_cards']}")

    if errors:
        for error in errors:
            print(f"FAIL {error}")
        return 1

    print("PASS rule-card resolution is project-local and exact")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
