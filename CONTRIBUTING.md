# Contributing

H5 Forge is a workflow skill for AI-assisted H5/Web development. Contributions should improve how the skill routes tasks, reads project context, handles incomplete input, or keeps generated work aligned with an existing H5/Web codebase.

## Good Contribution Areas

- Clearer task-routing rules in `SKILL.md`.
- Better reference material under `references/`.
- Real validation logs from actual H5/Web projects.
- Installation, diagnosis, and compatibility fixes.
- More precise rule-card fields or examples.
- Bug reports where the skill chose the wrong workflow.

## Before Opening a PR

1. Keep `SKILL.md` focused on orchestration. Put detailed rules in `references/`.
2. Keep version metadata consistent when publishing a release: `VERSION`, `.skillhub.json`, `README.md`, and `CHANGELOG.md`.
3. Add a `CHANGELOG.md` entry for user-visible behavior changes.
4. If a change affects task routing, include at least one before/after example.
5. If a change is based on a real project run, record the facts in `references/validation_log.md` or link to a reproducible case.

## Validation

There is no compile step for the skill itself. Use these checks before submitting:

```bash
bash -n scripts/discover_h5_skills.sh
grep -n '"version"' .skillhub.json
cat VERSION
```

For workflow changes, test at least one prompt from each affected mode:

- Light task: a small UI copy/style edit.
- Page development: a new page or module request.
- Code review: review an existing H5/Web page.
- Migration: state-management or directory-structure migration.

## Writing Style

- Be explicit about what the agent should do and when it should stop.
- Do not turn uncertain guesses into project rules.
- Prefer short decision rules over broad slogans.
- Use Chinese for existing Chinese docs unless a file is intentionally bilingual.

