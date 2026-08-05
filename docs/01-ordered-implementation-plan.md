# Ultimate Pi Agent Setup — Ordered Implementation Plan

Research and plan revision: 5 August 2026

Companion records: `ultimate-pi-architecture-decisions.md`, `ultimate-pi-risks-gaps-overlaps.md`, `ultimate-pi-brainstorm-evolution.md`, `ultimate-pi-sssf-comparison-and-closed-loop.md` and `ultimate-pi-documentation-index.md`. This file alone defines implementation order; unresolved or experimental ideas in the other records are not installation instructions.

## Outcome

Build a powerful but controlled Pi installation in layers. Each responsibility has one authority:

| Responsibility | Authority |
| --- | --- |
| Main interactive coding harness | Pi upstream |
| Intent approval | `@gotgenes/pi-permission-system` |
| Interactive PTY and sudo password entry | `pi-interactive-shell`, trusted-local main session only |
| Real containment | exactly one Gondolin/container/OpenShell boundary per profile |
| Structured user questions | `@juicesharp/rpiv-ask-user-question` |
| Current-task state | Pi conversation/plan by default; optional parent-only `@juicesharp/rpiv-todo` for long missions |
| Code architecture and impact | CodeGraph |
| Exact language semantics and edit diagnostics | Native Pi Lens in conservative mode; no self-MCP mirror or second LSP |
| Structural matching/codemods | `ast-grep` CLI |
| Project documents and decisions | One local RAG |
| Correctness | Repository checks through `project_check` |
| Closed-loop sequencing and acceptance | Deterministic `pi-factory` runtime; models are bounded phase workers |
| Commit/changelog/documentation finalization | Parent-only skill + preparation script + deterministic Git hooks |
| Conversation continuity | Pi compaction |
| Learned procedures/preferences | Hermes memory, later |
| Shell-output compression | RTK initially; LeanCTX only as a measured alternative |
| Delegation inside one harness | `@gotgenes/pi-subagents` + worktree companion |
| Foreign coding harnesses | Custom attachable session broker and external-agent adapter |
| External services | Lazy `pi-mcp-adapter` |

Do not install every layer at once. Complete the acceptance test for a stage before moving to the next one.

## The execution contract

The model should first lose tools it does not need, then permissions should approve the requested *intent*, and only then should an execution router choose the host or sandbox. A permission popup is not containment, while containment alone is not a pleasant approval experience.

```text
model
  -> role/profile tool visibility
  -> permission-system intent gate (allow / ask / deny)
  -> authoritative executor router (host OR sandbox)
  -> OS / VM / remote service enforcement
  -> bounded, structured result
  -> project_check evidence and completion gate
```

Every code path that can read, execute or mutate must join this chain. An extension that calls `node:fs`, `child_process`, a host LSP, an MCP server or a foreign CLI directly is outside a Gondolin tool router even when the built-in `bash` tool is safely routed.

For a composed autonomous run, an outer deterministic loop owns the sequence rather than the parent model:

```text
engineer/Pi parent
  -> immutable RunManifest + worktree
  -> pi-factory phase scheduler
  -> compiled child profile OR deterministic code operation
  -> typed result envelope + artifact/evidence references
  -> gates
  -> same-session correction, next phase, human pause, or fail
  -> one atomic run-acceptance decision
```

This outer loop never bypasses the execution contract above; each agent or code phase enters it independently.

### Tool placement, proxying and gates

“Proxy” below means preserve Pi's existing tool name and schema while changing its execution location. Add a new model-visible tool only when it represents a distinct semantic capability.

| Component | Visible surface | Trusted-local execution | Isolated execution | Gate and policy |
| --- | --- | --- | --- | --- |
| `read`, `grep`, `find`, `ls` | Keep the seven Pi built-ins | Host workspace | Same schemas proxied to Gondolin/whole sandbox | Permission path rules; guest paths canonicalized before policy checks |
| `write`, `edit` | Built-ins, or one hashline-compatible replacement | Host worktree | Gondolin/worktree; never a host fallback | Permission path rules; one owner of `read`/`edit`; completion evidence invalidated after writes |
| `bash` and user `!` | Existing `bash`; no per-CLI tools | Unprivileged host | Proxied to the guest | Permission Bash rules before dispatch; runtime boundary enforces effects |
| `interactive_shell` | One PTY tool, main agent only | Host, trusted-local only | Hidden; a future guest PTY must be a separate audited proxy | Permission alias parses `command`/`cwd`; risky and `sudo` commands ask |
| `ast-grep`, `rg`, Git, formatters, tests | Hidden behind `bash` | Host PATH | Must be installed in sandbox image and run there | Bash policy plus repository/worktree boundary |
| CodeGraph | One compact native bridge | Host index/broker | Run in sandbox, disable, or use a narrow read-only repo-relative broker | Read-only; reject arbitrary paths; never duplicate through MCP |
| LSP | Exactly one native LSP surface | Host only for trusted repositories | LSP and language server inside the sandbox, or disabled | Language servers may execute project code; never run two clients/servers for one responsibility |
| Knowledge RAG | `knowledge_search`, `knowledge_get` | Host service | Narrow host broker is acceptable | Read-only retrieval allowed; ingestion/writes slash-commanded or asked; no arbitrary host paths |
| `project_check` | One model tool | Calls executor service | Calls the same sandbox executor—never `child_process` on host | Declared repo checks only; no silent fixes |
| `pi-factory` | `/factory` UI plus at most `factory_start` and `factory_wait` in the trusted parent | Versioned outer engine; every writer gets a worktree | Same engine, but each phase uses the selected contained executor/profile | Engine owns sequence/evidence/acceptance, not permissions or effects; children cannot recursively start workflows by default |
| Questions/todos | `ask_user_question`; optional parent-only todo tool | In Pi process | In Pi process | Questions are not permissions; todos are not memory and must not auto-inject changing state |
| `@gotgenes/pi-subagents` | `subagent`, `get_subagent_result`, `steer_subagent` | In-process child sessions | Same executor/extensions; whole-process sandbox is strongest | Built-in allowlist plus permission frontmatter filters inherited extension tools; worktree companion for writers |
| Claude Code/Codex/Antigravity | One stable `agent_delegate` schema plus slash-command UI, not three raw tools | Dedicated worktree and persistent PTY session | Install/run each CLI in its own sandbox or inside the whole Pi sandbox | Every run is attachable and has a question channel; outer launch approval does not police internal commands |
| MCP | One lazy proxy by default | MCP server runs on host | Host MCP is outside Gondolin; expose only narrow remote APIs | Per-server/tool mutation rules; never generic host filesystem/shell MCP |
| RTK | No additional model tool; optional command rewrite | Host | Only if RTK is also installed in guest | Rewriting must never move execution back to host |
| Compaction/Hermes | Slash/lifecycle hooks; explicit memory lookup | Host service/state | Host broker or whole sandbox | One compaction writer; small explicit memory retrieval; no per-turn memory dump |
| Gondolin | No new model tools; `/gondolin` status only | Not loaded | Replaces all seven built-ins and `!` | Security boundary; mount/network/secret policy is authoritative |

### Extension trust rule

Pi packages execute with the privileges of the Pi process. Installing a package is equivalent to installing executable code, and a host Pi plus Gondolin only contains the operations that the Gondolin router actually delegates. Review and pin every extension; prefer `--ignore-scripts` where supported. Unknown project-local packages, settings, skills and language-server plugins must not be loaded from an untrusted repository.

---

## Stage 0 — Preserve state and create separate execution profiles

### 0.1 Back up existing configuration

Run from a normal user account, not root:

```bash
mkdir -p "$HOME/pi-setup-backup"
cp -a "$HOME/.pi" "$HOME/pi-setup-backup/pi-before-setup" 2>/dev/null || true
```

If the current Pi directory contains credentials, protect the backup:

```bash
chmod -R go-rwx "$HOME/pi-setup-backup"
```

### 0.2 Define profiles

Keep configurations physically separate so conflicting extensions cannot load together:

| Profile | Use | Process boundary | Sudo/PTY | Not loaded |
| --- | --- | --- | --- | --- |
| `trusted-local` | Daily work on repositories and dependencies you trust | Pi and tools on unprivileged host | `interactive_shell` available; one-shot `sudo` asks | Gondolin and other sandboxes |
| `isolated-local` | Unfamiliar code, generated build scripts, risky tests | Pi/auth on host; all seven built-ins and `!` routed to one Gondolin VM | Host PTY hidden; no host sudo | hashline unless merged into router, host LSP, raw external agents, generic MCP filesystem/shell |
| `isolated-readonly` | Audits, reviews, research over suspicious code | Read-only Gondolin mount or whole-process sandbox | None | write/edit and all mutating remote tools |
| `whole-sandbox` | Highly untrusted or autonomous local work | Whole Pi in `vmpi`, OpenShell, rootless Docker/Podman | No host sudo | Host-only extensions and credentials |
| `server-worker` | Hermes-launched unattended task | Ephemeral OpenShell/Gondolin/container/Daytona worker | None | interactive approval dependencies and shared mutable config |

Use separate Pi agent directories; copy only reviewed common configuration:

```bash
mkdir -p "$HOME/.pi/profiles/trusted" "$HOME/.pi/profiles/isolated"

PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" pi
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/isolated" pi
```

Small launcher scripts are safer than a runtime “mode” toggle because extension loading and tool ownership are decided at startup. Never stack sandbox runtimes: select exactly one containment authority for a session.

### 0.3 Compile and freeze the session contract

The launcher must compile one immutable `SessionManifestV1` before Pi starts. Models and extensions may consume this manifest but may not rewrite it:

```yaml
profile: trusted-local
executor: host
model: PROVIDER/MODEL_ID
thinking: medium
extensionSetHash: sha256:...
systemPromptHash: sha256:...
toolSchemaHash: sha256:...
skillCatalogHash: sha256:...
permissionPolicyHash: sha256:...
containmentPolicyHash: sha256:...
commandInventoryHash: sha256:...
compactionPolicyHash: sha256:...
cacheEpoch: 0
```

The manifest is the authority for capabilities and cache behavior. An automation may tighten a task grant, but it may not change containment, permission policy, provider/model, base system prompt, extension set, initial skill catalog or existing tool definitions. A user may deliberately choose another profile or model only by starting a replacement session. The old session remains auditable under its original hashes.

Add a small last-loaded `pi-cache-contract` extension for measurement and fail-fast diagnostics, plus a narrow launcher/SDK guard for enforcement. A normal extension can observe `model_select`, `before_agent_start`, `session_before_compact` and the final serialized `before_provider_request` payload, but Pi's public extension API does not provide a documented veto for every model change or every other extension's `setActiveTools()`/payload rewrite. Therefore detection can be Pi-native; strict prevention belongs at session construction or in a small reviewed Pi patch, not in prompt instructions.

#### Cache invariants and algorithmic response

| Component | Required invariant | Enforce algorithmically | Response to violation |
| --- | --- | --- | --- |
| Profile/containment | Executor, mounts, network and credential scope never change inside a session | Launcher freezes manifest; no model-visible switch/reload tool; control-plane files read-only to agent | Block; user starts a new session/profile |
| Permission system | Effective policy is read once at `session_start`; approvals change execution state only, never prompts/tools | Freeze merged config and hash; ignore on-disk changes until next session | Block reload; notify “effective next session” |
| Parent model | Provider/model/thinking remain fixed during an automated task | Router cannot call `setModel` on parent; monitor `model_select` | Automation blocked; explicit user switch starts a new cache epoch or preferably a new session |
| Base system prompt | Exact base prompt is stable; no clock, Git status, todo list, memory recap or task text is regenerated into it per turn | Hash the final system portion at every request; allowlist Pi-owned stable fields | Fail request in strict mode or warn and mark cache epoch broken |
| Tool schemas | Existing names, descriptions, JSON schemas and order never mutate | Canonical registration/load order; hash each definition and ordered active set | Block replacement/removal; require a new session |
| Dynamic tools | Activation is purely additive; loader remains active; a loaded tool is not removed in the same session | Guard `setActiveTools` in the SDK/session factory; verify provider/model deferred-tool support | Reject non-additive mutation; on native deferred loading keep the epoch, otherwise preactivate a fixed set or record one controlled epoch reset |
| Lazy tool prompt text | Dynamically loaded tools have no `promptSnippet` or `promptGuidelines` that rebuild the system prompt | Manifest linter rejects this metadata on lazy groups | Reject package/profile at startup |
| Skills | Name/description catalog is compiled once; full skill body is retrieved only when invoked | Capability-filter skills before launch; disable `/reload` for automation | Missing/incompatible skill prevents launch; changed skill applies next session |
| Dynamic task/context | Task, cwd, branch, changed files, retrieved facts and user answers are append-only user/tool messages, never system-prompt rewrites | Static `AgentProfileV1` plus dynamic `TaskEnvelopeV1`; final-payload prefix hash | Convert to message/tool result or block extension |
| Tool results | Compression/filtering happens before a result enters history; stored prior results are never rewritten | One ingestion pipeline stores compact result plus raw artifact reference | Reject retroactive pruner; intentional native compaction is the exception |
| RAG/Hermes | Retrieval is explicit and bounded; no changing memory dump in the system prompt | No automatic retrieval hook; per-call byte/token limits and IDs-first results | Drop excess; require explicit expansion |
| Subagents | Each child has a static role/profile and fixed model; task-specific data is its first user message | Compile child manifest before spawn; task grants only subtract capabilities | Refuse spawn if requirements unavailable |
| Foreign harnesses | Each run is a separate cache island with a fixed CLI/model/profile and bounded task packet | Session broker generates immutable launch spec and scoped config | Refuse in-place reroute; launch a new run |
| MCP | One stable proxy schema; server/tool discovery is lazy and additive; no eager per-server schema dump | Compile server allowlist; hash proxy schema; keep direct tools hidden | Refuse duplicate/direct exposure or non-additive swap |
| Compaction | Pi native compaction is the sole history writer and an explicit cache-epoch boundary | Only one `session_before_compact` owner; log summary/model/policy hashes | Allow controlled reset; reject competing history mutation |
| Runtime/provider payload hooks | Hooks may add stable headers/markers, but may not reorder or rewrite prompt history | Last-loaded final-payload hash guard and hook allowlist | Block profile in CI/smoke test; fail closed in strict runtime |

