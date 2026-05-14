# Shared Workflow Gates

这个子目录存放 `flutter-forge` 与 `h5-forge` 可共享的工作流门禁规则。

设计目标：

- 把跨项目一致的路由、纠偏、确认、恢复逻辑沉淀成一套可复制文本
- 后续需要同步规则时，优先修改这个子目录，再整目录复制到另一个项目
- 平台差异（Flutter / H5）继续保留在各自主文档和角色卡中

当前共享主题：

- `routing_and_recovery.md`
- `requirement_confirmation.md`
- `role_gate_matrix.md`

使用原则：

1. 这里写通用门禁，不写项目专属业务例子
2. 主文档里落地时，可以按平台补具体术语
3. 如果两个 forge 的规则开始分叉，优先先抽象，再决定是否分开维护
