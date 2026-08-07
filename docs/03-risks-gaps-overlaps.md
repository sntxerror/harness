# Ultimate Pi Setup — Risks, Gaps, Overlaps and Open Questions

Revision: 5 August 2026

Status: working risk register. The authoritative implementation sequence is in `ultimate-pi-setup-plan.md`; accepted architectural choices are in `ultimate-pi-architecture-decisions.md`.

This document records uncertainty instead of quietly converting it into design. A risk is closed only by a reproducible test, source inspection, or an explicit accepted trade-off.

## Severity and promotion rules

- **Blocker:** resolve before the named stage can become the daily driver.
- **High:** a failure can defeat containment, corrupt code/history, expose secrets, or make the model operate under false capabilities.
- **Medium:** likely reliability, cost, or usability problem with a bounded fallback.
- **Low:** inconvenience or maintenance debt that can be deferred.
- A package README is evidence of intent, not evidence that its lifecycle, failure behavior, or current Pi compatibility works.
- Any automatic mutation, context injection, memory write, or policy reload begins disabled and is promoted only from recorded trials.

## Risk register

### Control plane, permissions and containment

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-001 | Blocker before Stage 2 | Permission policy may be refreshed or re-read during a session | The model's effective command policy changes after the cache/capability snapshot | Patch or wrap permission-system so configuration is parsed once at `session_start`; hash it in the session manifest; integration-test that file edits and reload attempts have no effect until a new session |
| R-002 | Blocker before Stage 2.6 | A public Pi extension may not be able to veto every model, provider, system-prompt or active-tool mutation | Cache invariants could be advisory rather than enforced | Inspect the exact Pi SDK version; use supported lifecycle vetoes where available; otherwise put the guard in a small pinned Pi patch or launcher boundary and fail closed on unsupported mutations |
| R-003 | High | Command-head analysis is incomplete for `env`, `sudo`, shells, aliases, wrappers, scripts and dynamic expansion | Profiles can advertise commands that do not exist, or misclassify dangerous commands | Resolve through the same shell/parser used by permission-system; preflight inside the actual executor with `command -v`; return structured `COMMAND_UNAVAILABLE`; treat unresolved dynamic heads as ask, not deny |
| R-004 | High | The agent may be able to edit its own permissions, profile, hooks, skill manifests or broker configuration | It can indirectly expand future authority or make behavior irreproducible | Keep control-plane files outside repository write scope or mount read-only; compile immutable session snapshots; expose no reload/switch tool; require a new human-started session for policy changes |
| R-005 | High | Broad allow rules can be bypassed by nested shells or opaque wrappers if risk detection only examines the first token | Destructive or privileged actions may run without an ask | Make containment the security boundary; recursively classify known wrappers; prompt for unresolved opaque commands with dangerous arguments; record normalized intent and decision |
| R-006 | High | Sudo password or terminal secrets may leak through PTY capture, scrollback, transcripts or model-visible output | Credential disclosure | User types directly into a focused PTY; never use `sudo -S`; pause model output capture during secret entry; cap/expire scrollback; never place raw PTY logs in traces or memory |
| R-007 | High | Gondolin examples may use read-write mounts or omit the needed network/process restrictions | A profile described as isolated may still reach host data or network | Maintain an audited profile with explicit mounts, network policy and external-binary list; test escape paths and extension subprocesses; label it isolated only after tests pass |
| R-008 | High | A Pi-native extension process can execute on the host even when built-in Bash is guest-contained | LSP, graph, MCP or PTY tools bypass the apparent sandbox | For untrusted work, run the whole Pi process in containment or run the service in the guest; otherwise use a narrow read-only broker or disable the extension |
| R-009 | High | Repo-relative brokers can still be vulnerable to `..`, symlinks, alternate worktrees or path races | Read/write escape from the intended repository | Canonicalize after symlink resolution, bind to repository/worktree identity, reject paths outside the root, open with safe flags where possible, and fuzz-test path handling |

### Code intelligence and editing

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-010 | Blocker before Stage 3 daily use | Pi Lens exposes a broad default tool surface overlapping CodeGraph and `ast-grep`; defaults may inject context or perform formatting/fixes | Duplicate schemas, cache/context noise and competing mutation owners | Pin Pi Lens; disable context injection, format and autofix; compile the initial active tool set before the first request; ensure its loader cannot activate forbidden graph/AST-write tools |
| R-011 | Medium | Pi Lens is active but fast-moving and may have language-server, backpressure or formatting regressions | Unstable diagnostics or edits after upgrades | Pin exact version, smoke-test supported languages and upgrade in an evaluation profile; inspect issues and release diffs before promotion |
| R-012 | Medium | CodeGraph host/guest behavior and the exact Pi bridge lifecycle are not fully proven in the isolated profile | Stale index, duplicate watcher, or host path leakage | Validate one index owner and worktree identity; choose guest execution, narrow broker or disable; never start a second graph for convenience |
| R-013 | High | Language servers and project plugins execute repository-controlled code | Opening an untrusted repo can execute code outside Bash policy | Run LSP in the same trust boundary as the repository; disable automatic install/plugin execution; constrain workspace configuration and environment |
| R-014 | Medium | Two edit owners or automatic format/fix hooks can touch the same file | Patch conflicts, unexplained diffs and failed cache/evaluation attribution | Built-in Pi edit/write is authoritative initially; repository formatter runs only through `project_check` or explicit command; all extension autofix/edit hooks remain off |
| R-015 | Medium | Hashline or alternate patch experiments can lose newline/encoding/multi-file semantics | Silent corruption or failed edits | Separate evaluation profile, golden corpus, raw diff verification and one active edit owner; promote only if it beats built-in editing on measured failures |