The key distinction is exact-prefix stability. Appending a normal user message, a tool result, a structured question or a retrieved document does not invalidate the already cached prefix. Rewriting the system prompt, an earlier message, tool schemas, tool order or serialized history does. Compaction intentionally replaces old history and therefore begins a new cache epoch; it is not treated as an accidental violation.

#### Component-specific cache policy

- `@gotgenes/pi-permission-system`: safe after its config is frozen. Session approvals must live outside the prompt and must not hide/reveal tools.
- `pi-interactive-shell`: its overlay, focus state and PTY output are UI/runtime state. Only bounded transferred output enters the conversation. Do not let its structured spawn feature rewrite the parent prompt.
- `@gotgenes/pi-subagents`: patch/profile it so the static parent prefix and role body precede dynamic cwd/branch/task data. Each child is its own cache island. Never smart-route by switching the parent model.
- `pi-mcp-adapter`: keep its single proxy tool stable for the session. Lazy server metadata is preferred to direct MCP tool toggling.
- RTK or another command-output filter: safe when transformation happens once before the tool result is appended and raw output remains in an artifact. Never rewrite historical results.
- LeanCTX: only its narrow pre-insertion read/output mode is eligible. Wire-history pruning, prompt rewriting, alternate compaction, automatic memory/context injection and tool replacement are prohibited in the normal profile.
- Hermes memory: explicit retrieval is append-only and cache-safe. Per-turn automatic memory text in the system prompt is prohibited; a tiny verified preference block may be compiled once at session start.
- Todo tools: widget state is harmless, but do not inject the changing todo list on every turn. Keep todo optional and parent-only; the tool schema/guidance stays static.
- `pi-tscg`, prompt optimizers and provider replacements: do not add by default. Any extension that rewrites schemas, system content or final provider payload must first pass a deterministic multi-turn prefix-hash test for every provider. Provider replacement carries high compatibility and maintenance risk.
- Deprecated provider-cache replacements such as `pi-better-messages-cache` are omitted for current Pi except for a proven provider-specific compatibility defect; replacing Pi's provider forfeits upstream transport, retry, thinking and cache fixes.

Expose `/cache-status` and a small footer only to the user. Report current epoch, stable-prefix hash, tool-schema hash, provider cache-read/write tokens when available, and the reason for the last epoch change. Do not expose a model tool for changing cache policy.

### 0.4 Threat-based profile selection

- Trusted repository and ordinary interactive edits: `trusted-local`.
- Unreviewed install/build/test scripts, downloaded repositories, or prompt-injected content: `isolated-local`.
- Review that must not change the checkout: `isolated-readonly`.
- Extension code itself is untrusted, or subagents/MCP/LSP must all be contained: `whole-sandbox`.
- Remote/unattended work: `server-worker`.

The repository mount is still real data. Gondolin's `/workspace` is write-through in the official example, so `rm` can delete host project files. Use a disposable Git worktree/checkpoint for write tasks; the VM protects the rest of the host, not the mounted worktree from intentional deletion.

### 0.5 Inventory and baseline

```bash
node --version
npm --version
git --version
rg --version
sg --version || ast-grep --version
pi --version 2>/dev/null || true
```

Record:

- current Pi version;
- current installed extensions;
- available model/provider logins;
- Claude Code, Codex CLI and Antigravity CLI versions;
- representative task cost, tool-call count and duration.

Do not enable project-local `.pi/settings.json` from an untrusted repository until it has been reviewed. Project settings have historically included execution-affecting fields.

**Exit condition:** the current configuration can be restored, launchers select distinct extension sets, a representative task has a baseline transcript/metrics record, and an intentional prompt/tool mutation is detected while an ordinary appended turn preserves the prefix hash.

---

## Stage 1 — Install and verify current upstream Pi

The maintained package is `@earendil-works/pi-coding-agent`; the older `@mariozechner/pi-coding-agent` package is deprecated.

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
pi --version
```

Start Pi once in a small test repository and verify built-ins:

- `read` reads a known file;
- `grep` finds a known symbol;
- `bash` runs `git status --short`;
- `edit` can make and then manually revert a harmless test change;
- `/reload` works;
- a long Bash result is truncated with a reference to the full spill file rather than flooding context.

Pi's built-in tool-result protection is truncation, not semantic compression: Bash is bounded and large full output is spilled locally. Keep this fail-safe even after installing an output compressor.

**Exit condition:** vanilla Pi is stable before third-party interception is introduced.

Sources: [Pi](https://pi.dev/), [extension API](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md), [tool truncation design](https://github.com/earendil-works/pi/issues/134).

---

## Stage 2 — Security policy, structured questions and optional task state

Permissions, the PTY and structured questions are baseline features. A dedicated todo system is optional and remains deferred until real long-task traces justify its prompt/tool surface.

### 2.1 Install one permission authority and one PTY

Pin the versions verified during implementation, then upgrade deliberately:

```bash
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:@gotgenes/pi-permission-system@20.9.1
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:pi-interactive-shell@0.13.0
```

Create the permission-system `config.json` in the package's installed extension directory for this profile. Start with “allow ordinary work, ask on risky actions, deny nothing explicitly”:

```json
{
  "$schema": "https://raw.githubusercontent.com/gotgenes/pi-packages/main/packages/pi-permission-system/schemas/permissions.schema.json",
  "permissionReviewLog": true,
  "doublePressToConfirm": true,
  "shellTools": {
    "interactive_shell": {
      "commandArgument": "command",
      "workdirArgument": "cwd"
    }
  },
  "permission": {
    "*": "allow",
    "path": {
      "*": "allow",
      "*.env": "ask",
      "*.env.*": "ask",
      "*.env.example": "allow",
      "~/.ssh/*": "ask",
      "~/.aws/*": "ask",
      "~/.gnupg/*": "ask"
    },
    "bash": {
      "*": "allow",
      "rm *": "ask",
      "rmdir *": "ask",
      "sudo *": "ask",
      "doas *": "ask",
      "su": "ask",
      "su *": "ask",
      "git clean *": "ask",
      "git reset --hard*": "ask",
      "git restore *": "ask",
      "git checkout -- *": "ask",
      "git push *--force*": "ask",
      "git branch -D *": "ask",
      "git stash drop*": "ask",
      "git stash clear*": "ask",
      "chmod -R *": "ask",
      "chown -R *": "ask",
      "truncate *": "ask",
      "dd *": "ask",
      "mkfs*": "ask",
      "docker system prune*": "ask",
      "docker volume rm *": "ask",
      "kubectl delete *": "ask",
      "terraform destroy*": "ask",
      "claude *": "ask",
      "codex *": "ask",
      "antigravity *": "ask",
      "sh": "ask",
      "bash": "ask"
    },
    "external_directory": {
      "*": "ask",
      "/tmp/*": "allow",
      "/var/tmp/*": "allow"
    }
  }
}
```

Rules are last-match-wins, so broad allow rules precede the risk patterns. This is an ergonomic intent gate, not a complete shell parser or security boundary: wrapper commands such as `env`, `xargs`, `find -exec`, `bash -c` and `sudo` are conservatively floored to `ask`, and a headless prompt can fail closed even though no explicit rule says `deny`.

This configuration intentionally does **not** deny removal. It asks, shows the concrete action, requires confirmation, and then allows it. It also avoids a giant positive command whitelist. Add a rule only after real traces show an ordinary command asks too often or a risky family slipped through.

At a prompt, approve once for an exceptional action or approve the suggested bounded pattern for the rest of the session when the operation will repeat. Session approvals disappear with the session, avoiding a permanent whitelist without asking on every identical call. Keep `permissionReviewLog` protected (`chmod 600` on its files); command/path previews can themselves be sensitive.

### 2.2 Sudo workflow

`pi-permission-system` decides whether `sudo ...` may be attempted. `pi-interactive-shell` supplies a real PTY in which *you* type the password. Neither package should receive or store the password in the conversation.

Safe flow:

1. Pi proposes one exact `sudo <command>` through `interactive_shell`.
2. Permission-system asks once for that command.
3. After approval, the PTY displays the native password prompt.
4. Type the password directly into the terminal; Pi sees command output, not a chat-provided password.
5. Exit when the one command completes.

Never use `sudo -S`, paste a password into chat, grant a persistent root shell, or approve `sudo sh`, `sudo bash`, `sudo -s` or `sudo -i`. Test the integration harmlessly with `sudo -k && sudo true` and confirm that both the policy prompt and PTY password prompt appear. In `isolated-local`, the host interactive shell is hidden: guest dependency installation belongs in the sandbox image, and Gondolin must never proxy guest `sudo` to the host.

### 2.3 Why not `pi-safe-shell` in the main profile

`pi-safe-shell` is an alternative shell/edit safety policy. Running it beside permission-system and interactive-shell creates two competing decisions for Bash, writes, edits and PTY behavior; mismatched parsing causes duplicate prompts or surprising blocks. Keep it disabled in the normal profile. If its stricter behavior is useful for an audit, put it in a separate profile with permission-system removed, then compare traces. `pi-interactive-shell` is not a competing policy—it provides PTY mechanics and should be registered as a shell alias in the permission system as shown above.

Sources: [permission-system package](https://www.npmjs.com/package/@gotgenes/pi-permission-system), [permission-system source and documentation](https://github.com/gotgenes/pi-packages/tree/main/packages/pi-permission-system), [`pi-interactive-shell`](https://pi.dev/packages/pi-interactive-shell).

### 2.4 Install structured user questions; defer todo

```bash
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:@juicesharp/rpiv-ask-user-question
```

Restart Pi and test one single-choice and one multiple-choice question from the main session. Later, test the same flow from a direct subagent before depending on child-to-user questioning.

Keep these concepts separate:

- product/design question → `ask_user_question`;
- permission for a side effect → permission system;
- current work state → the parent conversation/plan initially; optional parent-only todo after measurement;
- long-term knowledge → RAG/Hermes.

If tasks repeatedly cross compaction, involve four or more independently verifiable steps, or require durable dependency tracking, trial `@juicesharp/rpiv-todo` in the trusted parent only. Configure one short guideline, do not auto-inject the changing todo list every turn, and do not give children separate todo stores. The parent remains the sole task-state owner.

The RPIV packages are actively maintained but young and single-maintainer. Smoke-test their loading after every upgrade because the monorepo has previously had dependency-layout issues.

Sources: [RPIV monorepo](https://github.com/juicesharp/rpiv-mono), [todo](https://github.com/juicesharp/rpiv-todo), [question tool](https://pi.dev/packages/%40juicesharp/rpiv-ask-user-question).

**Exit condition:** ordinary commands run without prompts, every tested risky family asks once, `sudo` accepts a password only through the PTY, dangerous actions are still contained by the selected profile, and questions are structured without becoming permission prompts.

---

## Stage 2.5 — Add isolation as a separate, tested profile

### 2.5.1 Start from Pi's official Gondolin example

There is no published npm package named `pi-gondolin`. The current integration is an official Pi example extension that depends on `@earendil-works/gondolin`. Audit and pin a Pi commit before copying it:

```bash
git clone https://github.com/earendil-works/pi.git "$HOME/src/pi"
cd "$HOME/src/pi"
git checkout <REVIEWED_PI_COMMIT>
cp -R packages/coding-agent/examples/extensions/gondolin \
  "$HOME/.pi/profiles/isolated/extensions/gondolin"
