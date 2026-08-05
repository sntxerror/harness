# Handoff — start here

Updated: 5 August 2026. Replace this file's contents at the end of each working session; it describes current state only, not history (history is `CHANGELOG.md` and git).

## Where the project stands

**V0.0 (canonical repo & tracking) is complete** — all six tasks checked. Everything before this point was documentation, schemas, config templates and the task tracker; no system code exists yet.

**V0.1 (baseline interactive harness) is the next version** and is research-gated: two of its seven tasks require verifying upstream pins before anything is installed.

The current branch is `feature/v0.0-closeout-and-cache-discipline`, which closes V0.0 and adds the cache-discipline mechanism spec. It has not been merged.

## What changed in the last session

- Closed V0.0-T3 (markdown lint clean, 25 files), V0.0-T5 (`validate-bundle.sh` repaired — it depended on `rg`, which is not installed; now uses `grep`, prunes `.git`, checks docs 00–10, all five schemas and per-version task files) and V0.0-T6 (placeholder resolution checklist appended to the V0.0 task file).
- Added `docs/10-context-and-cache-discipline.md` — the operational mechanism behind ADR-007. The docs previously stated the policy (frozen prefix, append-only tail) but never where breakpoints go, how invalidation is detected, or what CI checks. Covers request zones, breakpoint placement including the bounded lookback window, append-only mutation channels, the silent-invalidator audit table, economics and per-version obligations.
- Added ADR-034 (mid-session change uses append-only channels — `system`-role messages and additive tool loading — never prefix edits) and ADR-035 (cache conformance is hash-verified and CI-gated, not a convention).
- Added R-082 (breakpoint lookback starvation in long tool chains), R-083 (parallel fan-out cache stampede) and R-084 (verification specified but never implemented).
- Wired the obligations into tracked work: V0.3-T8/T9/T10 and V0.4-T9/T10.
- Added `CLAUDE.md` (repo working conventions) and this file.

## Do this first in the next session

```bash
cd /home/sntx/RND/harness
git status                                  # expect: on the feature branch, clean
bash scripts/validate-bundle.sh             # expect: exit 0
npx --yes markdownlint-cli2 "docs/**/*.md" "tasks/*.md" "*.md"   # expect: 0 issues
```

Then close out V0.0 per the roadmap:

```bash
git checkout develop && git merge --no-ff feature/v0.0-closeout-and-cache-discipline
git checkout main && git merge --no-ff develop
git tag -a v0.0 -m "V0.0 — canonical repo and tracking"
git push origin main develop --tags
git checkout develop
```

Confirm the tag is wanted before pushing it — it is the first release marker and the roadmap treats `v0.0` as the point where the repository structure is frozen as a baseline.

## Then: V0.1, and why it starts with research

`tasks/V0.1-baseline-harness.md` covers plan stages 0–2. Two tasks gate the rest, and both need web access:

**V0.1-T2 — pin upstream Pi.** Record exact version, source, install method and rollback metadata. The plan (`docs/01` Stage 1) installs vanilla Pi into two physically separate profile roots (`trusted-local`, `isolated-local`) before any extension.

**V0.1-T4 — verify three package pins.** For each, produce inspection notes or a rejection plus a named alternative:

| Package | Depends on it | Must verify |
| --- | --- | --- |
| `@gotgenes/pi-permission-system` | V0.1-T5 | **Blocker (R-001):** whether configuration can be re-read or hot-reloaded mid-session. Our invariant is parse-once at `session_start`, hashed into the manifest. If upstream cannot guarantee it, the fallback is a pinned patch or launcher-boundary guard that fails closed |
| `pi-interactive-shell` | V0.1-T6 | PTY behavior for sudo and secret entry — the password must be typed directly and never captured or echoed into transcript/logs (R-005/R-006). Also whether it exposes any path that bypasses the permission alias |
| `@juicesharp/rpiv-ask-user-question` | V0.1-T6 | Question schema shape against `schemas/UserQuestionV1.schema.json`; whether an adapter is needed to map its payload into ours (one schema in Pi, adapters map foreign questions in) |

For every pin also record: release date and activity, license, whether install runs scripts (prefer `--ignore-scripts`), and the specific behaviors we depend on — because "extension trust rule" in `docs/01` treats installing a package as installing executable code.

**V0.1-T1 needs no network** and can proceed in parallel: service-account layout, directories, profile roots, rootless worker runtime, verified by `scripts/server-preflight.sh`.

## Decisions needed from you

1. **Provider and model pin.** `config/session-manifest.example.yaml` carries `REPLACE_PROVIDER` / `REPLACE_MODEL_ID`, and V0.1-T2 cannot complete without them. This is not only a cost choice: the model identity is part of the frozen prefix, so changing it later is an epoch boundary, and whether the append-only mutation channels of ADR-034 exist at all is model-dependent (that is V0.3-T10). Pin an exact ID, never an alias — alias drift silently changes the prefix.
2. **Tag `v0.0` now?** The roadmap says yes once all boxes are checked, which they now are.
3. **Machine dependencies.** `rg` and `fd` are not installed; `jq`, `python3`, `node v24` and `npx` are. Scripts were kept dependency-light rather than requiring `rg`. Say if you would rather install the tools and let scripts assume them.

## Environment notes

- Repo root `/home/sntx/RND/harness`; frozen predecessor bundle in `/home/sntx/RND/archive` (read-only reference, do not edit).
- Remote is a private GitHub repository; `main` and `develop` both pushed.
- No CI runs yet — the verification commands above are run by hand. The first real CI gate is the cache regression test (V0.3-T9).

## Reading order for a fresh session

`docs/00-documentation-index.md` → `docs/02-architecture-decisions.md` → `ROADMAP.md` → the current task file. Add `docs/10-context-and-cache-discipline.md` before touching prompt assembly, tool registration, retrieval or history; add `docs/08`/`docs/09` before anything about personas, missions or topology.
