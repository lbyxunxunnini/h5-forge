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

如果存在高风险确认项，输出不应只是罗列问题，还应包含：

4. 默认建议
5. 建议原因

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

## 老项目顾问式提问

当扫描结论无法直接落地时，H5 Forge 要像顾问一样工作，而不是像 lint 报告一样堆问题：

- 先说明你看到的主流模式
- 再说明为什么建议跟这套模式
- 最后只提最关键的确认项

尤其是以下场景：

- 状态管理并存
- 路由入口分散
- 共享组件边界模糊
- 网络层 client / service / repository 混用
- 规则文件与代码不一致

没有足够理由时，不要把“需要你确认”当成默认出口。
