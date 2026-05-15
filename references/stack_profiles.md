# H5 Forge Reference - 技术栈 Profiles

profile 用于把技术栈扫描结果转成规则卡草案默认值。

## 内置 profile

| Profile | 触发 | 默认组织 |
|---------|------|----------|
| `zustand_feature_profile` | Zustand | `src/features/<feature>/{pages,components,stores,models,api}` |
| `redux_module_profile` | Redux | `src/modules/<module>/{views,components,store,models,api}` |
| `vue_pinia_profile` | Vue/Pinia | `src/features/<feature>/{pages,components,stores,composables,api}` |
| `react_query_profile` | TanStack Query / SWR | server state 进入 query hooks，client state 本地化 |
| `lean_h5_profile` | 未检测到主流栈 | 简单 layered 结构，复杂度上来再 feature-first |

## 使用

```bash
scripts/init_rule_card.py /path/to/app --profile auto
scripts/init_rule_card.py /path/to/app --profile zustand_feature_profile
```

profile 是起点，不是最终规则。正式规则卡必须以项目现状和团队确认优先。
