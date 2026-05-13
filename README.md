# H5 Forge

> 让 AI 真正理解你的 H5/Web 项目，而不只是生成代码。

H5 Forge 是一个为 H5/Web 开发提供结构化的 AI 协作工作流 skill。它不是代码生成器——它是一个**项目内编排与决策层**，在动手写代码之前先理解项目上下文、收口设计方案、统一工程规则。

GitHub: [lbyxunxunnini/h5-forge](https://github.com/lbyxunxunnini/h5-forge) · License: MIT · 当前版本：0.1.0

## 30 秒理解

H5 Forge 适合你在 AI 编码工具里长期维护 H5/Web 项目时使用。它会先判断任务大小和项目状态：小改动直接做，大需求先拆需求、UI、架构和实现方案，再写代码。

它解决的不是“H5/Web 怎么写”，而是“AI 在你的 H5/Web 项目里应该按什么规则写”。

### 适合

- 你用 Claude Code、Codex、Cursor、Trae 等 AI 编码工具开发 H5/Web。
- 你的项目有固定目录、命名、状态管理或组件复用规则。
- 你经常把 PRD、设计图、页面需求交给 AI 拆解。
- 你希望 AI 先扫描现有项目，再决定复用还是新写。

### 不适合

- 你只想找 H5/Web UI 组件库。
- 你只需要复制粘贴页面模板。
- 你不用 agent skills 或类似的 AI 工作流机制。

### 当前状态

这是一个 0.x 阶段的工作流 skill，已经具备完整文档、任务路由、规则卡、角色协作和前端协作 skills 委托策略。真实 demo、截图和录屏会在后续补充；欢迎通过 issue 提交真实项目试跑反馈。

## 为什么需要它

直接让 AI 写 H5/Web 代码，常见问题：

| 问题 | H5 Forge 的做法 |
|------|---------------------|
| 不了解现有项目风格，生成的代码格格不入 | 首次接入时扫描项目，生成规则卡，后续开发都基于规则卡 |
| 拿到不完整需求就硬编，全要返工 | 显式处理不完整输入，缺什么告诉你，不会假装理解了没看到的东西 |
| 把猜出来的 UI 结构当成设计图真实内容 | UI 来源标注：真实视觉 / 文字描述 / 结构推断，三种来源不混淆 |
| 轻量任务啰嗦一大堆，大任务反而没有设计过程 | 任务路由：10 秒测试快速分流，大任务走四角色设计流程 |
| 多个角色混在一起，分不清谁在决策 | 角色输出标注：每个角色带 `[h5-forge] 角色名：` 标签，决策权归属清晰 |
| 角色之间有分歧但没有讨论机制 | 讨论回合：最多 2 轮，决策权优先级拍板，不悬而不决 |

## 实际效果

装了之后打字会发生什么？两个典型场景：

**轻量任务 — 直接干活**

```
用户: 帮我改一下登录页的按钮颜色

[h5-forge] 页面工程师：轻量任务，直接执行
→ 读取 src/pages/login/index.tsx
→ 找到 Button，颜色从 blue 改为 CSS variable --color-primary
→ 完成
```

**大任务 — 先设计再动手**

```
用户: 我有个需求，做一个订单列表页，支持筛选和下拉刷新

[h5-forge] 模式：需求理解 -> 设计包
[h5-forge] 需求分析师：提取 8 个约束，核心是订单列表+筛选+分页
[h5-forge] UI 设计师：拆为 3 个组件，列表用 virtual list / List rendering
[h5-forge] 架构设计师：订单状态用 Pinia/Zustand，全局用 Redux/Pinia
[h5-forge] 页面工程师：开始生成代码，预计 3 个文件
```

轻量任务不打扰你，大任务先对齐再动手。

## 安装

### 方式一：npx skills（推荐）

需要先安装 [Node.js](https://nodejs.org/)，然后运行：

```bash
npx skills add lbyxunxunnini/h5-forge
```

CLI 会自动检测你安装的 AI 编码工具（Claude Code、Trea、Cursor、Codex 等），并安装到对应目录。

全局安装（所有项目共享）：

```bash
npx skills add lbyxunxunnini/h5-forge -g
```

指定工具安装：

```bash
npx skills add lbyxunxunnini/h5-forge -a claude-code
npx skills add lbyxunxunnini/h5-forge -a trae -a codex
```

### 方式二：git clone

```bash
git clone https://github.com/lbyxunxunnini/h5-forge ~/.claude/skills/h5-forge
```

根据你的工具替换路径，可选 `~/.trae/skills/`、`~/.agents/skills/`、`~/.cc-switch/skills/`。

### 更新

```bash
# npx 方式安装的
npx skills update

# git clone 方式安装的（替换为你实际的路径）
git -C ~/.claude/skills/h5-forge pull
```

## 使用

自然语言描述任务即可，不需要固定格式。

```
- 帮我做一个 H5/Web 新页面
- 先看看这个迭代中项目结构，再开始开发
- 我给你 PRD 和设计图，先拆页面结构
- 帮我 review 一下这段代码
- 把 Context/Provide 换成 Redux/Pinia
- 统一一下项目命名
```

手动触发兜底：

```
ff- 帮我做一个订单列表页
/h5-forge 帮我 review 这个页面
使用 h5-forge 处理这个任务
按 h5-forge 工作模式处理
```

继续未完成任务：

```
ff- 继续第2阶段
ff- 继续登录页
继续做这个需求
继续页面开发
```

`ff-` 和 `/h5-forge` 是显式触发标记，适合在宿主工具没有自动命中 skill 时强制进入 H5 Forge。

### 两条最快入口

如果你不想先读完整文档，直接按项目状态选择一个开场 prompt。

**已有 H5/Web 项目**

```text
这是一个迭代中的 H5/Web 项目。先用 h5-forge 扫描项目结构，生成规则卡草案，不要先写代码。
```

H5 Forge 会优先识别目录结构、状态管理、路由、网络层、公共组件、相似页面和已有规则文件。适合后续新增页面、扩展模块、代码审查、状态管理迁移和目录命名统一。

**新 H5/Web 应用**

```text
新 H5/Web 项目，使用 h5-forge business profile。先定目录、状态管理、路由、网络层和首批页面结构，再开始写代码。
```

可选 profile：

| Profile | 适合场景 | 默认策略 |
|---------|----------|----------|
| `mvp` | 快速原型、演示、想法验证 | 少规则，先跑起来 |
| `business` | 登录、列表、详情、表单、接口接入等标准业务应用 | 默认推荐，先收口核心工程规则 |
| `team` | 多人长期维护、规范优先、持续迭代 | 更严格的规则卡、测试和架构确认 |

### 安静模式与完整模式

H5 Forge 不会对所有任务都展开四角色流程：

- **运维直通**：测试、构建、分析、依赖配置、项目文档等维护任务，仍由 H5 Forge 接管，但快速执行。
- **安静模式**：改文案、颜色、字号、已定位 bug 等轻量任务，直接由页面工程师处理，只输出必要的 `[h5-forge]` 标记。
- **完整模式**：新页面、模块扩展、复用判断、状态管理接入、PRD/设计图解析、代码审查和迁移任务，会进入结构化流程。

这保证日常小改动不被流程拖慢，大需求又不会跳过设计收口。

进入完整流程时，H5 Forge 必须说明升级原因，例如：

```text
[h5-forge] 模式：页面开发
- 升级原因：新增订单列表页，涉及页面结构、筛选状态和路由接入
```

如果说不清升级原因，就不应进入完整流程，应走运维直通、轻量执行或中等任务路径。

### 典型场景

| 场景 | 说什么 |
|------|--------|
| 迭代中项目接入 | "这是一个迭代中 H5/Web 项目，先扫描结构再开发" |
| 新项目起步 | "新 H5/Web 项目，先给页面结构和文件方案" |
| 只有 PRD | "先做需求分析，缺设计图再告诉我" |
| 只有设计图 | "先做 UI 解析，缺业务规则再告诉我" |
| 代码审查 | "帮我 review 一下 src/pages/order_page.js/ts" |
| 状态迁移 | "把 Context/Provide 换成 Redux/Pinia" |
| 目录重构 | "统一一下项目命名和目录结构" |

## 诊断

安装后跑一下，确认环境正常：

```bash
# 检查 Node.js
node -v && npm -v

# 检查 skills CLI
npx skills --version

# 查看已安装的 skills
npx skills list

# 检查 h5-forge 是否被探测到
ls ~/.claude/skills/h5-forge/SKILL.md 2>/dev/null && echo "OK" || echo "未找到"
ls ~/.trae/skills/h5-forge/SKILL.md 2>/dev/null && echo "OK" || echo "未找到"
ls ~/.agents/skills/h5-forge/SKILL.md 2>/dev/null && echo "OK" || echo "未找到"
```

如果用的是 git clone 方式，确认 SKILL.md 文件存在于你 clone 的目录即可。

## 架构总览

```
┌─────────────────────────────────────────────────────┐
│                   用户自然语言输入                     │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│            H5 Forge 主控 (SKILL.md ~300行)       │
│                                                       │
│  ┌───────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │ 硬排除检查 │  │ 运维直通路径  │  │ 完整流程触发   │ │
│  └─────┬─────┘  └──────┬───────┘  └───────┬───────┘ │
│        └────────────────┼──────────────────┘         │
│                         ▼                             │
│  ┌─────────────────────────────────────────────────┐ │
│  │              任务路由 & 工作模式                   │ │
│  │                                                   │ │
│  │  运维直通 → 快速执行                               │ │
│  │  轻量任务 → 直接执行                               │ │
│  │  中任务   → 设计收口 + 执行                        │ │
│  │  大任务   → 四角色流程 + 讨论回合                   │ │
│  │  代码审查 → 5 维度审查                             │ │
│  │  迁移辅助 → 逐模块迁移                             │ │
│  └──────────────────────┬──────────────────────────┘ │
└─────────────────────────┼───────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  按需加载     │ │  前端 Skills  │ │  记忆协议     │
│  30+ 参考文档 │ │  委托+降级    │ │  规则卡/偏好  │
└──────────────┘ └──────────────┘ └──────────────┘
```

## 核心机制

### 1. 任务路由（第一道门）

每次 skill 命中后，先走快速路由决策：

```
任务进来
  → 是 H5/Web 项目？ → 否 → 不命中，退出
  → 硬排除？ → 是 → 普通模式处理
  → 测试/构建/配置/文档等维护任务？ → 是 → 运维直通，快速执行
  → 能 10 秒内说清改什么？ → 是 → 轻量任务，直接执行
  → 涉及新页面/复用/组件/状态/审查/迁移？ → 是 → 完整流程
  → 中间地带 → 简短扫描后执行，必要时升级
```

**硬排除条件**（不命中 h5-forge）：

1. 不是 H5/Web 项目
2. 纯知识问答，且不要求结合当前项目代码
3. 通用 git 操作，且不要求理解 H5/Web 项目
4. 闲聊、确认、追问
5. 明确与 H5/Web 项目无关的脚本、文档或环境任务

测试、构建、依赖、配置、CI 和 H5/Web 项目文档不再默认退出；它们走“运维直通”，保留接管但不展开重流程。

### 2. 四角色协作模型

大任务自动切换四个专业视角，每个角色有独立的思考框架：

| 角色 | 职责 | 思考框架 |
|------|------|---------|
| 需求分析师 | 理解 PRD，拆解功能点，识别边界条件 | PRD 分析四层法、验收标准模板、隐含需求识别 |
| UI 设计师 | 解析设计图，规划页面结构和交互 | 设计质量评估四维法、组件分类法、布局模式库 |
| 架构设计师 | 设计文件结构、状态管理、组件边界 | 技术选型权衡框架、风险评估矩阵、文件结构决策树 |
| 页面工程师 | 生成接近可运行的代码骨架 | 实现优先级、性能优化检查、边界情况处理清单 |

轻量任务直接由页面工程师执行，不走完整流程。

### 3. 讨论回合机制

角色之间出现分歧时，允许进入讨论回合：

- **触发条件**：大任务 + 2 个以上角色参与 + 有明确线性反馈
- **轮数上限**：2 轮。超过未达成一致，由决策权最高的角色拍板
- **决策权优先级**：需求分析师 > UI 设计师 > 架构设计师 > 页面工程师

每个角色发言带 `[h5-forge]` 标记，用户可完整感知讨论过程。

### 4. 规则卡（Rule Card）

规则卡是 H5 Forge 的核心持久化机制，一份 YAML 文件捕获项目的工程约定：

```yaml
project:
  name: "my_app"
  type: h5
  framework: "React / Vue / Next / Vite"
naming:
  page_suffix: "Page"
  file_case: kebab-case
state_management: zustand
routing: react-router
performance_budget:
  max_component_depth: 5
  list_must_virtualize_or_paginate: true
i18n:
  enabled: false
accessibility:
  enabled: false
```

- 存储位置：`~/.h5-forge/projects/*.rule_card.yaml`
- 生成时机：迭代中项目扫描后 / 新项目完成起步选择后
- 后续所有开发都基于规则卡保持一致性

### 5. 不完整输入处理

H5 Forge 的设计前提：**用户不会总是给你完整需求**。

| 输入模型 | 行为 |
|---------|------|
| 只给 PRD | 先做需求分析，产出页面结构树草案和待确认 UI 点 |
| 只给设计图 | 先做 UI 解析，缺业务规则再明确告诉你 |
| PRD + 设计图 | 完整流程：需求分析 → UI 解析 → 结构设计 → 实现 |
| 上下文不足 | 明确告诉你缺什么，不会硬编 |

### 6. UI 来源标注

每次 UI 分析输出都标注来源，防止 AI 把猜测当事实：

- `真实视觉输入` — 能可靠读取设计图
- `用户文字描述` — 基于用户口述
- `结构推断` — 设计图不可读时的降级推断

### 7. 渐进式加载（Progressive Disclosure）

主控文档 `SKILL.md` 只包含编排逻辑（~300 行），30+ 参考文档按需加载：

| 场景 | 加载的参考文档 |
|------|--------------|
| 迭代中项目接入 | `legacy_project_scan.md`、`rule_card_template.yaml` |
| 任务执行 | `task_runtime_prompt.md` |
| 工程判断 | `engineering_heuristics.md` |
| 前端协作 Skills 委托 | `frontend_skills.md`、`delegation_map.yaml` |
| 测试与质量 | `testing_strategy.md`、`quality_gates.md` |
| 代码审查 | `code_review_mode.md` |
| 迁移辅助 | `migration_assist.md` |
| 国际化/无障碍 | `i18n_a11y_check.md` |

完整映射见 [`references/load_map.md`](references/load_map.md)。

### 8. 前端协作 Skills 集成

H5 Forge 不重复造轮子。它检测本地是否安装了 H5/Web 前端 skills，有就委托通用子任务：

```
探测顺序：
1. 当前项目目录 (.claude/skills/, .agents/skills/, .cc-switch/skills/, .trae/skills/)
2. 宿主根目录 (~/.claude/skills/, ~/.agents/skills/, ~/.cc-switch/skills/, ~/.trae/skills/)
3. 未检测到 → 使用内置参考文档兜底（降级不降质量）
```

架构设计师决定调用哪些 skill，页面工程师执行调用。未安装时自动降级到内置流程，不阻塞任务。

委托映射见 [`references/delegation_map.yaml`](references/delegation_map.yaml)。

### 9. 工作模式与可见性

每次 skill 命中后输出一行工作模式标志：

| 模式 | 标志 |
|------|------|
| 运维直通 | `[h5-forge] 页面工程师：运维直通，快速执行` |
| 轻量任务 | `[h5-forge] 页面工程师：轻量任务，直接执行` |
| 页面开发 | `[h5-forge] 模式：页面开发` |
| 代码审查 | `[h5-forge] 模式：代码审查` |
| 迁移辅助 | `[h5-forge] 模式：迁移辅助` |
| i18n/a11y 检查 | `[h5-forge] 模式：i18n/a11y 检查` |
| 迭代中项目扫描 | `[h5-forge] 模式：迭代中项目扫描` |
| 新项目初始化 | `[h5-forge] 模式：新项目初始化` |
| 需求理解 | `[h5-forge] 模式：需求理解 -> 设计包` |

`[h5-forge]` 标记是必选输出，用户在连续对话中能随时感知 h5-forge 是否在工作。

## 项目结构

```
h5-forge/
├── SKILL.md                        # 主控文档（编排逻辑，~300行）
├── README.md                       # 本文件
├── VERSION                         # 版本号
├── CHANGELOG.md                    # 变更记录
│
├── references/                     # 按需加载的参考文档
│   ├── load_map.md                 # 场景 → 文档映射
│   ├── startup_handshake.md        # 启动握手输出格式
│   ├── rule_card_protocol.md       # 规则卡协议
│   ├── project_init_flow.md        # 项目初始化流程
│   ├── memory_protocol.md          # 记忆读写协议
│   ├── skill_visibility.md         # 可见性标记与会话状态
│   ├── code_review_mode.md         # 代码审查模式
│   ├── migration_assist.md         # 迁移辅助
│   ├── i18n_a11y_check.md          # 国际化/无障碍检查
│   ├── frontend_skills.md          # 前端协作 skills 集成
│   ├── engineering_heuristics.md   # 工程判断标准
│   ├── similar_implementation_search.md  # 相似实现检索
│   ├── existing_rules_discovery.md # 已有规则发现
│   ├── templates_catalog.md        # 页面模板目录
│   ├── anti_patterns.md            # 反模式检测
│   ├── testing_strategy.md         # 测试策略
│   ├── network_and_api.md          # 网络层规则
│   ├── routing_and_navigation.md   # 路由规则
│   ├── adr_format.md               # 架构决策记录格式
│   ├── role_handoff_formats.md     # 角色交接格式
│   ├── input_incomplete_handling.md # 输入不完整处理
│   ├── roles/                      # 四角色卡
│   │   ├── requirement_analyst.md  # 需求分析师
│   │   ├── ui_designer.md          # UI 设计师
│   │   ├── architecture_designer.md # 架构设计师
│   │   └── page_engineer.md        # 页面工程师
│   └── ...
│
├── memory/                         # 记忆模板与画像
│   ├── global_preferences.yaml     # 全局偏好
│   ├── profiles/                   # 状态管理画像（Zustand/Pinia/Redux）
│   ├── projects/                   # 项目规则卡示例
│   └── runtime/                    # 运行时任务记忆模板
│
└── scripts/
    └── discover_h5_skills.sh  # 前端协作 skills 探测脚本
```

## 前端协作 Skills（可选）

如果你的环境里已经安装了 React、Vue、Next、Vite、Tailwind、测试或浏览器调试相关 skills，H5 Forge 会优先探测并委托通用子任务（布局、路由、HTTP、测试）。

```bash
scripts/discover_h5_skills.sh
```

没有可协作 skill 时不会阻塞任务，H5 Forge 会回退到内置前端流程。

## 参与贡献

- 贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)
- 开源发布检查：[OPEN_SOURCE_CHECKLIST.md](OPEN_SOURCE_CHECKLIST.md)
- 真实试跑记录模板：[references/validation_log.md](references/validation_log.md)

如果你在真实 H5/Web 项目中试用了 H5 Forge，优先提交 GitHub issue 中的 `Validation case`，这比泛泛的“好用/不好用”更有助于改进路由和规则卡。

## 版本

当前版本：**0.1.0** · [CHANGELOG](CHANGELOG.md)