### Context, cache and compaction

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-016 | High | Provider cache semantics differ; an apparently stable Pi prefix may serialize differently by provider/model | Expected cache hits do not materialize | Hash the normalized final request payload per cache epoch; record provider cache-read/write usage where exposed; do not claim exact savings without traces |
| R-017 | Medium | Dynamic/deferred tool loading is provider-dependent; fallback may resend a changed complete schema list | Activating a tool invalidates the prefix unexpectedly | Prefer a small stable initial set; allow additive activation only when provider behavior is measured; otherwise start a new specialist child/cache island |
| R-018 | Medium | Fixed compaction thresholds are not optimal across context windows and task types | Premature summaries or insufficient output reserve | Select a deterministic policy once at session start from model context window and profile/task class; log it; do not mutate it mid-session; learn only after enough traces |
| R-019 | Closed | A cheaper dedicated compaction model may omit constraints, failures or provenance | Long-session continuity degrades invisibly | Closed by ADR-047: no separate summarization model is used, because justifying one requires a model comparison this project does not run. Compaction stays on the parent's pinned model, where continuity is a property of the model that holds the conversation. Structured fields, provenance and one Pi `CompactionEntry` remain required |
| R-020 | High | Pi's compaction serialization truncates individual tool results to about 2,000 characters | The summary model may see the wrong portion of a long failure or diff | Compact/filter output before it enters conversation history; retain raw output in bounded artifacts and include stable references, exit code, diagnostics and decisive tail/head sections |
| R-021 | Medium | RTK command rewriting may alter semantics or hide data needed for debugging | Incorrect conclusions or unrecoverable evidence loss | Use an explicit interceptor allowlist, structured envelopes and raw-artifact escape hatch; compare raw and compact forms in tests; never combine with LeanCTX rewriting |
| R-022 | Medium | LeanCTX version/configuration and advertised savings may not match the installed integration | More billed input, competing compaction, or duplicate retrieval | Trial only its narrow pre-insertion read/output features in a separate profile; verify exact config keys against the pinned version; disable graph, memory, agents, permissions and compaction |
| R-023 | Medium | Automatic context from any extension can be append-only yet still noisy and unstable | Higher cost and model distraction even if prefix cache remains intact | Target near-zero per-turn injection; require explicit retrieval; record injected byte/token counts separately from tool schemas and system prompt |
| R-024 | Medium | Full raw tool output may be saved in artifacts without retention limits | Disk growth and secret retention | Per-command byte caps, expiry, repo/session namespace, redaction and explicit `/show-raw`; exclude secrets from durable logs and Hermes |

### Retrieval, memory and long-term knowledge

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-025 | High | Project RAG and Hermes can both store the same fact | Contradictory retrieval and unexplained behavior changes | RAG owns authoritative documents/ADRs/notes; Hermes owns reviewed procedures, preferences and episodic outcomes; use typed records, provenance and explicit promotion |
| R-026 | High | Automatic memory capture can preserve transient mistakes, malicious repo text or stale constraints | Memory poisoning across sessions/projects | No automatic promotion; namespace by user/repo/branch/role; candidate → replay/evaluation → human review → versioned promotion; support revoke/export/delete |
| R-027 | High | Shared writable memory/config databases across simultaneous workers create races and cross-task contamination | Non-determinism and accidental context bleed | One versioned memory service/API; immutable reads for workers; candidate submissions only; coordinator resolves conflicts; never share a mutable SQLite file |
| R-028 | Deferred to V0.7 | A local RAG engine has not yet been selected and operational details may dominate quality | Duplicate indexes or brittle retrieval | Removed from the execution layer by ADR-048: no local engine, index or embedding model is selected, so the risk cannot arise before the remote tier. The selection requirements — incremental indexing, provenance, filters, IDs-first retrieval, export/delete, bounded payloads, source code excluded — carry forward to the V0.7 service unchanged |

### Native and foreign subagents

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-029 | High | Native subagent packages may concatenate prompts, inherit cwd/tools, or inject task text in cache-hostile order | Specialist profiles are imprecise and cache islands are ineffective | Compile `AgentProfileV1` first and pass `TaskEnvelopeV1` as the final user message; test exact payload order, cwd, tool list, credentials and policy before relying on a package |
| R-030 | High | Child extensions/skills can inherit parent capabilities unintentionally | A read-only scout receives writes, Bash, credentials or unrelated instructions | Capability compiler emits the complete child snapshot; deny undeclared tools and skills; make `COMMAND_UNAVAILABLE` explicit; do not rely only on prompt instructions |
| R-031 | Medium | Child questions can deadlock if the user-interaction channel is parent-only | Unattended agent waits forever | Normalize questions into a broker event with timeout/default/cancel; surface the relevant session; allow attach/focus; batch mode must forbid interactive dependencies |
| R-032 | High | Foreign harness internal permissions are not automatically governed by Pi's permission-system | Claude/Codex may make broader changes than the parent intended | Launch each with its own generated policy/config, scoped cwd/worktree, MCP export and containment; parent policy only authorizes launching the envelope—it is not transitive |
| R-033 | Medium | CLI subscriptions, quotas, automation terms or login state may not support sustained subagent use | Delegations fail or violate service expectations | Verify current product terms and CLI behavior; rate-limit; expose clear provider errors; never route solely to exploit a subscription |
| R-034 | Blocker before Antigravity automation | Antigravity's current CLI, policy and MCP configuration are not verified | False assumption of parity with Claude/Codex | Keep it manual/raw until installed-version inspection proves task mode, permissions, structured output, questions and scoped MCP; otherwise omit adapter |

### Attachable process broker

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-035 | High | tmux sessions can be orphaned or confused after Pi/broker crashes | Lost ownership, lingering privileged processes or duplicate attach | Private tmux server/socket, durable process registry, session IDs, heartbeats, reconciliation, explicit cleanup/retention and attach instructions |
| R-036 | High | Multiple writers can send input to one terminal | Corrupted command stream or accidental approvals | Single input lease; user attach preempts automation; model sends only protocol messages, not arbitrary `send-keys`; record lease transitions |
| R-037 | High | Foreign CLIs expose different or no structured question protocols | Text scraping mistakes normal output for a question | Adapter-specific protocol first; otherwise supervised attach notification; silence/regex detection is only a fallback and cannot be used for unattended privilege decisions |
| R-038 | Medium | Worktree/session ownership can conflict with parent Git finalization | Child commits the wrong branch or parent stages unrelated changes | Dedicated worktree per write-capable child; parent remains commit owner by default; adapters disable child commits unless explicitly requested; return a manifest of changed files and HEAD |

