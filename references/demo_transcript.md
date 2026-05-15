# H5 Forge Demo Transcript

## h5f-fast

```text
用户：h5f-fast 把登录页按钮文案改成“立即登录”，主按钮颜色沿用主题色

[h5-forge] 模式：轻量任务 / 快速
[h5-forge] 页面工程师：读取登录页和主题变量，完成按钮文案与颜色调整，最小验证通过
```

## h5f-a

```text
用户：h5f-a 做一个会员中心页，缺少的部分按你推荐方案推进直到做完

[h5-forge] 模式：页面开发 / 全自动
- auto_assumption：未提供状态管理方案，检测到项目主流是 Zustand，新增 feature-local store
- auto_assumption：未提供空状态视觉，沿用项目已有 EmptyState 组件
[h5-forge] 验证工程师：路由接入、组件渲染和最小测试通过
```

## 规则卡初始化

```text
用户：h5f- 先扫描这个项目，生成规则卡草案

[h5-forge] 模式：迭代中项目扫描
- 扫描摘要：React + Vite + Zustand + React Router + Axios + Vitest
- 规则卡草案：.h5-forge/projects/app.rule_card_draft.yaml
```
