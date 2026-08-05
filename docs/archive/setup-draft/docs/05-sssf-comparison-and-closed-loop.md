# Ultimate Pi Setup — SSSF Comparison and Closed-Loop Workflow Design

Research revision: 5 August 2026

Compared source: [`disler/super-simple-software-factory`](https://github.com/disler/super-simple-software-factory), main commit `de31374882e7a4e3e5b7bb9bd09e69dc2f779356` from 2 August 2026 and example commit `b2dcb8e436db9b10f7580d7568b3e251609eb36b` from 4 August 2026.

## Verdict

SSSF reveals a real gap in our plan: we designed a strong agent platform and execution substrate, but not yet one small executable runtime that turns those components into a repeatable task loop.

The missing layer is **deterministic workflow orchestration outside the model**:

- named phases;
- typed inputs and outputs;
- explicit artifacts and evidence;
- deterministic code phases;
- bounded correction loops;
- run-level acceptance;
- durable run identity and resumability;
- unified events and process lifecycle.

We should take that architecture, not install SSSF unchanged. SSSF is only days old, has no release, is Pi-only, runs on the current branch, has no sandbox or real human approval phase, and currently has correctness bugs in fresh-install model handling and diff verification. Its own README explicitly calls branch-per-run, sandboxing, merge and human approval future additions.

Our architecture is substantially stronger in containment, permissions, user interaction, cache stability, capability truth, code intelligence, retrieval, worktree isolation, foreign harnesses, MCP scoping, output control, commit discipline and memory ownership. The correct result is therefore:

> Build a small reusable `pi-factory` workflow engine inspired by SSSF's phase/envelope/gate loop, and run every agent phase through our existing immutable profiles, executors, tools and brokers.

Do not make SSSF itself the new host, do not stamp an editable copy of the entire control engine into every repository, and do not expose every researched tool to the parent model.

## What SSSF actually implements

The repository is not only diagrams. The hidden `.claude/skills/sssf/` tree contains a deployable skill, Python workflow templates, Pi subprocess adapter, Pydantic data contracts, post-run write checks, deterministic quality commands, SQLite tracing and a Vue/Bun trace UI. The `example` branch contains a stamped demo repository and generated specs/documentation.

Its core execution pattern is:

```text
engineer request
→ deterministic Python phase
→ Pi agent with a named roster profile
→ parse typed JSON envelope
→ run gates
→ continue the same Pi session with exact violations
→ deterministic test/review/revision loops
→ explicit run acceptance
→ trace every event and artifact
```

Notable implemented mechanisms:

1. Python owns sequencing, branching, bounded retries and final acceptance.
2. Agents are selected by stable role names; workflows never name models directly.
3. Each agent role has model, thinking, system/user prompts, tool list, extension list and repository write scope.
4. Every agent call declares a Pydantic output type.
5. Larger context crosses phase boundaries through files in `context_handoff/`; envelopes carry small structured references.
6. Invalid JSON and failed gates are corrected in the same Pi session rather than cold-started.
7. Known commands such as tests, Git diff and commit are deterministic `code` phases.
8. A successful phase is separate from an accepted run.
9. One run ID joins several workflow scripts and maps each role to a persistent Pi session.
10. SQLite/WAL records sessions, phases, events, envelopes, gate evidence, agent sessions and processes while work is running; JSONL and artifacts remain the raw record.
11. Tool usage, cache read/write tokens, cost and context occupancy are recorded separately.
12. The skill uses lazy cookbooks and an installer/generator to stamp a repository-local factory.

Sources: [README](https://github.com/disler/super-simple-software-factory/blob/de31374882e7a4e3e5b7bb9bd09e69dc2f779356/README.md), [agent execution](https://github.com/disler/super-simple-software-factory/blob/de31374882e7a4e3e5b7bb9bd09e69dc2f779356/.claude/skills/sssf/templates/adws/adw_modules/agents.py), [runner](https://github.com/disler/super-simple-software-factory/blob/de31374882e7a4e3e5b7bb9bd09e69dc2f779356/.claude/skills/sssf/templates/adws/adw_modules/runner.py), [trace schema](https://github.com/disler/super-simple-software-factory/blob/de31374882e7a4e3e5b7bb9bd09e69dc2f779356/.claude/skills/sssf/templates/adws/adw_modules/tracer.py).

## What our research missed or under-specified

### 1. A workflow engine as a first-class component

Our plan has the right ingredients—profiles, subagents, project checks, worktrees, brokers, commit finalization and traces—but mostly describes who owns each capability. It does not yet define one executable state machine that decides which capability runs next and why.

This is the largest gap. `pi-factory` should be a control-plane program, not another agent prompt.

### 2. Phase status and run acceptance are different facts

A test command may execute correctly and still return red. A reviewer may complete correctly and reject the change. Treating phase execution success as task success makes traces and exit codes lie.

We need both:

```yaml
phase:
  executionStatus: success | failure | cancelled | blocked
  verdict: pass | fail | not_applicable

run:
  accepted: true | false
  reason: ...
```

Only one `finish_run()` transaction may set the final database status, exit code and UI result.

### 3. Typed result envelopes enforced at runtime

`AgentProfileV1.outputContract` in our plan is directionally correct but not enough. Every call needs an actual schema validated by code, with no free-form handoff between phases.

We should define one source schema per output type and generate:

- runtime validator;
- model-facing JSON Schema or compact report instruction;
- UI rendering metadata;
- version/hash recorded in the run manifest.

This improves on SSSF's fragile three-copy contract, where a Pydantic type, prompt example and call site must be edited together manually.

### 4. Same-session correction as the default retry

When an envelope fails to parse or a mechanical gate returns actionable violations, retrying from scratch loses the agent's working context and repeats discovery. The normal correction path should append a bounded structured error to the same child session.

Cold restart is reserved for:

- crashed/corrupt session;
- changed profile/model/capability hash;
- containment failure;
- poisoned or irreconcilable context;
- explicit alternate-model challenger.

### 5. A standard handoff/evidence directory

We have stable references in several places but no single run-scoped artifact contract. Add:

```text
.agent-runs/<run-id>/
  manifest.json
  events.jsonl
  phases/<seq>-<phase-id>/
    input.json
    output.json
    evidence.json
    stdout.log
    stderr.log
  artifacts/
  worktree.json
```

The directory is runtime state and normally Git-ignored. Artifacts are content-addressed or at least hashed, size-bounded, typed and referenced from envelopes. Durable project outputs such as specs and documentation remain normal repository files.

### 6. Deterministic code phases beyond `project_check`

Our plan correctly makes `project_check` authoritative, but SSSF generalizes the rule: any known invocation belongs to code, not an agent.

First-class deterministic operations should include:

- capability and dependency preflight;
- worktree creation/checkpoint;
- CodeGraph/RAG index health checks;
- changed-file and diff capture;
- formatter/linter/typechecker/compiler/test execution;
- documentation-impact rules;
- changelog preparation validation;
- commit and merge preparation;
- artifact hashing and cleanup;
- trace/memory candidate export.

The model decides only where judgement is necessary: planning, implementation, semantic review, research synthesis and documentation wording.

### 7. Gate evidence as a durable object

`project_check` returns correctness evidence, but every workflow boundary should support small deterministic gates with item-level evidence:

- output schema valid;
- declared artifact exists and matches hash/type;
- actual changed paths equal or are a permitted superset/subset of claims;
- write scope respected;
- required checks are fresh for current tree hash;
- every acceptance criterion has reviewer evidence;
- changelog and docs rules pass;
- no unresolved approval/question/process remains;
- commit tree equals the validated tree.

Failed gates return exact machine-produced violations to the same phase owner. A security or containment breach is not a retryable gate—it aborts the run.

### 8. Unified run and process identity

Our foreign-agent broker has a process registry, but all work should share one identity chain:

```text
RunID
├── WorktreeID / repository / base SHA
├── PhaseID
│   ├── AgentSessionID or CommandProcessID
│   ├── ProfileHash / capabilityHash / cacheEpoch
│   └── EvidenceIDs / artifact hashes
└── Final staged-tree hash / commit SHA
```

This allows Pi, native children, Claude Code, Codex CLI, deterministic checks, MCP calls and Hermes candidates to appear in one trace without sharing their conversation histories.

### 9. A reusable workflow library

We planned specialist profiles but not named, tested compositions. Start with a small set rather than SSSF's twelve near-duplicates:

| Workflow | Phases | Use |
| --- | --- | --- |
| `inspect` | intake → parallel read-only recon → evidence fusion → report | architecture, debugging and impact analysis |
| `plan` | intake → recon/retrieval → plan → optional human approval | risky or unclear work before edits |
| `implement` | intake → worktree → build → checks/fix loop → review/revise → final checks → finalize | normal code change |
| `research` | intake → web/docs/RAG workers → source gate → synthesis | technical research and writing |
| `release` | validated tree → docs/changelog → release checks → human risk gate → commit/tag/push | external side effects |
| `incident` | intake → diagnostics → hypothesis → bounded experiment → validation → report | debugging/diagnostics without premature mutation |

These workflows should be ordinary typed Python modules or similarly readable code, not a hidden autonomous planner or large workflow DSL.

### 10. Exact cache and context observability per phase

Our plan asks for cache tracing; SSSF demonstrates the useful decomposition. Record per agent turn and phase:

- uncached input tokens;
- cache-read tokens;
- cache-write tokens;
- output and reasoning tokens;
- cost;
- context occupancy and limit;
- compaction events/policy/summary model;
- system/tool/skill/profile hashes;
- retrieval and automatic-injection bytes/tokens.

This lets us distinguish a large but cheap cached context from a cache miss, and lets later router/compaction changes use evidence rather than intuition.

### 11. Lazy operational skills, not only task skills

SSSF's skill reads a small routing table and lazily loads the cookbook for install, run, observe or modify. Our progressive skill discovery should explicitly cover operational workflow skills as well:

- `factory-run`;
- `factory-observe`;
- `factory-resume`;
- `factory-author-workflow`;
- `commit-finalization`;
- `memory-review`.

The startup prompt receives only compact descriptions. Full procedures load only after the user or task selects the operation.

## What our architecture designed better

### Security and containment

SSSF runs Pi and deterministic commands with the operator's full environment on the current checkout. It has no sandbox, branch-per-run, merge step or human approval phase. It checks repository writes only after an agent finishes. That cannot contain network, process, credential or external API effects and cannot restore dirty work already destroyed by `git checkout`; its source explicitly reports such a loss as unrecoverable.

Our design is better because:

- each run chooses one explicit containment owner;
- writer roles use disposable worktrees;
- profiles control tools, paths, credentials, network and MCP;
- permission-system asks on risky intent;
- sudo requires a focused human PTY;
- foreign harnesses get their own internal policy and containment;
- control-plane files are read-only and immutable for the session.

Take SSSF's post-phase diff check only as defense in depth inside a disposable worktree. Never call it a sandbox or rely on rollback to protect a dirty user checkout.

Source: [SSSF write enforcement](https://github.com/disler/super-simple-software-factory/blob/de31374882e7a4e3e5b7bb9bd09e69dc2f779356/.claude/skills/sssf/templates/adws/adw_modules/permissions.py).

### Capability truth and cache correctness

SSSF invalidates a resumed agent session when the model changes, but not when its system prompt, thinking level, tools, extensions, write scope, compaction policy, credentials or executor changes. It therefore lacks a complete session identity and can resume incompatible state or silently invalidate provider caches.

Our `SessionCapabilitySnapshot` and cache contract are stronger. `pi-factory` should reuse a child session only when the complete compatibility hash matches:

```text
provider/model/thinking
+ system prompt hash
+ ordered tool schema hash
+ skill catalog/selected skill versions
+ extension set hash
+ MCP export hash
+ permission/containment/executor hash
+ compaction policy hash
+ repository/worktree identity
```

### Tool ownership and context cleanliness

SSSF gives agents mostly Pi's generic built-ins plus a local subagent extension. It does not solve graph/LSP/RAG/MCP duplication or automatic context injection.

Our one-owner map remains superior:

- CodeGraph for relationships/impact;
- Pi Lens for exact LSP semantics and diagnostics, with auto context/fixes disabled;
- `ast-grep` through Bash for structural work;
- one explicit project RAG;
- `project_check` for correctness;
- Pi compaction only;
- RTK or narrow LeanCTX, never both;
- one lazy MCP proxy for remote/stateful services.

`pi-factory` must compile the appropriate subset for each phase. “Accessible to the workflow” never means “permanently visible to every model.”

### Repository validation

SSSF ships placeholder quality commands that exit zero and are therefore recorded as passed, although the output says they are placeholders. Its README acknowledges that an uncustomized test phase is theater. Our project-native `project_check` should refuse to advertise a level as valid unless real commands are configured and preflighted.

Also, SSSF's current `diff_matches_claims` only checks that claimed paths exist—it does not compare the claim to Git's actual diff. This is reported upstream in [issue #6](https://github.com/disler/super-simple-software-factory/issues/6). Our gate must compute both sets and reject omitted, extra, out-of-scope and untracked changes.

### User interaction and foreign harnesses

SSSF starts non-interactive Pi subprocesses with stdin disabled. It has no mid-run product questions, permission relay, attached shell or direct user takeover, and its Claude Code adapter is a stub.

Our attended/supervised/batch modes, tmux broker, structured question relay and per-harness adapters are necessary for a real closed loop. A workflow can pause in `waiting_for_user` without losing its process/session state, notify the user, and resume from the same phase after an answer.

### Git and completion discipline

SSSF's `commit_all()` stages every change and commits directly on the current branch using agent-proposed text. Our parent-owned finalizer is safer and more complete:

- one writer per worktree;
- exact staged-tree hash;
- fresh `project_check` receipt;
- documentation-impact decision;
- concise root changelog entry;
- deterministic hooks;
- compact validated commit subject;
- separate merge/push risk gates.

### Memory and continuity

SSSF resumes Pi sessions and saves handoff artifacts but has no project RAG, reviewed cross-session memory or explicit compaction ownership. Our separation remains correct:

- workflow state lives in the run database/artifacts;
- Pi-native compaction owns each child conversation;
- project RAG owns authoritative documents/decisions;
- Hermes later owns reviewed procedures/preferences/episodes.

The outer workflow must be resumable even if every model session is discarded. Conversation resumption is an optimization, not the source of truth.

## What to take, adapt or reject

| SSSF mechanism | Decision | Our implementation |
| --- | --- | --- |
| Deterministic code owns the loop | Take | `pi-factory` outer runtime |
| Three phase lanes | Adapt | `human`, `agent`, `code`; gate verdicts remain typed records rather than a fourth execution owner |
| Typed Pydantic envelopes | Take and improve | One schema source generates validator and model instructions; version/hash every contract |
| Files plus small envelopes | Take | Hashed run artifacts and stable evidence IDs |
| Same-session parse/gate correction | Take | Bounded correction if full child compatibility hash is unchanged |
| Known commands as code | Take | General deterministic operation registry using our `Executor` |
| Run acceptance separate from phase success | Take | One atomic `finish_run()` controls DB/UI/exit status |
| SQLite/WAL event mirror plus raw JSONL | Take | Redacted append-only events and bounded raw artifacts; optional OpenTelemetry export later |
| Process table and killability | Take and extend | Every Pi/native/foreign/code process; private tmux sessions; reconciliation after crash |
| Role roster | Take and merge | `AgentProfileV1` is the roster; router resolves `modelClass` to a fixed route before spawn |
| Post-phase Git write check | Take as gate only | Compare actual diff to declared/permitted paths in a disposable worktree; never primary containment |
| Skill with lazy cookbooks | Take | Small `.agents/skills/factory-*` skills and Pi slash-command UI |
| Stamp full engine into every repo | Reject | Install versioned engine once; scaffold only thin repo workflow/config contracts |
| Manually synchronized output triad | Reject | Generate prompt/report schema from one contract definition |
| Placeholder checks that exit zero | Reject | Missing real checks are `unconfigured`, never green |
| Current-branch `git add -A` commits | Reject | Dedicated worktree, exact manifest/staging, parent finalizer and merge gate |
| After-the-fact permissions as safety | Reject | Immutable capability profiles + containment first; diff gate second |
| Resume based on model only | Reject | Resume only on full session compatibility hash |
| Full prompt in subprocess argv | Reject where avoidable | Pass bounded task via protected file/stdin/API supported by adapter; never record secrets in command lines |
| One Pi-only adapter | Extend | Pi native, Pi CLI, Claude Code, Codex CLI and verified Antigravity adapters under one contract |

## Proposed `pi-factory` architecture

```text
Pi UI / CLI / CI / Hermes coordinator
              │
              ▼
      pi-factory control API
  run · wait · answer · attach · cancel
              │
              ▼
   immutable RunManifest + worktree
              │
              ▼
 deterministic phase scheduler ─────► SQLite/JSONL/artifacts/UI
      │          │          │
      │          │          └── human pause/approval/question
      │          └── code phase → shared Executor → project_check/Git/etc.
      └── agent phase → profile compiler → Pi/native/foreign adapter
                                │
                                └── scoped CodeGraph/Pi Lens/RAG/MCP/skills
              │
              ▼
 typed envelope → gates → same-session correction or next phase
              │
              ▼
 final checks → docs/changelog → staged hash → commit → merge decision
              │
              ▼
 reviewed trace/evaluation → optional Hermes memory candidate
```

### Runtime ownership

`pi-factory` owns:

- run/phase state machine;
- retry and loop budgets;
- artifact/evidence registry;
- worktree lifecycle;
- process/session registry;
- typed envelope validation;
- gates and final acceptance;
- question/approval pause state;
- trace schema;
- adapter invocation;
- resume/recovery.

It does **not** own:

- filesystem/shell implementations;
- CodeGraph, LSP, RAG or MCP engines;
- conversation compaction;
- model permission decisions inside another harness;
- repository checks;
- long-term memory;
- Git policy wording.

Those remain the existing authoritative components.

## Contracts

### RunManifestV1

```yaml
runId:
workflowId:
workflowVersion:
requestHash:
mode: attended | supervised | batch
repositoryId:
baseSha:
worktreePath:
containmentProfile:
permissionProfileHash:
serviceRegistryHash:
createdBy:
createdAt:
budget:
  maxCost:
  maxWallTime:
  maxAgentTurns:
  maxRepairLoops:
```

### PhaseSpecV1

```yaml
id:
kind: human | agent | code
owner:
description:
inputContract:
outputContract:
profileRef:
operationRef:
requires: []
gates: []
retryPolicy:
onPass:
onFail:
```

### PhaseResultV1

```yaml
executionStatus: success | failure | blocked | cancelled
verdict: pass | fail | not_applicable
summary:
claims: {}
changedFiles: []
artifacts: []
evidence: []
questions: []
nextHints: []
usage: {}
sessionCompatibilityHash:
```

### GateReportV1

```yaml
gateId:
passed:
checks:
  - item:
    passed:
    evidenceRef:
    message:
severity:
retryable:
```

The workflow engine stores full objects. Models receive only the fields and references needed by their phase.

## Tool and profile use inside the loop

| Phase/role | Visible tools/services | Hidden or code-owned |
| --- | --- | --- |
| Intake/router | structured question, profile/workflow catalog metadata | all code intelligence, shell and writes |
| Scout | read/grep/find/ls; CodeGraph; optional Pi Lens navigation; explicit RAG search/get; `ast-grep` through read-only Bash | write/edit, commit, memory writes, foreign delegation unless workflow explicitly permits |
| Planner | scout evidence, bounded CodeGraph/RAG references, structured question if attended | repository mutation, Git commit, broad MCP |
| Builder | Pi read/edit/write/Bash; Pi Lens diagnostics/navigation; `ast-grep`; selected knowledge refs; optional `project_check fast` | CodeGraph if plan already contains evidence; memory writes; Git commit; unrelated MCP |
| Deterministic checks | shared `Executor`, `project_check`, changed-file tracker, artifact store | no model-visible tool schema |
| Reviewer | read-only diff/spec/evidence; CodeGraph impact; Pi Lens diagnostics; `project_check` receipt | edit/write/Bash where avoidable; commit; memory write |
| Researcher | web/browser evidence, RAG, selected remote MCP | repository writes and local shell unless required |
| Finalizer | staged diff/manifest, docs rules, changelog generator, `project_check release`, Git preparation | arbitrary code editing and child delegation |
| Memory evaluator | redacted accepted-run evidence and user corrections | raw secrets, transient failed hypotheses, direct production skill/policy mutation |

This preserves our context rule: tools are available to the *workflow system* but exposed only to the phase that needs them.

## Closed-loop `implement` workflow

1. **Intake:** normalize the request into `TaskEnvelopeV1`; ask only unresolved product questions.
2. **Preflight:** validate workflow, profiles, model/provider credentials, commands, services, repository checks, worktree and budgets before any agent starts.
3. **Worktree:** create a dedicated branch/worktree and immutable run manifest; select containment once.
4. **Recon:** run read-only CodeGraph/Pi Lens/RAG/grep/ast-grep scouts, parallel only where evidence domains are independent.
5. **Plan:** produce typed acceptance criteria, intended paths, required checks, risks and evidence references.
6. **Human gate:** only for ambiguity, risky scope or explicitly attended workflows; batch mode fails blocked rather than waiting.
7. **Build:** route to a fixed Pi/Claude/Codex specialist profile; pass plan and evidence references, not parent transcript.
8. **Scope gate:** compare actual worktree diff with declared and permitted paths; abort on control-plane or containment breach.
9. **Fast checks:** run `project_check fast` as code. On failure, send structured failure/tail/artifact references back to the same builder session.
10. **Semantic review:** an independent read-only model checks each acceptance criterion against code/diff/evidence.
11. **Revision loop:** bounded builder correction → scope gate → fast checks → reviewer. Any post-check write invalidates prior receipts.
12. **Full checks:** run configured full/release checks on the exact tree hash.
13. **Documentation/finalization:** determine documentation impact, update docs, prepend concise changelog, generate compact commit subject, then rerun affected checks.
14. **Completion gate:** require accepted review, fresh check receipt, no unresolved question/process, exact staged-tree hash, valid docs/changelog and permitted diff.
15. **Commit:** deterministic parent finalizer commits in the worktree. Push/deploy/merge remains a separate risk-gated operation.
16. **Return:** produce typed result with commit/patch, evidence, checks, cost, unresolved risks and attachable trace.
17. **Learn:** export only reviewed outcome/router/skill/memory candidates; never change production policy automatically.

## User and model interface

### User commands

```text
/factory list
/factory run implement <task>
/factory watch <run-id>
/factory attach <run-id> [phase]
/factory answer <run-id> <question-id>
/factory resume <run-id>
/factory cancel <run-id>
/factory inspect <run-id>
```

### Model-visible surface

Keep only two small stable tools in the trusted parent, or activate them once and retain them:

```text
factory_start(workflow, task, mode?, constraints?)
factory_wait(run_id, cursor?, timeout_ms?)
```

Questions and permissions surface through Pi UI events and user slash commands. Attach/cancel/profile administration are user commands, not generic model tools. Children cannot recursively start factories unless their profile explicitly grants a bounded workflow.

### Interaction states

```text
queued → running → waiting_for_user → running
                 ↘ blocked
running → accepted | failed | cancelled
```

Every `waiting_for_user` event has a question ID, requesting phase, choices/free-text contract, expiry/default behavior and attach target. Privileged password prompts never become question events; they require direct attended PTY focus.

## Cache and continuity behavior

- Each agent role/run is a separate cache island with a fixed compatibility hash.
- Task, phase input, evidence references and corrections are appended as user/tool messages.
- A gate correction continues the same session only when compatibility hash and worktree identity are unchanged.
- Pi-native compaction remains the sole conversation history writer within each Pi session.
- Phase envelopes and artifacts—not conversation summaries—are the durable workflow state.
- Foreign harness sessions follow their native compaction but return the same typed result contract.
- Restarting an agent from artifacts must remain possible; resuming model context is an optimization.
- The workflow engine never rewrites parent system prompts or toggles parent models/tools.

## Do not copy these SSSF weaknesses

1. **Fresh-install crash:** current `context_window()` reads `~/.pi/agent/models.json` before its advertised fallback; [issue #5](https://github.com/disler/super-simple-software-factory/issues/5).
2. **False diff gate:** `diff_matches_claims` checks only whether claimed files exist, not the actual diff; [issue #6](https://github.com/disler/super-simple-software-factory/issues/6).
3. **Unreliable generic JSON output:** a real open report shows a scout failing to produce the required JSON; [issue #1](https://github.com/disler/super-simple-software-factory/issues/1). Structured-output handling needs adapter-specific support plus repair/fallback.
4. **Generated-code drift:** the current `make_adw.py` template returns `run.succeeded`, while the current runner exposes `run.finish()`. Generated workflows therefore need a test suite and versioned generator compatibility checks.
5. **Placeholder green checks:** placeholder commands exit zero; unconfigured validation can look successful.
6. **Unsafe checkout:** all agents inherit operator environment and work on the current branch; post-hoc rollback cannot restore destroyed pre-existing dirty work.
7. **Incomplete session identity:** only model changes invalidate an agent session.
8. **Prompt leakage:** task prompt is placed in the subprocess argv and may be visible to host process inspection.
9. **No human pause protocol:** stdin is disabled and there is no structured mid-run interaction.
10. **No factory self-tests:** the repository currently contains demo-app tests but no obvious committed unit/integration suite for its Python control engine.

These limitations do not invalidate the design pattern; they are why we take the pattern and integrate it with our stronger substrate rather than adopting the current repository as production infrastructure.

## Implementation sequence

### Phase A — Minimal local workflow core

Build after `pi-session-control`, the shared `Executor` and `project_check` exist:

1. `RunManifestV1`, `PhaseSpecV1`, `PhaseResultV1`, `GateReportV1`;
2. SQLite/WAL + JSONL/artifact store;
3. one phase context manager with atomic start/end/failure;
4. Pi CLI adapter using compiled `AgentProfileV1`;
5. schema validation and bounded same-session correction;
6. deterministic code-operation registry;
7. `inspect`, `plan` and `implement` workflows;
8. worktree and diff-scope gates;
9. run acceptance separate from phase execution;
10. CLI and headless tests before Pi UI integration.

### Phase B — Pi-native control surface

1. `/factory` commands and compact status/footer;
2. two stable model-visible tools (`factory_start`, `factory_wait`);
3. structured question/approval relay;
4. trace waterfall/detail UI;
5. `factory-run` and `factory-observe` lazy skills.

### Phase C — Native and foreign workers

1. native Pi/subagent adapter;
2. attachable Claude Code and Codex adapters through the tmux broker;
3. Antigravity only after its installed protocol/config is verified;
4. task-scoped MCP/skill exports;
5. crash reconciliation, timeout/cancel and input lease.

### Phase D — Evaluation and learning

1. per-phase cache/context/cost/quality metrics;
2. workflow and roster comparison reports;
3. deterministic model/harness router based on traces;
4. optional separate compaction summarizer evaluation;
5. Hermes memory/skill candidates after acceptance and review;
6. server workers only after local recovery and containment tests pass.

## Direct recommendation

Do not replace our plan with SSSF and do not merely add its visualizer.

Add a new central component—`pi-factory`—between the Pi/user surface and our phase-specific workers. Borrow SSSF's deterministic phases, typed envelopes, same-session corrections, gates, run acceptance, run IDs, artifact handoff and event schema. Implement them against our immutable capability compiler, one Executor, `project_check`, worktrees, containment, user-question broker, scoped intelligence services, foreign harness adapters and parent commit finalizer.

That creates the missing closed loop while preserving the clean architecture we designed: **code controls the workflow; profiles control capabilities; containment controls effects; models supply judgement; gates decide whether evidence is sufficient; the user can always inspect, answer, attach or stop.**
