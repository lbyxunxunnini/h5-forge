# H5 Forge Quickstart

3 分钟上手，只记入口和自检命令。

## 1. 标准入口

```text
h5f- 新增一个订单列表页，接入现有路由和状态管理
```

标准入口会自动路由：小改动直接做，新页面/大功能先收口需求、UI 和架构。

## 2. 快速入口

```text
h5f-fast 帮我把登录页按钮颜色和文案改掉
```

快速入口优先走轻量/中等路径，最多读取少量关键文件。发现结构风险时才升级。

## 3. 全自动入口

```text
h5f-a 做一个会员中心页，缺少的部分按你推荐方案推进直到做完
```

全自动入口会把非阻塞缺口写成 `auto_assumption` 并继续执行。高风险事项仍会中断确认。

## 4. 初始化项目

```bash
scripts/project_snapshot.py /path/to/h5-app
scripts/init_rule_card.py /path/to/h5-app --interactive
```

生成规则卡草案后，确认目录结构、状态管理、路由、网络层和共享组件规则，再提升为正式规则卡。

## 5. 自检

```bash
scripts/doctor.sh
scripts/validate_release.sh
```

自检会检查版本一致、规则卡 schema、H5 技术栈扫描、路由 golden、文档链接和 demo fixture。