### MCP and remote services

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-039 | High | Native Pi, MCP proxy and foreign child can expose the same LSP/graph/RAG service under different names | Duplicate schemas, duplicate indexes and inconsistent results | Canonical service registry with one owner and role-specific exports; Pi Lens MCP never returns to the same Pi; one CodeGraph/RAG service per project identity |
| R-040 | High | Mutating MCP tools or broad credentials leak into low-trust children | External side effects outside repository policy | Export read-only subsets by default; task-scoped credentials; mutating tools require explicit profile and risk approval; hide generic filesystem/shell MCP |
| R-041 | Medium | Client configuration formats drift across Pi, Claude, Codex and other harnesses | MCP sharing silently fails or exports a different set | Generate client-specific files from one canonical registry; version and hash the export; validate with each installed CLI; fail closed on unsupported fields |
| R-042 | Medium | One MCP proxy schema can still become a giant permanently visible meta-tool | Context cost and ambiguous routing | Keep stable proxy schema small, list services briefly, fetch schemas only on activation, cap results and prefer parent retrieval for one-off child needs |

### Git, changelog and documentation finalization

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-043 | Blocker before enforcement | Changelog policy is unclear for merge commits, reverts, amend/fixup, generated/version commits and projects without a changelog | Hooks become annoying or encourage bypass | Define explicit exceptions in repository `agent-workflow.json`; default to one prepended concise entry for each agent-authored change set; test merge/revert/amend flows |
| R-044 | Medium | Documentation-impact detection can miss public behavior/config changes | Code and docs diverge | Use deterministic changed-path/rule mapping, public API/config diff checks and an explicit `docs-not-needed` reason; never rely solely on an LLM judgment |
| R-045 | Medium | LLM-generated commit/changelog text can be invalid or overly broad | Bad history or hook failure | Strict JSON schema, bounded staged-diff summary, deterministic fallback, no LLM inside hooks, human-editable preview |
| R-046 | High | A hook that mutates files after staged-hash calculation or partial staging can commit unrelated changes | Irreproducible commit contents | Preparation command performs all mutations then re-stages and recalculates hash; hooks only validate; compare staged manifest; parent owns final commit |
| R-047 | Medium | `--no-verify` and non-agent commits bypass policy | Inconsistent repository history | CI repeats deterministic checks where appropriate; local hooks optimize UX, not security; document authorized exceptions |

### Observability, maintenance and server evolution

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-048 | High | Traces contain source, prompts, credentials, PTY text or retrieved private knowledge | Sensitive-data exposure | Structured allowlisted fields, content hashing/sampling, redaction, local retention controls and separate raw-artifact policy; no secret PTY capture |
| R-049 | Medium | Status UI state accidentally becomes model context | Per-turn token growth and cache changes | Render health/cache/policy/process state only in UI; model requests a bounded status tool explicitly if reasoning needs it |
| R-050 | High | Fast-moving extensions change schemas and hooks between releases, and a policy-carrying package can move behaviour across a major without breaking a signature | Cache invalidation and behaviour regression — the permission system alone shipped 24 majors in three months | Refresh to latest deliberately and on a date, never in the background or per install (ADR-039); resolved version and hash recorded in lockfile and manifest; evaluation profile and smoke suite before promotion; behaviours we depend on re-read for policy-carrying packages |
| R-092 | Medium | A version written in a document is read as a decision rather than as evidence of a past resolution | Environments are reproduced months stale for no stated benefit, and the pin drift is invisible until an install fails | Documents record resolution dates alongside versions (ADR-039); the refresh task re-resolves every pin and rewrites the recorded values rather than editing individual numbers |
| R-051 | High | A server coordinator's “self-improvement” can modify policies, prompts or skills without review | Authority escalation and non-reproducible behavior | Proposal-only learning; replay/evaluation; human review; signed/versioned promotion; staged rollout and rollback; workers cannot write control-plane files |
| R-052 | Medium | Terminal Pi, VS Code frontend and server workers accidentally share session state | Context bleed and confusing ownership | Shared services/config are versioned APIs; conversation history, task state, cache epoch and credentials remain session-specific; display frontend/session identity |

### Closed-loop workflow runtime

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-053 | Blocker before Stage 6.5 | `pi-factory`, native subagent chains and the foreign broker can each become an outer scheduler | Duplicate retries, commits, questions and conflicting “done” states | `pi-factory` alone owns the task loop; every native/foreign harness is a phase adapter; children cannot recursively start workflows by default |
| R-054 | High | Output schemas drift between runtime types, prompts and call sites | Correction loops waste tokens or invalid data crosses a phase | One versioned schema source generates runtime validator and compact model-facing contract; record schema hash in every phase |
| R-055 | High | A role session resumes after prompt/tool/extension/policy/executor changes | Incompatible context, cache misses and wrong authority | Resume only when full `SessionCompatibilityV1` hash matches, not merely model/role name; otherwise cold-start from artifacts |
| R-056 | High | Phase execution success is confused with semantic verdict or final run acceptance | Red tests/rejected reviews appear green in DB/UI/exit code | Store execution status and verdict separately; exactly one atomic `finish_run()` sets database, UI and process exit state |
| R-057 | High | Agent-declared changed paths are trusted without computing the real Git diff | Hidden, omitted, untracked or out-of-scope changes pass | Gate compares actual base/tree diff, declared paths and allowed scope; include deletes, renames, submodules and untracked files; bind receipt to tree hash |
| R-058 | High | Post-hoc rollback is treated as a sandbox | External effects persist and pre-existing dirty work can be irrecoverably lost | Always use a disposable worktree/containment first; post-phase diff scope is defense in depth and blocks merge, not a security boundary |
| R-059 | Medium | Bounded same-session repair loops oscillate, repeat identical failures or exceed cost limits | Expensive stuck runs | Per-phase and run budgets; failure-signature deduplication; stop on no-progress; optional challenger is a new session with explicit evidence packet |
| R-060 | High | Human question/approval pauses deadlock in supervised or batch execution | Invisible indefinite run | Explicit `waiting_for_user` state, question ID/expiry/default/cancel, notification and attach target; batch mode fails blocked when interaction was not declared |
| R-061 | High | Run artifacts, prompts, diffs and SQLite traces retain source or secrets | Durable sensitive-data exposure | Structured redaction, content caps, separate protected raw-artifact retention, encrypted/permissioned storage where needed, and no password PTY capture |
| R-062 | Medium | SQLite event/process state diverges after crash or multiple writers contend | UI claims stale running phases or resume duplicates work | WAL/busy timeout, idempotent phase transitions, heartbeats, startup reconciliation, process identity verification and fault-injection tests |
| R-063 | Medium | A repository-stamped engine drifts across projects and can be edited by the agents it grades | Unreproducible workflow behavior and self-modified acceptance | Install one versioned engine; scaffold only thin repo policy/workflows; engine/control files read-only; record engine version/hash |
| R-064 | High | Placeholder or missing project checks are recorded as passing | False closed-loop acceptance | `project_check` marks missing/unconfigured commands explicitly and blocks any workflow requiring that level; no placeholder may exit green |
| R-065 | Medium | SSSF is mistaken for a mature production dependency because its design is compelling | Import fresh-install, diff-gate, generator-drift and missing-sandbox problems | Treat current SSSF as a source reference/evaluation profile; follow upstream issues; build tests around borrowed patterns before promotion |

