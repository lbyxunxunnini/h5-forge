# H5 Forge Reference - H5 技术栈识别

规则卡扫描不再只看通用目录结构，必须识别 H5/Web 技术栈信号。

## 扫描入口

```bash
scripts/h5_stack_scan.py /path/to/h5-app
scripts/project_snapshot.py /path/to/h5-app --json
```

## 识别范围

| 类别 | 信号 |
|------|------|
| 框架 | React、Vue、Next、Nuxt、Vite |
| 状态管理 | Zustand、Redux、Pinia、Vuex、React Context |
| 路由 | React Router、Vue Router、Next Router |
| 网络层 | Axios、fetch、TanStack Query、SWR |
| 样式 | Tailwind、Sass、CSS Modules、styled-components/Emotion |
| 测试 | Vitest、Jest、Testing Library、Playwright、Cypress |
| 国际化 | i18next、vue-i18n |
| 组件库 | Ant Design、Vant、Element Plus、Naive UI |

## 置信度

- `high`：至少 3 条证据。
- `medium`：至少 1 条证据。
- `low`：未检测到直接证据。

扫描结果只作为草案依据，不能直接覆盖团队显式规则。