cd "$HOME/.pi/profiles/isolated/extensions/gondolin"
npm install --ignore-scripts

cd /path/to/disposable-worktree
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/isolated" \
  pi -e "$HOME/.pi/profiles/isolated/extensions/gondolin"
```

Requirements are Node.js 23.6 or newer and QEMU. Install QEMU through the OS package manager; use the Stage 2 interactive PTY for the one approved `sudo apt install ...` command if necessary. The first boot downloads guest assets, so expect hundreds of megabytes of disk/network activity and a resident QEMU process while the session is open.

Install only host-safe UI/policy packages in the isolated profile—no interactive shell:

```bash
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/isolated" \
  pi install npm:@gotgenes/pi-permission-system@20.9.1
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/isolated" \
  pi install npm:@juicesharp/rpiv-ask-user-question
```

Copy the reviewed intent policy, but let the custom guest/host path mapper translate `/workspace` before `external_directory` checks. Verify extension load order: permission hooks must see the original tool call, and Gondolin must remain the sole implementation of all seven built-ins.

The official example eagerly starts a VM at session start, mounts the host CWD read-write at `/workspace`, overrides `read`, `write`, `edit`, `bash`, `grep`, `find` and `ls`, and routes user `!` commands. That is excellent schema-preserving proxying—zero extra model-visible tools—but it is a starting example, not the final policy.

The inspected example focuses on tool routing and does not configure the explicit `createHttpHooks` allowlist/secret policy required by this plan. Do not label the stock copy “hardened” merely because commands run in a VM.

### 2.5.2 Build a thin audited policy fork

Create `pi-gondolin-profile`, a small local extension derived from the example. Keep the seven original tool names and `/gondolin` status command, but add a reviewed configuration contract such as:

```json
{
  "version": 1,
  "workspace": {
    "guestPath": "/workspace",
    "mode": "read-write-worktree"
  },
  "network": {
    "default": "deny",
    "allowedHosts": [
      "registry.npmjs.org",
      "github.com",
      "api.github.com"
    ]
  },
  "secrets": {},
  "limits": {
    "memoryMb": 1024,
    "cpus": 2,
    "commandTimeoutMs": 600000
  },
  "guestPathMap": {
    "/workspace": "$HOST_CWD"
  }
}
```

This file is a planned wrapper contract, **not** a configuration format supported by the stock example. Implement it with Gondolin's `createHttpHooks`, VFS providers and VM options. Requirements:

- deny network by default and revalidate redirects;
- allow only exact required hosts, not broad wildcard internet;
- block internal/private ranges unless a named local service is intentionally mapped;
- use Gondolin secret placeholders bound to specific hosts; never put real credentials in guest environment variables or mount `.env`, `~/.ssh`, `~/.aws` or a host agent socket;
- support read-only and read-write-worktree mounts; never mount the home directory or container socket;
- canonicalize guest `/workspace/...` to the host worktree before the permission system evaluates `external_directory` and path rules;
- expose no generic host RPC, TCP forwarding or SSH backchannel by default;
- route `project_check` and any process manager through the same `Executor` instance;
- fail closed if the VM or proxy is unavailable—never silently run the command on host.

An allowed network host can receive any data visible inside the VM. Host allowlisting therefore limits destinations but is not content-aware exfiltration protection. Keep credentials outside the guest and minimize the mounted data set.

### 2.5.3 What remains outside the VM

With host Pi plus the Gondolin extension, extension code still runs on the host. Only delegated operations are contained. The isolated profile must therefore apply this explicit policy:

- hide `interactive_shell`; a future guest PTY must talk to the VM, never spawn a host shell;
- run CodeGraph and LSP in the guest, replace them with narrow read-only brokers, or disable them;
- allow only the two read-only RAG calls through a host broker;
- make `project_check` use `GondolinExecutor`;
- omit RTK unless its binary is installed in the image and rewriting stays in the guest;
- omit hashline because both extensions replace `read`/`edit`, unless hashline semantics are merged into the Gondolin router;
- do not expose generic filesystem/shell MCP servers; host MCP servers are outside the VM;
- do not launch Claude Code, Codex CLI or Antigravity on the host from this profile;
- verify that every Pi subagent receives the same router. If this cannot be proven, use a whole-process sandbox for subagent work.

### 2.5.4 Choose the containment engine by need

| Option | Best use | Advantages | Important limits | Decision |
| --- | --- | --- | --- | --- |
| Audited Gondolin Pi router | Balanced local isolation while keeping provider auth/UI on host | Hardware VM; mediated filesystem/network/secrets; preserves built-in schemas | Other host extensions are not contained; Alpine/custom-image work; RW mount remains destructible | Recommended `isolated-local` after the fork is tested |
| `@the-agency/vmpi@0.4.1` | Whole Pi and all extensions inside a local Gondolin VM | Coherent boundary, full PTY, network allowlist, fast checkpoint resume | Young; Linux-tested; older Gondolin dependency; mounts host `~/.pi` read-only, so audit auth exposure; image must contain all extensions/CLIs | Strong trial for `whole-sandbox`, not automatic promotion |
| `@nqbao/pi-sandbox@0.1.3` | Lightweight daily Linux/macOS containment | Bubblewrap or `sandbox-exec`; little VM overhead; fails closed without backend | Young; custom host extensions still bypass it; weaker boundary than a VM | Optional alternative when QEMU cost is unacceptable |
| `pi-sandbox@0.5.0` | Standalone policy experiment | Prompts on unknown domains/paths | Duplicates permission-system prompts and policy; inspected coverage is not a clean fit | Do not combine with this stack |
| `pi-container-sandbox@0.2.2` | Disposable experiment | Familiar Docker/Apple-container model | Inspected version overrides only `read`/`write`/`edit`/`bash`; current `grep`/`find`/`ls` can remain host | Avoid until all built-ins are covered |
| Rootless Docker/Podman | Simple whole-process fallback | Mature, transparent, all extension code inside | Provider credentials/config enter container unless proxied; coarser policy | Good fallback |
| NVIDIA OpenShell | Remote/server or maximum-policy worker | Whole-process FS/process/network/credential/inference policy; Pi image available | Gateway and policy administration; still rapidly evolving | Preferred future server evaluation |
| Daytona | Remote branch/workspace jobs | Ephemeral remote environments and branch synchronization | External service/GitHub workflow dependency | Specific remote projects only |

For `vmpi` testing:

```bash
npm install -g @the-agency/vmpi@0.4.1
cd /path/to/disposable-worktree
vmpi setup
vmpi status
vmpi
```

For OpenShell later:

```bash
uv tool install -U openshell
openshell sandbox create --name pi-sandbox --from pi -- pi
```

Do not install multiple entries from this table into the same Pi profile. The permission system may remain as the human-facing intent gate, but exactly one runtime owns containment and one extension owns each built-in tool.

### 2.5.5 Isolation acceptance tests

Run against a disposable worktree with dummy secrets:

1. All seven built-ins and `!pwd` report `/workspace`; no built-in touches the host directly.
2. Reading the host home, SSH directory and a sibling repository fails at the runtime boundary.
3. A write under `/workspace` reaches only the disposable worktree; read-only mode blocks it.
4. An unallowlisted HTTPS request and redirect fail; an allowlisted package/document request succeeds.
5. The guest receives a placeholder, not a real secret; the allowed upstream receives the injected credential.
6. A risky guest command asks once, then runs in the guest; cancellation runs nowhere.
7. `interactive_shell`, host LSP, generic MCP shell/filesystem and raw external-agent tools are absent.
8. Killing QEMU produces a visible failure and never a host fallback.
9. A subagent cannot bypass the guest; if it can, disable subagents in this profile and use `vmpi`/OpenShell.
10. VM and child processes terminate when the session ends.

Sources: [Pi containerization guide](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/containerization.md), [official Gondolin example](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/gondolin), [Gondolin repository](https://github.com/earendil-works/gondolin), [security design](https://earendil-works.github.io/gondolin/security/), [limitations](https://earendil-works.github.io/gondolin/limitations/), [`vmpi`](https://pi.dev/packages/%40the-agency/vmpi), [`@nqbao/pi-sandbox`](https://pi.dev/packages/%40nqbao/pi-sandbox), [OpenShell quickstart](https://docs.nvidia.com/openshell/get-started/quickstart).

**Exit condition:** the selected isolated profile passes all tests, the trusted profile remains unaffected, and the tool-surface snapshot proves there is one owner per built-in.

---

## Stage 2.6 — Build the immutable capability and cache control plane

This is the first custom component because every later specialist, skill, MCP server and foreign harness depends on an accurate capability snapshot.

Build four small modules as one package, `pi-session-control`:

1. `profile-compiler` — resolves the selected execution profile, extension set, containment, model, credentials and permission policy before Pi starts;
2. `capability-compiler` — computes `available in executor ∩ profile ∩ specialist role ∩ task grant`; task grants may only remove capabilities;
3. `skill-capability-filter` — includes skill name/description only when its declared commands, tools, files, MCP servers and profile are available;
4. `pi-cache-contract` — records system/tool/skill/policy hashes and detects accidental prompt-prefix mutation.

The frozen `SessionCapabilitySnapshot` contains:

```yaml
profile:
executor:
model:
commands: []
tools: []
skills: []
mcpServers: []
repositoryChecks: []
policyHash:
capabilityHash:
cacheEpoch:
```

Command availability is checked inside the selected executor, not on the host. Reuse the permission system's shell parser to extract statically identifiable command heads, resolve each with `command -v`, and reject a known-missing command before execution with a structured `COMMAND_UNAVAILABLE` result and valid alternatives. Convert a genuine exit `127` similarly. Commands constructed dynamically and not safely resolvable may still execute under the broad trusted policy; do not pretend static analysis is complete.

Patch the permission integration so configuration is read, merged, validated and frozen at `session_start`. A disk change produces “effective next session” and never changes an active session. Models and automation receive no `reload_permissions`, `switch_sandbox`, `switch_profile` or equivalent control-plane tool. A user-facing profile switch waits for idle, terminates the current runtime and launches a new process/session with a new snapshot.

The cache guard runs last and compares the base system prompt, ordered tool schemas, skill catalog, provider/model, compaction policy and final serialized prefix to the frozen manifest. It may detect through Pi hooks, but strict prevention of another extension's `setActiveTools`, `setModel` or payload rewrite requires a narrow SDK/session-construction guard; do not rely on a prompt or an observer alone.

Project skills use `.agents/skills/` as the canonical cross-harness location. Pi receives only name and precise description at startup and reads the full `SKILL.md` on demand. Selected skills are mirrored or exported to a foreign harness only when that harness supports them and the task requires them. No session reload is used for task-specific skill discovery.

Skill authoring budgets and layering (August 2026 review): descriptions target ≤ 100 tokens; bodies target ≤ 5k tokens; supporting material goes into referenced files loaded on demand (third disclosure level), not into the body. Scope precedence is explicit: project (`.agents/skills/`) overrides user overrides global; a skill from an untrusted repository is never auto-loaded (see extension-trust rules above). Skills carry knowledge and judgment, never control flow — imperative multi-step sequencing in skill prose is a lint error (ADR-032, R-080).

**Exit condition:** unavailable commands/skills/tools prevent a specialist from launching; ordinary available commands are not repeatedly prompted; policy/config edits do not affect the active runtime; a deliberate test mutation is detected while an ordinary append-only turn preserves its prefix hash; and the measured startup context cost of the skill catalog equals metadata only — progressive disclosure is verified by token measurement, not assumed from the file format.

---

## Stage 3 — Install code intelligence without duplication

### 3.1 Install CodeGraph

```bash
npm install -g @colbymchenry/codegraph
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:@vndv/pi-codegraph
```

For each project:

```bash
cd /path/to/project
codegraph init -i
```

CodeGraph owns:

- symbol relationships;
- callers/callees;
- architectural exploration;
- execution relationships;
- blast-radius and impact analysis.

Do not install GitNexus or another code graph alongside it. CodeGraph already watches project changes, so a second graph means a second index, watcher and conflicting model tool surface.

In `trusted-local`, the index and bridge may run on the host. In `isolated-local`, do not pretend the bridge is contained: either bake CodeGraph into the guest, disable it, or expose a narrow host broker that accepts only repo-relative symbolic queries and returns read-only structured results. Do not let the model pass arbitrary host paths to that broker.

Source: [CodeGraph](https://github.com/colbymchenry/codegraph), [Pi bridge](https://pi.dev/packages/%40vndv/pi-codegraph).

### 3.2 Use Pi Lens as the single native LSP/diagnostics integration

The chosen native integration is Pi Lens, not Pi Lens MCP and not a second standalone Pi LSP:

```bash
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:pi-lens@3.8.71
```

Pin the version reviewed during implementation; the package is active and changes quickly. Start in conservative, cache-clean mode at `~/.pi-lens/config.json`:

```json
{
  "widget": { "visible": true },
  "format": { "enabled": false },
  "actionableWarnings": {
    "enabled": true,
    "includeLspCodeActions": true,
    "deltaOnly": true,
    "autoFix": { "enabled": false, "maxFixes": 0 }
  },
  "contextInjection": { "enabled": false }
}
```

This keeps native LSP diagnostics/navigation, cached findings, health/status and read-coverage mechanics while disabling automatic context injection, formatting and quick-fix mutation. Repository-native formatter/linter/compiler/test commands remain authoritative through `project_check`.

Pi Lens owns:

- exact definitions, references, hover, types, code actions and rename;
- per-file LSP diagnostics and conservative diagnostic triage;
- optional read-coverage/read-guard feedback;
- LSP process lifecycle in `trusted-local`.

CodeGraph still owns cross-file architecture, dependency relationships and impact analysis. `ast-grep` CLI still owns structural codemods. The capability compiler should establish the initial active surface before the first request and hide Pi Lens project-graph/identifier-search and AST-replace tools that duplicate those authorities. Permit additive activation of `lsp_navigation` when supported, but do not permit the loader to activate overlapping graph or write tools in the balanced profile.

Do not connect Pi Lens's MCP mirror back into the same Pi instance. It exists for other hosts or workers that lack the native lifecycle integration. Do not install `@narumitw/pi-lsp` or another LSP MCP server beside Pi Lens.

Language servers and project plugins can execute project code. Pi Lens is therefore host-only in `trusted-local`. For unfamiliar code, run Pi Lens and its servers inside a whole-process sandbox, build a narrow guest transport, or omit it; routing Bash into Gondolin does not contain the host extension or language-server process.

Sources: [Pi Lens](https://github.com/apmantza/pi-lens), [configuration](https://github.com/apmantza/pi-lens/blob/master/docs/globalconfig.md), [agent tools](https://github.com/apmantza/pi-lens/blob/master/docs/agent-tools.md).

### 3.3 Keep structural and lexical search as CLIs

Use:

```bash
rg 'literal-or-regex' .
sg run --pattern 'STRUCTURAL_PATTERN' --lang typescript
```

Do not expose a dedicated permanent model tool for every `rg` or `ast-grep` operation. Pi's Bash tool is sufficient, and repository-local `sgconfig.yml` remains authoritative for codemods/rules. In an isolated profile, these binaries and repository-native toolchains must exist inside the selected image; a host-side fallback would break the boundary.

### 3.4 Add a short routing policy

Place a concise project instruction in the repository's chosen agent-guidance file:

```markdown
## Project intelligence

