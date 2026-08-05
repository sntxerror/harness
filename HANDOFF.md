# Handoff — start here

Updated: 5 August 2026. Replace this file's contents at the end of each working session; it describes current state only, not history (history is `CHANGELOG.md` and git).

## The rule that governs how you work here

**Ask before implementing any decision recorded in `docs/` (ADR-036).** The documents are authority over *what was decided*, never permission to do it now. Present the decision, where it is recorded, what it commits us to and what it rules out — then wait. Approval is per decision and does not carry to the next phase or a later re-run. Runbook command blocks are reviewed content, not scripts to run on sight. Full statement in `CLAUDE.md`.

## Where the project stands

**V0.0 (canonical repo & tracking) is complete** — all six tasks checked. **V0.1 (baseline interactive harness) is the current version**, partially started on the server.

Branch `feature/v0.0-closeout-and-cache-discipline` holds the V0.0 closeout, the cache-discipline spec and the governance decision. Not merged. Tagging `v0.0` is approved and pending the merge.

## Remote server — actual state right now

Host `62.238.51.68`, Ubuntu 26.04, 4 vCPU / 7.6 GiB / 70 GB free, key-based SSH as `sntx`. Full survey and the divergences from the runbook's assumptions are in `docs/07` §"Current host".

Changed so far:

| Change | State | Note |
| --- | --- | --- |
| Passwordless sudo for `sntx` | **Active** | `/etc/sudoers.d/90-sntx-nopasswd`, installed by the operator. Time-boxed for setup — remove with `sudo rm /etc/sudoers.d/90-sntx-nopasswd` when Phase 0 is done |
| `piops` service account | **Created** | uid 1001, disabled password, no sudo. Must never receive sudo — the isolated profile's guarantees depend on it |
| `/srv/pi-agent` tree | **Created** | `repos`, `worktrees`, `runs`, `artifacts`, `backups`; `0750 piops:piops`. `sntx` correctly cannot read into it |

Not done, and each needs its own approval before proceeding:

- **Package set** — `rg`, `jq`, `sqlite3`, `podman` are still missing, so `scripts/server-preflight.sh` exits 1 and V0.1-T1 cannot pass. Install was stopped mid-flight; nothing was written.
- **Service-user directories** under `/home/piops` (`docs/07` §"Service-user directories").
- **`loginctl enable-linger piops`** for user services.
- **sshd hardening** — `PasswordAuthentication no`, `PermitRootLogin no`, `AllowUsers`. This is the one change that can lock you out; validate with `sudo sshd -t` before reload and keep a session open.

Pi itself: **0.83.0** at `~/.nvm/versions/node/v24.19.0/bin/pi`, under the `sntx` account. Nothing is installed for `piops` yet.

## Model pin

Requested: **GPT-5.6 Luna via the `openai-codex` provider**, thinking level medium. Verified working end to end on the server:

```bash
pi --model openai-codex/gpt-5.6-luna:medium --no-tools --no-session -p "..."
```

Catalog facts for `gpt-5.6-luna` (from the host's own `models-store.json`): context 272,000, max output 128,000, $0.20/$1.20 per Mtok, cache read $0.02 (0.1×), cache write $0.25 (1.25×), doubling tier above 272k. Authenticated providers on the host are `openai-codex` (OAuth), `openrouter` (key) and `gemini` (key).

Open: whether to pin the direct `openai-codex` route or `openrouter`, which reaches the same models with a 1.05M context window. That choice also determines the API surface and which usage fields exist for cache verification — see `docs/10` §10.3. `config/session-manifest.example.yaml` keeps its placeholders; the resolved values belong in a profile-specific copy, with an **exact** ID and never an alias.

## Archive

`docs/archive/` holds frozen predecessor material — provenance only, never authority, never edited, excluded from lint and the JSON check. Pruned to 916K: `setup-draft/` was removed after verifying it byte-identical to the initial commit `2e87052` (recoverable with `git show 2e87052:<path>`; its review is already migrated to `docs/reviews/`), as were the raw GCP quota CSVs and SSSF's bundled visualizer app. If something in the archive still matters, restate it in an authoritative document rather than citing it.

## Verify the repository

```bash
cd /home/sntx/RND/harness
bash scripts/validate-bundle.sh                                    # expect exit 0
npx --yes markdownlint-cli2                                        # expect 0 issues
```

Then close V0.0 (tagging is approved):

```bash
git checkout develop && git merge --no-ff feature/v0.0-closeout-and-cache-discipline
git checkout main && git merge --no-ff develop
git tag -a v0.0 -m "V0.0 — canonical repo and tracking"
git push origin main develop --tags
git checkout develop
```

## V0.1 — what remains

`tasks/V0.1-baseline-harness.md`, plan stages 0–2.

- **T1 (stage 0 layout)** — partially done on the server as recorded above; blocked on the package set and the remaining Phase 0 steps.
- **T2 (pin upstream Pi)** — largely answered: 0.83.0 is installed and running. Still to record: install method and rollback metadata, and the provider/route decision above.
- **T4 (verify three package pins)** — not started, needs web access. For each, produce inspection notes or a rejection plus a named alternative:

| Package | Gates | Must verify |
| --- | --- | --- |
| `@gotgenes/pi-permission-system` | T5 | **Blocker (R-001):** whether configuration can be re-read or hot-reloaded mid-session. Our invariant is parse-once at `session_start`, hashed into the manifest. If upstream cannot guarantee it, the fallback is a pinned patch or launcher guard that fails closed |
| `pi-interactive-shell` | T6 | PTY behavior for sudo and secret entry — the password must be typed directly and never captured or echoed into transcript or logs (R-005/R-006). Also whether any path bypasses the permission alias |
| `@juicesharp/rpiv-ask-user-question` | T6 | Question schema against `schemas/UserQuestionV1.schema.json`; whether an adapter is needed to map its payload into ours |

Also record per pin: release date and activity, license, whether install runs scripts (prefer `--ignore-scripts`), and the behaviors we depend on — installing a package is installing executable code (`docs/01`, extension trust rule).

## Environment notes

- Workstation repo `/home/sntx/RND/harness`; frozen predecessor bundle in `/home/sntx/RND/archive` (read-only reference).
- Workstation has `jq`, `python3`, `node v24`, `npx`; no `rg`/`fd` — scripts are kept dependency-light rather than requiring them.
- Remote is a private GitHub repository; `main` and `develop` pushed. The harness repo is **not** cloned on the server.
- No CI. The verification commands above are run by hand; the first real gate is the cache regression test (V0.3-T9).

## Reading order for a fresh session

`CLAUDE.md` → `docs/00-documentation-index.md` → `docs/02-architecture-decisions.md` → `ROADMAP.md` → the current task file. Add `docs/10` before touching prompt assembly, tool registration, retrieval or history; `docs/07` before anything on the server; `docs/08`/`09` before personas, missions or topology.
