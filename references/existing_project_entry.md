# H5 Forge Reference - Existing Project Entry

迭代中 H5/Web 项目的首要目标不是马上写新代码，而是先让 AI 理解项目现状，并生成可复用的规则卡。

## 入口目标

让外部用户用一句话启动老项目接入：

```text
这是一个迭代中的 H5/Web 项目。先用 h5-forge 扫描项目结构，生成规则卡草案，不要先写代码。
```

## 需要回答的问题

扫描完成后，H5 Forge 应能回答：

- 项目主目录结构是什么？
- 页面和组件怎么命名？
- 状态管理主方案是什么？
- 路由在哪里注册？
- 网络层怎么接入？
- 公共组件边界在哪里？
- 哪些页面或组件适合复用？
- 哪些历史遗留写法不应继续扩大？

## 扫描顺序

1. `package.json`：依赖、前端框架、状态管理、路由、网络、序列化、测试工具
2. `src/` 顶层结构：feature-first、layer-first、module-first 或混合结构
3. 路由入口：React Router、Vue Router、Next/Nuxt 路由、History Router 或自定义路由层
4. 状态管理入口：Redux、Pinia、Zustand、Context/Provide、MobX、局部 state 或混合模式
5. 网络层：client、repository、service、model、DTO、错误处理
6. shared/core/common 目录：公共组件、主题、工具、基础设施
7. 典型页面：最近或最主流的列表页、详情页、表单页
8. 已有规则：`.claude/rules/`、`.agents/rules/`、`rules.md`、`CONVENTIONS.md`

## 输出格式

```text
[h5-forge] 模式：迭代中项目扫描
- 项目结构：feature-first / layer-first / mixed
- 状态管理：Zustand / Pinia / Redux / Context/Provide / mixed
- 路由方案：前端路由 / 前端路由 / History/Router / custom
- 网络层：client + repository / service only / mixed
- 公共组件：shared/components / core/components / custom
- 规则卡：草案已生成，等待确认
- 高风险确认项：...
```

## 高风险确认项

只有会影响长期维护的点才抛给用户确认：

- 多种状态管理并存，无法判断主流方案
- 路由注册分散，新增页面有多种入口
- shared 目录存在多套相似组件
- 网络层 service / repository / API client 混用
- 页面命名和目录命名存在明显冲突
- 规则文件与实际代码不一致

不要把所有低风险细节都变成问题。低风险项可以在规则卡草案中标注置信度。

## 顾问式提问规则

迭代中项目不是只扫描后直接执行。只要扫描或后续开发中出现以下场景，H5 Forge 必须先像顾问一样给判断，再向用户确认：

1. 多种主流写法并存，无法直接判断应该跟哪一套
2. 复用旧代码和新写都合理，但长期维护成本不同
3. 改动可能触碰公共组件、共享状态、公共样式或主路由
4. 规则文件、规则卡与实际代码相互冲突
5. 用户目标明确，但落点模块或页面边界不清

提问要求：

- 先给 2-4 行当前判断摘要
- 再给默认建议和原因
- 再只问 1-3 个关键问题

推荐格式：

```text
[h5-forge] 架构设计师：
- 当前判断：项目里同时存在 Pinia 和 Zustand，但订单模块最近 3 个页面都在用 Pinia
- 默认建议：本次继续跟 Pinia，避免在同一业务域扩散第二套状态方案
- 需要你确认：
  1. 订单模块后续是否也统一收口到 Pinia？
```

禁止行为：

- 不要把老项目里的每个细节都变成问题
- 不要只抛问题不给建议
- 不要在高风险点未确认前直接改公共层

## 后续任务策略

生成规则卡后，后续开发优先遵守：

1. 已有项目规则
2. 当前模块主流写法
3. 前端协作 skills 的通用建议
4. H5 Forge 内置默认规则

如果四者冲突，以已有项目规则和当前模块主流写法为先。
