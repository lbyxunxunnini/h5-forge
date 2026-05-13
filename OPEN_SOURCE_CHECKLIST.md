# Open Source Checklist

Use this checklist before publishing a GitHub release or asking external users to try H5 Forge.

## Required Before Public Sharing

- [x] Add an open-source license.
- [x] Keep `VERSION`, `.skillhub.json`, and README version text consistent.
- [x] Document installation through `npx skills add`.
- [x] Document git clone fallback installation.
- [x] Add contribution guidelines.
- [x] Add issue templates.
- [ ] Add at least one real validation log from a H5/Web project.
- [ ] Add a short demo transcript.
- [ ] Add screenshots or a recording showing the workflow in action.

## Release Check

Run:

```bash
bash -n scripts/discover_h5_skills.sh
cat VERSION
grep -n '"version"' .skillhub.json
grep -n '当前版本' README.md
```

Confirm:

- `VERSION` matches `.skillhub.json`.
- README version text matches the release.
- `CHANGELOG.md` has an entry for the release or an `Unreleased` section.
- No local-only files are tracked, such as `.h5-forge/`, `.claude/`, `.DS_Store`, or runtime mapping files.

## Evidence To Add Later

- A before/after case where direct AI coding produced inconsistent structure and H5 Forge avoided it.
- A real rule-card initialization log from an existing H5/Web project.
- A page-development transcript showing requirement analysis, UI parsing, architecture decisions, and implementation.
- A failure case where the workflow was too heavy or routed incorrectly, with the fix recorded.

