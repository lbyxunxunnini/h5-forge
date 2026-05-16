# H5 Forge Reference - Load Map

这个文件定义主 skill 之外的按需加载映射。主 `SKILL.md` 不再重复列出大量“遇到什么就读什么”的声明。

## 场景 -> 参考文件

### 迭代中项目首次接入

- [existing_project_entry.md](existing_project_entry.md)
- [existing_project_scan.md](existing_project_scan.md)
- [rule_card_template.yaml](rule_card_template.yaml)
- [example_rule_card.yaml](example_rule_card.yaml)
- [existing_rules_discovery.md](existing_rules_discovery.md)
- [h5_stack_detection.md](h5_stack_detection.md)
- [stack_profiles.md](stack_profiles.md)

### 新 H5/Web 应用从 0 到 1

- [new_project_app_profiles.md](new_project_app_profiles.md)
- [new_project_profile_selection.md](new_project_profile_selection.md)
- [new_project_cocreation_mode.md](new_project_cocreation_mode.md)
- [project_init_flow.md](project_init_flow.md)
- [rule_card_template.yaml](rule_card_template.yaml)

### 相似实现检索与复用追踪

- [similar_implementation_search.md](similar_implementation_search.md)

### 进入具体任务执行

- [task_runtime_prompt.md](task_runtime_prompt.md)
- [fast_mode.md](fast_mode.md)
- [autonomous_mode.md](autonomous_mode.md)

### 需要记忆读写规则

- [memory_protocol.md](memory_protocol.md)

### 需要工程判断标准或 H5/Web 专项规则

- [engineering_heuristics.md](engineering_heuristics.md)

### 需要前端协作 skills 委托规则

- [frontend_skills.md](frontend_skills.md)
- [delegation_map.yaml](delegation_map.yaml)

### 需要网络层项目规则

- [network_and_api.md](network_and_api.md)

### 需要路由层项目规则

- [routing_and_navigation.md](routing_and_navigation.md)

### 需要测试与质量建议

- [testing_strategy.md](testing_strategy.md)
- [quality_gates.md](quality_gates.md)
- [build_and_quality.md](build_and_quality.md)

### 需要反模式、模板或调试手册

- [anti_patterns.md](anti_patterns.md)
- [templates_catalog.md](templates_catalog.md)
- [debugging_playbook.md](debugging_playbook.md)

### 需要架构决策记录格式

- [adr_format.md](adr_format.md)

### 需要角色交接格式

- [role_handoff_formats.md](role_handoff_formats.md)

### 需要处理输入不完整场景

- [input_incomplete_handling.md](input_incomplete_handling.md)

### 需要可见性标记或会话状态规则

- [skill_visibility.md](skill_visibility.md)
- [session_management.md](session_management.md)

### 需要启动握手输出格式

- [startup_handshake.md](startup_handshake.md)

### 需要规则卡协议

- [rule_card_protocol.md](rule_card_protocol.md)

### 需要项目初始化流程

- [project_init_flow.md](project_init_flow.md)

### 需要代码审查模式

- [code_review_mode.md](code_review_mode.md)

### 需要迁移辅助

- [migration_assist.md](migration_assist.md)

### 需要国际化/无障碍检查

- [i18n_a11y_check.md](i18n_a11y_check.md)

### 需要案例或验证记录

- [case_studies.md](case_studies.md)
- [case_study_member_center.md](case_study_member_center.md)
- [case_study_large_rework.md](case_study_large_rework.md)
- [validation_log.md](validation_log.md)
- [demo_transcript.md](demo_transcript.md)
- [mode_test_cases.md](mode_test_cases.md)

### 需要发布与产品化检查

- [release_playbook.md](release_playbook.md)
- [rule_card_validation.md](rule_card_validation.md)

## 反向索引：每个参考文件被哪些上层文件引用

维护时用此表检查引用完整性。新增 reference 文件时同步更新此表。

| 参考文件 | 被引用方 |
|---------|---------|
| task_runtime_prompt.md | SKILL.md（执行协议）、load_map.md |
| fast_mode.md | SKILL.md（h5f-fast）、load_map.md |
| autonomous_mode.md | SKILL.md（h5f-a）、load_map.md |
| decision_and_question_protocol.md | task_runtime_prompt.md、skill_visibility.md、load_map.md |
| skill_visibility.md | SKILL.md（输出日志）、load_map.md |
| session_management.md | SKILL.md（上下文恢复）、load_map.md |
| startup_handshake.md | SKILL.md（启动判定）、load_map.md |
| rule_card_protocol.md | SKILL.md（规则卡检查）、load_map.md |
| rule_card_validation.md | load_map.md |
| project_init_flow.md | SKILL.md（项目初始化）、load_map.md |
| memory_protocol.md | SKILL.md（记忆机制）、load_map.md |
| engineering_heuristics.md | load_map.md |
| h5_stack_detection.md | load_map.md |
| stack_profiles.md | load_map.md |
| frontend_skills.md | SKILL.md（前端协作 skills）、load_map.md |
| delegation_map.yaml | load_map.md |
| host_subagent_support.md | SKILL.md（并行协议）、load_map.md |
| similar_implementation_search.md | SKILL.md（相似实现）、load_map.md |
| input_incomplete_handling.md | load_map.md |
| network_and_api.md | load_map.md |
| routing_and_navigation.md | load_map.md |
| testing_strategy.md | task_runtime_prompt.md、load_map.md |
| quality_gates.md | task_runtime_prompt.md、load_map.md |
| build_and_quality.md | load_map.md |
| anti_patterns.md | load_map.md |
| templates_catalog.md | load_map.md |
| debugging_playbook.md | load_map.md |
| adr_format.md | load_map.md |
| role_handoff_formats.md | load_map.md |
| code_review_mode.md | load_map.md |
| migration_assist.md | load_map.md |
| i18n_a11y_check.md | load_map.md |
| release_playbook.md | load_map.md |
| case_studies.md | load_map.md |
| case_study_member_center.md | load_map.md |
| case_study_large_rework.md | load_map.md |
| mode_test_cases.md | load_map.md |
| demo_transcript.md | load_map.md |
| validation_log.md | load_map.md |
