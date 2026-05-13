# H5 Forge Reference - Frontend Skills Integration

H5 Forge 负责总控和项目内决策，不替代 React、Vue、Next、Vite、Tailwind、测试、浏览器调试等通用前端技能。

## 使用原则

默认先检查当前环境是否已经安装了可协作的前端 skill，而不是每次联网查询。

探测优先看：

- 当前会话上下文已明确列出的可用 skills
- 本地映射文件 `.h5-forge/skill_mapping.local.env`
- 当前工作区 `.claude/skills/`、`.agents/skills/`、`.cc-switch/skills/`、`.trae/skills/`
- 当前宿主根目录 `~/.claude/skills/`、`~/.agents/skills/`、`~/.cc-switch/skills/`、`~/.trae/skills/`

如果环境里已安装对应 skill：

- 优先委托前端 skill
- 再由 H5 Forge 做项目内适配和最终收口
- 不把通用建议直接套进项目，必须遵守当前项目规则卡和主流写法

如果环境里未安装：

- 不阻塞任务
- 回退到 H5 Forge 内置参考文档和本地流程
- 需要统一选择协作目录时，引导用户运行 `scripts/discover_h5_skills.sh`

## 优先识别的 Skill 类型

H5 Forge 不绑定某个“官方 h5 skills”仓库。优先识别以下命名方向：

- `react-*`
- `vue-*`
- `next-*`
- `vite-*`
- `web-*`
- `frontend-*`
- `h5-*`

## 委托策略

### 需求理解阶段

不要委托。这个阶段属于项目和业务理解，必须由 H5 Forge 自己完成。

### UI 解析阶段

如果问题主要是：

- 响应式布局
- CSS 布局溢出
- 移动端适配
- 设计稿到组件拆分

可优先参考布局、设计系统或 CSS/Tailwind 类 skill。

### 架构与实现设计阶段

如果问题主要是：

- React / Vue / Next / Nuxt 分层架构
- 路由方式
- 数据请求和缓存
- 表单管理
- 状态管理
- SSR / SSG / CSR 边界

可优先参考对应框架或工程化 skill。

### 页面开发阶段

如果问题主要是：

- 组件测试
- E2E 测试
- Storybook / 组件预览
- 浏览器调试

可优先参考测试或浏览器调试类 skill。

## 收口规则

即使调用前端协作 skills，H5 Forge 仍负责最终收口：

1. 是否符合当前项目目录结构
2. 是否符合当前项目命名规则
3. 是否符合当前项目主流框架和状态管理模式
4. 是否需要复用已有页面、组件、hook、store 或 API 层
5. 是否要压缩或调整通用建议，避免和项目现状冲突

换句话说：

- 前端协作 skill 提供通用最佳实践
- H5 Forge 负责项目内适配和最终决策

