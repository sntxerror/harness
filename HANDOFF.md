# Handoff — start here

Updated: 7 August 2026. Replace this file's contents at the end of each working session; it describes current state only, not history (history is `CHANGELOG.md` and git).

## The rule that governs how you work here

**Ask before implementing any decision recorded in `docs/` (ADR-036).** The documents are authority over *what was decided*, never permission to do it now. Present the decision, where it is recorded, what it commits us to and what it rules out — then wait. Approval is per decision and does not carry to the next phase or a later re-run. Runbook command blocks are reviewed content, not scripts to run on sight. Full statement in `CLAUDE.md`.

## Branches — `develop` moved on 7 August 2026

The replan branch **is** `develop` now. `develop` was fast-forwarded from `54112fe` to `b2615f2` (no force; the old tip was a strict ancestor), and the previous tip is preserved and pushed as **`archive/develop-pre-replan`**. `feature/replan-execution-layer-first` still exists at the same commit and is now redundant. `main` is unchanged at `v0.0`.

## The plan was re-sequenced on 7 August 2026

The roadmap follows a two-layer split (ADR-040). The **execution layer** — everything that makes one task run well on one local machine — is V0.1 through V0.6 and is built, used and measured before any **agentic layer** component starts. Remote hosting moved behind the switch because it adds no capability; delegation and foreign CLI workers moved forward because they add most of what parity means.

Three documents carry it: `docs/11` (the layer line, the parity matrix, the measured switch gate), `docs/12` (Claude Code / Codex / Antigravity control surfaces, compiled provider profiles) and `docs/reviews/2026-08-07-open-decisions-dossier.md` (the open decisions, with D1, D2, D5 and D6 now struck through).

**V0.4 is not "the switch point".** It is where self-hosting starts. The switch is a measured gate at V0.6 — a capability matrix plus a ten-day dual run against VS Code and Claude Code, declared per workload class and reversible (ADR-041). That gate **stays**: it evaluates our tooling against the tool it replaces, which is the one kind of comparison this project still runs (ADR-047).

## Four decisions were settled on 7 August 2026

**ADR-046 — the parent runs `openai-codex/gpt-5.6-luna`, thinking `medium`.** The direct ChatGPT OAuth route, pinned to an exact ID. It was chosen *against* price and context window: OpenRouter reaches the same model at half the price with 1.05M context against 272k. The deciding fact is that all six `openai-codex` models declare `compat.supportsToolSearch` and `supportsOpenAIGrammarTools`, and none of OpenRouter's 273 declares either — tool search is Pi's deferred-tool-loading mechanism, so the cheaper route would permanently fix the parent's tool surface for each epoch. OpenRouter stays authenticated for scouting queries only, at the exact dated ID `deepseek/deepseek-v4-flash-0731` (never the `~…-latest` alias, never the rolling `deepseek/deepseek-v4-flash` pointer).

The parent runs the *cheap* tier deliberately. The case for a strong parent — its envelopes are checked by no gate — is answered by keeping the parent's job small and routing quality-bearing phases to profiled workers where a gate does check them.

**This pin has a reopening condition, and it is the most important thing to carry forward.** `supportsToolSearch` was read from Pi **0.80.10**'s catalog, four minors behind what we intend to run. V0.1-T2 must re-read it on the upgraded catalog for both routes. If 0.84.x declares tool search for OpenRouter, ADR-046 is reopened rather than defended (R-105).

**ADR-047 — we evaluate our tooling, never models.** No benchmarking, ranking or comparative evaluation of language models. Pins are chosen once against a stated property and revised when that property changes. This removed the D2 settling test and the continuity benchmark that gated a separate compaction model — so there is no separate compaction model; compaction runs on the parent's pinned model. What stays measured: the cache regression gate, prefix and token budgets, the V0.6 parity gate, and tool-integration A/Bs where two components would otherwise do one job.

**ADR-048 — no RAG in the coding harness.** No local index, no local embedding model, no `knowledge_search`/`knowledge_get`. Project knowledge becomes a remote-tier service at V0.7. Until then the harness reads `docs/` directly, which a ~5,500-line corpus inside the working repository makes correct. V0.2-T4 was **removed, not deferred in place**; plan Stage 4 is now scheduled at V0.7. The reopening trigger is stated in advance (R-107): a routine question needing more than three file reads, or `docs/` passing ~15,000 lines.

## Where the project stands

**V0.0 is closed and tagged.** **V0.1 is the current version. T1 and T4 are done; T2, T3, T5–T8 remain.**

## V0.1-T1 is done — and it corrected the record

The `~/.pi` backup is `docs/archive/pi-workstation-backup-2026-08-07.tar.gz` (7.0M), verified to restore: 1589 files, `diff -r` clean. It covers the configuration tree and excludes both `auth.json` files and `agent/sessions/`; the extracted archive was swept for credential-shaped strings and returned none. A tarball rather than a copied tree because `.gitignore` excludes `*.sqlite` and `*.db` and `validate-bundle.sh` rejects symlinks anywhere in the bundle.

**Act on this: there is an OpenRouter API key in a session transcript.** The first archive built for T1 included `agent/sessions/`, and the pre-commit sweep found one 73-character `sk-or-v1-` + 64-hex string in `2026-07-10T17-19-36-950Z_019f4d0a…jsonl`. It is *not* the key now in `auth.json`, so it is a previously-used one that a conversation echoed into its own transcript. It was never committed. Two consequences: that key should be rotated at OpenRouter if it is still valid, and **excluding `auth.json` is not sufficient to make a `~/.pi` backup safe** — transcripts are credential-bearing and nothing in the tree marks them so. Sweep before staging, every time.

