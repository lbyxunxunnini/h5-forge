# H5 Forge Reference - 角色交接格式

四个角色之间的产出物用固定格式交接，下游角色能直接消费。

## 需求分析师 → UI 设计师

```markdown
## 需求摘要
- 业务目标：...
- 页面目标：...
- 用户路径：...

## 业务约束
- 必须覆盖的状态：...
- 核心交互 vs 次要交互：...

## 待确认项
- [ ] ...

## 用户确认状态
- 已确认：...
- 未确认：...
- 是否允许进入下一角色：是 / 否
```

## 需求分析师 → 架构设计师

- 功能需求清单
- 非功能需求（性能/安全/兼容性）
- 技术约束条件
- 用户确认状态：已确认 / 未确认

如果“用户确认状态 = 未确认”，禁止把交接内容继续下发给 UI 设计师或架构设计师，只能回到用户讨论。

## UI 设计师 → 架构设计师

```markdown
## 页面结构树
- 顶部导航区
  - 返回按钮
  - 标题
  - 更多操作
- 内容区
  - 列表区块
  - 筛选区块
- 底部操作区

## 区块划分方案
- ...

## 组件边界
- 页面私有组件：...
- 可能复用的组件：...

## UI 风险点
- ...
```

## 架构设计师 → 页面工程师

```markdown
## 文件结构方案
- src/pages/member_detail/
  - member_detail_page.js/ts
  - components/
    - member_info_card.js/ts
    - member_action_bar.js/ts

## 命名方案
- 页面：xxx_page.js/ts
- 私有组件：xxx_component.js/ts

## 关键实现决策
- 状态管理：Pinia/Zustand
- 路由：前端路由
- ...

## 复用策略
- 复用 order_list 的筛选结构
- 不复用 product_detail 的布局（业务差异太大）

## 规则卡路径
- ~/.h5-forge/projects/xxx.rule_card.yaml
```

## 架构设计师：组件抽取建议

```markdown
## 组件抽取建议
- 组件名：FilterableList
- 来源：order_list.js/ts、product_list.js/ts
- 接收参数：filterConfig、itemBuilder、onItemTap
- 保留差异点：筛选条件定义、列表项布局
```

## 页面工程师产出

```markdown
## 页面代码
- [文件路径]

## 组件代码
- [文件路径]

## 状态/接口接入骨架
- ...

## 高风险确认点
- [ ] ...
```
