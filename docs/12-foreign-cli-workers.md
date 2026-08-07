# 12 — Foreign CLI Workers

Status: accepted design, 7 August 2026. Implements ADR-042, ADR-043 and ADR-044. Defines how the factory spawns Claude Code, Codex CLI and Antigravity CLI as phase workers, how a provider profile is selected, how a worker is steered onto our capability surface instead of its vendor's, and what must be measured before any of it is believed. Interaction modes, the session broker and the question protocol remain specified in `docs/01` Stage 10; this document supplies the provider-specific surfaces that stage assumed but never enumerated.

Every external fact here was resolved on **7 August 2026** and is evidence of what was true that day, not a target (ADR-039). All three CLIs change fast enough that an adapter verifies its own surface at launch rather than trusting this table.

## 1. Position

A foreign worker executes one phase of one run in one worktree and returns a typed envelope. It is not a peer agent, it does not schedule, it does not commit, and it never edits the shared checkout. The factory owns the sequence; the CLI owns nothing but the turn it was given.

Three properties are required of every adapter, and an adapter that cannot supply all three is not promoted:

- **A launch spec that is fully determined before the process starts** — binary, model, effort, system-prompt addendum, MCP set, tool restrictions, workspace mode, worktree path, timeout. The model never assembles this; policy compiles it.
- **A structured result**, not a screen scrape. Where the CLI can emit machine-readable events or a schema-constrained final message, the adapter uses that path and treats the PTY as a viewing surface only.
- **A measured prefix cost** recorded into the event stream on every launch, because a foreign worker's context overhead is invisible to our own cache accounting and is the largest hidden cost in the design (§6).

## 2. Control channel preference

| Rank | Channel | Use when | Cost of choosing it |
| --- | --- | --- | --- |
| 1 | Native headless structured output | The CLI emits JSON/JSONL events or accepts an output schema | None; strictly best |
| 2 | ACP (Agent Client Protocol) | The CLI ships or has a maintained ACP adapter and we need turn-level control, permission relay and tool-call visibility | One protocol dependency; adapter maturity varies |
| 3 | PTY with sentinel detection | Neither of the above exists for that CLI or version | Prompt detection by silence/text is a fallback, never a correctness mechanism (`docs/01` §10.4) |

The earlier plan listed `ACPAdapter (later)` behind three PTY adapters. That ordering was written before ACP had adoption; it now has. ACP became the headline feature of Zed 1.0 on 29 April 2026 with Claude Code, Codex CLI, Gemini CLI and OpenCode running in-editor at launch, JetBrains shipped support in December 2025, and Zed and JetBrains co-launched the ACP Agent Registry on 28 January 2026. Anthropic has not adopted it natively — Claude Code reaches ACP through Zed's `@zed-industries/claude-code-acp` bridge — so ACP is a genuine option per provider rather than a universal answer, which is why it ranks below a first-party structured channel and above scraping.

ACP matters in the other direction too: `pi-acp` exposes Pi itself as an ACP agent over stdio, which is the cheapest available answer to the editor-integration gap in `11` §4.1 — the harness becomes drivable from Zed, JetBrains or a VS Code ACP client without building an IDE extension. That is an open decision, not a commitment (dossier §D10).

## 3. Provider control surfaces

### 3.1 Claude Code (`claude`)

| Need | Flag or mechanism |
| --- | --- |
| Headless run | `-p` / `--print` |
| Machine-readable output | `--output-format json` or `stream-json`; `--input-format stream-json` for a driven session |
| Model | `--model claude-sonnet-5` (alias or full ID; overrides the `model` setting and `ANTHROPIC_MODEL`) |
| Prompt control | `--append-system-prompt`, `--system-prompt`, `--system-prompt-file` |
| MCP set | `--mcp-config` (file path or inline JSON) with `--strict-mcp-config` to ignore every other MCP source |
| Tool restriction | `--disallowedTools` — a bare tool name removes the tool from context; a scoped rule (`Bash(rm *)`) leaves it present and denies matching calls. `--allowedTools` for the pre-approved set |
| Settings overlay | `--settings` (file path or inline JSON), session-scoped, ≤ 2 MiB |
| Approval behaviour | `--permission-mode` (`default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions`, `manual`) |
| Child roles | `--agents '{"reviewer":{"description":…,"prompt":…}}'` |
| Deterministic enforcement | Hooks. `PreToolUse` runs before the permission prompt and may deny; matchers cover built-ins (`Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Agent`, `WebFetch`, `WebSearch`) and MCP tools by regex (`mcp__server__.*`). A hook decision never overrides a `deny` or `ask` rule |

