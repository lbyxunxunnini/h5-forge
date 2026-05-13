# H5 Forge Reference - 架构决策记录（ADR）

关键技术选择用 ADR 记录，让未来的人理解"当时为什么这么决定"。

## 格式

```markdown
## ADR: [决策标题]

- 状态：Proposed / Accepted / Deprecated / Superseded
- 背景：[为什么需要做这个决策，描述约束和上下文]
- 决策：[我们选择……，用完整句子主动语态]
- 后果：[正面、负面、中性都要写]
```

## 规则

- 存放在项目中，与代码同仓
- 顺序编号，永不复用
- 被推翻时标记 Superseded 并引用替代 ADR，而非删除
- 控制在 1-2 页

## 何时使用

- 技术选型（状态管理方案、路由方案、网络层方案）
- 架构模式选择（feature-based vs layer-based）
- 公共组件抽取决策
- 与项目主流模式不一致的例外决策

## 来源

- [Michael Nygard - Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