`~/.pi/profiles/trusted` exists and is empty. `scripts/pi-trusted.sh` selects it via `PI_CODING_AGENT_DIR` and carries the ADR-046 pin. It does **not** compile a `SessionManifestV1`: the hashes that manifest needs do not exist until T3 and T5, and a manifest of empty hashes is a check that always passes (R-057). The gap is marked in the script.

**The recorded `rg` finding was wrong, twice.** There is no system ripgrep on this workstation — no binary, no package, no shell function, nothing in any rc file. Pi vendors its own `ripgrep 15.1.0` and `fd 10.4.2` into `$PI_CODING_AGENT_DIR/bin/` and calls them by path. So `rg` exists for Pi, does not exist for anything Pi spawns, and does not exist in a profile root Pi has not populated — the divergence is live today between `~/.pi/agent` and the trusted root T1 just created.

That is a sharper case than the login-shell story it replaces, and it is recorded as **R-106**: two profiles on one machine can disagree about whether a command exists, with no shell involved. V0.3-T2's preflight must resolve commands per profile root. `scripts/executor-inventory.sh` is the reference implementation and probes three views — login shell, executor, and each profile's vendored `bin/`.

T1's acceptance criterion changed in the same commit: "representative task metrics" was removed, because producing one needs Pi installed in the profile (T3) and a reachable model. It was never satisfiable at Stage 0. The baseline transcript belongs with T3.

## Workstation state, verified 7 August 2026

- **Pi 0.80.10** at `~/.config/nvm/versions/node/v24.18.0/bin/pi`, against **0.84.1** upstream. T2 is an upgrade decision across four minors.
- **Provider logins:** `openai-codex` (OAuth, token to 12 August, refreshable), `openrouter` (API key), `gemini` (key). Both routes were live here — the earlier note implying OpenRouter only was wrong, so D1 was never constrained by authentication.
- Pi's own default is still `openrouter` / **`openrouter/free`**, which is a *router* ("Free Models Router", 200k, $0) that picks a different backing model per request. It is incompatible with a frozen prefix by construction and must change when T3 configures the profile.
- `~/.pi/agent` carries `npm:pi-interactive-shell`, unpinned. The trusted profile carries nothing — that is the distinct-extension-set evidence.
- `node` v24.18.0, `npm` 11.16.0, `git` 2.53.0, `jq` 1.8.1, `tmux`, `docker` resolve in the executor. `ast-grep`, `codegraph`, `podman` absent.
- **All three foreign CLIs installed**: `claude` 2.1.210, `codex-cli` 0.145.0, `agy` 1.1.4. V0.5 needs no provisioning; the V0.6 parity comparison is directly runnable.
- Repo at `/home/sntx/RND/harness`. There is **no** `/home/sntx/RND/archive` — an earlier note claiming a frozen bundle there was stale; the only archive is `docs/archive/` inside the repository.
- No CI. Both gates are run by hand and were clean at the last commit.

## Remote server — paused until V0.7

Host `62.238.51.68`, Ubuntu 26.04, key-based SSH as `sntx`; full survey in `docs/07` §"Current host". `piops` (uid 1001, no sudo) and `/srv/pi-agent` exist; the package set, service-user directories, linger and sshd hardening do not, and each needs its own approval. Pi 0.83.0 is installed there under `sntx`.

**One server item does not wait:** `/etc/sudoers.d/90-sntx-nopasswd` is still active and its removal is a **V0.1 exit condition** (ADR-038, R-090) — a time-boxed privilege outliving its phase is the failure that rule exists to prevent.

## What remains in V0.1

`tasks/V0.1-baseline-harness.md`, plan stages 0–2.

- **T2 (pin upstream Pi)** — next. An upgrade decision 0.80.10 → 0.84.x with rollback metadata, **plus** the ADR-046 re-read described above.
- **T3 (install Pi into the profile roots)** — depends on T2.
- **T5–T8** — permission system, PTY, structured questions, privileged-command channel.
- **D3** (`UserQuestionV1` adapter placement) and **D4** (whether `@juicesharp/rpiv-config` and `rpiv-i18n` are accepted uninspected) are still open. D4 is two tarball reads on the V0.1-T4 terms and is cheaper to settle than to decide — it was not reached this session.

## Still-open defects

`docs/02` has ADR-028 and ADR-029 each appearing twice, and the prose after ADR-036 belongs to a factory/workflow ADR. Recorded as D19 with three costed options; untouched.

## Verify the repository

```bash
cd /home/sntx/RND/harness
bash scripts/validate-bundle.sh                                    # expect exit 0
npx --yes markdownlint-cli2                                        # expect 0 issues
```

## Reading order for a fresh session

`CLAUDE.md` → `docs/11-execution-and-agentic-layers.md` → `docs/00-documentation-index.md` → `docs/02-architecture-decisions.md` → `ROADMAP.md` → the current task file. `docs/11` comes early on purpose: every other document describes the whole design and is easy to mistake for a work queue.

Add `docs/10` before touching prompt assembly, tool registration, retrieval or history; `docs/12` before anything involving Claude Code, Codex or Antigravity as workers; the open-decisions dossier before proposing a decision that may already be costed there; `docs/07` before anything on the server; `docs/08`/`09` before personas, missions or topology.