Two defects constrain what this surface can be trusted to do, and both are recorded as risks rather than worked around silently:

- `--disallowedTools` **does not affect MCP server tools under `-p`** (anthropics/claude-code #12863). Built-in tools are removed correctly; MCP tools remain callable regardless of the flag. Tool restriction for this adapter is therefore enforced by the generated MCP set and by hooks, not by the flag alone (R-093).
- **Built-in MCP servers cannot be removed from context.** `deniedMcpServers` prevents calls but leaves the servers' tool lists and instruction blocks in every session's initial context (#82498, #43690). The adapter's prefix has a floor it cannot configure away (R-094).

That floor is large. Independent measurement in July 2026 put Claude Code at roughly **33,000 tokens sent before the user's prompt**, of which about 24,000 are tool definitions, against roughly 6,900 for a lean comparator. Prompt caching reduces the price of that prefix but not its existence; it occupies the worker's window on every turn.

### 3.2 Codex CLI (`codex exec`)

| Need | Flag or mechanism |
| --- | --- |
| Headless run | `codex exec "<task>"` — single session to completion, no approval prompts, final message on stdout |
| Machine-readable output | `--json` turns stdout into a JSONL event stream (`thread.started`, `turn.started`, `turn.completed`, `turn.failed`, `item.*`, `error`), covering agent messages, reasoning, command executions, file changes, MCP tool calls and plan updates |
| **Typed result** | `--output-schema <json-schema>` constrains the final response to a schema |
| Model and effort | `--model gpt-5.6-luna`; `model_reasoning_effort` ∈ `none, minimal, low, medium, high, xhigh` |
| Profiles | `config.toml` holds flat keys plus `[profiles.*]` and `[mcp_servers.*]`; select with `--profile`, or set `default_profile` |
| Containment and approvals | `sandbox_mode`, `approval_policy` |
| Per-launch override | `--config key=value` |

Codex is the best-behaved headless worker of the three by a wide margin: `--json` plus `--output-schema` supplies exactly the typed-envelope contract `pi-factory` already requires, with no scraping and no sentinel protocol. It is therefore the **default worker for any batch or schema-constrained phase**, and the reference implementation against which the other two adapters are written.

### 3.3 Antigravity CLI (`agy`)

Antigravity CLI is Google's successor to Gemini CLI, announced May 2026; Gemini CLI shut down on 18 June 2026, so any plan text naming `gemini` as a binary is stale.

| Need | Flag or mechanism |
| --- | --- |
| Headless run | `-p` / `--print` |
| Unattended edits | `--mode=accept-edits` is **required**: a plain `agy` in a non-interactive shell waits forever on an approval prompt that never renders |
| Model | `--model <id>` |
| MCP set | `~/.antigravity/mcp_config.json` global, `.agents/mcp_config.json` per workspace |
| Packaged capability | Plugins: `plugin.json` plus optional `mcp_config.json`, `hooks.json`, `skills/`, `agents/`, `rules/` |

Two cautions. Non-TTY execution has a reported empty-output defect (#76) that third-party pty bridges exist to work around, so the adapter allocates a pty rather than piping (R-095). And the default model differs by release channel — Gemini 3.5 Flash on the general CLI, Gemini 3.6 Flash on `antigravity-preview-05-2026` — so the adapter passes `--model` explicitly and asserts what it got instead of inheriting a default.

## 4. Provider profiles

A profile binds task nature to binary, model, effort and access. It is compiled by policy from the phase spec; the model cannot pass one. Defaults are deliberately the cheap-but-capable tier, because the factory's gates catch what a cheaper model gets wrong and re-running a bounded phase is cheaper than paying frontier rates for every phase.

| Profile | Task nature | Binary | Model | Access |
| --- | --- | --- | --- | --- |
| `recon` | Read-only exploration, file location, evidence gathering | `codex exec` | `gpt-5.6-luna`, effort `low` | Read-only mount |
| `sweep` | Long-context passes over many files or documents | `agy -p` | `gemini-3.6-flash` (1M context) | Read-only mount |
| `implement` | Bounded change against an approved plan | `codex exec` | `gpt-5.6-terra`, effort `high` | Dedicated worktree |
| `implement-hard` | Change the cheap tier failed twice on | `claude -p` | `claude-sonnet-5` | Dedicated worktree |
| `review` | Independent requirement review of a diff | `claude -p` | `claude-sonnet-5` | Read-only worktree |
| `typed` | Any phase whose contract is a JSON schema | `codex exec --output-schema` | `gpt-5.6-luna` | Per phase |

### 4.1 When a Pi child beats a foreign CLI

Model diversity is not by itself a reason to spawn a foreign CLI. A native Pi child can already be routed to another provider's model through its `modelClass` (`docs/01` §9.1), and it inherits the full capability surface — graph, LSP, knowledge, `project_check` — with no vendor prefix and no export machinery. If the only requirement is "have Sonnet 5 look at this", a Pi child is the cheaper and better-instrumented way to get it.

A foreign CLI earns its place when the requirement is the **vendor's harness**, not the vendor's model:

| Reason | Example |
| --- | --- |
| The subscription is the cheap path for that model | Attended work under an existing Claude or ChatGPT plan (§7) |
| A schema-constrained result is wanted without building the contract | `codex exec --output-schema` for a typed phase |
| The vendor's own agentic loop, skills or search behave better on that task class | Long autonomous sweeps; vendor-specific tooling |
| A capability Pi lacks | Whatever remains unowned after the parity gaps close (`11` §4.1) |
| Genuine harness diversity in review | A second opinion produced by a different loop, not just a different model |

Applied to the table above: `review` names Claude Code rather than a Pi child with `modelClass: strong-coding` because a differently-shaped agent loop finds different problems. `recon` and `typed` name Codex for the structured channel. Where neither reason holds, the phase runs as a native child.

The review profile deliberately names a different vendor from the implement profile. The existing rule that reviewer and implementer should differ (`docs/01` §9.1) is worth more across vendors than across models of one family, and foreign workers are what make it affordable.

Catalog facts behind the defaults, resolved 7 August 2026:

| Model | Input / output per Mtok | Context | Note |
| --- | --- | --- | --- |
| `claude-sonnet-5` | $2 / $10 | — | Introductory pricing stated through 31 August 2026; re-resolve after |
| `gpt-5.6-luna` | $0.20 / $1.20 | 272k, 128k max output | List price was $1 / $6 before an announced 80% reduction; the reduced figure is corroborated by the host's own `models-store.json`, which also records cache read at 0.1× and cache write at 1.25× |
| `gemini-3.6-flash` | $1.50 / $7.50 | 1M | Released 21 July 2026; knowledge cutoff March 2026 |

`gpt-5.6-terra` ($2.50 / $15 list, before an announced 20% reduction) is the escalation tier within the same CLI, which makes escalation a config change rather than a different adapter.

## 5. Steering a worker onto our capability surface

The reason to inject configuration rather than accept vendor defaults is not aesthetic. A vendor CLI arrives with its own search, its own file reading, its own web tools and — in Claude Code's case — roughly 24k tokens of tool definitions describing them. We already own better answers for most of that: CodeGraph for architecture, Pi Lens for exact semantics, `ast-grep` for structure, the RAG for decisions, `project_check` for truth. A worker that re-derives those by reading files is paying twice and getting a worse answer.

The mechanism is the same in all three cases and is generated per task, never hand-maintained:

1. **Export a task-scoped MCP set** from the canonical registry containing only the servers this phase needs — the Pi Lens MCP mirror where semantics are needed, the CodeGraph server, the knowledge broker, `project_check`. The registry is the single source; the export is disposable. Both mirrors attach to the already-running engine: CodeGraph shares one background server and one watcher across sessions over a local socket, so an exported worker queries the same `.codegraph/codegraph.db` the parent does and builds nothing (ADR-045). A phase whose work is architectural — review, impact, recon — gets the graph by default, because a reviewer that cannot see blast radius is reviewing text.
2. **Point the CLI at that set exclusively** — `--mcp-config` with `--strict-mcp-config` for Claude Code, generated `[mcp_servers.*]` in a per-task `config.toml` for Codex, a workspace `.agents/mcp_config.json` for Antigravity.
3. **Remove the overlapping built-ins where the CLI allows it** — `--disallowedTools` with bare names for Claude Code, subject to R-093.
4. **Append the routing policy to the system prompt**, in the same words as `docs/01` §3.4: graph for architecture, LSP for exact semantics, `ast-grep` for structure, knowledge search for decisions, repository checks for validation. `--append-system-prompt` for Claude Code, `AGENTS.md` in the worktree for Codex, plugin `rules/` for Antigravity.
5. **Enforce what the prompt only requests**, where the CLI has a deterministic hook: a Claude Code `PreToolUse` hook denying the tools the phase must not use, with the reason naming the tool that should be used instead.

Steps 4 and 5 are different in kind and must not be confused: a prompt addendum is a request, a hook is enforcement, and only the second survives a model that decides otherwise. Where no hook exists, the restriction is a preference and is reported as one.

The single mirror rule from `docs/01` §11 still holds: exporting Pi Lens over MCP to a foreign worker is permitted precisely because that worker has no native lifecycle integration, and it must reuse the running engine rather than starting a second language server for the same worktree.

## 6. The measurement obligation

Everything in §5 is a hypothesis until the prefix is counted. The plan's own discipline — measured budgets, not assumed ones (ADR-035) — applies with more force here, because a foreign worker's context is outside our cache accounting entirely.

Every adapter therefore records, per launch, into the event stream: `foreign_binary`, `foreign_version`, `model`, `effort`, `prefix_tokens_measured`, `mcp_servers_exported`, `tools_removed`, `tools_denied_by_hook`, `input_tokens`, `output_tokens`, `cached_input_tokens` where the provider reports it, `wall_ms`, and the phase verdict. A profile whose measured prefix does not improve on the stock CLI is recorded as not improving on it; the config is then either fixed or dropped. Reporting a saving that was not measured is the specific failure ADR-035 was written against.

The concurrency budget is part of the same accounting. Three CLIs each carrying their own prefix, run in parallel across worktrees, is the cheapest way to make a bounded task expensive. Start at two concurrent foreign workers, raise only from traces (R-100).

## 7. Authentication and the provider-policy boundary

Anthropic's February 2026 terms restrict OAuth authentication to Claude Code and Claude.ai; using subscription OAuth tokens with the Agent SDK is not permitted, and the SDK requires an API key. Local, scripted invocation of the official CLI on your own machine remains within the consumer terms — it is the product's intended use. A programmatic-usage split from subscription limits was announced for 15 June 2026 and then cancelled on that date, which is itself the reason not to design against a particular billing arrangement.

Two consequences for this design, both load-bearing:

- The factory **spawns the official CLI as a local process**. It does not re-implement a provider client, does not proxy OAuth tokens, and does not wrap a subscription into a service. That is what keeps the arrangement on the right side of the line, and it is a design constraint rather than a convenience (R-096).
- **Unattended, high-volume use is a separate question from technical capability.** The existing rule stands: technical ability to automate a subscription does not establish provider-policy permission for it. Where a workload is genuinely unattended and high volume, it runs on an API key under commercial terms, and the profile records which credential class it used.

## 8. Sources

- [Claude Code CLI reference](https://code.claude.com/docs/en/cli-reference), [hooks reference](https://code.claude.com/docs/en/hooks), [`--disallowedTools` vs MCP tools (#12863)](https://github.com/anthropics/claude-code/issues/12863), [built-in MCP servers in context (#82498)](https://github.com/anthropics/claude-code/issues/82498), [tool-injection suppression (#43690)](https://github.com/anthropics/claude-code/issues/43690), [measured prefix comparison](https://systima.ai/blog/claude-code-vs-opencode-token-overhead)
- [Codex non-interactive mode](https://developers.openai.com/codex/noninteractive), [advanced configuration](https://developers.openai.com/codex/config-advanced), [headless execution mode](https://deepwiki.com/openai/codex/4.2-headless-execution-mode-(codex-exec))
- [Antigravity CLI](https://antigravity.google/product/antigravity-cli), [Gemini CLI transition notice](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/), [MCP and skills configuration](https://medium.com/google-cloud/configuring-mcp-servers-and-skills-for-antigravity-cli-and-ide-a938c7eebb78), [non-TTY bridge and #76](https://github.com/rhishi99/agy-headless-bridge)
- [Agent Client Protocol](https://agentclientprotocol.com/get-started/introduction), [Zed ACP](https://zed.dev/acp), [`@zed-industries/claude-code-acp`](https://www.npmjs.com/package/@zed-industries/claude-code-acp), [`pi-acp`](https://www.npmjs.com/package/pi-acp)
- [GPT-5.6 model tiers](https://openai.com/index/gpt-5-6/), [Gemini 3.6 Flash announcement](https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-3-6-flash-3-5-flash-lite-3-5-flash-cyber/), [Claude model pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [Claude Code terms discussion](https://autonomee.ai/blog/claude-code-terms-of-service-explained/), [billing-change cancellation](https://www.aicodex.to/articles/claude-subscription-credit-changes)
