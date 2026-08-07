# Bundle Changelog

## 7 August 2026 (native structured questions)

- Added ADR-049: `ask_user_question` is implemented natively, ~470 lines on Pi's `ui.select()` and
  `ui.input()`, replacing `@juicesharp/rpiv-ask-user-question`. Not a rejection on trust — all three
  RPIV tarballs were read (nothing installed or executed) and all three are clean; `rpiv-i18n` is a
  soft optional peer that never needed accepting. Replaced because T4 established the `credential`
  refusal can only live in our code, so an adapter was required either way and cost more than the
  implementation. Upstream's own 166-line `rpc-fallback.ts` proves the budget.
- Typebox is retained and pinned to Pi's resolved version (1.1.38): Pi depends on it directly and
  every built-in declares parameters with `Type.Object` + `Static<typeof schema>`.
- Closes D3 by dissolving it (no adapter exists) and D4 by inspection. **No V0.1 decisions remain
  open.** Added R-109 (we now track Pi's dialog primitives ourselves) and R-110 (a typebox version
  split would change the tool schema, and the prefix hash, silently).
- Accepted losses recorded rather than disputed: no preview pane, no tabbed multi-question review,
  multi-select by comma-separated indices.

## 7 August 2026 (provider pin, evaluation policy, retrieval deferral, V0.1-T1)

- Added ADR-046: the parent runs the direct `openai-codex` OAuth route pinned to `gpt-5.6-luna`
  at thinking `medium`, with OpenRouter retained for scouting only at `deepseek/deepseek-v4-flash-0731`.
  Chosen *against* price and window — OpenRouter is half the price with 1.05M context against 272k —
  because all six `openai-codex` models declare `compat.supportsToolSearch` and none of OpenRouter's
  273 does, and deferred tool loading is the one property that cannot be bought back by configuration.
  Settles D1 and D2. Rejected a stronger parent: quality-bearing phases route to gated workers.
- Added ADR-047: we evaluate our tooling, never models. Removed the D2 settling test and the
  continuity benchmark gating a separate compaction model — so compaction runs on the parent's pinned
  model. The V0.6 parity gate stays; it measures our harness against the tool it replaces.
- Added ADR-048: no RAG, no index and no local embedding model in the coding harness. Project
  knowledge becomes a remote-tier service at V0.7 and plan Stage 4 moves with it; the harness reads
  `docs/` directly. Settles D6. **Removed V0.2-T4** rather than deferring it in place.
