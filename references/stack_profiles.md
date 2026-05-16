# H5 Forge Reference - Stack Profiles

技术栈 profile 是规则卡初始化的建议模板。它不覆盖项目扫描结果，只用于给 `init_rule_card.py` 补足低置信度字段和确认清单。

## 内置 profile

| Profile | 适用场景 |
|---------|----------|
| `zustand_feature_profile` | Zustand / 状态管理库，feature-first 目录 |
| `redux_module_profile` | Redux 风格，module-first 目录 |
| `vue_pinia_profile` | Vue/Pinia 风格，feature-first 目录 |
| `react_query_profile` | TanStack Query / SWR，server state 进入 query hooks |
| `lean_h5_profile` | 尚未形成复杂架构的新项目或快速验证项目 |

## 自动选择规则

`scripts/init_rule_card.py --profile auto` 的推荐顺序：

1. 检测到 Redux → `redux_module_profile`
2. 检测到 Zustand → `zustand_feature_profile`
3. 检测到 Vue/Pinia → `vue_pinia_profile`
4. 检测到 TanStack Query / SWR → `react_query_profile`
5. 无明显主流技术栈 → `lean_h5_profile`

## 使用方式

```bash
python3 scripts/init_rule_card.py /path/to/app --profile auto
python3 scripts/init_rule_card.py /path/to/app --profile zustand_feature_profile
python3 scripts/init_rule_card.py /path/to/app --interactive
```

`--interactive` 会输出推荐 profile、扫描摘要和高风险确认清单。脚本仍只写 `_draft` 草案，不直接生成正式规则卡。

## 原则

- profile 是建议，不是事实。
- 扫描 evidence 优先于 profile。
- profile 填补低置信度字段时必须保留 low / medium confidence。
- 用户确认前只能写 `*.rule_card_draft.yaml`。
