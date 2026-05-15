#!/usr/bin/env python3
"""Detect H5/Web project stack signals for rule-card initialization."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


STACK_RULES = {
    "framework": {
        "react": {
            "dependencies": ("react", "react-dom"),
            "content": ("import React", "from 'react'", "from \"react\"", "createRoot("),
            "files": ("App.tsx", "App.jsx"),
        },
        "vue": {
            "dependencies": ("vue",),
            "content": ("createApp(", "<template>", "defineComponent(", "defineProps"),
            "files": (".vue",),
        },
        "next": {
            "dependencies": ("next",),
            "content": ("next/link", "next/navigation", "getServerSideProps", "generateMetadata"),
            "files": ("next.config", "app/page.", "pages/_app."),
        },
        "nuxt": {
            "dependencies": ("nuxt",),
            "content": ("defineNuxtConfig", "useRoute()", "useFetch("),
            "files": ("nuxt.config",),
        },
        "vite": {
            "dependencies": ("vite",),
            "content": ("defineConfig(", "@vitejs/plugin"),
            "files": ("vite.config",),
        },
    },
    "state_management": {
        "zustand": {
            "dependencies": ("zustand",),
            "content": ("create<", "createStore(", "zustand/middleware"),
            "files": ("store.ts", "store.tsx", "useStore.ts"),
        },
        "redux": {
            "dependencies": ("redux", "@reduxjs/toolkit", "react-redux"),
            "content": ("configureStore(", "createSlice(", "Provider store=", "useSelector("),
            "files": ("store.ts", "slice.ts"),
        },
        "pinia": {
            "dependencies": ("pinia",),
            "content": ("defineStore(", "createPinia("),
            "files": ("store.ts", "stores/"),
        },
        "vuex": {
            "dependencies": ("vuex",),
            "content": ("createStore(", "mapState", "mapActions"),
            "files": ("store.js", "store.ts"),
        },
        "react_context": {
            "dependencies": (),
            "content": ("createContext(", "useContext(", ".Provider"),
            "files": ("context.ts", "context.tsx"),
        },
    },
    "routing": {
        "react_router": {
            "dependencies": ("react-router", "react-router-dom"),
            "content": ("createBrowserRouter", "useNavigate(", "<Routes", "<Route"),
            "files": ("router.tsx", "routes.tsx"),
        },
        "vue_router": {
            "dependencies": ("vue-router",),
            "content": ("createRouter(", "createWebHistory(", "router.push"),
            "files": ("router.ts", "routes.ts"),
        },
        "next_router": {
            "dependencies": ("next",),
            "content": ("next/router", "next/navigation", "useRouter("),
            "files": ("app/page.", "pages/"),
        },
    },
    "networking": {
        "axios": {
            "dependencies": ("axios",),
            "content": ("axios.create", "AxiosInstance", "axios.get", "axios.post"),
            "files": ("api.ts", "request.ts", "http.ts"),
        },
        "fetch": {
            "dependencies": (),
            "content": ("fetch(", "RequestInit", "Response.json"),
            "files": (),
        },
        "tanstack_query": {
            "dependencies": ("@tanstack/react-query", "@tanstack/vue-query", "react-query"),
            "content": ("QueryClient", "useQuery(", "useMutation("),
            "files": (),
        },
        "swr": {
            "dependencies": ("swr",),
            "content": ("useSWR(",),
            "files": (),
        },
    },
    "styling": {
        "tailwind": {
            "dependencies": ("tailwindcss",),
            "content": ("@tailwind", "className=\"flex", "class=\"flex"),
            "files": ("tailwind.config",),
        },
        "sass": {
            "dependencies": ("sass", "node-sass"),
            "content": (),
            "files": (".scss", ".sass"),
        },
        "css_modules": {
            "dependencies": (),
            "content": ("styles.", "module.css", "module.scss"),
            "files": (".module.css", ".module.scss"),
        },
        "styled_components": {
            "dependencies": ("styled-components", "@emotion/react", "@emotion/styled"),
            "content": ("styled.", "css`"),
            "files": (),
        },
    },
    "testing": {
        "vitest": {
            "dependencies": ("vitest",),
            "content": ("describe(", "expect(", "vi."),
            "files": ("vitest.config",),
        },
        "jest": {
            "dependencies": ("jest",),
            "content": ("jest.fn", "describe(", "expect("),
            "files": ("jest.config",),
        },
        "testing_library": {
            "dependencies": ("@testing-library/react", "@testing-library/vue"),
            "content": ("render(", "screen.", "fireEvent", "userEvent"),
            "files": (),
        },
        "playwright": {
            "dependencies": ("@playwright/test", "playwright"),
            "content": ("test(", "page.goto"),
            "files": ("playwright.config",),
        },
        "cypress": {
            "dependencies": ("cypress",),
            "content": ("cy.visit", "cy.get"),
            "files": ("cypress.config",),
        },
    },
    "i18n": {
        "i18next": {
            "dependencies": ("i18next", "react-i18next"),
            "content": ("useTranslation(", "i18n.t(", "initReactI18next"),
            "files": ("i18n.ts", "locales/"),
        },
        "vue_i18n": {
            "dependencies": ("vue-i18n",),
            "content": ("createI18n(", "useI18n("),
            "files": ("i18n.ts", "locales/"),
        },
    },
    "component_library": {
        "antd": {
            "dependencies": ("antd",),
            "content": ("from 'antd'", "from \"antd\""),
            "files": (),
        },
        "vant": {
            "dependencies": ("vant",),
            "content": ("from 'vant'", "from \"vant\""),
            "files": (),
        },
        "element_plus": {
            "dependencies": ("element-plus",),
            "content": ("from 'element-plus'", "from \"element-plus\""),
            "files": (),
        },
        "naive_ui": {
            "dependencies": ("naive-ui",),
            "content": ("from 'naive-ui'", "from \"naive-ui\""),
            "files": (),
        },
    },
}


TEXT_SUFFIXES = {
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".vue",
    ".mjs",
    ".cjs",
    ".json",
    ".css",
    ".scss",
    ".sass",
    ".less",
}


def parse_package_dependencies(package_json: Path) -> set[str]:
    if not package_json.exists():
        return set()
    try:
        data = json.loads(package_json.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return set()

    dependencies: set[str] = set()
    for key in ("dependencies", "devDependencies", "peerDependencies"):
        section = data.get(key, {})
        if isinstance(section, dict):
            dependencies.update(section.keys())
    return dependencies


def collect_project_files(root: Path) -> list[Path]:
    candidates: list[Path] = []
    for directory_name in ("src", "app", "pages", "components", "test", "tests", "e2e", "cypress"):
        directory = root / directory_name
        if not directory.exists():
            continue
        for path in directory.rglob("*"):
            if path.is_file() and path.suffix in TEXT_SUFFIXES:
                candidates.append(path)

    for pattern in (
        "vite.config.*",
        "next.config.*",
        "nuxt.config.*",
        "webpack.config.*",
        "tailwind.config.*",
        "vitest.config.*",
        "jest.config.*",
        "playwright.config.*",
        "cypress.config.*",
        "tsconfig.json",
    ):
        candidates.extend(path for path in root.glob(pattern) if path.is_file())
    return sorted(set(candidates))


def read_text_sample(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")[:200_000]
    except OSError:
        return ""


def add_evidence(evidence: list[dict[str, str]], source: str, value: str) -> None:
    item = {"source": source, "value": value}
    if item not in evidence:
        evidence.append(item)


def confidence_for(count: int) -> str:
    if count >= 3:
        return "high"
    if count >= 1:
        return "medium"
    return "low"


def scan(root: Path) -> dict[str, object]:
    package_json = root / "package.json"
    dependencies = parse_package_dependencies(package_json)
    files = collect_project_files(root)
    file_text = {path: read_text_sample(path) for path in files}

    result: dict[str, object] = {
        "project_root": str(root),
        "is_h5_project": package_json.exists()
        and any((root / name).exists() for name in ("src", "app", "pages", "index.html")),
        "dependencies": sorted(dependencies),
        "signals": {},
    }

    signals: dict[str, object] = {}
    for category, tools in STACK_RULES.items():
        category_signals: dict[str, object] = {}
        for tool, rule in tools.items():
            evidence: list[dict[str, str]] = []

            for dep in rule["dependencies"]:
                if dep in dependencies:
                    add_evidence(evidence, "package.json", dep)

            for path in files:
                relative = str(path.relative_to(root))
                lower_relative = relative.lower()

                for filename_hint in rule["files"]:
                    if filename_hint.lower() in lower_relative:
                        add_evidence(evidence, relative, f"file:{filename_hint}")

                text = file_text[path]
                for token in rule["content"]:
                    if token in text:
                        add_evidence(evidence, relative, token)

            if evidence:
                category_signals[tool] = {
                    "confidence": confidence_for(len(evidence)),
                    "evidence": evidence[:8],
                }

        signals[category] = category_signals

    result["signals"] = signals
    return result


def print_summary(result: dict[str, object]) -> None:
    print(f"project_root: {result['project_root']}")
    print(f"is_h5_project: {str(result['is_h5_project']).lower()}")
    print(f"dependencies: {', '.join(result['dependencies'])}")
    print("signals:")
    for category, tools in result["signals"].items():
        if not tools:
            continue
        print(f"  {category}:")
        for tool, info in tools.items():
            evidence_values = ", ".join(item["value"] for item in info["evidence"][:3])
            print(f"    - {tool}: {info['confidence']} ({evidence_values})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project_root", type=Path)
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    args = parser.parse_args()

    root = args.project_root.resolve()
    if not root.exists():
        print(f"project root does not exist: {root}", file=sys.stderr)
        return 2

    result = scan(root)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print_summary(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
