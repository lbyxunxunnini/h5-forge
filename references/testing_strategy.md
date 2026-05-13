# H5 Forge Reference - Testing Strategy

H5 Forge 把测试视为交付链路的一部分，而不是事后补丁。

## 基本原则

1. 小改动不强行补重测试，但必须判断是否影响已有行为
2. 新组件、新交互、新状态切换优先考虑 Component 测试
3. 关键用户流程优先考虑集成测试
4. 可复用 UI 组件优先考虑预览或 story-like 展示

## 何时加 Component 测试

以下场景优先考虑：

- 新增可复用组件
- 组件存在明显交互行为
- 组件有多种状态展示
- 修复过 UI 逻辑 bug，且容易回归

如果工作区有前端协作 skills，优先委托：

- `frontend-testing-apps` 或项目已安装的 Vitest / Playwright / Cypress / Testing Library 类 skill

## 何时加集成测试

以下场景优先考虑：

- 登录、下单、支付、续费、搜索等关键主路径
- 多页面跳转且状态依赖明显
- Bug 修复涉及完整用户流程

如果工作区有前端协作 skills，优先委托：

- `frontend-testing-apps` 或项目已安装的 Vitest / Playwright / Cypress / Testing Library 类 skill

## 测试文件放置建议

默认约定：

- Component 测试：`test/components/` 或贴近 feature 的 `test/features/<feature>/`
- 集成 / E2E 测试：`e2e/`、`tests/e2e/` 或项目现有目录

最终仍以项目现有主流结构为准。

## 命名建议

- Component 测试：`<component_or_page_name>_test.js/ts`
- 集成测试：`<flow_name>_flow_test.js/ts` 或项目主流命名

## 最低测试判断

在页面开发结束后，至少做一次判断：

1. 是否改了用户可见行为？
2. 是否引入了新的状态分支？
3. 是否修了容易回归的问题？
4. 是否属于关键用户路径？

如果至少有一个答案是“是”，就不应直接跳过测试策略说明。