- Use grep for literal text and known filenames.
- Use LSP for exact definitions, references, types, diagnostics and code actions.
- Use CodeGraph for architecture, dependencies, callers/callees and impact.
- Use ast-grep for syntax-shaped search and codemods.
- Use knowledge search for documentation, decisions and historical knowledge.
- Use repository checks, not inferred confidence, to validate work.
```

**Exit condition:** five representative questions route correctly: literal search, definition, references, caller chain and structural pattern.

---

## Stage 4 — Connect one explicit knowledge RAG

The RAG owns prose and durable project knowledge, not current source-code structure.

Expose only a compact retrieval interface:

```text
knowledge_search(query, scope?, filters?, limit?)
knowledge_get(ids, max_chars?)
```

Keep writing/promotion behind a slash command or an approval-gated tool initially:

```text
/knowledge-store
```

Recommended result shape:

```json
{
  "results": [
    {
      "id": "adr:payments:0007",
      "title": "Webhook idempotency decision",
      "score": 0.84,
      "scope": "project",
      "source": "docs/adr/0007.md",
      "preview": "..."
    }
  ]
}
```

Rules:

- return previews, provenance and stable IDs;
- expand only selected records;
- never inject retrieved passages every turn;
- exclude secrets, build output and generated dependencies;
- do not index source code merely to duplicate CodeGraph/LSP;
- do not add another vector/graph memory system.

If the RAG already exposes MCP, connect it later through the lazy MCP adapter. If lifecycle hooks or project scoping are needed, build a two-tool Pi-native adapter around the existing engine rather than replacing the engine.

The RAG may remain a host service in `isolated-local` because its contract is narrow and read-only. The broker—not the model—chooses indexed collections and resolves IDs. It must not accept arbitrary filesystem paths or shell fragments. Knowledge ingestion, deletion and promotion remain hidden behind `/knowledge-store` or a permission-gated administrative tool.

**Exit condition:** queries for a design decision retrieve its authoritative document, while a symbol caller query still routes to CodeGraph.

---

## Stage 5 — Build the first correctness component: `project_check`

Do this before output compression, autonomous goals or external agents.

### 5.1 Project configuration

Create `.pi/project-check.json` in each repository:

```json
{
  "version": 1,
  "checks": {
    "fast": [
      { "name": "format", "command": "pnpm format:check" },
      { "name": "typecheck", "command": "pnpm typecheck" }
    ],
    "full": [
      { "name": "lint", "command": "pnpm lint" },
      { "name": "test", "command": "pnpm test" },
      { "name": "build", "command": "pnpm build" }
    ]
  }
}
```

Replace commands with repository-native commands. Do not guess missing scripts.

### 5.2 Tool contract

Expose one tool:

```text
project_check(scope="changed|repository", level="fast|full|release")
```

Internally, `project_check` must depend on one `Executor` interface, not call host `child_process` directly:

```ts
interface Executor {
  run(argv: string[], options: { cwd: string; timeoutMs: number }): Promise<RunResult>;
}

// Selected once when the profile starts:
// HostExecutor | GondolinExecutor | ContainerExecutor | RemoteWorkerExecutor
```

It must:

- run declared commands without a shell when practical;
- capture full stdout/stderr in bounded local artifacts;
- parse structured compiler/linter/test output where available;
- return exit code, duration, compact failures and artifact references;
- record which Git tree and changed-file set was validated;
- invalidate success when files change afterward;
- never silently fix files.

This same executor becomes the common choke point for validation, later output compression, process tracking and the external-agent adapter. A Gondolin session must map guest `/workspace` back to the canonical host worktree before permission path checks and evidence recording.

Later, the completion gate reads this evidence. The model cannot mark a todo complete merely because it edited a file.

**Exit condition:** intentional format, type and test failures are reported compactly and exact raw output can be expanded.

---

## Stage 6 — Measure baseline usage

Before changing Pi's core read, Bash or edit paths, run 20–30 real tasks and record:

- input/output tokens;
- repeated reads of unchanged files;
- Bash results exceeding 5 KB and 50 KB;
- raw-output reruns;
- failed/stale edits;
- CodeGraph/LSP/RAG usage and misroutes;
- validation failures after claimed completion;
- session-compaction quality;
- model/provider used;
- elapsed time and user corrections.

Optional observability:

```bash
pi install npm:@braintrust/pi-extension
```

Only enable external tracing for repositories whose prompts, code and tool results are safe to transmit. Otherwise implement local JSONL tracing.

**Exit condition:** optimization decisions are based on actual traces.

---

## Stage 6.5 — Build the deterministic closed-loop runtime

Our earlier design assigned every capability an owner but did not define one executable program that composes those owners into a repeatable task loop. Build `pi-factory` after the capability compiler, shared `Executor` and `project_check`; use SSSF's phase/envelope/gate pattern as a source reference, not as an installed production dependency.

The engine is a reusable CLI/library. A thin Pi-native extension supplies lifecycle/UI integration. Repositories contain only workflow/profile references and repository-native check/documentation policy—not a copied mutable implementation of the engine.

### 6.5.1 Core contracts

Define and version:

```text
RunManifestV1
PhaseSpecV1
PhaseResultV1
GateReportV1
ArtifactRefV1
SessionCompatibilityV1
```

Every agent output has one source schema. Generate runtime validation and the compact model-facing report contract from it; do not maintain separate handwritten type, prompt example and call-site versions.

The complete session compatibility hash includes provider/model/thinking, static role prompt, ordered tool schemas, selected skills/extensions, MCP export, permission/containment/executor, compaction policy and worktree identity. Continue a Pi session only when this hash is unchanged.

### 6.5.2 One phase primitive

Support three execution owners:

| Kind | Owner | Meaning |
| --- | --- | --- |
| `human` | user/operator | Intake, answer, approval or explicit risk decision; may pause the run |
| `agent` | compiled `AgentProfileV1` | Judgement work through Pi, a native child or a foreign-harness adapter |
| `code` | named deterministic operation | Executor-backed checks, Git, snapshots, diff capture, artifact processing and finalization |

Every phase starts pessimistically, records a required intent description, produces a typed result and ends as `success`, `failure`, `blocked` or `cancelled`. Its semantic verdict is separate: a test or review phase can execute successfully while returning `fail`.

Only `finish_run(accepted, reason)` sets final database status, UI result and process exit code.

### 6.5.3 Handoffs, corrections and gates

Large context travels through run-scoped hashed artifacts; small typed envelopes carry summaries, claims, changed paths, evidence IDs and next-step hints. The next agent receives selected envelope fields and references, not the upstream transcript.

When JSON/schema parsing or a retryable mechanical gate fails, append exact structured violations to the same child session and retry within a fixed budget. Cold-start only when the child compatibility hash changed, the session is corrupt, containment failed, or the workflow deliberately launches a challenger.

Initial gates:

- output schema and artifact existence/hash/type;
- actual Git diff versus declared and permitted paths, including untracked files;
- no control-plane path changes;
- fresh `project_check` receipt for the current tree hash;
- reviewer evidence for every acceptance criterion;
- no unresolved process, question or approval;
- documentation/changelog/commit rules;
- final staged tree equals the validated tree.

A permission, credential or containment breach aborts; it is not sent back to the model as a repairable gate.

### 6.5.4 Durable state and observability

Use one local SQLite database in WAL mode as the queryable event mirror and append-only JSONL/artifacts as the recoverable raw record. Record:

- runs, phases, attempts and dependencies;
- agent sessions and full compatibility hashes;
- processes/tmux sessions, start/end/heartbeat and cancellation;
- typed envelopes and gate item evidence;
- artifact metadata/hashes/retention;
- worktree/base/tree/staged/commit identities;
- input, output, reasoning, cache-read and cache-write tokens/cost separately;
- context occupancy, compaction events and retrieval/injection sizes;
- permissions/questions/user corrections and final acceptance.

Redact secrets and cap raw content. UI state never enters model context automatically. A crashed runner reconciles live processes and resumes from committed phase state; model-session continuity is an optimization, because envelopes/artifacts are the workflow source of truth.

### 6.5.5 Initial workflows

Implement only:

```text
inspect   = intake -> read-only recon -> evidence fusion -> report
plan      = intake -> recon/retrieval -> plan -> optional human gate
implement = intake -> worktree -> plan -> build -> checks/fix
            -> semantic review/revise -> full checks
            -> docs/changelog -> completion gate -> commit
