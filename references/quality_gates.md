# H5 Forge Reference - Quality Gates

在大任务中，每个阶段结束后都应经过最小质量检查。

## after_requirement

- 业务目标是否明确
- 页面目标是否明确
- 关键状态是否覆盖
- 明确需求与推断需求是否区分
- 待确认项是否列出

## after_ui_parsing

- 页面结构树是否完整
- 空态 / 加载态 / 错误态是否被考虑
- 组件边界是否清晰
- 明显依赖业务规则的区块是否已标注

## after_implementation

- 模块归属是否明确
- 命名是否符合项目主流规范
- 状态管理接法是否与项目一致
- 是否已说明复用策略
- 是否列出高风险确认点

## after_development

- 代码是否符合既定结构和命名
- 是否需要 `npm run lint`
- 是否需要 Component 测试或集成测试
- 是否保留了必要占位而不是盲目编造逻辑
