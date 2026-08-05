# Working conventions for this repository

Read `HANDOFF.md` first for current state. This file is how to work here, not what the system is — that lives in `docs/`, starting at `docs/00-documentation-index.md`.

## Ask before implementing any documented decision (ADR-036)

**The documents record what was decided. They are not permission to do it now.** Before implementing any architecture decision from `docs/` — provisioning, accounts and privileges, package or version pins, profile and containment layout, provider/model choice, schema or contract changes, service topology — put it to the operator and wait for an explicit answer.

When asking, give: the decision and where it is recorded, what implementing it commits us to, what it rules out, and any place the document disagrees with the machine's actual state.

- Approval is **per decision**. It does not carry to the next decision in the same document, the next phase of the same runbook, or a re-run after something changed.
- A command block in a runbook is **reviewed content, not a script to run on sight**. Privileged commands are the operator's to run; a password is never typed into anything an agent can observe (R-005/R-006).
- Silence is not approval. Neither is the operator having approved a related step earlier.

Proceed without asking only for reversible, non-privileged work already covered by a decision: reading state, the read-only preflight, validation and lint, drafting documents, preparing scripts for review.

These documents are specific enough to read like an execution plan. Following them faithfully will provision hosts and create accounts that nobody chose to create today — which is the failure this rule exists to prevent.

## What this repository is

The canonical home of the Ultimate Pi Agent System. Today it is documentation, schemas, config templates and a task tracker; code lands as versions are implemented. `docs/` is implementation authority — an idea appearing in `docs/04-brainstorm-evolution.md` is history, not permission to build.

## Change discipline (from `docs/00`)

Order matters and is not negotiable:

1. A settled decision changes in `docs/02-architecture-decisions.md` first, with rationale and what it rejects.
2. `docs/01-ordered-implementation-plan.md` is then updated to match.
3. New uncertainty goes to `docs/03-risks-gaps-overlaps.md` with a mitigation, not to prose.
4. Only then does code or config change.

Corollary: do not fix a doc/code disagreement by editing the code to match a stale doc, or vice versa, without deciding which one is actually wrong.

## Tasks

- Work is expressed as tasks in `tasks/V0.x-*.md` with an ID (`V0.x-Ty`), type, dependencies and acceptance criteria.
- Check a box only when its stated acceptance criterion is demonstrably met — not when the work "looks done". If a criterion turns out to be wrong, change the criterion explicitly in the same commit.
- Adding a task is normal and preferred over silently widening an existing one.
- From V0.7 the mission board replaces these files as tracker of record; until then the checkboxes are authoritative.

## Git

- `main` holds tagged releases, `develop` integrates, `feature/<task-id>-<slug>` per unit of work.
- Conventional-Commit shaped subjects; prepend a `CHANGELOG.md` bullet manually until V0.4's commit finalization automates it.
- A version merges to `main` only when every box in its task file is checked.
- Never commit resolved secrets or a config template with placeholders filled in — resolve at point of use, not in `config/`.

## Verification before any commit

```bash
bash scripts/validate-bundle.sh
npx --yes markdownlint-cli2
```

Both must be clean. `validate-bundle.sh` is read-only, needs `jq`, and takes no network. Globs and ignores live in `.markdownlint-cli2.jsonc`; rule config in `.markdownlint.jsonc`. Both tools skip `docs/archive/` — frozen imported material, kept verbatim, never edited and never a reason for a check to fail.

## Writing style for this repo

The documents are dense and declarative on purpose: each states a decision, its reason, and what it rules out. Match that. Specifically — prefer prose that carries the "because" over bullet walls; state what is rejected alongside what is chosen; give tables a single clear authority column; do not add generic advice a reader could have assumed.

## Cache discipline applies to our own prompts too

`docs/10-context-and-cache-discipline.md` is not only a spec for the system being built — it is how work in this repository is done. When authoring skills, profiles or prompt assembly here: nothing volatile in a prefix, state changes append rather than re-render, and any mid-session instruction uses an append-only channel. Reviews use the checklist in `10` §9.

## Things that are easy to get wrong here

- **`REPLACE_` placeholders are intentional.** Never "fix" one to make a check pass; `validate-bundle.sh` counts them deliberately. Resolution happens in a profile-specific copy at point of use (`tasks/V0.0` §T6).
- **One owner per responsibility.** Before adding any tool, package or index, find the existing owner in `docs/01` (Outcome table) and `docs/03` (overlap table). A duplicate needs a measured advantage, not a plausible one.
- **Pins are exact and reviewed.** Upgrading a pinned package is a task with inspection notes, not a routine bump (R-050).
- **Placeholder checks that always pass are worse than no check** (R-057). Omit the entry instead.
