# H5 Forge Reference - 阶段转换检查点

这个文件定义每次阶段转换时必须执行的检查点动作。目标是防止：
- 阶段转换遗漏（如 S2 后忘记进 S4）
- 输出格式丢失（角色前缀、阶段日志）
- Session 状态丢失

## 什么时候用

每次阶段转换时（S1→S2、S2→S4、S4→S5、S5→S6），controller 先过一遍这个检查点。S2→S4 是特殊硬阻断：S2 输出完成后不得结束回复，必须继续输出 S4 阶段日志并开始实现。

## 检查点动作（按顺序执行）

### 1. 状态回写（P0）

通过 `scripts/ff_session.sh` 将当前状态写入宿主 session。session 路径和格式以 [session_management.md](session_management.md) 为准，禁止绕过脚本手写另一套 YAML：

```bash
scripts/ff_session.sh init --track execution --phase S1 --mode 页面开发
scripts/ff_session.sh update --phase S4 --mode 页面开发 --recent_action "进入 S4，实现已确认方案"
scripts/ff_session.sh wait --waiting_state artifact --expected_input screenshot --pending_question "请补充当前 UI 截图"
```

### 2. 输出校验（P0）

运行 `scripts/validate_output.sh` 校验当前会话累积的 `[h5-forge]` 输出：
- 阶段切换前：`scripts/validate_output.sh`（确保格式、阶段全名和角色前缀合法）
- S2→S4 硬阻断：输出 S4 阶段日志后立刻运行 `scripts/validate_output.sh --require-s4`
- 任务收口时：`scripts/validate_output.sh --require-complete`
- 校验失败时：立即修正并重新输出，不允许带着违规输出进入下一阶段

### 3. 阶段日志输出（P0）

输出格式：`[h5-forge] 阶段：{阶段编号} {阶段名}`

合法阶段名对照表：

| 编号 | 合法名 |
|------|--------|
| S1 | 需求确认 |
| S2 | 方案确认 |
| S3 | 拆包冻结 |
| S4 | 实现中 |
| S5 | 验证中 |
| S6 | 完成（不输出阶段日志，输出完成日志） |
| C0 | 想法收口 |
| C1 | 方向共创 |
| C2 | 工程定型 |
| C3 | 首批范围冻结 |

**禁止使用的阶段名**（常见错误）：
- ~~S1 需求分析~~ → 应为 `S1 需求确认`
- ~~S1 需求梳理~~ → 应为 `S1 需求确认`
- ~~S2 方案设计~~ → 应为 `S2 方案确认`
- ~~S4 开发中~~ → 应为 `S4 实现中`
- ~~S4 编码中~~ → 应为 `S4 实现中`
- ~~S5 测试中~~ → 应为 `S5 验证中`

### 4. 角色结果日志（按需）

只输出本轮真实参与的专项判断，必须带角色前缀：

```text
[h5-forge] 角色名：结论内容
```

合法角色名：`需求分析师` / `UI 设计师` / `架构设计师` / `页面工程师` / `验证工程师` / `主控`

**禁止裸输出分析结论**——即使只是补充说明，也必须带角色前缀。

### 5. S2→S4 硬阻断检查（UI 优化/架构级任务/页面开发/功能开发）

S2 方案确认完成后，在进入 S4 前额外检查：

- [ ] S2 的阶段日志已输出？
- [ ] S2 的角色结果日志已输出（带角色前缀）？
- [ ] 非 `h5f-a` 场景下用户确认已收到（回写"已确认"）？如果正在等待确认，已通过 `ff_session.sh wait` 写入等待态？
- [ ] 下一条回复将输出 `[h5-forge] 阶段：S4 实现中`？

如果任一检查未通过，先补全再进入 S4，不允许在 S2 输出"结论"后退出。

## Session 恢复时的检查点

如果从宿主 session 恢复：

1. 通过 `scripts/ff_session.sh read` 读取 `当前阶段`、`当前模式`、`等待状态`、`等待输入类型`、`任务对象`、`恢复键` 和 `最近操作`
2. 如果 `等待状态 != none`，输出 `[h5-forge] 恢复等待：上一轮正在等待{等待输入类型}，已接入本轮补充并继续 {当前模式} / {当前阶段}`；否则输出 `[h5-forge] 恢复阶段：{当前阶段}` 告知用户
3. 从 `最近操作` 指示的位置继续执行
4. 等待态恢复并消费用户输入后，运行 `scripts/ff_session.sh update --waiting_state none --expected_input none --last_user_input "<摘要>"`
5. 不重新走路由和分类
