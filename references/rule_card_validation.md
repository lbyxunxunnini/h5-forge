# H5 Forge Reference - 规则卡校验

规则卡必须满足基础 schema，避免文档和实际 controller 读取字段漂移。

## 校验命令

```bash
scripts/validate_rule_card.py references/rule_card_template.yaml --allow-placeholders
scripts/validate_rule_card.py /path/to/project.rule_card.yaml
```

## 必填字段

- `project_rule_card.project.name`
- `project_rule_card.project.status`
- `project_rule_card.team_rules.directory_structure.rule`
- `project_rule_card.team_rules.state_management.primary_pattern`
- `project_rule_card.team_rules.naming_conventions.pages`

## 推荐字段

- `routing_and_navigation.route_definition_rule`
- `component_boundaries.shared_component_rule`
- `api_integration.request_layer_rule`
- `module_boundaries.rule`

`high` 置信度必须有至少 3 条 evidence。
