# H5 Forge Reference - Templates Catalog

H5 Forge 可以识别以下高频页面模式，并优先按“结构模板 + 项目适配”的方式推进。

## 列表页

常见元素：

- 首次加载
- 下拉刷新
- 分页加载
- 空态
- 错误态

推荐结构：

```text
FeatureListPage
- PageShell / PageLayout
  - Header / NavBar
  - Body
    - PullRefresh / ScrollContainer
      - VirtualList / List rendering
        - List items
        - Pagination loading footer
  - Optional floating action / bottom action
```

状态接入建议：

- 页面级列表状态放在页面 store / hook / composable
- 列表项自身不要持有整体列表加载状态
- 分页状态、刷新状态、首次加载状态应区分

常见坑点：

- 首次加载和分页加载混成同一状态
- 长列表不分页、不懒加载、不虚拟化
- 空态、错误态和正常列表态切换不清
- 列表项直接依赖全局状态导致重渲染范围过大

## 表单页

常见元素：

- 字段校验
- 提交按钮状态
- 提交中 loading
- 失败提示

推荐结构：

```text
FeatureFormPage
- PageShell / PageLayout
  - Header
  - Body
    - Form
      - Field sections
      - Error / helper messages
  - Bottom submit area / sticky action bar
```

状态接入建议：

- 字段临时输入状态可局部保存
- 提交状态、提交结果、接口错误优先放页面级状态层
- 提交按钮状态应由表单有效性 + 提交中状态共同决定

常见坑点：

- 把所有字段状态和业务状态混在同一个大 component state 里
- 提交中没有禁用重复提交
- 校验规则散落在页面各处
- 成功 / 失败 / loading 没有清晰反馈

## 详情页

常见元素：

- 首屏加载
- 数据展示区块
- 操作入口
- 错误重试

## Tab 页

常见元素：

- 分段切换
- 子页面状态保持
- 嵌套导航或嵌套滚动

## 搜索页

常见元素：

- 输入框
- 防抖
- 搜索历史
- 结果列表
- 空结果态

说明：

- 这些模板是识别模式的参考，不是强行套壳
- 具体结构仍要服从项目规则和任务需求