### Session portability and ownership

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-066 | High | Pi JSONL is treated as self-contained although system prompts, tool schemas, skill bodies, effective policy and external artifacts are environment-owned | Another provider/harness cannot reconstruct the work or authority surface | `PortableSessionBundleV1` includes readable/content-addressed capability snapshots, versions, compatibility hash and external artifact manifest |
| R-067 | High | Opaque provider response IDs, reasoning signatures, hosted compaction or hosted agent messages become the sole carrier of meaning | Provider loss or model switch makes the session incomplete | Preserve sealed state only as an optional same-provider optimization; require readable provider-neutral messages, summaries, task envelopes and evidence |
| R-068 | High | Hosted search/browser citations are retained without the passages/ranking actually shown to the model | Research cannot be replayed or audited and sources may later change | Evidence-critical tools retain query, result ordering, passages/snapshot, timestamp, URL, content hash and filtering metadata; citations alone do not pass an evidence gate |
| R-069 | High | Native or foreign child instructions/messages are hidden or only a final summary returns | Incorrect edits and permissions cannot be attributed to the task actually delegated | Persist exact readable launch/task envelope, lineage, model/profile, capability grant, questions/answers and result before relying on provider orchestration |
| R-070 | High | Portable bundles retain secrets, private code, PTY credentials or unlimited raw logs | Export becomes a concentrated disclosure and retention risk | Default mode `0600`, Git-ignore, structured redaction, per-artifact retention class/size cap, no password capture and explicit deletion manifest |
| R-071 | Medium | Portable export becomes another auto-summary/context injector | Duplicate continuity stories, cache churn and permanent overhead | Slash command or factory code phase only; no model tool, per-turn hook or automatic reinjection; Pi compaction remains sole history writer |
| R-072 | Medium | A portable handoff is mistaken for deterministic replay | New model makes different choices or lacks equivalent tools | Define replay as semantically sufficient continuation, validate capabilities before launch and surface unavailable evidence/tools instead of silently substituting |

### Persona and mission control plane (see 08/09)

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-073 | High | A persona suggester or persona-architect agent can mint wider personas and escalate privilege indirectly | Self-authorization through the authoring pipeline | Subset rule: only narrowings of active personas run without review; any new grant requires human review; minimal-scope drafting objective; provenance on every candidate |
| R-074 | High | Web UI and IM gateway become unaudited authority surfaces | Remote policy changes, approvals or persona activation without attribution | Authentication, least privilege, every write an event on the trace; editor writes declarations only; sudo/credential entry impossible remotely by construction |
| R-075 | High | A poisoned or wrong memory write propagates across personas through shared scopes | Cross-persona contamination (shared memory is the biggest attack surface) | Writes only to own namespace through candidate review; cross-namespace access is read-only and profile-declared; provenance, contradiction handling and revocation in the memory service |
| R-076 | Medium | The mission board degrades into free-form inter-agent chat or a knowledge side-channel | Unaudited knowledge transfer and unreplayable coordination | Typed envelopes/events only; knowledge admitted only via the memory service; board schema validation rejects free text outside declared fields |
| R-077 | Medium | Lease handling deadlocks or starves missions | Stuck or unfair scheduling | Atomic all-or-nothing lease acquisition at dispatch; no mid-run acquisition; timeout/expiry with heartbeats; per-resource fairness queue |
| R-078 | High | Events lack lineage identifiers because instrumentation was added late | Observability, conformance checking and the DAW UI become unreliable retrofits | `mission_id/run_id/parent_span_id/role/profile_hash` mandatory from Stage 5 (Executor) onward; event schema validated in CI |
| R-079 | Medium | Lifecycle logic drifts between orchestrator code, docs and UI | Illegal transitions and inconsistent state displays | Statechart definitions as versioned data are the single source; enforcement, validators, tests and UI rendering are generated from them (ADR-032) |
| R-080 | Medium | Skills accumulate prose control flow as agent-authored skills arrive | Model-dependent workflow compliance instead of deterministic sequencing | Lint flags imperative multi-step language in `SKILL.md`; sequencing moves to workflow definitions or scripts invoked by the skill |
| R-081 | Medium | Suggest-only routing quietly becomes auto-routing as trust grows | Unreviewed persona selection for capable personas | Auto-selection permitted only for read-only credential-free personas by explicit policy; mutation/credential/spend personas always require confirmation |
| R-082 | Medium | A long agentic turn appends more content blocks than the provider's breakpoint lookback window, so the next request finds no cache entry | Silent, total cache miss inside otherwise correct sessions; cost attributed to "long context" rather than the real cause | Intermediate breakpoint roughly every 15 blocks in phases that emit long tool chains; smoke suite asserts non-zero cache reads after multi-tool turns (`10` §3) |
| R-083 | Medium | Parallel fan-out (factory phases, subagents) issues identical-prefix requests simultaneously, before any of them has written the cache | Every branch pays full uncached price; measured savings collapse exactly when concurrency is highest | Send one request, await its first streamed token, then release the remainder; fan-out ordering is a property of the scheduler, not of prompt construction (`10` §7) |
| R-084 | Medium | Cache verification is specified but never implemented, because the failure mode is invisible without it | ADR-007 degrades to convention; a single unrelated extension silently taxes every future session | Prefix hashing with `CACHE_EPOCH_VIOLATION` from V0.3; separate uncached/read/write event fields from V0.4; scripted smoke session as a CI gate (ADR-035) |
| R-085 | High | The `shellTools` alias that puts `interactive_shell` on the bash enforcement stack is config, so a missing, misspelled or mis-keyed entry degrades silently to opaque whole-tool gating rather than failing | A tool permitted once can then run any command at any privilege the account holds, with nothing anywhere reporting that command-level policy stopped applying | Alias presence and argument names are asserted at `session_start` and hashed into the manifest, not assumed; T7 probes assert a command denied on the `bash` surface is denied identically through this tool (R-057 — a check that silently stops applying is worse than none) |
| R-091 | High | An `interactive_shell` call carrying only `sessionId` and `input` presents an empty command string to the bash gate, which matches the `"*": "allow"` rule | Keystroke injection into an already-authenticated privileged session is invisible to command-level policy by construction, no matter how strict the `bash:` rules are | Sticky per-session classification refuses all input injection into privileged-origin sessions (ADR-037); the empty-command case is an explicit T7 probe rather than an assumed default |
| R-086 | High | `mode` is supplied by the model, the package ships no mode allowlist, and `hands-free`/`dispatch` permit keystroke injection and output polling over the same command | A privileged command reaches a non-blocking mode where the model, not the operator, types the password — defeating the one property that made this channel safe | Privileged commands are refused outside `mode: "interactive"` (ADR-037); T7 probes attempt the same privileged command in all four modes and assert only interactive is admitted |
| R-087 | High | Ctrl+B backgrounds a live session; a backgrounded session keeps its id in the session manager and stays addressable by `input`/`inputKeys`/`inputHex`/`inputPaste` | An operator-authenticated root shell is handed back to the model after the blocking call that protected it has returned | Classification is sticky to the session for its whole lifetime, not evaluated at spawn; input injection is refused for any privileged-origin session in every state (ADR-037) |
| R-088 | Medium | The permission system's `/permission-system` modal writes and applies `yoloMode` mid-session, auto-approving every ask-state check including subagent forwarding | The single toggle that disables the ask path is reachable from a slash command and persisted to global config, silently voiding ADR-037's gate | Freeze covers the extension-config modal, not only policy rules: the command is not registered in our profile and resolved config is hashed into the manifest at `session_start` |
| R-089 | Medium | `handoffSnapshotEnabled` writes un-redacted terminal tails to `~/.pi/cache/interactive-shell/`, and the package has no secret-awareness of any kind | A prompt that echoes what it reads puts a secret in the model-visible result and in a plaintext file on disk; only `sudo`'s own echo suppression prevents it today | Snapshot disabled in our profile; T7's secret-entry probe uses a deliberately echoing prompt rather than only `sudo`, so the test measures our control and not `sudo`'s |
| R-090 | Medium | Sudo kept for Phase 0 convenience is never revoked, because nothing fails when it persists | A time-boxed affordance becomes a standing privilege, and the ADR-037 guard is mistaken for the containment boundary it explicitly is not | Revocation is a checked V0.1 exit condition, not an intention (ADR-038); `server-preflight.sh` asserts the sudoers file is absent once Phase 0 is closed |