```

Add `research`, `incident` and `release` after these three pass recovery, containment and trace tests.

The normal implementation loop is bounded:

```text
build
→ actual-diff scope gate
→ project_check fast
→ same-session fix when red
→ independent requirement review
→ same-session revision when rejected
→ invalidate stale receipts after every write
→ project_check full/release
→ docs/changelog/commit preparation
→ atomic completion gate
```

### 6.5.6 Interface and tool exposure

User surface:

```text
/factory list|run|watch|attach|answer|resume|cancel|inspect
```

Trusted-parent model surface, fixed from session start or additively activated once and retained:

```text
factory_start(workflow, task, mode?, constraints?)
factory_wait(run_id, cursor?, timeout_ms?)
```

Profiles, models, tools, MCP servers, worktrees and permissions are compiled by policy; the model cannot pass arbitrary tool lists, credentials, commands, containers or tmux operations to `factory_start`. Questions and approvals use the existing structured UI/broker. Attach/cancel/profile administration remain user commands.

### 6.5.7 SSSF lessons and non-adoption

Borrow:

- deterministic code-owned phases;
- typed envelopes and small artifact references;
- same-session correction;
- itemized gates;
- bounded test/review loops;
- phase success versus run acceptance;
- run IDs, process registry and SQLite/WAL traces;
- lazy operational skills.

Do not copy:

- current-branch execution or `git add -A` commits;
- after-the-fact Git rollback as primary safety;
- placeholder checks that exit zero;
- manually synchronized output-schema copies;
- full control-engine stamping into each repository;
- model-only session invalidation;
- prompts in process-list-visible argv where avoidable;
- Pi-only/non-interactive execution.

The current SSSF source is extremely young and has reported fresh-install model-registry and false-diff-gate bugs. Re-evaluate upstream later for reusable fixes, but require our own unit, integration, fault-injection and containment tests before promotion.

Detailed comparison: `ultimate-pi-sssf-comparison-and-closed-loop.md`.

**Exit condition:** a disposable repository completes `implement`; a failing check and rejected review each correct in the same compatible child session; an incompatible profile change cold-starts; a crash resumes from artifacts; a user question pauses/resumes; an unauthorized path or stale check blocks commit; and DB/UI/exit code agree on final acceptance.

---

## Stage 7 — Add shell-output compression

### Recommended first implementation: RTK

Install RTK using its current platform instructions, then:

```bash
rtk init --agent pi
```

Verify on:

- `git status` and `git diff`;
- passing and failing tests;
- compiler diagnostics;
- package installation;
- Docker logs.

Requirements:

- Pi's native truncation remains the fallback;
- raw output remains recoverable or trivially rerunnable;
- exact Git and snapshot workflows can bypass compression;
- `project_check` prefers JSON/JUnit/SARIF/compiler machine formats over text compression.
- the rewrite result is logged so a surprising command can be diagnosed;
- in `isolated-local`, RTK is either baked into the guest image or disabled—rewriting `git` to host `rtk git` is a sandbox escape.

Do not install RTK and LeanCTX shell rewriting together. If LeanCTX later wins the A/B test, remove/disable RTK interception first.

Source: [RTK](https://github.com/rtk-ai/rtk).

**Exit condition:** substantial output reduction without increased raw reruns or missed failures.

---

## Stage 8 — Add one edit-safety implementation

Trial one current hashline package in a disposable profile, for example:

```bash
pi -e npm:pi-hashline-edit-pro
```

Test:

1. ordinary single-file edit;
2. multi-location edit;
3. file changes after read but before edit;
4. formatter moves lines after edit;
5. subagent tool compatibility;
6. RAG/CodeGraph unaffected.

Only after passing the trial in `trusted-local`:

```bash
pi install npm:pi-hashline-edit-pro
```

Choose exactly one owner of `read`/`edit`. Do not combine hashline, `pi-readseek`, another stale-read guard and Pi Lens post-edit mutation.

Do not load the stock hashline extension with the stock Gondolin extension: both replace `read`/`edit`, and load order does not create a coherent security design. For `isolated-local`, initially use Gondolin's tools. Later, copy the small stale-read/hash contract into the audited Gondolin router so the VM remains the only executor and only tool owner.

**Exit condition:** stale edits fail safely and the model can recover without excessive rereading.

---

## Stage 9 — Add native Pi subagents and model profiles

```bash
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:@gotgenes/pi-subagents@18.1.0
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:@gotgenes/pi-subagents-worktrees@0.2.3
```

Use this fork because it is a focused in-process core with a typed service/lifecycle API and native synchronous integration with the selected permission system. Children share the parent runtime's extensions and skills; permission-system removes denied tools before the child's first turn and forwards `ask` state to the parent UI. The worktree package is separate and must load after the core.

Confirm package order in the trusted profile's `settings.json`:

```json
{
  "packages": [
    "npm:@gotgenes/pi-subagents@18.1.0",
    "npm:@gotgenes/pi-subagents-worktrees@0.2.3"
  ]
}
```

Start with conservative runtime settings in the profile's `subagents.json`:

```json
{
  "maxConcurrent": 2,
  "graceTurns": 3,
  "consumedSessionRetentionMinutes": 10,
  "unconsumedSessionRetentionMinutes": 120
}
```

Opt only writer roles into worktrees using `subagents-worktrees.json`:

```json
{
  "worktreeAgents": ["worker"]
}
```

If worktree creation fails, the companion fails the child rather than silently using the shared checkout. A changed worktree is committed to a temporary `pi-agent-...` branch for review/merge.

Compile every child from two different records:

```yaml
# AgentProfileV1 — static and cacheable
id: implementer
version: 1
systemPromptRef: profiles/implementer.md
modelClass: strong-coding
thinking: high
tools: []
skills: []
mcpServers: []
permissionProfile: implementer
outputContract: implementation-result-v1
```

```yaml
# TaskEnvelopeV1 — dynamic first user message
goal:
scope:
constraints:
relevantFiles: []
contextRefs: []
requiredChecks: []
doneWhen: []
returnFormat:
```

Role instructions, tool names and output schema remain static. Task text, cwd, worktree path, branch, Git status and retrieved findings belong in `TaskEnvelopeV1`, never in a regenerated system prompt. Patch the subagent prompt assembly if necessary so dynamic environment data follows the static role prefix. Children receive only capability-filtered skills; full skill bodies are loaded on demand. The parent owns task state and commits by default.

### 9.1 Role tool and permission policy

Create project roles under `.pi/agents/`. The `tools:` field controls built-in tools. Because children inherit normal extension tools, use `permission: { "*": deny, ... }` to create the complete per-role extension-tool allowlist; denied tools are removed before the child starts. Replace logical extension names below with the exact registered names from a tool-surface snapshot.

| Role | Model route | Built-ins | Extension permissions and workspace |
| --- | --- | --- | --- |
| Scout/explorer | Fast/cheap model | `read,grep,find,ls` | Allow exact CodeGraph/LSP names only if needed; repository only; no writes/Bash |
| Implementer | Strong coding model | `read,grep,find,ls,write,edit,bash` | Allow `project_check`; worktree; risky operations ask; sudo denied |
| Reviewer | Different strong provider | `read,grep,find,ls` | Allow `project_check`; no Bash/write; repository only |
| Researcher | Research/long-context model | `read` | Allow `knowledge_search`, `knowledge_get` and one read-only web surface; no code write/Bash |

Minimal read-only role:

```markdown
---
description: Locate relevant files, data flow, risks and handoff points.
tools: read,grep,find,ls
model: REPLACE_WITH_FAST_MODEL
thinking: low
max_turns: 12
prompt_mode: replace
inherit_context: false
permission:
  "*": deny
  read: allow
  grep: allow
  find: allow
  ls: allow
  tools:
    ask_user_question: allow
  external_directory: deny
---
Return a compact evidence-based map with repo-relative paths and unresolved questions. Do not propose edits.
```

Minimal writer role:

```markdown
---
description: Implement one approved, bounded change in an isolated worktree.
tools: read,grep,find,ls,write,edit,bash
model: REPLACE_WITH_STRONG_CODING_MODEL
thinking: high
max_turns: 30
prompt_mode: replace
inherit_context: false
permission:
  "*": deny
  read: allow
  grep: allow
  find: allow
  ls: allow
  write: allow
  edit: allow
  tools:
    project_check: allow
    ask_user_question: allow
  bash:
    "*": allow
    "rm *": ask
    "sudo *": deny
    "git push *": ask
  external_directory: deny
---
Implement only the approved task. Run project_check and return changed files, evidence, risks and remaining work.
```

This deliberate subagent `deny` policy is narrower than the permissive main-agent policy. It does not require a giant global whitelist: only four small role files enumerate what each specialist needs. `interactive_shell`, MCP, external-agent delegation, memory writes and recursive `subagent` calls remain absent unless explicitly allowed. For a role that needs a scratch/cache path, add it to that role's `external_directory` map; do not loosen the global policy.

Default rules:

- `inherit_context: false` by default; fork only when prior reasoning is genuinely needed;
- pass a compact task packet and references;
- read-only is default;
- only roles listed in `worktreeAgents` may write;
- concurrency begins at 2;
- permission-system handles both visibility and `ask` in the parent UI;
- recursive delegation remains denied;
- test `ask_user_question` from a direct child before relying on it; permission prompts and product questions are separate UI flows;
- reviewer uses a different model/provider from implementer when possible.

Smart routing v1 maps the static role's `modelClass` to an available provider/model before the child session starts. Validate exact provider/model IDs against Pi's model registry and keep a documented fallback per role. The subagent core does not enforce a provider allow-glob or learned router. If later traces prove availability/fallback is recurring, add a tiny deterministic resolver; it chooses a new child cache island and may never change tools, worktree, credentials, sandbox or the parent model.

### 9.2 Sandboxed subagents

In-process children are more compatible with a shared Gondolin executor than separately spawned Pi CLIs, but `tools:`/permissions are still not OS containment. Prove that every child built-in resolves to the same router and that inherited extension tools cannot perform host I/O. For highest assurance, run the whole Pi runtime and children inside `vmpi`, OpenShell or a rootless container.

The batteries-included `pi-subagents` package is a strong alternative when scheduling, model scopes, child-only extension loading, richer chains and spawn budgets matter more than in-process composition. Do not run both. Re-evaluate only after the simpler core demonstrably lacks a needed workflow.

Sources: [`@gotgenes/pi-subagents`](https://pi.dev/packages/%40gotgenes/pi-subagents), [worktree companion](https://github.com/gotgenes/pi-packages/tree/main/packages/pi-subagents-worktrees), [permission-system integration](https://github.com/gotgenes/pi-packages/tree/main/packages/pi-permission-system), [batteries-included alternative](https://pi.dev/packages/pi-subagents).

**Exit condition:** two parallel read-only agents finish, can be steered/cancelled, and return compact useful results without permission bypass.

---

## Stage 10 — Add external Claude Code, Codex and Antigravity delegation

### 10.0 Interaction is independent from scheduling

Do not define a run as merely “attended” or “unattended.” Every local foreign-harness run must be both background-capable and attachable, and every run must have a way to request human input. The launch spec has independent fields:

```yaml
execution: foreground | background
interaction: attended | supervised | batch
attachable: true
questionChannel: broker
workspace: read_only | worktree
```

- `attended`: open the PTY immediately. The user can type directly; automation observes but does not send input while the user holds the input lease.
- `supervised`: recommended default. Run in the background, notify on questions/stalls/completion, and let the user attach at any time without restarting the child.
- `batch`: no routine interaction expected, but the child still has the question broker. If it needs a decision, pause it and promote the run to `supervised`; never guess or answer permission/credential prompts automatically.

“Unattended” therefore means *not currently focused*, not *unable to ask*. A remote `server-worker` may queue a structured question and wait, but has no sudo and must fail closed when an approval cannot be obtained.

### 10.1 Prototype through the existing PTY

`pi-interactive-shell` can already run Claude Code, Codex and other interactive CLIs, preserve scrollback, allow human takeover, launch dispatch/background sessions and create worktrees. Use it first in `trusted-local` to learn which delegation patterns are valuable:

```json
{
  "spawn": {
    "commands": {
      "pi": "pi",
      "codex": "codex",
      "claude": "claude"
    },
    "defaultArgs": {
      "pi": [],
      "codex": [],
      "claude": []
    },
    "worktree": true,
    "worktreeBaseDir": "~/.pi/worktrees/external"
  },
  "transferLines": 200,
  "transferMaxChars": 20000,
  "completionNotifyLines": 50,
  "completionNotifyMaxChars": 5000
}
```

This belongs in the trusted profile's `interactive-shell.json`. You may launch explicitly with `/spawn codex "review this diff" --dispatch --worktree` or `/spawn claude ...`. Antigravity can be exercised as a raw command after confirming its installed CLI syntax.

For model-driven launches, prefer `interactive_shell({command: "..."})` during this prototype so the permission-system `commandArgument` alias can inspect the concrete command. The extension's structured `spawn` object may not present a top-level `command` to a generic permission hook; do not assume it is equivalently gated. User-entered `/spawn` is an explicit user action. In every case, the outer gate controls only launch: the downstream CLI's internal shell actions are not individually visible to Pi's permission system.

`pi-interactive-shell` currently provides the right prototype UX: dispatch/background execution, preserved scrollback, `/attach`, a focus shortcut and immediate user takeover. It uses its own PTY rather than tmux, so it is excellent for trusted-local sudo and short supervised experiments but is not the final durable process supervisor. A Pi crash or broker restart must not orphan the only copy of a long foreign-agent session.

Do not install `pi-live-terminal` or `@romansix/pi-tmux` as an additional generic model-visible terminal tool in the daily profile. Both demonstrate useful attach/peek/tmux mechanics, but they overlap the existing PTY and would let a model bypass the external-agent policy. Reuse tmux itself—or audited library code—behind the custom broker. `pi-interactive-subagents` is a credible multiplexer-based alternative for Pi-only children, including `caller_ping`, but it overlaps `@gotgenes/pi-subagents` and its help/interrupt behavior is not a complete foreign-harness protocol; do not run both.

After traces justify automation, build one `agent_delegate` Pi-native extension with adapters, a persistent session broker and a normalized sandbox/worktree policy. Keep `pi-interactive-shell` for direct human PTY/sudo use, and disable its model-driven structured foreign-agent spawning once the broker is enabled. User `/spawn` can remain as an explicit diagnostic escape hatch if its resulting session is clearly marked unmanaged.

### 10.2 Stable tool and user-command surface

```text
agent_delegate(task, role?, executor="auto", access="read_only",
               workspace="current", context_refs?, timeout?,
               execution="background", interaction="supervised")
