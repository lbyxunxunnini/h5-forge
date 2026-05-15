#!/usr/bin/env python3
"""Create a H5 Forge rule-card draft from project snapshot evidence."""

from __future__ import annotations

import argparse
import importlib.util
from pathlib import Path


PROFILE_NAMES = {
    "auto",
    "zustand_feature_profile",
    "redux_module_profile",
    "vue_pinia_profile",
    "react_query_profile",
    "lean_h5_profile",
}


def load_snapshot(repo: Path):
    path = repo / "scripts" / "project_snapshot.py"
    spec = importlib.util.spec_from_file_location("project_snapshot", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load snapshot script: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def signal_exists(signals: dict[str, object], category: str, tool: str) -> bool:
    return tool in signals.get(category, {})


def choose_profile(signals: dict[str, object], requested: str) -> tuple[str, str]:
    if requested != "auto":
        return requested, "explicit"
    if signal_exists(signals, "state_management", "zustand"):
        return "zustand_feature_profile", "detected zustand signals"
    if signal_exists(signals, "state_management", "redux"):
        return "redux_module_profile", "detected redux signals"
    if signal_exists(signals, "state_management", "pinia") or signal_exists(signals, "framework", "vue"):
        return "vue_pinia_profile", "detected vue/pinia signals"
    if signal_exists(signals, "networking", "tanstack_query") or signal_exists(signals, "networking", "swr"):
        return "react_query_profile", "detected query-cache signals"
    return "lean_h5_profile", "no dominant stack detected"


def profile_defaults(profile_name: str) -> dict[str, str]:
    defaults = {
        "zustand_feature_profile": {
            "directory_structure": "src/features/<feature>/{pages,components,stores,models,api}",
            "module_boundaries": "Feature owns page UI, feature-local store and feature API adapters; shared only for cross-feature reuse.",
            "component_boundaries": "Extract shared components only after 2+ real usages or design-system consistency requirements.",
            "page_split_style": "feature-first",
        },
        "redux_module_profile": {
            "directory_structure": "src/modules/<module>/{views,components,store,models,api}",
            "module_boundaries": "Keep slice/selectors/actions/API aligned by business module.",
            "component_boundaries": "Prefer module-private components unless reuse is already proven.",
            "page_split_style": "module-first",
        },
        "vue_pinia_profile": {
            "directory_structure": "src/features/<feature>/{pages,components,stores,composables,api}",
            "module_boundaries": "Feature owns Pinia stores and composables; app-level stores only for session/global state.",
            "component_boundaries": "Keep page-specific Vue components local; promote to shared after reuse is real.",
            "page_split_style": "feature-first",
        },
        "react_query_profile": {
            "directory_structure": "src/features/<feature>/{pages,components,queries,models}",
            "module_boundaries": "Server state stays in query hooks; client UI state stays local or feature store.",
            "component_boundaries": "Shared components require real reuse or design-system constraints.",
            "page_split_style": "feature-first",
        },
        "lean_h5_profile": {
            "directory_structure": "src/pages, src/components, src/api, src/stores until complexity requires feature-first",
            "module_boundaries": "Keep boundaries simple; migrate to feature-first when reuse or state sharing grows.",
            "component_boundaries": "Prefer local components first.",
            "page_split_style": "simple-layered",
        },
    }
    return defaults[profile_name]


def best_signal(signals: dict[str, object], category: str) -> tuple[str, dict[str, object]] | None:
    tools = signals.get(category, {})
    if not tools:
        return None
    ranked = sorted(
        tools.items(),
        key=lambda item: ({"high": 3, "medium": 2, "low": 1}.get(item[1]["confidence"], 0), len(item[1]["evidence"])),
        reverse=True,
    )
    return ranked[0]


def evidence_lines(info: dict[str, object], indent: str = "      ") -> str:
    evidence = info.get("evidence", [])[:5]
    if not evidence:
        return f"{indent}evidence: []"
    lines = [f"{indent}evidence:"]
    for item in evidence:
        lines.append(f'{indent}  - "{item["source"]}: {item["value"]}"')
    return "\n".join(lines)


def render_card(project_root: Path, data: dict[str, object], profile_name: str, profile_reason: str) -> str:
    signals = data["stack_signals"]
    framework = best_signal(signals, "framework")
    state = best_signal(signals, "state_management")
    routing = best_signal(signals, "routing")
    network = best_signal(signals, "networking")
    styling = best_signal(signals, "styling")
    testing = best_signal(signals, "testing")
    i18n = best_signal(signals, "i18n")

    framework_name, _ = framework if framework else ("", {"confidence": "low", "evidence": []})
    state_name, state_info = state if state else ("", {"confidence": "low", "evidence": []})
    routing_name, routing_info = routing if routing else ("", {"confidence": "low", "evidence": []})
    network_name, network_info = network if network else ("", {"confidence": "low", "evidence": []})
    styling_name, styling_info = styling if styling else ("", {"confidence": "low", "evidence": []})
    testing_name, testing_info = testing if testing else ("", {"confidence": "low", "evidence": []})
    i18n_name, i18n_info = i18n if i18n else ("", {"confidence": "low", "evidence": []})
    defaults = profile_defaults(profile_name)

    project_name = project_root.name.replace("-", "_")
    return f"""project_rule_card:
  project:
    name: "{project_name}"
    type: "h5"
    status: "existing"
    overall_confidence: "medium"
    source_rules:
      - "project_snapshot"
      - "h5_stack_scan"
      - "{profile_name}"

  team_rules:
    directory_structure:
      rule: "{defaults['directory_structure']}"
      confidence: "low"
      evidence: []

    module_boundaries:
      rule: "{defaults['module_boundaries']}"
      confidence: "low"
      evidence: []

    naming_conventions:
      pages: "*Page.tsx / *Page.vue / project-mainstream page naming"
      components: "BusinessSemantic + Section/Card/List/Item"
      states: "follow detected state-management files"
      models: "TypeScript interface/schema/DTO follows project convention"
      helpers: "*Utils.ts or project-local helper naming"
      confidence: "low"
      evidence: []

    state_management:
      primary_pattern: "{state_name}"
      scope_rules: "Follow project-mainstream {state_name or 'state management'} pattern"
      confidence: "{state_info['confidence']}"
{evidence_lines(state_info)}

    component_boundaries:
      shared_component_rule: "{defaults['component_boundaries']}"
      page_private_component_rule: "Keep page-only components private to page/feature"
      confidence: "low"
      evidence: []

    api_integration:
      request_layer_rule: "{network_name}"
      model_mapping_rule: "Follow {framework_name or 'project'} TypeScript/schema convention"
      error_handling_rule: ""
      confidence: "{network_info['confidence']}"
{evidence_lines(network_info)}

    routing_and_navigation:
      route_definition_rule: "{routing_name}"
      route_naming_rule: ""
      navigation_trigger_rule: ""
      confidence: "{routing_info['confidence']}"
{evidence_lines(routing_info)}

    localization:
      localization_strategy: "{i18n_name}"
      string_management_rule: ""
      confidence: "{i18n_info['confidence']}"
{evidence_lines(i18n_info)}

    theming_and_styling:
      color_source_rule: "{styling_name}"
      spacing_rule: "Follow existing tokens/classes before inventing new values"
      typography_rule: "Follow existing type scale or design-system tokens"
      confidence: "{styling_info['confidence']}"
{evidence_lines(styling_info)}

    testing:
      framework: "{testing_name}"
      coverage_rule: "Critical business logic requires unit/component coverage"
      component_test_rule: "When behavior changes"
      confidence: "{testing_info['confidence']}"
{evidence_lines(testing_info)}

  personal_preferences:
    page_split_style:
      rule: "{defaults['page_split_style']}"
      confidence: "low"

    private_component_naming:
      rule: "Use business semantic names, avoid generic Content/Wrapper names"
      confidence: "low"

  quick_context:
    snapshot_generated_by: "scripts/init_rule_card.py"
    recommended_profile: "{profile_name}"
    profile_reason: "{profile_reason}"
    src_top_dirs: {data['src_top_dirs']}
    routing_entries: {data['routing_entries']}
    state_entries: {data['state_entries']}
    network_entries: {data['network_entries']}
    test_entries: {data['test_entries']}
    confirmation_checklist:
      - "Confirm directory_structure.rule"
      - "Confirm state_management.primary_pattern"
      - "Confirm routing_and_navigation.route_definition_rule"
      - "Confirm api_integration.request_layer_rule"
      - "Confirm component_boundaries.shared_component_rule"

  inferred_rules:
    active_rules: []
    low_confidence_rules: []
    conflicts_to_watch: []

  reuse_knowledge:
    similar_pages: []
    reusable_patterns: []
    avoid_reuse_targets: []

  task_only_context:
    temporary_business_rules: []
    field_special_cases: []
    api_compat_notes: []

  quality_preferences:
    analyze_required: true
    component_test_expectation: "when behavior changes"
    integration_test_expectation: "for critical flows"
    preview_expectation: "for reusable UI components"
"""


def print_wizard_summary(project_root: Path, data: dict[str, object], profile_name: str, profile_reason: str, output: Path) -> None:
    print("H5 Forge rule-card initialization")
    print(f"project: {project_root}")
    print(f"profile: {profile_name} ({profile_reason})")
    print(f"output: {output}")
    print(f"src_top_dirs: {', '.join(data['src_top_dirs']) if data['src_top_dirs'] else 'none'}")
    print(f"routing_entries: {', '.join(data['routing_entries']) if data['routing_entries'] else 'none'}")
    print(f"state_entries: {', '.join(data['state_entries']) if data['state_entries'] else 'none'}")
    print("confirm before promoting draft:")
    print("  - directory structure")
    print("  - state management")
    print("  - routing entry")
    print("  - network layer")
    print("  - shared component rule")


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project_root", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--profile", choices=sorted(PROFILE_NAMES), default="auto")
    parser.add_argument("--interactive", action="store_true", help="Print wizard summary and confirmation checklist.")
    args = parser.parse_args()

    project_root = args.project_root.resolve()
    snapshot_module = load_snapshot(repo)
    data = snapshot_module.snapshot(project_root)
    if not data["is_h5_project"]:
        print(f"FAIL not a H5/Web project: {project_root}")
        return 1

    profile_name, profile_reason = choose_profile(data["stack_signals"], args.profile)
    output = args.output or project_root / ".h5-forge" / "projects" / f"{project_root.name}.rule_card_draft.yaml"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_card(project_root, data, profile_name, profile_reason), encoding="utf-8")
    if args.interactive:
        print_wizard_summary(project_root, data, profile_name, profile_reason, output)
    print(f"PASS rule-card draft written: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