### Layer sequencing, the parity gate and foreign CLI workers (see 11/12)

| ID | Severity | Concern | Consequence | Current mitigation / evidence needed |
| --- | --- | --- | --- | --- |
| R-093 | High | Claude Code's `--disallowedTools` has no effect on MCP server tools in print mode (anthropics/claude-code #12863) | A phase's tool restriction appears configured and is partly unenforced; a worker denied a capability by flag can still call it through MCP | Restriction is carried by the generated MCP set and by `PreToolUse` hooks, never by the flag alone; the adapter asserts the effective tool list from the worker's own output before the phase is trusted (R-057 — a check that cannot fail is worse than none) |
| R-094 | Medium | Claude Code's built-in MCP servers load their tool lists and instruction blocks into every session and cannot be removed from context (#82498, #43690); measured prefix is ~33k tokens, ~24k of it tool definitions | Every launch of that adapter carries a context floor that no configuration reaches, and an unmeasured design will attribute the cost to "long context" | `foreign_prefix_tokens` measured and recorded per launch (ADR-043); profiles that do not improve on the stock CLI are recorded as not improving on it; the floor is a selection input when choosing between adapters for a phase |
| R-095 | Medium | `agy` hangs indefinitely on an approval prompt in a non-TTY context, has a reported empty-output defect there (#76), and its default model differs by release channel | An Antigravity phase silently never returns, or returns nothing, or runs on a model nobody chose | Adapter allocates a pty rather than piping, passes `--mode=accept-edits` and an explicit `--model`, and asserts the model actually used from the worker's output; phase timeout is mandatory, not optional |
| R-096 | High | Automating a subscription-authenticated CLI is technically possible in arrangements the provider's terms do not cover | A working pipeline is one policy clarification away from failing, and it would fail in the agentic layer where nobody is watching | The factory spawns the official CLI as a local process and never proxies OAuth or wraps a subscription into a service (`12` §7); attended profiles use subscription auth, orchestrator-dispatched profiles use an API key, and the credential class is recorded in the profile and the event stream |
| R-097 | High | Web search and fetch have no owner anywhere in the plan, and the capability is used daily in the current environment | The parity gate is declared with a capability missing, or the gap is closed hastily by whatever extension is nearest — with an unbounded page as a tool result and an unexamined egress path | Recorded as parity gap D10 with a V0.6 deadline; the owner must satisfy pre-insertion bounding (ADR-013), a permission class distinguishing read-only fetch from anything transmitting repository content, and ADR-028's local-evidence rule for retrievals that decide something |
| R-098 | Medium | Image and screenshot input is unverified in the pinned Pi version and has no owner | A routine input path in the current environment disappears at the switch without anyone having decided to lose it | Recorded as parity gap D11; verify the pinned version's message content types before V0.6 and, if absent, record it as an accepted loss in the gate review rather than leaving the row blank |
| R-099 | High | The parity gate is declared from impression — "it feels good enough now" — rather than from run records | The switch happens early, the previous environment is abandoned, and the resulting friction is attributed to the harness being new rather than to it being worse | Thresholds fixed in advance (`11` §4.2), evidence is run IDs in a dated review, and a rollback condition is written before the dual-run period starts, not after |
| R-100 | Medium | Three foreign CLIs, each carrying its own prefix, run in parallel across worktrees | The cheapest way to make a bounded task expensive; cost regressions appear exactly when concurrency is highest, compounding R-083 | Concurrency starts at two foreign workers and rises only from traces; per-run cost is a parity-gate threshold, so a regression fails the gate rather than being absorbed |
| R-101 | Medium | All three provider CLIs change flags, config formats and default models faster than this document can track | Generated configs stop applying silently, and a worker runs with vendor defaults while the launch spec claims otherwise | Adapters verify their own surface at launch and assert what they got — binary version, effective model, exported server set — instead of trusting the recorded table; a mismatch fails the phase rather than degrading it |
| R-103 | Medium | `@vndv/pi-codegraph` (0.1.10, eleven releases in three weeks then quiet since 22 June 2026) is single-maintainer and an order of magnitude younger than the engine it proxies | The Pi-native graph surface stops tracking the engine's tool names or arguments, and the daily driver silently loses its architecture authority | The bridge is a thin proxy that starts no watcher or index, so its failure mode is cheap and pre-decided: consume the engine through the lazy MCP proxy instead, with invariants 1–3 of ADR-045 unchanged and no code to write. Tool-name drift is caught by the capability compiler's preflight, which resolves the registered surface at `session_start` rather than trusting the pinned README |
| R-104 | Medium | "One graph surface per session" degrades into "the graph is available everywhere" once foreign workers can receive the CodeGraph server | Graph access becomes an ambient property of any agent, and the frozen prefix of some session ends up carrying two interfaces to one capability | Graph access is a declared grant in `AgentProfileV1`, compiled per profile and visible in the session manifest (ADR-045); the tool-surface snapshot asserts exactly one CodeGraph interface per compiled session, and a profile declaring both fails to launch rather than being deduplicated silently |
| R-102 | Medium | Deferring the isolated profile past the switch is a scheduling decision that could quietly become a permanent omission | The third workload class (unfamiliar or risky code) never migrates, and the harness is unavailable exactly where containment matters most | Deferral recorded as decision D17 with the reason (attended, local, trusted repositories are the `trusted-local` threat profile) rather than as silence; the third switch declaration in `11` §4.3 cannot be made without it |

### Provider pin, evaluation policy and the profile-scoped executor (see ADR-046/047/048)

| ID | Severity | Risk | Consequence | Mitigation |
| --- | --- | --- | --- | --- |
| R-105 | High | ADR-046 accepts a dearer route with a smaller window on one catalog flag, `supportsToolSearch`, read from Pi 0.80.10 — four minors behind the version we intend to run | The pin's entire justification is stale on the day the upgrade lands, and nobody re-reads it because the decision is recorded as settled | V0.1-T2 re-reads the flag on the upgraded catalog for both routes as an explicit acceptance step, not a side effect; if OpenRouter declares tool search, ADR-046 is reopened rather than defended. The contingency is written into the ADR itself so the reopening condition survives the session that set it |
| R-106 | High | Pi vendors `rg` and `fd` into `$PI_CODING_AGENT_DIR/bin/` and calls them by path, so a command can exist for Pi, not exist for anything Pi spawns, and not exist in a second profile on the same machine | A profile advertises a capability its executor cannot resolve, and the disagreement is invisible to every check that asks the shell — which is how the recorded workstation survey came to state a shell-function `rg` that was never there | V0.3-T2's preflight resolves commands **per profile root**, probing the vendored `bin/` alongside the executor's PATH, and a profile claiming a command it cannot invoke fails to launch. `scripts/executor-inventory.sh` is the reference implementation and already reproduces the divergence between `~/.pi/agent` and a fresh profile root |
| R-107 | Medium | ADR-048 removes retrieval from the execution layer on the argument that the agent can read `docs/` directly, which is true at ~5,500 lines and stops being true silently | The harness degrades into grepping a corpus it has outgrown, and the absence is attributed to model quality rather than to a missing component | The trigger is stated in advance rather than left to judgement: when a routine question needs more than three file reads to answer, or `docs/` passes roughly 15,000 lines, retrieval is reopened as a V0.7 dependency that has become urgent. Until then the `read`/`grep` path is the recorded owner, not a gap |
| R-108 | Medium | ADR-047 forbids model evaluation, so a pin can only be revised when a *stated* property changes — and nobody is watching for that | Provider capability moves, the reason for the pin quietly stops being true, and the system keeps a model chosen against facts that expired | Each pin records the property it was chosen for (ADR-046 records tool search), and that property is re-asserted at the same moment the package refresh re-reads policy-carrying behaviours (ADR-039). A pin whose stated reason no longer holds is reopened; one that is merely old is not |
| R-109 | Medium | ADR-049 makes us the maintainer of a tool that tracks two moving surfaces — Pi's `ui.select()`/`ui.input()` signatures and typebox's schema builders — where the upstream package absorbed both changes for us | A Pi minor changes a dialog primitive and the question surface breaks in a session that has no other way to reach the operator, which is the worst place for a component to fail | The tool is the smallest possible use of both surfaces (two dialog calls, `Type.Object` only), so the exposed API is narrow by construction; V0.1-T7's battery exercises single-choice, multi-choice and refusal paths after every Pi upgrade, and the upgrade is a dated act that re-runs the smoke suite (ADR-039). The read upstream package remains a working reference implementation if a primitive's contract changes in a way we did not anticipate |
| R-110 | Medium | Our typebox copy and Pi's are separately resolved, and both build schema objects consumed by one validator | Two typebox versions produce a subtly different tool schema, changing the frozen prefix hash with no error and no visible cause — the exact failure ADR-035 exists to catch, arriving through the dependency tree rather than through the prompt | Our dependency is pinned to the version Pi resolves (1.1.38 on 7 August 2026) and re-asserted whenever Pi is upgraded, since a Pi minor may move it. The cache regression gate (V0.3-T9) catches the symptom; the pin alignment is what prevents it |

## Open questions, ordered by when they block progress

### Before Stage 1–2 becomes the baseline

1. Which exact upstream Pi version is pinned, and which lifecycle events can enforce the immutable cache/capability contract without a fork?
2. Does the pinned permission-system re-read configuration during `before_agent_start` or another hook, and what is the smallest patch to freeze it?
3. What is the canonical list of control-plane paths, and how will they be made read-only in trusted-local and isolated-local profiles?
4. How is password-entry mode signaled to suspend PTY capture without hiding ordinary sudo failures?

### Before Stage 3 intelligence is promoted

1. What exact Pi Lens API/config filters its initial active tools and prevents later activation of graph/AST-write duplicates?
2. Which language servers are already installed, which may execute project plugins, and which belong inside containment?
3. Does the chosen CodeGraph Pi bridge reuse one index across worktrees safely, or should each worktree use a namespaced view of a shared daemon?
4. Which project-document RAG engine wins on the real corpus, including deletion, provenance and incremental update tests?

### Before compaction/output optimization

1. What task classes and model context windows justify distinct `reserveTokens`/`keepRecentTokens` policies?
2. Which continuity benchmark measures retained requirements, decisions, unresolved failures, artifact IDs and next actions?
3. Can Pi's compaction hook use a separate model with exactly one valid `CompactionEntry` on the pinned version?
4. Which commands benefit from RTK without semantic loss, and what raw-output artifact format is sufficient?
5. Which exact LeanCTX version/config disables all overlapping features, and does it reduce billed input on our traces?

### Before automated delegation

1. Which native subagent package, if any, can accept the compiled static profile and dynamic task envelope without hidden prompt concatenation?
2. What structured question/approval mechanisms do the installed Claude Code, Codex CLI and Antigravity CLI versions expose?
3. Can each foreign harness consume a generated, task-scoped MCP config and its own deny/ask/allow policy non-interactively?
4. What are the attach, cancellation, timeout, orphan-reconciliation and cleanup contracts for the private tmux broker?
5. Are child commits ever desirable, or should every adapter enforce no-commit and return changes to the parent?

### Before Stage 6.5 closed-loop orchestration

1. Will `pi-factory` be implemented as a Python/Pydantic engine with a thin Pi-native TypeScript adapter, or as one TypeScript engine? Choose after prototyping cancellation, schema generation and SQLite/process integration—not by ecosystem taste.
2. What exact session compatibility fields are available from Pi and each foreign harness, and which adapters cannot safely resume?
3. Which repository state transitions are idempotent enough for crash recovery, especially worktree creation, check receipts, changelog preparation and commit?
4. What artifact size, retention and redaction policy applies per repository trust class?
5. Which user questions may pause supervised runs, and which conditions must fail immediately in batch mode?
6. What constitutes no progress in repair/revision loops and when may a challenger model be started?
7. Should outer phase parallelism replace most agent-internal subagents so work remains observable, or are there measured low-level recon cases where nested fan-out is cheaper?

### Before commit finalization enforcement

1. What exact changelog entry format and section heading are required?
2. Which commits are exempt: merge, revert, fixup, release/version, generated-only, dependency lockfile-only?
3. What constitutes a documentation-impacting change, and how is a justified no-doc decision represented?
4. Should the local hook be installed with `core.hooksPath`, a repository bootstrap command, or a task runner?

### Before Hermes/server rollout

1. What exact Hermes memory package/API is being evaluated, and can writes be held as untrusted candidates?
2. What is the migration/export/revocation path, and how are contradictions resolved?
3. Which memories may be shared between Pi, Claude and Codex, and which remain user/repo/role private?
4. How is remote user interaction delivered when an unattended worker asks a question or needs approval?
5. Which evaluation gate may propose prompt/skill/routing changes, and who promotes them?
6. Does the selected Hermes version provide a stable service boundary for the narrow Memory Service, or should the first adapter use an independent reviewed store until Hermes Coordinator is deployed?

### Before portable session export is promoted

1. Which exact Pi runtime/session API version provides the live active branch, retained compaction tail and extension entries?
2. Which configuration inputs must be copied versus referenced by content hash so another harness can reconstruct the effective prompt/tool/capability surface without credentials?
3. Can the exporter recover spilled Bash output and MCP/browser evidence without copying unbounded or secret-bearing data?
4. Which foreign harnesses expose readable structured events, and which must be marked `portability: partial` because internal agent messages remain hidden?
5. Does an export/revoke-provider/import test preserve requirements, decisions, failures, validation state, pending questions and next action?
6. Can `deletion-manifest.json` enumerate and remove every local dependency while clearly identifying remote/provider copies outside our control?

## Redundancy and conflict map

| Responsibility | Authoritative owner | Overlapping candidates | Decision |
| --- | --- | --- | --- |
| Command intent approval | permission-system | `pi-safe-shell`, prompting `pi-sandbox`, child-internal policies | One Pi owner in trusted profile; each foreign child still gets its own compiled internal policy; alternatives only in separate evaluation profiles |
| Human PTY / sudo | `pi-interactive-shell` initially; broker attach UI later | `pi-live-terminal`, `pi-tmux`, generic terminal MCP, broker's own pane | One user-facing path per profile; direct PTY remains for local sudo, broker owns long foreign runs |
| OS containment | Gondolin profile initially; audited stronger boundary where needed | permission rules, Docker, OpenShell, Daytona, host sandbox | Permission is UX, not containment. Exactly one containment owner per worker |
| Code relationships | CodeGraph | GitNexus, code RAG, Pi Lens graph tools | CodeGraph only; hide duplicates |
| Definitions/references/diagnostics | native Pi Lens LSP surface | standalone Pi LSP, LSP MCP, CodeGraph symbol approximations | One Pi Lens/LSP instance; no self-MCP |
| Structural search/codemods | `ast-grep` CLI | Pi Lens AST tools, generic AST MCP | CLI through Bash; activate no dedicated schema unless traces justify it |
| Project documents/decisions | one local RAG | Hermes facts, code RAG, per-agent vector DB | RAG only for authoritative prose; explicit retrieval |
| Procedures/preferences/episodes | Hermes later | RAG notes, compaction summary, todo state | Typed, reviewed Hermes records only; never session recap |
| Conversation continuity | Pi-native compaction | LeanCTX history pruning, Hermes recap, todo recap, memory injection | One Pi `CompactionEntry`; typed external references only |
| Shell-output reduction | RTK initial trial | LeanCTX shell rewriting, arbitrary summarizer, shell MCP | One interceptor at a time, raw artifact retained |
| Editing | Pi built-in edit/write | Hashline, Pi Lens autofix/format, LeanCTX edit, LSP code action | Built-in owner; explicit LSP actions only; experiments isolated |
| Current task state | Pi plan/conversation | `rpiv-todo`, subagent todo stores, Hermes | Parent-only; todo package only after measured need |
| Questions | one structured question tool + broker event | multiple ask-user packages, PTY text scraping | One schema in Pi; adapter maps foreign questions into it |
| MCP exposure | one lazy proxy + generated role exports | direct eager servers, native/MCP mirrors | Remote/stateful services only; one canonical registry |
| Validation | `project_check` | multiple post-edit hooks, guessed test runners | One deterministic repository-native gate |
| Workflow sequencing/acceptance | `pi-factory` | SSSF, native subagent chains, foreign broker loops, prompt-owned autonomous plans | One deterministic outer owner; all harnesses are phase adapters |
| Commit/changelog/docs | parent commit finalizer | child commits, LLM hooks, formatter hooks | Parent prepares; hooks validate only |
| Tracing/evaluation | one structured event stream | verbose raw transcript loggers | One redacted schema and bounded artifacts |

## Combinations that must not be active together

- permission-system and `pi-safe-shell` in the same profile;
- multiple model-visible shell/PTY tools that can start the same command class;
- RTK and LeanCTX command/output rewriting on the same request path;
- native Pi Lens plus a second Pi LSP or Pi Lens MCP loopback;
- CodeGraph plus GitNexus or a source-code RAG used for the same relationship queries;
- Pi compaction plus LeanCTX/Hermes/todo extensions that each restore or rewrite session history;
- Pi Lens formatter/autofix plus another automatic post-edit formatter/fixer;
- built-in edit/write plus an unproven replacement edit tool in the daily profile;
- two automatic memory writers, or Hermes and RAG both accepting the same record type;
- multiple CodeGraph, RAG or LSP daemons per child when a shared scoped service exists;
- child commits and parent commit finalization on the same change set;
- SSSF or a native/foreign subagent chain independently scheduling the same run beside `pi-factory`;
- host PTY/LSP/graph/MCP subprocesses presented as if Gondolin-contained;
- mutable control-plane files and algorithmic in-session policy/profile switching.

## Missing thin components

| Gap | Why an existing package is insufficient | Proposed component | Complexity | Promotion gate |
| --- | --- | --- | --- | --- |
| Immutable session capabilities and cache rules | Packages manage individual concerns but do not compile and freeze the whole effective surface | `pi-session-control` | Medium–high | Exact payload/profile tests; unsupported mutation fails closed |
| One validation authority | Generic agents guess commands and hooks compete | `project_check` | Low–medium | Correct repository-native checks, structured failures, changed-file awareness |
| Deterministic closed-loop composition | Individual tools/profiles do not define sequence, corrections, handoffs or acceptance; current SSSF lacks required safety/integration | `pi-factory` | High | Typed `implement` loop passes crash, question, scope, validation and atomic acceptance tests |
| Commit/changelog/docs consistency | Hooks cannot safely generate text; agents forget workflow | `commit-prepare` + validating hooks + skill | Medium | Partial staging, amend/revert and fallback tests |
| Attachable foreign agents | Interactive shell lacks durable broker semantics; subagent packages do not normalize external CLIs | `agent_delegate` + private tmux broker | High | Attach/takeover/question/cancel/crash-recovery suite |
| Role-specific MCP sharing | Each CLI has a different format and eager configs leak tools | canonical registry exporter | Medium | Generated configs validate on installed clients; no duplicate service |
| Tool-output evidence envelope | Native history stores too much, compaction later sees truncation | output coordinator | Medium | Diagnostic retention beats raw/truncated baseline; raw recovery works |
| Typed continuity | Native summary alone lacks machine-stable task/evidence fields | small Pi-native compaction adapter | Medium | One valid entry; benchmark retains required fields better than baseline |
| Compact status without prompt cost | Existing status extensions may show only one subsystem or inject text | status widget | Low | UI-only, negligible runtime, no model context unless explicitly requested |
| RAG/CodeGraph result fusion | Generic routers duplicate retrieval or auto-inject | optional explicit fusion command | Medium | Traces show repeated dual queries and better combined answer quality |

## Acceptance evidence checklist

Before declaring the balanced setup reliable, retain evidence that:

1. the startup manifest lists exact Pi/extension/model versions, profile, capabilities, tools, skills, permissions, MCP exports, compaction policy and hashes;
2. changing a policy/config/control-plane file mid-session does not change behavior;
3. unavailable commands and capabilities fail before model work is wasted;
4. risky removal, privilege and network/credential operations ask once at the correct boundary, while ordinary commands do not nag;
5. sudo password entry occurs only in focused PTY and does not appear in transcript, trace or memory;
6. the isolated profile prevents the documented host filesystem/network/process accesses, including extension subprocesses;
7. CodeGraph, Pi Lens and RAG each answer only their assigned query classes and start no duplicate index/server;
8. long tool results preserve exit status, decisive diagnostics and a retrievable raw artifact before Pi compaction;
9. compaction continuity tests preserve constraints, decisions, failures, evidence IDs and next actions;
10. every specialist receives exactly its compiled prompt/tools/skills/commands/MCP/credentials and a separately appended task envelope;
11. foreign agents can be attached, focused, interrupted and questioned without arbitrary tmux control being model-visible;
12. `project_check`, changelog, documentation impact and commit-message validation operate on the exact staged change set;
13. traces report cache epochs/hits, tool/context overhead, approvals, retrieval, checks and delegation without secrets;
14. package upgrades are tested in an evaluation profile and can be rolled back from exact pins.
15. phase execution status, semantic verdict, run acceptance, UI status and exit code cannot disagree;
16. the full session compatibility hash controls resume versus cold-start;
17. a closed-loop run can recover from artifacts after discarding every model session;
18. actual diff scope, fresh checks, documentation/changelog rules and staged hash all gate the deterministic commit;
19. user questions pause visibly and can be answered/attached/cancelled, while batch work never waits invisibly.
20. a portable bundle passes inspection, export, cross-provider continuation, audit and deletion tests without using the original provider's IDs or opaque state;
21. provider-hosted search or subagent facilities are never the sole evidence carrier for an accepted phase;
22. Hermes Memory Service stores only reviewed derived memories, while raw session/run bundles remain in the session/factory artifact store.
