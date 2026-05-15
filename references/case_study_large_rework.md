# H5 Forge Case Study - 大改造示例

示例场景：把旧会员中心从单文件页面拆成 feature-first 结构。

## 输入

- 旧页面包含用户资料、权益卡片、订单入口、优惠券和客服入口。
- 状态散落在多个 `useState` 和请求函数中。
- 项目主流为 React + Zustand + Axios + React Router。

## H5 Forge 处理

- 需求分析师收口首版范围。
- UI 设计师拆区块和空状态。
- 架构设计师冻结 `features/member-center` 边界。
- 页面工程师分包实现页面、store、api、components。
- 验证工程师执行最小渲染和路由验证。

## 规则卡更新

- 新增 `member-center` feature 目录模式。
- 记录 Zustand feature-local store 规则。
- 记录 `EmptyState` 和 `MemberCard` 复用规则。