agent_runtime(action="status|steer|cancel|result|request_attach", id?, message?)
```

For cache cleanliness, choose one of two policies per profile:

1. keep the two small schemas active and byte-identical for the whole session; or
2. on models with Pi-supported native deferred tool loading, keep `/agents` user commands always available, load both tools together additively on first delegation, and never remove them until the session ends.

On providers without native deferred tool loading, prefer the fixed initial schemas; Pi's fallback sends the complete changed tool list and may invalidate the cached prefix even for an additive change.

Do not expose `agent_runtime` only while a child is active and then remove it; non-additive tool toggling breaks the cache contract. The raw `claude`, `codex` and `antigravity` CLIs remain hidden behind the adapter; direct shell launches ask under the Stage 2 policy.

User commands do not add model schemas:

```text
/agents                         list runs and states
/agents attach <id>             focus existing pane/session
/agents detach <id>             return focus to Pi without stopping child
/agents answer <id>             answer a queued structured question
/agents steer <id> <message>    send an ordinary follow-up
/agents cancel <id>             request graceful cancellation
/agents logs <id>               open bounded transcript/artifact
```

Adapters:

```text
PiSubagentAdapter
ClaudeCodeAdapter
CodexCliAdapter
AntigravityAdapter
ACPAdapter (later)
```

### 10.3 Persistent PTY/session broker

Use a private tmux server as the default local backend because tmux has durable named sessions, stable pane IDs, `capture-pane`, `pipe-pane`, `send-keys`, control mode and attach/detach. GNU Screen is possible but offers less precise programmatic control and is not the recommended backend.

```text
Pi UI / parent agent
        |
        v
agent_delegate -> capability/profile compiler -> session broker
                                              |-> tmux PTY -> Claude Code
                                              |-> tmux PTY -> Codex CLI
                                              `-> tmux PTY -> Antigravity
        ^                                             |
        `--- question/event broker <------------------'
```

Requirements:

- private tmux socket directory mode `0700`, opaque run IDs and transcript/artifact files mode `0600`;
- one pane/session per run, dedicated worktree for writers and no shared-checkout concurrent writers;
- survive Pi UI restart and re-discover live runs from a broker registry;
- bounded ring buffer plus raw transcript artifact; never inject full scrollback into Pi;
- no automatic focus stealing; completion/question notification offers an attach action;
- when Pi already runs inside tmux, select/switch to the child window; otherwise open a supported terminal tab when explicitly requested or print the exact attach command;
- exclusive input lease: either broker automation or the attached user may send keystrokes, never both;
- detach preserves the child; cancel is separate and attempts graceful shutdown before a gated force kill;
- state machine: `starting`, `running`, `needs_input`, `user_attached`, `paused`, `completed`, `failed`, `cancelled`, `orphaned`.

`pi-interactive-shell` may remain the front-end overlay for direct PTYs if a small integration can attach it to the broker's tmux pane; otherwise implement only a compact attach/focus view. Do not expose the broker's generic `send-keys`, `new-window` or arbitrary tmux commands to the model.

### 10.4 Human-question and permission protocol

PTY prompt detection based only on silence or terminal text is a fallback, not a correctness mechanism. Prefer this order:

1. native structured event/ACP protocol where a harness supports it;
2. a scoped local `user_question` MCP tool or localhost/Unix-socket helper supplied to the child;
3. an explicit sentinel JSON line emitted by the wrapper;
4. stall/silence detection that notifies the parent and offers attachment.

The question broker records `{runId, questionId, prompt, choices?, sensitivity, deadline?}` and changes the run to `needs_input`. It notifies the human through Pi, but the parent model must not answer on the user's behalf unless the task grant explicitly permits a low-risk default. The response returns only to the requesting child and is appended as a normal child message, preserving both parent and child cache prefixes.

Credential prompts, sudo, SSH host-key changes, destructive confirmations and downstream harness permission dialogs require direct user attachment or a dedicated trusted UI. Never capture passwords into Pi history, logs or MCP messages. Foreign background agents should normally run without host sudo; dependency elevation belongs in a prepared sandbox image. Claude Code Remote Control can be an optional Claude-specific remote UI, but it does not replace the common broker for Codex/Antigravity and sends control traffic through Anthropic's service.

### 10.5 Task packet

Send only:

```yaml
goal:
role:
constraints:
working_directory:
allowed_actions:
relevant_files:
changed_files:
codegraph_findings:
knowledge_refs:
known_failures:
required_checks:
expected_output_schema:
```

Do not forward Pi's entire transcript, hidden prompt, credentials or raw histories.

### 10.6 Isolation

- review/research: read-only repository mount;
- implementation: dedicated worktree and branch;
- never allow multiple harnesses to edit one checkout concurrently;
- Pi reruns `project_check` after integrating a foreign agent's diff;
- external harness internal permission prompts do not replace the outer OS sandbox.
- a parent permission check sees only the CLI launch, not commands the foreign harness later runs;
- therefore install the CLI inside the selected guest, or launch it in its own Gondolin/container/OpenShell worker;
- use `interactive_shell` for the prototype and trusted human PTY/sudo; use the persistent broker for durable supervised background foreign agents;
- normalize stdout, stderr, structured events, cost/quota, changed files and final evidence into bounded artifacts.

### 10.7 Routing policy v1

Use deterministic rules first:

```yaml
routes:
  - role: explore
    executor: pi
    model_class: fast
    access: read_only
  - role: implement
    complexity: high
    executor: codex-cli
    workspace: worktree
  - role: review
    executor: claude-code
    access: read_only
  - domain: google-cloud
    executor: antigravity
    access: read_only
