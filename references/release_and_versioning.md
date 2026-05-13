# H5 Forge Reference - Release And Versioning

H5 Forge 不依赖独立安装脚本，但仍需要最基本的版本化和更新约定。

## 版本来源

- `VERSION`
- `CHANGELOG.md`
- `.skillhub.json`

三者应保持一致。

## 版本规则

建议采用简单语义版本：

- `0.x`：快速迭代阶段
- `1.0.0`：结构和核心协议稳定
- patch：文档修正、小规则补充
- minor：新增 reference、角色协议、规则卡字段
- major：调整 skill 主结构、记忆协议、角色流程

## 更新流程

每次更新至少做三件事：

1. 更新相关文档或 reference
2. 更新 `CHANGELOG.md`
3. 如有必要，更新 `VERSION` 和 `.skillhub.json`

## 冲突检测

如果工作区同时存在其他 H5/Web skill：

- H5 Forge 负责总控与编排
- 前端协作 skills 负责通用技术子任务
- 不要把 H5 Forge 和前端 skill 写成相互覆盖关系

如果存在同名本地 skill：

- 优先保留一个唯一的 `h5-forge`
- 避免多个目录名相同但内容不同
