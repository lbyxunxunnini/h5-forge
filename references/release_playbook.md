# H5 Forge Reference - 发布流程

## 发布前检查

```bash
scripts/doctor.sh
scripts/validate_release.sh
```

必须通过：

- VERSION、README、CHANGELOG、`.skillhub.json` 版本一致
- 规则卡模板和示例可校验
- H5 技术栈扫描 fixture 通过
- 规则卡草案生成可用
- 路由 golden 通过
- 文档链接同步

## 发布内容

- README 顶部说明当前版本。
- CHANGELOG 顶部新增版本段。
- demo transcript 和 validation log 同步更新。
- 如新增入口或模式，更新 QUICKSTART、CHEATSHEET、SKILL.md 和 load_map。

## 标签建议

H5 Forge 从 `v0.1.0` 开始使用 v 前缀发布线，用于和历史无 `v` 的 `0.x.x` 版本隔离。
