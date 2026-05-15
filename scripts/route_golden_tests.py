#!/usr/bin/env python3
"""Run deterministic golden checks for H5 Forge routing examples."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


DOC_KEYWORDS = ("README", "文档", "安装说明", "CHANGELOG", "LICENSE", "贡献指南")
NEW_PROJECT_KEYWORDS = ("新的 H5", "新 H5", "新 Web", "从 0 到 1", "先共创")
UI_OPTIMIZE_KEYWORDS = ("视觉", "样式", "卡片", "布局", "动效", "层级")
ARCHITECTURE_KEYWORDS = ("包体积", "重构", "迁移", "依赖清理", "性能优化", "代码审查")
PAGE_KEYWORDS = ("新建", "新增", "页面", "详情页", "模块", "路由接入")
FEATURE_KEYWORDS = ("跨页面", "业务闭环", "弹窗", "提示栏", "深链", "授权", "流程", "状态联动")
MEDIUM_HINTS = ("筛选", "先看相似实现", "局部", "增加")
LIGHT_HINTS = ("按钮", "颜色", "文案", "字号", "跳到", "点击后")


def execution_policy(prompt: str) -> str:
    stripped = prompt.strip()
    if stripped.startswith(("h5f-a", "h5f a")) or any(
        keyword in prompt for keyword in ("全自动", "自动做完", "不要反复确认", "推荐方案自动")
    ):
        return "全自动"
    if stripped.startswith("h5f-fast") or any(keyword in prompt for keyword in ("快速处理", "轻量优先", "先直接改")):
        return "快速"
    return "标准"


def classify(prompt: str) -> str:
    if any(keyword in prompt for keyword in DOC_KEYWORDS):
        return "直通模式"
    if any(keyword in prompt for keyword in NEW_PROJECT_KEYWORDS):
        return "新项目共创"
    if "优化" in prompt and any(keyword in prompt for keyword in UI_OPTIMIZE_KEYWORDS):
        return "UI 优化"
    if any(keyword in prompt for keyword in ARCHITECTURE_KEYWORDS):
        return "架构级任务"
    if any(keyword in prompt for keyword in FEATURE_KEYWORDS):
        return "功能开发"
    if "新增" in prompt and "模块" in prompt:
        return "页面开发"
    if any(keyword in prompt for keyword in PAGE_KEYWORDS):
        if any(keyword in prompt for keyword in MEDIUM_HINTS) and "新建" not in prompt:
            return "中等任务"
        return "页面开发"
    if any(keyword in prompt for keyword in MEDIUM_HINTS):
        return "中等任务"
    if any(keyword in prompt for keyword in LIGHT_HINTS):
        return "轻量任务"
    return "功能开发"


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cases", type=Path, default=root / "tests" / "route_golden_cases.json")
    args = parser.parse_args()

    cases = json.loads(args.cases.read_text(encoding="utf-8"))
    failed = False
    for case in cases:
        actual = classify(case["prompt"])
        expected = case["expected_mode"]
        actual_policy = execution_policy(case["prompt"])
        expected_policy = case.get("expected_policy", "标准")
        if actual != expected or actual_policy != expected_policy:
            failed = True
            print(f"FAIL {case['name']}: expected {expected}/{expected_policy}, got {actual}/{actual_policy}")
            print(f"  prompt: {case['prompt']}")
        else:
            print(f"PASS {case['name']}: {actual}/{actual_policy}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
