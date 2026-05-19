#!/usr/bin/env python3
"""validate_checklist.py — 校验角色 checklist 是否真的填了实质内容。

用法:
    python3 scripts/validate_checklist.py --role page_engineer < input.txt
    python3 scripts/validate_checklist.py --role requirement_analyst input.txt
    cat input.txt | python3 scripts/validate_checklist.py --role architecture_designer

输入: 包含 ```yaml ... ``` checklist 块的 LLM 输出文本
输出: PASS / FAIL + 具体错误，FAIL 时退出码 2

校验维度:
1. 角色对应的 schema 必填字段非空
2. 字段类型正确（list / str / bool 等）
3. 不允许占位值（"TBD"、"..."、"xxx"、空字符串、单字符）
4. 枚举字段在允许列表内

设计原则:
- 不依赖第三方库，标准库实现
- LLM 自我陈述格式（[x]/[ ]）不作为通过依据，必须解析结构化产物
- 失败信息精确到字段，便于 LLM 自纠
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from typing import Any


# ---------- Schema ----------

PLACEHOLDER_PATTERNS = [
    r"^$",                          # 空字符串
    r"^\.{2,}$",                    # ... ……
    r"^[xX]+$",                     # xxx XXX
    r"^TBD$",                       # TBD
    r"^TODO$",                      # TODO
    r"^待补$",                      # 待补
    r"^未填$",                      # 未填
    r"^\?+$",                       # ???
    r"^_+$",                        # ___
]


@dataclass
class FieldSpec:
    """字段规格说明。"""
    name: str
    required: bool = True
    field_type: str = "str"   # str | list | bool | enum
    min_items: int = 1        # list 类型最少几项
    enum_values: tuple = ()   # enum 类型的合法值
    allow_empty_when: str | None = None  # 当某字段为某值时允许本字段空（如 not_applicable）


ROLE_SCHEMAS: dict[str, list[FieldSpec]] = {
    "requirement_analyst": [
        FieldSpec("business_goal", field_type="str"),
        FieldSpec("scope_in", field_type="list", min_items=1),
        FieldSpec("scope_out", field_type="list", min_items=0),  # 允许空，表示无明确排除
        FieldSpec("key_branches", field_type="list", min_items=1),
        FieldSpec("non_functional", field_type="list", min_items=0),
        FieldSpec("task_semantic", field_type="enum",
                  enum_values=("page", "feature", "architecture")),
        FieldSpec("decision", field_type="enum",
                  enum_values=("allow", "block")),
    ],
    "ui_designer": [
        FieldSpec("source", field_type="enum",
                  enum_values=("real_visual", "text_description", "structural_inference")),
        FieldSpec("blocks", field_type="list", min_items=1),
        FieldSpec("hierarchy", field_type="str"),
        FieldSpec("interactions", field_type="list", min_items=1),
        FieldSpec("missing_inputs", field_type="list", min_items=0),
        FieldSpec("component_ownership", field_type="list", min_items=1),
        FieldSpec("decision", field_type="enum",
                  enum_values=("allow", "need_ui_input", "back_to_requirement")),
    ],
    "architecture_designer": [
        FieldSpec("module_layout", field_type="list", min_items=1),
        FieldSpec("state_management", field_type="str"),
        FieldSpec("routing", field_type="str"),
        FieldSpec("freeze_constraints", field_type="list", min_items=1),
        FieldSpec("reuse_strategy", field_type="list", min_items=1),
        FieldSpec("write_scope", field_type="list", min_items=1),
        FieldSpec("decision", field_type="enum",
                  enum_values=("allow", "need_confirm", "back_upstream")),
    ],
    "page_engineer": [
        FieldSpec("target_files", field_type="list", min_items=1),
        FieldSpec("changes", field_type="list", min_items=1),
        FieldSpec("freeze_alignment", field_type="bool"),
        FieldSpec("deviations", field_type="list", min_items=0),
        FieldSpec("regression_scope", field_type="list", min_items=0),
        FieldSpec("verification_type", field_type="enum",
                  enum_values=("minimal", "necessary", "full")),
        FieldSpec("commands_run", field_type="list", min_items=0),
    ],
}


# ---------- Parser ----------

YAML_BLOCK_RE = re.compile(
    r"```ya?ml\s*\n(?P<body>.*?)\n```",
    re.DOTALL | re.IGNORECASE,
)

CHECKLIST_KEY_RE = re.compile(r"^\s*checklist\s*:", re.MULTILINE)


def extract_checklist_block(text: str) -> str | None:
    """从输出中提取 checklist YAML 块。

    优先识别带 checklist: 顶级 key 的 yaml 块；若不存在则取第一个 yaml 块。
    """
    for match in YAML_BLOCK_RE.finditer(text):
        body = match.group("body")
        if CHECKLIST_KEY_RE.search(body):
            return body
    # 回退：第一个 yaml 块
    first = YAML_BLOCK_RE.search(text)
    return first.group("body") if first else None


def parse_simple_yaml(body: str) -> dict[str, Any]:
    """轻量 YAML 解析器，支持 checklist schema 用到的语法。

    支持:
    - 任意缩进层级的 key: value
    - "- item" 列表
    - 引号包裹的字符串
    - 布尔字面量 true / false
    - 注释 #
    - 行内空数组 []
    - 嵌套对象和列表（递归解析）
    """
    lines = body.splitlines()

    def parse_scalar(raw: str) -> Any:
        s = raw.strip()
        # 去掉行内注释
        if "#" in s:
            new_s = []
            in_quote = None
            for ch in s:
                if in_quote:
                    if ch == in_quote:
                        in_quote = None
                    new_s.append(ch)
                elif ch in ('"', "'"):
                    in_quote = ch
                    new_s.append(ch)
                elif ch == "#":
                    break
                else:
                    new_s.append(ch)
            s = "".join(new_s).strip()
        if s.lower() == "true":
            return True
        if s.lower() == "false":
            return False
        if s.lower() in ("null", "~", ""):
            return None
        # 引号字符串
        if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
            return s[1:-1]
        # 行内空数组
        if s == "[]":
            return []
        return s

    def get_indent(line: str) -> int:
        return len(line) - len(line.lstrip(" "))

    def parse_block(start: int, min_indent: int) -> tuple[dict[str, Any], int]:
        """递归解析从 start 行开始、缩进 >= min_indent 的块。"""
        result: dict[str, Any] = {}
        i = start

        while i < len(lines):
            line = lines[i]
            stripped = line.strip()

            # 空行或注释跳过
            if not stripped or stripped.startswith("#"):
                i += 1
                continue

            indent = get_indent(line)

            # 缩进小于当前块 → 退出
            if indent < min_indent:
                break

            # 列表项不应在此层出现（由上层处理）
            if stripped.startswith("- "):
                break

            # key: value 行
            if ":" in stripped:
                key, _, rest = stripped.partition(":")
                key = key.strip()
                rest_stripped = rest.strip()

                if rest_stripped:
                    # 行内值
                    result[key] = parse_scalar(rest_stripped)
                    i += 1
                else:
                    # 多行值：探测下一非空行
                    j = i + 1
                    while j < len(lines) and (not lines[j].strip() or lines[j].strip().startswith("#")):
                        j += 1

                    if j >= len(lines):
                        result[key] = None
                        i = j
                        continue

                    nxt = lines[j]
                    nxt_indent = get_indent(nxt)

                    if nxt_indent <= indent:
                        # 没有子内容
                        result[key] = None
                        i = j
                        continue

                    if nxt.lstrip().startswith("- "):
                        # 列表
                        items: list[Any] = []
                        k = j
                        list_indent = nxt_indent
                        while k < len(lines):
                            cur = lines[k]
                            cur_stripped = cur.strip()
                            if not cur_stripped or cur_stripped.startswith("#"):
                                k += 1
                                continue
                            cur_indent = get_indent(cur)
                            if cur_indent < list_indent:
                                break
                            if cur_indent == list_indent and cur_stripped.startswith("- "):
                                item_raw = cur_stripped[2:]
                                items.append(parse_scalar(item_raw))
                                k += 1
                            elif cur_indent > list_indent:
                                # 多行列表项续行，追加到上一项
                                if items:
                                    prev = items[-1]
                                    items[-1] = f"{prev} {cur_stripped}" if isinstance(prev, str) else cur_stripped
                                k += 1
                            else:
                                break
                        result[key] = items
                        i = k
                    else:
                        # 嵌套对象
                        sub, i = parse_block(j, nxt_indent)
                        result[key] = sub
            else:
                # 无法识别的行，跳过
                i += 1

        return result, i

    data, _ = parse_block(0, 0)
    return data


# ---------- Validator ----------

@dataclass
class ValidationError:
    field: str
    reason: str

    def __str__(self) -> str:
        return f"  - {self.field}: {self.reason}"


def is_placeholder(value: str) -> bool:
    s = value.strip() if isinstance(value, str) else ""
    if len(s) <= 1:
        return True
    for pat in PLACEHOLDER_PATTERNS:
        if re.match(pat, s, re.IGNORECASE):
            return True
    # 短于 4 个字符且全是非中英数字 → 占位
    if len(s) < 4 and not re.search(r"[\w\u4e00-\u9fff]{2,}", s):
        return True
    return False


def validate_field(spec: FieldSpec, value: Any) -> list[ValidationError]:
    errors: list[ValidationError] = []

    # 必填检查
    if spec.required and value is None:
        errors.append(ValidationError(spec.name, "字段缺失或为空"))
        return errors

    if value is None:
        return errors

    # 类型校验
    if spec.field_type == "str":
        if not isinstance(value, str):
            errors.append(ValidationError(spec.name, f"应为字符串，实际为 {type(value).__name__}"))
            return errors
        if is_placeholder(value):
            errors.append(ValidationError(spec.name, f"占位值 '{value}'，必须填实质内容"))
    elif spec.field_type == "list":
        if not isinstance(value, list):
            errors.append(ValidationError(spec.name, f"应为列表，实际为 {type(value).__name__}"))
            return errors
        if len(value) < spec.min_items:
            errors.append(ValidationError(
                spec.name,
                f"列表至少需要 {spec.min_items} 项，当前 {len(value)} 项",
            ))
        for idx, item in enumerate(value):
            if isinstance(item, str) and is_placeholder(item):
                errors.append(ValidationError(
                    f"{spec.name}[{idx}]",
                    f"占位值 '{item}'",
                ))
    elif spec.field_type == "bool":
        if not isinstance(value, bool):
            errors.append(ValidationError(spec.name, f"应为布尔值，实际为 {value!r}"))
    elif spec.field_type == "enum":
        if value not in spec.enum_values:
            errors.append(ValidationError(
                spec.name,
                f"应为 {list(spec.enum_values)} 之一，实际为 '{value}'",
            ))

    return errors


def validate_checklist(role: str, data: dict[str, Any]) -> list[ValidationError]:
    if role not in ROLE_SCHEMAS:
        return [ValidationError("role", f"未知角色 '{role}'，可用: {list(ROLE_SCHEMAS)}")]

    # 容错：data 可能直接是 checklist 内容，或有顶级 checklist 包裹
    if "checklist" in data and isinstance(data["checklist"], dict):
        data = data["checklist"]

    schema = ROLE_SCHEMAS[role]
    errors: list[ValidationError] = []

    for spec in schema:
        value = data.get(spec.name)
        errors.extend(validate_field(spec, value))

    # 不识别的字段给出 warning（不导致失败）
    schema_names = {s.name for s in schema}
    schema_names.add("checklist")  # 顶级包装
    extras = [k for k in data.keys() if k not in schema_names]
    # 不作为 error，但可以打印
    return errors


# ---------- CLI ----------

def main() -> int:
    parser = argparse.ArgumentParser(description="校验角色 checklist 结构化输出")
    parser.add_argument(
        "--role",
        required=True,
        choices=list(ROLE_SCHEMAS),
        help="角色名",
    )
    parser.add_argument(
        "input",
        nargs="?",
        help="输入文件路径，省略则从 stdin 读取",
    )
    parser.add_argument(
        "--json-output",
        action="store_true",
        help="以 JSON 格式输出结果",
    )
    args = parser.parse_args()

    if args.input:
        try:
            with open(args.input, encoding="utf-8") as f:
                text = f.read()
        except OSError as exc:
            print(f"FAIL: 无法读取文件 {args.input}: {exc}", file=sys.stderr)
            return 2
    else:
        text = sys.stdin.read()

    body = extract_checklist_block(text)
    if body is None:
        msg = f"FAIL: 输出中未找到 ```yaml ... ``` checklist 块（角色: {args.role}）"
        if args.json_output:
            print(json.dumps({
                "result": "fail",
                "role": args.role,
                "errors": [{"field": "_block", "reason": "missing yaml checklist block"}],
            }, ensure_ascii=False))
        else:
            print(msg)
        return 2

    try:
        data = parse_simple_yaml(body)
    except Exception as exc:
        msg = f"FAIL: YAML 解析失败: {exc}"
        if args.json_output:
            print(json.dumps({
                "result": "fail",
                "role": args.role,
                "errors": [{"field": "_parse", "reason": str(exc)}],
            }, ensure_ascii=False))
        else:
            print(msg)
        return 2

    errors = validate_checklist(args.role, data)

    if args.json_output:
        print(json.dumps({
            "result": "pass" if not errors else "fail",
            "role": args.role,
            "errors": [{"field": e.field, "reason": e.reason} for e in errors],
        }, ensure_ascii=False))
    else:
        if not errors:
            print(f"PASS: {args.role} checklist 校验通过")
        else:
            print(f"FAIL: {args.role} checklist 校验失败 ({len(errors)} 项)")
            for e in errors:
                print(e)

    return 0 if not errors else 2


if __name__ == "__main__":
    sys.exit(main())
