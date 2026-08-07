# Handoff — start here

Updated: 7 August 2026. Replace this file's contents at the end of each working session; it describes current state only, not history (history is `CHANGELOG.md` and git).

## The rule that governs how you work here

**Ask before implementing any decision recorded in `docs/` (ADR-036).** The documents are authority over *what was decided*, never permission to do it now. Present the decision, where it is recorded, what it commits us to and what it rules out — then wait. Approval is per decision and does not carry to the next phase or a later re-run. Runbook command blocks are reviewed content, not scripts to run on sight. Full statement in `CLAUDE.md`.

## Where the project stands

**V0.0 is closed and tagged.** The closeout branch merged through `develop` to `main`; `v0.0` is tagged and `main`, `develop` and the tag are pushed. Both gates were clean before and after.

**V0.1 (baseline interactive harness) is the current version.** T4 is done; T1 and T2 are partially done on the server. Branch `feature/V0.1-T4-package-pin-inspection` holds the T4 review and is **committed locally but not pushed and not merged** — V0.1 has open boxes, so nothing merges yet.

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

Pi itself: **0.83.0** at `~/.nvm/versions/node/v24.19.0/bin/pi`, under the `sntx` account. Nothing is installed for `piops` yet. Upstream is **0.84.1** as of 7 August, so the host is one minor behind; under ADR-039 the refresh is expected, but it changes the machine and therefore needs approval before anyone runs it.

## Pin policy (ADR-039, decided 7 August)

Packages take their latest published version at install or refresh. A version in a document records what was resolved on a date — it is evidence, not a target, and a stale number is never a reason to install an older release. Every pin in `docs/` was re-resolved on 7 August 2026; the notable moves were permission-system 20.9.1 → **24.0.0**, interactive-shell 0.13.0 → **0.14.0**, subagents 18.1.0 → **19.2.1**, pi-sandbox 0.5.0 → **0.6.2**, pi-lens 3.8.71 → **3.8.74**. Six others were already latest.

What stays exact is the *resolved* version and hash, recorded into the lockfile and manifest: the cache epoch and `SessionCompatibilityV1` are computed over package identity, so a version that changes underneath a live profile invalidates both silently. Refresh is a dated act that re-runs the smoke suite, not a background process, and for policy-carrying packages it re-reads the behaviours we depend on — a major can move them without breaking a signature (R-050, R-092).

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

## V0.1 — what remains

`tasks/V0.1-baseline-harness.md`, plan stages 0–2.

- **T1 (stage 0 layout)** — partially done on the server as recorded above; blocked on the package set and the remaining Phase 0 steps.
- **T2 (pin upstream Pi)** — largely answered: 0.83.0 is installed and running. Still to record: install method and rollback metadata, and the provider/route decision above.
- **T4 (verify three package pins)** — **done.** `docs/reviews/2026-08-06-v0.1-t4-package-pin-inspection.md`. All three pins accepted with conditions, read from published tarballs without installing or executing them; exact versions and tarball hashes are in §1 of the review.

What T4 settled, because T5 and T6 now depend on it:

- **R-001 cannot be satisfied upstream.** The permission system has no filesystem watcher, so on-disk edits are inert mid-session — but `/reload` (`resources_discover`) and the `/permission-system` config modal are two explicit mutation paths, the modal including `yoloMode`, which auto-approves every ask-state check including subagent forwarding. A launcher guard is the cheaper fallback because the surface is two registrations rather than a watcher.
- **`pi-interactive-shell` has no secret-awareness of any kind.** `sudo` is safe only because `sudo` suppresses echo. Keep `handoffSnapshotEnabled` off — it writes un-redacted terminal tails to `~/.pi/cache/interactive-shell/` (R-089).
- **An adapter is required for `UserQuestionV1`.** Upstream is a synchronous 1–4 question batch with no `sensitivity`, `status` or deadline; the rule that a `credential` question never goes to a questionnaire that echoes typed text can only live in our adapter.

## The privileged-command channel (ADR-037/038, decided 7 August)

`interactive` is one of four modes and the only **blocking** one — `hands-free`, `dispatch` and `monitor` all return a `sessionId` immediately and let the model inject keystrokes and poll output. In interactive mode the model's turn is suspended for the session's life and the focused overlay writes straight to the PTY, so privileged commands run there and nowhere else. Headless sessions have no privileged channel at all: the tool requires a TUI and errors without one.

The T4 review's §3.2 claim that `interactive_shell` escapes command-level gating was **wrong and is corrected in place.** The permission system's `shellTools` config maps the tool's `command` onto the full bash enforcement stack, and `docs/01` §2.1 already carried the exact entry. Gating is configuration; the only code we own is the mode rule and sticky per-session classification — needed because a call carrying only `sessionId` and `input` presents an *empty* command to the gate and matches `"*": "allow"` (R-091), and because Ctrl+B leaves a session addressable after the blocking call returns (R-087).

Sudo stays for Phase 0, confined to that channel, and is revoked as a **V0.1 exit condition** (ADR-038, R-090). `piops` never receives it. This is intent control, not containment — the container boundary is still the security boundary (R-008).

New work: **V0.1-T8** builds the channel; T7's battery gains its four probes.

**Two decisions remain open (ADR-036):** adapter placement for `UserQuestionV1` and whether `description`/`preview` extend the schema; and whether `@juicesharp/rpiv-config` and `@juicesharp/rpiv-i18n` are accepted uninspected. The pin question that stood here is settled by ADR-039 above.

Two pre-existing defects in `docs/02` are flagged but untouched: ADR-028 and ADR-029 each appear twice (lines 245/253 and 337/353), and the prose following ADR-036 belongs to a factory/workflow ADR rather than to ADR-036. Renumbering would break cross-references.

## Environment notes

- Workstation repo `/home/sntx/RND/harness`; frozen predecessor bundle in `/home/sntx/RND/archive` (read-only reference).
- Workstation has `jq`, `python3`, `node v24`, `npx`; no `rg`/`fd` — scripts are kept dependency-light rather than requiring them.
- Remote is a private GitHub repository; `main` and `develop` pushed. The harness repo is **not** cloned on the server.
- No CI. The verification commands above are run by hand; the first real gate is the cache regression test (V0.3-T9).

## Reading order for a fresh session

`CLAUDE.md` → `docs/00-documentation-index.md` → `docs/02-architecture-decisions.md` → `ROADMAP.md` → the current task file. Add `docs/10` before touching prompt assembly, tool registration, retrieval or history; `docs/07` before anything on the server; `docs/08`/`09` before personas, missions or topology.