```

Treat this mapping as a hypothesis. Record success, rework, latency, quota consumption, validation and user acceptance. A learned router comes only after enough real outcomes.

The router chooses a model/harness for a new child run, never permissions and never the parent model. `access`, worktree path, network policy and credential scope are computed before routing and may only be tightened by an adapter. A provider fallback creates another child cache island; it may change the child model but may not move an isolated task to a host process.

Subscription logins and quotas remain owned by the official CLIs. Track availability and concurrency per executor. Technical ability to automate a subscription does not by itself establish provider-policy permission for unattended high-volume use.

ACP is preferable to PTY scraping when each downstream agent's implementation becomes stable, but adapters must tolerate headless-CLI mode first.

**Exit condition:** each foreign agent completes a read-only supervised-background task; can request an answer, pause and resume; can be attached/detached without restart; survives a Pi UI restart; cancellation works; output is normalized; and no agent modifies the shared checkout.

Sources: [`pi-interactive-shell`](https://github.com/nicobailon/pi-interactive-shell), [`pi-live-terminal`](https://pi.dev/packages/pi-live-terminal), [`pi-tmux`](https://github.com/indigoviolet/pi-tmux), [`pi-interactive-subagents`](https://github.com/HazAT/pi-interactive-subagents), [Claude Code Remote Control](https://code.claude.com/docs/en/remote-control).

---

## Stage 11 — Add MCP only for services that deserve MCP

```bash
pi install npm:pi-mcp-adapter
```

Restart Pi, then run:

```text
/mcp setup
```

Preferred project file `.mcp.json`:

```json
{
  "settings": {
    "toolPrefix": "server",
    "idleTimeout": 10,
    "directTools": false,
    "autoAuth": false
  },
  "mcpServers": {
    "example": {
      "command": "replace-with-server-binary",
      "args": [],
      "lifecycle": "lazy",
      "idleTimeout": 10,
      "requestTimeoutMs": 30000,
      "directTools": false,
      "debug": false
    }
  }
}
```

Keep the single proxy tool by default—approximately 200 schema tokens—and promote only frequently used, decision-critical tools through `directTools`. Promoting or demoting a `directTools` entry changes the tool surface and the session compatibility hash: it takes effect only in a new session (or a deliberately recorded cache epoch), never mid-session. Server/tool discovery output is bounded (cap listed servers and per-listing bytes); listing is free for allowlisted servers, but activation of a mutating server follows the same permission gates as its calls.

Use MCP for remote/stateful APIs, authenticated systems, databases, browser services and an existing RAG service. Do not expose CodeGraph, LSP or local CLIs again through MCP.

Gate at the semantic operation, not only at server startup:

- read-only documentation/search calls may be `allow`;
- issue creation, messages, database writes, browser form submission and deployment are `ask`;
- destructive/admin calls remain absent unless explicitly enabled for a task;
- server credentials are process-scoped and never added to model context;
- the proxy validates server name, tool name, argument size and timeout and returns bounded structured output.

An MCP server launched by host Pi runs on the host even when built-in Bash is in Gondolin. In `isolated-local`, allow only reviewed remote API/RAG brokers with no generic filesystem, shell or arbitrary local-resource tools. Put an MCP server inside a whole-process sandbox when it must inspect or mutate the repository.

Maintain one canonical MCP registry and compile a task-specific subset for each harness. “Share MCP” means share the authoritative service and configuration source, not expose every server or start duplicate index processes.

| Child role | Direct MCP access |
| --- | --- |
| Scout/reviewer | CodeGraph read-only only when repeated exploration is needed; otherwise parent passes references |
| Implementer | Project knowledge and CodeGraph read-only when justified; no memory writes |
| Researcher | Project knowledge plus one browser/web surface |
| Commit finalizer | None by default |
| Release agent | GitHub/issue tracker mutations only with scoped credentials and `ask` |

Decision rule:

- one or two lookups → parent retrieves and passes stable references;
- repeated interactive exploration → child receives the scoped MCP server;
- stateful index → all clients connect to one shared service, never one server/index per child;
- mutating or expensive service → parent broker or child-specific token and policy.

For Claude Code, generate a temporary allowlisted `.mcp.json` and launch with its strict MCP-config option. For Codex CLI, generate task-specific `[mcp_servers.*]` configuration and skill selection. Verify the installed Antigravity version and configuration format before exporting anything; if an allowlist cannot be enforced, launch it with no MCP. A parent Pi permission hook cannot govern tool calls made internally by a foreign CLI.

Keep Pi Lens native inside Pi; its MCP mirror may be offered to a foreign harness only when that child genuinely needs Pi Lens data and doing so does not start a second LSP/index for the same worktree. Prefer the existing shared engine or parent-supplied findings.

Source: [Pi MCP Adapter](https://github.com/nicobailon/pi-mcp-adapter).

`pi-mcp-adapter` is a single-maintainer research-time pin. If it fails evaluation, the named fallback class is a self-hosted gateway/registry (MetaMCP or MCPJungle) behind the same canonical-registry exporter, or harness-native deferred tool loading if Pi gains it; the one-lazy-proxy contract and hashes stay identical regardless of implementation.

**Exit condition:** servers start lazily, disconnect when idle, permissions gate mutating calls, no native/MCP duplicates are visible, and the **measured** startup token cost of the MCP tool surface stays within budget (proxy schema ≈ 200 tokens; assert with a token count in the smoke test and report it in `/cache-status`) — lazy behavior is verified by measurement, not assumed.

---

## Stage 11.5 — Add deterministic commit, changelog and documentation finalization

The parent/release role owns commits by default. Native and foreign subagents return a diff, worktree or patch; they do not independently commit, because concurrent changelog prepends and documentation decisions would race.

Create:

```text
.agents/skills/commit-finalization/SKILL.md
scripts/commit-prepare
.githooks/pre-commit
.githooks/commit-msg
agent-workflow.json
```

The commit transaction is:

```text
staged diff
→ immutable diff hash
→ documentation-impact classification
→ required documentation update
→ project_check
→ generate changelog line + compact commit subject
→ prepend root CHANGELOG.md
→ stage docs/changelog
→ recalculate final staged hash
→ write receipt under .git/
→ deterministic hooks verify receipt/content
→ commit
```

Every non-temporary project commit prepends exactly one concise outcome-based bullet beneath a stable marker in root `CHANGELOG.md`. Normal target length is 6–18 words, past tense, with no file list, hash or vague “updates” wording. Commit subjects use compact Conventional Commit form and stay within 72 characters; bodies are reserved for breaking changes, migrations, security consequences or non-obvious rationale.

The optional generation request is ephemeral and separate from the parent conversation/cache. It receives only bounded staged diff statistics, selected hunks, public symbols/config keys and documentation rules, and returns strict JSON:

```json
{
  "changelog": "Added capability-scoped MCP access for delegated CLI agents.",
  "commitSubject": "feat(agents): scope MCP access by specialist profile",
  "documentationImpact": "updated",
  "documentationFiles": ["README.md", "docs/agents.md"]
}
```

Hooks never call an LLM and never mutate files; they only verify the prepared receipt, changelog placement, subject format, documentation decision and staged hash. If documentation impact is uncertain, block and ask rather than invent rushed documentation. Configure repository-specific rules in `agent-workflow.json`, such as public API/config changes requiring README or named docs.

The skill description must be precise enough to load only immediately before a commit. Declare `git`, root `CHANGELOG.md`, `project_check` and the allowed profiles in skill metadata. Ordinary editing/review agents do not receive it. Mirror it to Claude/Codex only for a deliberately delegated release role; otherwise the parent executes the transaction.

**Exit condition:** a test commit cannot proceed without a fresh validation receipt, one correctly prepended changelog entry, compliant subject and an explicit documentation-impact result; concurrent children cannot race the root changelog.

---

## Stage 12 — Make compaction explicit and single-owner

Pi remains the only component that replaces old conversation context.

### 12.1 What Pi-native compaction means

Pi automatically compacts when estimated context exceeds `contextWindow - reserveTokens`, or manually on `/compact [instructions]`. It summarizes older turns, preserves a recent tail, appends a `CompactionEntry` to the session, and reloads the model with `system prompt + summary + kept messages`. `/tree` branch changes use a related branch summary. The session log is not deleted; compaction changes what is sent to the model.

Start with Pi's supported settings rather than another compactor:

```json
{
  "compaction": {
    "enabled": true,
    "reserveTokens": 16384,
    "keepRecentTokens": 20000
  }
}
```

These are current defaults, not universal optimums. Compile settings once at session start from the selected model's context/output limits and the task profile; do not change them algorithmically mid-session. Start with a small deterministic mapping rather than asking another model to choose numbers:

- ordinary coding: Pi defaults until traces show a failure;
- long research/architecture: retain a larger recent tail when the context window permits;
- high-output implementation/review: reserve at least the configured maximum answer/check-report budget plus safety margin;
- small-context models: compact earlier and keep a smaller tail rather than risking overflow.

Record the chosen policy and inputs in `compactionPolicyHash`. A user can select another policy only by starting a replacement session or accepting an explicit cache-epoch change. A learned/LLM threshold tuner is deferred until traces provide labeled examples; threshold selection is cheap deterministic arithmetic and does not initially justify another model call.

Preserve enough recent tokens for the active edit/test loop, and trigger `/compact` at a clean checkpoint before a major phase change. Pi truncates each serialized tool result to 2,000 characters in the summarization request. That fallback may omit the semantically important portion of a raw log, so `project_check`, RTK and tool-result filters must place compact failures, exit state and artifact references into the stored result *before* compaction. The compactor never depends on arbitrary first-2,000-character slices of raw logs.

### 12.2 Thin coordinator, not a second compactor

Start with Pi's default summarizer. Build one thin native compaction coordinator only after continuity tests expose missing structured state. The coordinator still uses Pi's `session_before_compact` lifecycle and produces Pi's one `CompactionEntry`; it is not a second history system. Its canonical resume snapshot:

```yaml
goal:
constraints:
decisions:
changed_files:
current_failures:
validation_state:
task_state_ref:
retrieval_refs:
active_processes:
pending_approvals:
next_action:
```

Rules:

- optional task/todo state is persisted independently; the summary stores only a short reference;
- CodeGraph and RAG outputs are represented by stable references, not copied wholesale;
- full Bash output stays in artifacts;
- active background processes and worktrees must be recorded;
- one component writes the resume snapshot;
- other extensions may contribute typed data but may not inject competing summaries.
- each subagent session may run Pi's native compaction independently; only its bounded final result/lifecycle reference returns to the parent, never its compaction summary as a second parent resume state.

Use `session_before_compact` only to enrich or replace the one Pi compaction entry. Do not let LeanCTX, Hermes, a todo extension and a memory extension each inject their own session recap. If the coordinator produces the summary, it must carry `firstKeptEntryId`, token accounting and serializable `details` exactly as Pi expects.

Pi's lifecycle permits the coordinator to call a separate summarization model. Trial this only after establishing a native baseline. Select the summary model once in the session manifest, use the same structured serialization and cancellation signal, record usage, and benchmark constraint/decision/failure retention. A cheap model is acceptable only if it meets the continuity test suite; “nearly free” is not sufficient evidence. This remains a Pi-native compaction hook and does not authorize LeanCTX or Hermes to rewrite history.

### 12.3 Three different kinds of “compression”

| Mechanism | Operates on | When | Owner |
| --- | --- | --- | --- |
| Tool-output bounding/compression | One `bash`, compiler, test or read result | Before result enters conversation | Pi truncation + RTK/structured parser |
| Conversation compaction | Old turns already in the session | Threshold or `/compact` | Pi only |
| Retrieval/memory | External documents or durable experience | Explicit query/startup policy | RAG/Hermes |

An AST-aware command parser can compact compiler/test output or summarize changed symbols, but it does not replace conversation compaction. Prefer native JSON, SARIF, JUnit, compiler diagnostics and `ast-grep`-derived facts before heuristic text summaries; always retain raw artifacts.

Test compaction on a deliberately long disposable task and verify:

- goal and constraints survive;
- exact failures survive;
- task state survives independently, including any optional parent-only todo reference;
- validation status is not falsely preserved after later edits;
- no duplicate session summary is injected.

Source: [Pi compaction and branch-summarization documentation](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/compaction.md).

**Exit condition:** work resumes correctly after compaction using a small, inspectable snapshot.

### 12.4 Add a portable session projection without changing compaction

Pi's JSONL remains the native working session format and `CompactionEntry` remains the only conversation-history replacement. Add a separate explicit export path for cross-provider, cross-harness and audit use:

```text
PortableSessionBundleV1/
├── manifest.json
├── continuity.json
├── events.jsonl
├── capabilities/
├── compaction/
├── evidence/
├── artifacts/
└── deletion-manifest.json
```

The exporter reads the active Pi branch through the runtime API; it never selects a session file by modification time, rewrites history or injects the export back into the current prompt. The portable projection removes chain-of-thought from the readable record, keeps provider-only signatures only in an optional sealed-state area, and ensures readable user/assistant text, tool calls/results, questions/answers, child task envelopes, compaction summaries and decisive evidence remain available without the original provider.

`pi-session-control` contributes the compiled profile, prompt/tool/skill/capability contents or content-addressed snapshots—not only hashes. `pi-factory` contributes run/phase lineage, gates, worktree/tree identities and artifact manifests. The foreign-agent broker contributes exact launch envelopes, readable transcripts/events, questions, answers and normalized results. Evidence-critical browser/search tools contribute query, result ordering, retrieved passages/snapshots, timestamps, URLs and hashes.

Expose only user/control-plane operations:

```text
/session export-portable
/session verify-portable
/session inspect-portable
/session delete-portable
```

An interim manual trial may use `@danchamorro/pi-handoff-agent`, which registers `/handoff-export` without a model-visible tool or per-turn injection. Its current continuity packet is useful but does not include the complete capability manifest, factory evidence contract, deletion inventory or foreign process tree; use it as a source reference or temporary bridge, not the final canonical format.

Routing rule:

- compatible hash unchanged: resume native session;
- process crash with compatible hash: resume and reconcile;
- provider/model/profile/tool/policy/executor/worktree changed: start a new session from `continuity.json` plus explicit artifact/evidence retrieval;
- every model session unavailable: resume the factory run from manifests, envelopes and repository state.

Portability acceptance test: export a disposable run, remove access to the original provider, start a different supported harness, retrieve only declared artifacts and complete the next validated phase. Inspection, export, replay, audit and deletion must all be explainable from the local bundle.

Sources: [session-portability principles](https://earendil.com/posts/session-portability/), [Pi session format](https://pi.dev/docs/latest/session-format), [`@danchamorro/pi-handoff-agent`](https://pi.dev/packages/%40danchamorro/pi-handoff-agent).

**Exit condition:** a different provider/harness can continue from a small readable snapshot, expand exact evidence on demand and audit the abandoned session without provider IDs or opaque compaction state.

---

## Stage 13 — Add Hermes Memory Service with a non-overlapping role

Hermes memory is useful; it should not become a second project-document RAG or a second session compactor.

The reason to defer it is sequencing, not lack of value. Before Hermes, the setup needs stable project identity, retrieval scopes, compaction ownership, evidence IDs and deletion/export controls. Otherwise the system will memorize transient failures, duplicate documents already in RAG, re-inject stale summaries and make it difficult to determine why a behavior changed.

Hermes owns:

- repeated user preferences;
- successful operating procedures;
- recurring corrections and failure patterns;
- cross-session episodic history;
- candidate reusable skills.

It does not own:

- live todos;
- current source-code facts;
- CodeGraph relationships;
- authoritative project documents;
- Pi's resume summary.

Use a promotion pipeline:

```text
observation
→ repeated/useful check
→ candidate memory
→ provenance + contradiction/staleness check
→ project/global scope
→ promotion
```

Suggested memory record:

```json
{
  "type": "procedural",
  "scope": "project:example",
  "claim": "Run pnpm check before the Docker build; it catches generated-type drift faster.",
  "evidence": ["session:...", "command:...", "exit:0"],
  "confidence": 0.87,
  "validUntil": null
}
```

Retrieval policy:

- inject only a very small stable policy/preferences block at session start;
- retrieve other memories explicitly;
- do not promote transient todo state or one-off failures;
- procedural memories may auto-promote only after repeated evidence;
- executable skills, prompts and permission policies require review and versioning.

### 13.1 Pi/Hermes Memory Service interface

Expose only a narrow service contract to Pi:

```text
memory_search(query, scope, types?, limit?)
memory_get(ids, max_chars?)
/memory-propose
/memory-review
```

Do not expose a generic memory SQL/filesystem tool. `memory_search`/`get` are read-only and may remain host-brokered in `isolated-local`; proposal/promotion/deletion require explicit review. Keep the stable startup injection to a few verified preferences/policies and fetch episodic/procedural memories explicitly.

### 13.2 Later Hermes Coordinator architecture

The later full Hermes Agent deployment—called `Hermes Coordinator` in this architecture—can coordinate Pi, Claude Code, Codex and other workers and connect to IM channels. They should share a versioned memory API—not one writable SQLite file or a common prompt/skill directory. Namespace records by user, repository identity, branch/task and agent role; attach provenance, confidence, author, timestamps and revocation state. Workers submit candidates, while one service resolves contradictions and promotion.

Hermes Coordinator owns the IM front door, scheduling, remote delivery and launching `pi-factory`. `pi-factory` remains the only workflow scheduler and acceptance authority. A remote question flows `worker → factory/broker → Hermes → authenticated user → Hermes → requesting worker`; Hermes never invents an answer or sends terminal keystrokes directly.

“Self-improvement” means a controlled evaluation pipeline. A remembered observation can propose a skill, route or prompt change, but production configuration changes only after sandboxed replay/evaluation, review, versioning, staged rollout and rollback. Memory must never rewrite sandbox, permission or credential policy automatically.

Source: [Hermes Agent](https://github.com/nousresearch/hermes-agent).

**Exit condition:** a learned procedure is recalled across sessions without duplicating project documents or Pi's compaction summary.

---

## Stage 14 — LeanCTX experiment, deliberately narrow

LeanCTX is not a normal additive extension in this architecture. Full LeanCTX overlaps CodeGraph, RAG, Hermes memory, RTK, permissions, subagents and Pi compaction.

Its potentially unique value here is narrower: avoid paying again for unchanged file content, return deltas/signatures/maps when full text is unnecessary, compact noisy command results, and measure where context is spent. Those benefits occur *before* or *at* tool-result delivery. LeanCTX does not make Pi's conversation compaction obsolete, and its broader graph/memory/agent/edit features provide no unique authority in this stack.

| LeanCTX feature | Existing owner | Trial decision |
| --- | --- | --- |
| Read cache/delta/signature/map | No exact equivalent | Test; highest potential value |
| Shell-output compression | RTK + structured parsers | A/B alternative; never simultaneous |
| Code graph | CodeGraph | Disable |
| Session/project memory | Pi compaction + RAG + Hermes | Disable |
| Execute/permissions | permission-system + executor/sandbox | Disable |
| Editing | Pi/hashline/Gondolin router | Disable |
| Multi-agent orchestration | `@gotgenes/pi-subagents` | Disable |
| Wire/prompt proxy | Pi/provider path | Last, separate experiment only |

Create a separate `pi-lean` profile and first enable only:

- cached unchanged rereads/deltas;
- conservative file `map`/`signatures` modes;
- context/savings observability;
- optionally shell compression only after disabling RTK.

Disable overlapping LeanCTX tools in `~/.lean-ctx/config.toml`:

```toml
disabled_tools = [
  "ctx_execute",
  "ctx_edit"
]