- Added R-105 (the pin's justification was read from a stale catalog and V0.1-T2 must re-read it),
  R-106 (Pi vendors `rg`/`fd` per profile root, so two profiles can disagree about whether a command
  exists), R-107 (the "just read the files" argument expires silently) and R-108 (a forbidden
  evaluation means nobody watches for a pin's stated reason expiring). Closed R-019; deferred R-028.
- **Completed V0.1-T1.** Backed up `~/.pi` to `docs/archive/pi-workstation-backup-2026-08-07.tar.gz`
  excluding both `auth.json` files and `agent/sessions/`, verified restorable at 1589 files with
  `diff -r` clean and swept clean of credential-shaped strings; created `~/.pi/profiles/trusted` and
  `scripts/pi-trusted.sh`; added `scripts/executor-inventory.sh`.
- **Found an OpenRouter API key inside a session transcript** while sweeping the first archive before
  staging it — `sk-or-v1-` + 64 hex, not the key currently in `auth.json`. Never committed; the
  archive was rebuilt without `agent/sessions/`. Recorded because it establishes that excluding
  `auth.json` does not make a `~/.pi` backup safe: transcripts are credential-bearing.
- **Corrected a fact recorded in two documents:** there is no system ripgrep on the workstation and
  `rg` was never a shell function. Pi vendors `ripgrep 15.1.0` and `fd 10.4.2` into the profile's
  `bin/` and calls them by path. Also corrected: the workstation is authenticated to both provider
  routes, not OpenRouter alone, and `/home/sntx/RND/archive` does not exist.
- **Changed V0.1-T1's acceptance criterion in the same commit:** dropped "representative task
  metrics", which needs Pi installed in the profile and a reachable model and was never satisfiable
  at Stage 0; added the vendored-`bin/` clause, which T1 demonstrated.
- `develop` fast-forwarded to the replan branch; previous tip preserved as `archive/develop-pre-replan`.

## 7 August 2026 (two-layer re-sequencing and the switch gate)

- Added ADR-040: the system has an execution layer and an agentic layer, and the execution layer is
  completed, used and measured before any agentic component starts. Settled the two boundary cases —
  a foreign CLI worker executing one phase is delegation, not orchestration; and remote is a
  deployment property, not a capability.
- Added ADR-041: the move off VS Code plus Claude Code is a measured parity gate at V0.6, declared
  per workload class and reversible — not the moment the system can first commit its own changes.
  Rejected declaring the switch from impression rather than from run records.
- Added ADR-042/043: foreign CLI harnesses are execution-layer workers with compiled provider
  profiles (`recon`, `sweep`, `implement`, `implement-hard`, `review`, `typed`) and cheap-but-capable
  defaults, steered onto our capability surface by registry-generated MCP exports, tool removal,
  prompt addenda and hook enforcement — with the prefix measured on every launch, never assumed.
- Added ADR-044: control-channel preference for foreign workers is structured headless output, then
  ACP, then PTY. Codex's `codex exec --json --output-schema` supplies the typed-envelope contract
  directly and becomes the reference adapter; `AcpAdapter` loses its "later" marking.
- Added `docs/11-execution-and-agentic-layers.md` and `docs/12-foreign-cli-workers.md`.
- **Found three parity gaps the plan assigned to nobody:** web search and fetch, image input, and
  editor integration — all used daily in the current environment (R-097, R-098, decisions D10–D12).
- Added the open-decisions dossier: nineteen entries with evidence resolved 7 August 2026, costed
  options and the single observation that would settle each, ordered by the version it blocks.
- Re-sequenced the roadmap: remote services V0.5 → V0.7, delegation and foreign workers V0.6 → V0.5,
  portability and the parity gate → V0.6, mission control → V0.8, interfaces → V0.9. Rewrote the
  task files; no checked box moved.
- Added ADR-045, resolving the CodeGraph contradiction: the engine shares one background server and
  one watcher across sessions over a local socket, so duplicate indexes and watchers are caused by a
  second *engine*, never by a second *consumer*. The blanket "never expose CodeGraph through MCP"
  rule is replaced by three invariants — one index and one daemon per repository, one graph surface
  per session, one authority for graph questions — and graph access becomes a declared profile
  grant, so a foreign worker whose phase needs architecture receives the MCP server exactly as the
  plan already permitted for the Pi Lens mirror. Rejected restricting the graph to Pi processes.
- Recorded what that clarified: a foreign CLI is worth spawning for the vendor's *harness*, not its
  model, since a native Pi child can already be routed to another vendor's model by `modelClass` and
  keeps the full capability surface with no vendor prefix (`12` §4.1).
- Left one measured sub-choice open at V0.2 (V0.2-T7): the bridge's eight named graph tools against
  the engine's single `codegraph_explore` — eight schemas in the frozen prefix against one.
- Added R-093 to R-104, covering Claude Code's unenforceable MCP tool restriction under `-p` and its
  irreducible ~33k-token prefix, Antigravity's non-TTY hang, the subscription-automation boundary,
  the two parity gaps, gate-by-impression, foreign-worker concurrency cost, provider CLI drift and
  the risk that deferring isolation becomes permanent omission.

## 7 August 2026 (pin policy)

- Added ADR-039: packages resolve to their latest published version at install or refresh. A version
  in a document is evidence of a past resolution, never a target — the exact *resolved* version and
  hash are what get recorded, because the cache epoch and `SessionCompatibilityV1` are computed over
  them. Rejected genuinely floating ranges, which would make the manifest hash unreproducible.
- Re-resolved every pin carried in `docs/` on 7 August 2026: permission-system 20.9.1 → 24.0.0,
  interactive-shell 0.13.0 → 0.14.0, subagents 18.1.0 → 19.2.1, pi-lens 3.8.71 → 3.8.74, pi-sandbox
  0.5.0 → 0.6.2. Confirmed already-latest: subagents-worktrees 0.2.3, pi-container-sandbox 0.2.2,
  vmpi 0.4.1, @nqbao/pi-sandbox 0.1.3, pi-handoff-agent 0.2.0, rpiv-ask-user-question 2.4.0.
- Amended the pin rule in `CLAUDE.md` and rewrote R-050's mitigation; added R-092 (a version read as
  a decision rather than as evidence).

## 7 August 2026 (privileged-command channel)

- Added ADR-037: privileged commands have exactly one channel — `interactive_shell` in
  `mode: "interactive"`, the only blocking mode, where the focused overlay writes keystrokes
  straight to the PTY and the model's turn is suspended for the session's life.
- Added ADR-038: the harness account's sudo is time-boxed to Phase 0 and revoked as a V0.1 exit
  condition; `piops` never receives it. Permissions are intent control, containment is the boundary.
- **Corrected the T4 review §3.2.** `interactive_shell` does *not* escape command-level gating: the
  permission system's `shellTools` config maps its `command` onto the full bash enforcement stack,
  and `docs/01` §2.1 already specified the entry. The gating half is configuration, not code.
- Recorded what survives that correction: `mode` is model-supplied with no allowlist, and a call
  carrying only `sessionId` and `input` presents an empty command that matches `"*": "allow"` — so
  privilege classification must be sticky to the session, not evaluated per call.
- Added R-085 (silent alias degradation), R-086 (mode not enforced), R-087 (backgrounded sessions
  stay writable), R-088 (`yoloMode` reachable mid-session), R-089 (un-redacted handoff snapshots),
  R-090 (time-boxed sudo never revoked) and R-091 (empty-command injection).
- Added V0.1-T8 for the channel itself and extended T7's battery with its four probes.

## 6 August 2026 (V0.0 tagged; V0.1-T4 pin inspection)

- Closed and tagged `v0.0`: the closeout branch merged through `develop` to `main`, both gates clean.
- Added `docs/reviews/2026-08-06-v0.1-t4-package-pin-inspection.md` and checked V0.1-T4. All three
  pins accepted with conditions, read from published tarballs without installing or executing them.
- Recorded the R-001 answer: the permission system has no filesystem watcher, so on-disk edits are
  inert, but `/reload` (`resources_discover`) and the `/permission-system` config modal both mutate
  policy mid-session — the modal including `yoloMode`, which auto-approves every ask-state check.
  Parse-once cannot come from upstream; a launcher guard or pinned patch is required.
- Recorded that `pi-interactive-shell` has no secret-awareness of any kind and no permission-system
  integration: `sudo` is safe only because `sudo` disables echo, and the `interactive_shell` tool's
  free-form `command` receives neither the `bash` token gates nor automatic path extraction.
- Recorded the `UserQuestionV1` gap: upstream is a synchronous 1–4 question batch with no
  `sensitivity`, `status` or deadline concept, so an adapter is required and owns the rule that a
  `credential` question is never routed through a questionnaire that echoes typed text.

## 5 August 2026 (archive import and pruning)

- Imported the predecessor material as `docs/archive/`: frozen, non-authoritative provenance, excluded from lint and the JSON check so it can never fail current gates. Nested git history in the vendored SSSF clone was removed and its files are tracked as plain content.
- Pruned what carried no reference value: `setup-draft/` (verified byte-identical to the initial commit except the already-migrated review and the archive banner), the raw GCP quota CSVs (the readable `gcp-audit.md` is kept), and SSSF's bundled visualizer app (its `SKILL.md`, cookbooks and references are kept — that is what `05` compares against). Archive 14M → 916K.

## 5 August 2026 (governance and host survey)

- Added ADR-036: documented decisions are authority over content, not authorization to act. Agent sessions obtain explicit operator approval per architecture decision before implementing it; runbook command blocks are reviewed content, not scripts to run on sight. Reflected in `CLAUDE.md`, `docs/00` change discipline and the runbook header.
- Surveyed the remote host and recorded actual facts plus four divergences from the runbook's assumptions in `07` (single sudo-capable account rather than an operator/service split, Ubuntu 26.04, nvm-hidden node/Pi in non-interactive shells, no container runtime).
- Added `10` §10: provider calibration for the current pin — measured cost/context data from the host's model catalog, the explicit-versus-automatic cache-write distinction across model families, and the list of mechanics that are not yet established for this API surface.

## 5 August 2026 (V0.0 closeout)

- Closed V0.0: markdown lint clean; `validate-bundle.sh` repaired (dropped the hard `rg` dependency, prunes `.git`, now asserts docs 00–10, all five schemas and a task file per roadmap version); placeholder resolution checklist recorded per template.
- Added `10-context-and-cache-discipline.md`: request zones, breakpoint placement, append-only mutation channels, silent-invalidator audit, cache economics and per-version obligations — the mechanism implementing ADR-007.
- Added ADR-034 (append-only mid-session change; no prefix edits) and ADR-035 (cache conformance as a hash-verified CI gate).
- Added R-082 (breakpoint lookback starvation), R-083 (fan-out cache stampede) and R-084 (unimplemented cache verification).
- Tracked the new obligations as V0.3-T8/T9/T10 and V0.4-T9/T10.
- Added `CLAUDE.md` (repository working conventions) and `HANDOFF.md` (current state and next actions).

## 5 August 2026 (evening revision)

- Added `08-persona-mission-control.md`: personas as top-level profiles, missions, capability assignment pipeline, multi-scope memory, leases, statechart lifecycles and the observability event contract.
- Added `09-topology-and-clients.md`: one control plane with registered runners and stateless clients, placement policy, boundary-only session transfer, forge/IDE/web-UI viewing layers and the edge-only A2A stance.
- Added ADR-028 through ADR-033 and risks R-073 through R-081.
- Integrated the MCP/skills review: measured token-cost exit conditions for Stages 4 and 11, skill authoring budgets and scope precedence, `directTools` epoch rule and the named MCP-gateway fallback class.
- Declared `self-dev` the first persona; self-development begins at factory-core stage via gitflow and the candidate pipeline.

## 5 August 2026

- Consolidated the researched Pi architecture, implementation plan, risks and experiment history.
- Added the deterministic `pi-factory` closed-loop design and SSSF comparison.
- Added `PortableSessionBundleV1` and the local-readable-record portability decision.
- Split Hermes into the narrow `Hermes Memory Service` and later full `Hermes Coordinator`.
- Added a gradual remote-server runbook from vanilla SSH Pi through isolated workers and IM coordination.
- Added permission, interactive shell, profile, router, project-check, session-manifest and systemd templates.
- Added initial schemas for profiles, task envelopes, project checks, user questions and portable session manifests.
- Added read-only preflight and bundle validation scripts.
