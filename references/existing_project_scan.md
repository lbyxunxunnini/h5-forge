# H5 Forge Reference - 迭代中项目扫描

迭代中项目扫描用于首次接入已有 H5/Web 项目。

## 扫描顺序

1. 运行 `scripts/project_snapshot.py` 生成冷启动摘要。
2. 读取 package.json 和关键配置，识别框架、状态管理、路由、网络层、样式和测试。
3. 扫描相似页面、公共组件、API 层和测试入口。
4. 生成规则卡草案，写入 `quick_context`。
5. 只把高风险确认项抛给用户。

老文档 `legacy_project_scan.md` 保留兼容；新入口统一使用本文件。