excluded_commands = [
  "git diff",
  "git apply",
  "git add -p"
]
```

The exact disabled-tool list must be completed against the installed version so its graph, memory, multi-agent, permission and write paths are not exposed. Avoid a full `lean-ctx wrap` until that audit is complete because it installs hooks, rules, server/daemon integration and potentially changes core tool routing.

Test in four separate steps:

1. observability only;
2. read caching/modes;
3. shell compression after RTK is disabled;
4. optional wire proxy last.

Do not enable its session-memory restoration or code graph. Do not test wire compression simultaneously with read-path replacement. An independent Pi benchmark has reported a configuration where LeanCTX produced higher billed input, so local A/B measurement is mandatory rather than trusting advertised savings.

Useful commands after installation:

```bash
lean-ctx doctor
lean-ctx gain
lean-ctx gain --live
```

Sources: [LeanCTX](https://github.com/yvgude/lean-ctx), [Pi integration benchmark issue](https://github.com/yvgude/lean-ctx/issues/361).

**Exit condition:** lower tokens/cost with equal task success, no increased raw rereads and no conflicts. Otherwise remove it and retain RTK plus Pi-native tools.

---

## Stage 15 — Server architecture: Hermes coordinator, ephemeral Pi workers

Only after the local stack is stable:

```text
Hermes coordinator
  → task queue/router
  → ephemeral Pi worker
  → per-task container + worktree
  → evidence/artifact store
  → shared memory service
  → approval gateway
```

Hermes owns scheduling, durable learning, remote interaction and deciding when to launch Pi. Pi owns repository-local code work, tools, checks and Git state.

Server controls:

- one unprivileged container/microVM per write task;
- no host Docker socket;
- no host SSH-agent socket by default;
- scoped credentials per task;
- network off by default;
- CPU/RAM/PID/disk/time limits;
- read-only root filesystem where practical;
- repository/worktree is the only ordinary writable mount;
- approval requests are durable, authenticated, operation-hashed and default-deny on timeout;
- no interactive sudo;
- long-running processes are registered, bounded and cleaned up.

Shared services, not shared mutable files:

- memory API;
- task queue;
- approval gateway;
- artifacts/evidence;
- observability/model gateway.

Do not mount one mutable SQLite memory database into multiple workers or let workers rewrite the production skill/prompt directory.

Self-improvement pipeline:

```text
experience
→ memory candidate
→ repeated evidence
→ skill proposal
→ isolated evaluation
→ review/version
→ monitored rollout
→ rollback capability
```

**Exit condition:** an isolated Pi worker can complete, validate and return a change; Hermes can retain a reviewed procedural memory; the worker cannot reach host credentials or mutate production agent configuration.

---

## Final component inventory

### Install during the baseline build

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
npm install -g @colbymchenry/codegraph

pi install npm:@gotgenes/pi-permission-system@20.9.1
pi install npm:pi-interactive-shell@0.13.0
pi install npm:@juicesharp/rpiv-ask-user-question
pi install npm:@vndv/pi-codegraph
pi install npm:pi-lens@3.8.71
```

These commands target `trusted-local`; prepend its `PI_CODING_AGENT_DIR` in real launch/install scripts. Build the `isolated-local` directory from the reviewed official Gondolin example separately and do not copy host-only LSP/PTY/edit extensions into it.

### Install after measurement

```bash
# RTK: install by current platform method, then
rtk init --agent pi

pi install npm:pi-hashline-edit-pro       # trusted-local only, after trial
pi install npm:@gotgenes/pi-subagents@18.1.0
pi install npm:@gotgenes/pi-subagents-worktrees@0.2.3
pi install npm:pi-mcp-adapter
```

### Build locally

1. `pi-session-control`: profile/capability compiler, skill filter and cache-contract guard
2. profile launchers plus audited Gondolin executor/router and policy config
3. `project_check` on the shared `Executor` abstraction
4. `pi-factory`: typed phase/envelope/gate runtime, run/artifact store, worktree/process state and final acceptance
5. Pi-native `/factory` UI plus stable `factory_start` and `factory_wait` tools
6. changed-file/evidence gates and commit-finalization skill, preparation script and deterministic hooks
7. optional compaction coordinator and summary-model adapter after baseline tests
8. external-agent adapter, tmux session/question broker and process status display
9. task-specific MCP/skill exporters for Claude Code, Codex and verified Antigravity versions
10. optional CodeGraph/RAG result fusion after traces justify it

### Test later, separately

- Hermes memory;
- LeanCTX narrow profile;
- `@the-agency/vmpi` whole-sandbox profile;
- OpenShell server/maximum profile;
- `@nqbao/pi-sandbox` as a lightweight alternative, never stacked with Gondolin;
- Braintrust/Langfuse tracing;
- Chrome DevTools/browser profile;
- checkpoint/rewind or Entire;
- Oh My Pi as a separate complete distribution.

### Omit

- GitNexus beside CodeGraph;
- a second LSP client;
- another code RAG;
- multiple `read`/`edit` replacements;
- RTK and LeanCTX shell interception together;
- another LSP client or Pi Lens MCP beside native Pi Lens;
- Pi Lens automatic context injection, formatting or autofix in the balanced profile;
- direct and MCP exposure of the same capability;
- Hermes/LeanCTX/Pi all restoring session summaries;
- multiple todo/plan/goal systems;
- automatic write-capable external agents in the shared checkout;
- `pi-safe-shell` beside permission-system/interactive-shell;
- `pi-sandbox` beside permission-system in the normal profile;
- `pi-container-sandbox@0.2.2` until it routes `grep`, `find` and `ls` too;
- host `interactive_shell`, host LSP or generic local MCP inside a Gondolin-routed profile;
- SSSF installed unchanged as a second production orchestrator or its full mutable engine stamped into each repository;
- native subagent chains, foreign-agent broker and `pi-factory` each independently owning the same task loop;
- multiple sandbox runtimes in one profile.

## Conflict and ownership map

| Conflict | Why it breaks or wastes resources | Resolution |
| --- | --- | --- |
| Permission-system + `pi-safe-shell`/prompting `pi-sandbox` | Two command parsers and approval UIs | Permission-system + PTY in trusted profile; alternative alone in a test profile |
| Gondolin + hashline/readseek | Competing registration of `read`/`edit` | Gondolin owns isolated tools; merge stale-edit semantics into its router later |
| Gondolin + host LSP/CodeGraph/MCP/PTY | Built-ins are contained but extension processes are not | Guest process, narrow broker, or disable; whole-process sandbox for strongest boundary |
| Gondolin + RTK only on host | Rewritten command may no longer execute in guest | Install RTK in image or disable it |
| CodeGraph + GitNexus/code RAG | Duplicate indexes, watchers and schemas | CodeGraph only |
| Native Pi Lens + another Pi LSP/Pi Lens MCP | Duplicate servers, diagnostics, actions and schemas | Native Pi Lens only in trusted profile; no self-MCP mirror |
| Pi compaction + LeanCTX/Hermes recap | Competing/stale resume narratives | Pi only; other systems return references or typed contributions |
| RTK + LeanCTX shell rewrite | Double transform and lost raw semantics | A/B, one active |
| RAG + Hermes | Duplicate durable facts and retrieval | RAG authoritative docs; Hermes procedures/preferences/episodes |
| Native capability + MCP copy | Two schemas and possibly two execution boundaries | Prefer native; MCP for genuinely remote services |
| Multiple write agents/foreign CLIs in one checkout | Racing edits and invalid evidence | One writer per worktree; parent validates merged diff |
| `pi-factory` + independent subagent/SSSF chains | Two schedulers own retries, commits and acceptance | `pi-factory` owns the outer loop; native/foreign agents are phase adapters; SSSF remains a source reference |
| Multiple sandbox runtimes | Ambiguous tool owner, paths, network and failure behavior | Exactly one runtime per profile |

## Context and runtime budget

| Layer | Model-visible schema | Automatic prompt/context | Background/runtime cost |
| --- | --- | --- | --- |
| Permission-system | None | Tiny policy guidance at most; prompts only on `ask` | Negligible hooks/logging |
| Interactive shell | One tool, trusted main agent only | None | PTY only while active |
| Gondolin router | Zero additional tools; replaces seven schemas | CWD/status hint only | QEMU VM, image download and guest memory/CPU |
| CodeGraph/Pi Lens | Capability-filter overlapping graph/AST tools; keep compact diagnostics/navigation | Pi Lens context injection disabled | CodeGraph index watcher + Pi Lens/LSP processes |
| RAG/Hermes | Two retrieval tools each at most; memory write hidden | Tiny verified preference block only | Index/service processes; retrieval on demand |
| `project_check` | One tool | None | Repository checks only when called |
| `pi-factory` | Two small stable parent tools; children see none unless explicitly delegated | No automatic workflow dump; bounded phase envelopes/references only | SQLite/WAL and process watcher while runs exist; agent/model cost occurs only in agent phases |
| `@gotgenes/pi-subagents` | Three orchestration/control tools | Per-role prompt and optional inherited context | In-process child sessions/models only when launched |
| MCP | One proxy by default | None | Lazy servers with idle shutdown |
| External agents | Two fixed small schemas, or additive once on deferred-tool models and retained | Task packet only | Separate CLI/model/sandbox/tmux session per run |
| RTK/LeanCTX narrow | No dedicated tool when used as interceptor | No recap injection | Per-command transform; LeanCTX daemon/proxy only in its test profile |

Target the daily driver at roughly the seven built-ins plus structured questions, one CodeGraph surface, one LSP surface, two knowledge calls, `project_check`, two small factory tools and the focused subagent tools. Keep MCP behind one stable proxy. Keep foreign-agent control behind slash commands or activate its two schemas additively once and retain them until session end. Gondolin should add no schema tokens. Automatic per-turn injection should be near zero; normal retrieval and workflow state should return previews/IDs first and expand selected results. This preserves prompt caching because the stable system/tool prefix changes only at a deliberate cache-epoch boundary.

---

## Upgrade procedure

Never update the whole stack at once.

For each extension upgrade:

1. record current package and Pi versions;
2. review changelog and manifest;
3. test with `pi -e npm:<package>` or in a disposable profile where possible;
4. run tool-surface snapshot and smoke tests;
5. test permissions and compaction;
6. run one representative project task;
7. promote the version;
8. keep the previous configuration/package state available for rollback.

Re-run the conflict audit whenever an extension begins providing a new graph, memory, LSP, edit, shell, permission or compaction feature.

## Immediate next action

Execute this order:

1. Back up the current Pi directory and create separate `trusted` and `isolated` agent directories/launchers.
2. Install upstream Pi in `trusted-local`; snapshot its vanilla tool surface.
3. Install pinned permission-system, interactive shell and structured-question package; apply the ask-on-risk policy and test ordinary commands plus the PTY `sudo` flow. Defer todo until long-task traces justify it.
4. Build `pi-session-control`; freeze permissions/capabilities, filter unavailable commands/skills and prove cache-prefix invariants before adding specialists.
5. Build `isolated-local` from a pinned official Gondolin example in a disposable worktree; add default-deny network, path mapping and fail-closed behavior; pass the ten isolation tests.
6. Add CodeGraph and native Pi Lens in conservative mode to `trusted-local`. Do not expose Pi Lens MCP back to Pi; add intelligence to isolation only after guest execution or a narrow broker is proven.
7. Connect the two-call RAG, then build the shared `Executor` and `project_check` correctness tool.
8. Run 20–30 real tasks and collect local traces before installing RTK, hashline, todo or subagents.
9. Build `pi-factory` v1 with typed phases/envelopes/gates, worktree/diff evidence, same-session correction, SQLite/JSONL run state and `inspect`, `plan`, `implement` workflows. Test it headlessly before adding UI.
10. Add the Pi-native `/factory` commands and the two stable parent tools; prove pause/answer/cancel/crash recovery and atomic run acceptance.
11. Add RTK, then hashline in `trusted-local`, one at a time. Keep the isolated router as sole owner until equivalent edit checks are merged into it.
12. Add `@gotgenes/pi-subagents` plus worktrees, compiled profiles/task envelopes and explicit per-role models. Integrate them as factory adapters, not a second workflow owner; test child questions/approvals and containment.
13. Add the parent-owned commit-finalization skill, changelog/documentation preparation and deterministic hooks as the factory's final code phases.
14. Prototype Claude/Codex delegation through the trusted PTY and user `/spawn`; then build the tmux-backed attachable session/question broker and factory adapters only after useful routes are evident.
15. Add lazy MCP and task-specific child exports. Keep native Pi Lens, CodeGraph and local CLIs from being duplicated through MCP.
16. Establish Pi-native compaction baselines; add a coordinator or separate summary model only if continuity tests justify it.
17. Trial Hermes memory, LeanCTX and server orchestration last, each in a separate evaluation profile.

The exact starting stack is therefore: upstream Pi; permission-system; interactive shell; structured questions; CodeGraph; native Pi Lens with context injection/formatting/autofix disabled; `rg`/`ast-grep` and repository checks through Bash; one explicit RAG; and a separate audited Gondolin profile. The first custom component is `pi-session-control`, followed by the shared `Executor`/`project_check`, then `pi-factory`. Commit finalization becomes a factory code phase once checks are stable, and the attachable foreign-agent broker comes after useful delegation traces exist.
