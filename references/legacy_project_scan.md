# H5 Forge Reference - Legacy Project First Scan

这个文件是“迭代中项目首次接入”的扫描路由与检查清单，不再维护一套与 `SKILL.md` 平行的旧规则。

## 目标

首次进入迭代中 H5/Web 项目时，优先建立项目规则理解，不要立刻写代码。

## 最低扫描范围

至少覆盖：

1. 目录结构
2. 模块边界
3. 命名风格
4. 状态管理主模式
5. 组件库与共享组件使用方式
6. 接口接入方式
7. 公共组件边界
8. 路由与导航方式
9. 国际化、主题、依赖注入等主流工程规则
10. 已有规则文件（`.claude/rules/`、`.trae/rules/`、`.agents/rules/`、项目根目录的 `rules.md`、`analysis_rules.md` 等）

## 扫描原则

- 优先看最近、最主流、最具代表性的代码
- 不要被孤例和历史遗留误导
- 低置信度判断必须显式标注
- 不要在扫描阶段直接开始写页面代码
- 识别项目主流模式时，参考 `engineering_heuristics.md`

## 输出要求

输出三部分：

1. 项目规则理解摘要
2. 结构化规则卡
3. 高风险确认项

## 必读配套文件

- `references/rule_card_template.yaml`
- `references/engineering_heuristics.md`
- `references/memory_protocol.md`
- `references/routing_and_navigation.md`
- `references/network_and_api.md`

## 扫描后检查

完成扫描后，至少过一遍：

- `references/quality_gates.md` 中的 `after_requirement`
- `references/quality_gates.md` 中的 `after_implementation`
