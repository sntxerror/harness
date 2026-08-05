# Ultimate Pi Setup — Session Portability Specification

Revision: 5 August 2026

## Decision

The setup uses two local canonical records:

- Pi JSONL is the native conversation record;
- `pi-factory` manifests, envelopes, events and artifacts are the workflow record.

Native session resumption is an optimization. Correctness requires that a new provider or harness can continue from readable local state without dereferencing provider IDs or decrypting provider-only state.

This specification adds a portable projection. It does not add another session manager, compactor, memory system or workflow scheduler.

## Ownership

| Information | Authoritative owner | Portable contribution |
| --- | --- | --- |
| User/assistant/tool timeline | Pi SessionManager | Active branch events with raw pre-compaction lineage |
| Conversation compaction | Pi | Readable summary, retained-tail IDs/content, source range and policy |
| Effective prompt/tools/skills/policy | `pi-session-control` | Compiled readable snapshots, versions and hashes |
| Task/run/phase state | `pi-factory` | Manifests, envelopes, gates, acceptance and repository identities |
| Native child task/messages | Native subagent adapter | Exact task, lineage, grant, questions and result |
| Foreign CLI process/session | Foreign-harness broker | Launch spec, events/transcript, questions, result and artifacts |
| Project facts/documents | Project RAG | Stable document/retrieval references and optional snapshots |
| Code relationships | CodeGraph | Query/result references and engine/index identity when decisive |
| Procedural/episodic learning | Hermes Memory Service | Reviewed memory IDs only; never raw session replacement |

## Portability tests

A bundle is acceptable only when it supports:

1. **Inspection** — a user can see readable instructions, messages, tools, questions and evidence.
2. **Export** — the local bundle plus declared external artifacts contains all required meaning.
3. **Replay/continuation** — another capable harness can construct a semantically sufficient context.
4. **Audit** — actions can be connected to a readable task, capability grant, evidence and approval.
5. **Deletion** — every local dependency and known remote retention dependency is enumerated.

Replay does not promise the same next token, reasoning or outcome. It promises that no indispensable meaning is available only to the original provider.

## `PortableSessionBundleV1`

```text
portable-session-<timestamp>-<id>/
├── manifest.json
├── continuity.json
├── events.jsonl
├── capabilities/
│   ├── session-manifest.json
│   ├── system-prompt.txt
│   ├── tool-schemas.json
│   ├── skill-catalog.json
│   ├── permission-summary.json
│   └── containment-summary.json
├── compaction/
│   └── lineage.json
├── evidence/
│   └── index.json
├── artifacts/
│   └── ...
├── provider-state/
│   └── sealed-state.json
└── deletion-manifest.json
```

`provider-state/` is optional, encrypted/permissioned and never required by the portable continuation path.

### `manifest.json`

Required fields:

- schema and exporter version;
- generated timestamp;
- source harness/session/active-branch identifiers;
- parent run/phase/agent lineage;
- repository origin hash, base commit, tree/worktree identity;
- provider/model/thinking used by the source session;
- `SessionCompatibilityV1` hash;
- content hash, byte size, MIME/type and retention class for every member;
- portability grade: `complete`, `partial` or `failed` with explicit reasons;
- redaction policy/version and warnings.

Credentials, tokens, passwords, raw environment variables and unrestricted home-directory paths are forbidden.

### `continuity.json`

This is the compact first document consumed by the receiving agent:

```json
{
  "goal": "",
  "constraints": [],
  "decisions": [],
  "completed": [],
  "changedFiles": [],
  "currentFailures": [],
  "validationState": [],
  "pendingQuestions": [],
  "activeProcesses": [],
  "evidenceRefs": [],
  "artifactRefs": [],
  "nextAction": ""
}
```

The receiving agent starts with this bounded record. It retrieves `events.jsonl` or artifacts only when evidence is needed. The bundle is not automatically injected into every turn.

### `events.jsonl`

Each event is readable and typed:

```json
{
  "id": "evt_...",
  "parentId": "evt_...",
  "timestamp": "...",
  "actor": { "kind": "user|agent|tool|code", "id": "..." },
  "type": "message|tool_call|tool_result|question|answer|approval|compaction|handoff|gate",
  "content": {},
  "artifactRefs": [],
  "redactions": []
}
```

Preserve readable user/assistant text, tool name/arguments, bounded tool results, shell exit state, questions/answers, approvals, task envelopes, agent lineage, compaction summaries and gates. Remove hidden chain-of-thought. Preserve a readable explanation or handoff for any opaque provider item that affects later work.

### Capability snapshots

Hashes alone can detect an incompatible resume but cannot reconstruct the environment. The bundle therefore contains either readable contents or content-addressed local references for:

- base/system role prompt;
- ordered model-visible tool schemas;
- selected skill catalog and version/source hashes;
- extension/package pins;
- effective permission summary;
- containment/executor/mount/network summary;
- compaction policy;
- repository/project instructions;
- MCP proxy/export identity.

Secrets and private provider configuration are replaced by capability descriptors such as `credential: available-through-broker`, never copied.

### Compaction lineage

For every active compaction checkpoint record:

- Pi compaction entry ID;
- readable summary;
- first kept entry or materialized retained tail;
- summarized source entry IDs/hashes;
- summarization instructions;
- summarizer provider/model and usage;
- compaction policy hash;
- structured continuity fields/details;
- raw pre-compaction branch availability.

Pi remains the only component that changes active conversation history. Export reads this state after the fact.

### Evidence and hosted tools

Evidence-critical web/search/browser operations record:

- exact query/request;
- retrieval timestamp;
- result ordering and filtering metadata when available;
- URL/title;
- passages or captured content actually shown to the model;
- content hash and snapshot/artifact reference;
- tool/provider identity;
- known incompleteness.

A polished answer, citation list or provider object ID is not sufficient evidence. Provider-hosted search can be used for discovery, but an accepted research/review gate requires a locally visible evidence record.

### Child agents

Before a child starts, persist:

- parent/run/phase/child lineage;
- exact `AgentProfileV1` and `TaskEnvelopeV1` references;
- provider/model/thinking;
- allowed tools, commands, paths, MCPs, credentials and network class;
- worktree/repository identity;
- exact readable task text.

Persist structured questions, user answers, final typed result and artifacts. If a foreign/provider-hosted harness hides internal delegation or messages, mark the bundle `partial`; hidden messages may not be the sole basis of an accepted gate.

## Export behavior

The Pi-native exporter:

- registers slash commands only;
- exposes no permanent model-visible tool;
- starts no background daemon;
- performs no per-turn prompt/context injection;
- reads the live Pi branch through runtime APIs;
- never guesses the active session from file modification time;
- never rewrites or prunes the source session;
- optionally uses a separately configured one-shot summarizer for `continuity.json`;
- falls back to deterministic extraction when summarization fails;
- writes atomically into a new directory with mode `0700` and files `0600`;
- verifies hashes/schema before reporting success.

Suggested commands:

```text
/session export-portable [run|session]
/session verify-portable <path>
/session inspect-portable <path>
/session delete-portable <path>
```

`pi-factory` may invoke the same exporter as deterministic code at phase/run boundaries. It must not inject the resulting packet back into the current parent conversation.

## Resume decision

```text
compatibility hash equal and native session healthy
    -> resume native session

process crashed but compatibility hash equal
    -> reconcile processes/worktree, then resume

provider/model/profile/tools/skills/policy/executor/worktree changed
    -> new cache island from continuity + explicit evidence retrieval

native sessions unavailable
    -> resume pi-factory from manifests/envelopes/artifacts
```

Do not try to preserve the old provider's prompt cache across a provider switch. Preserve the receiving profile's stable static prefix; append the bounded task/continuity packet as the first dynamic user message.

## Security and retention

- Bundle root mode `0700`; files `0600`.
- Add bundle location to Git ignore or keep it outside repositories.
- Never record sudo passwords, interactive credential input, secret environment values or SSH-agent material.
- Redact structured fields before generic regex fallback.
- Store full raw output only under bounded retention classes.
- Mark each artifact `ephemeral`, `run`, `project` or `audit` retention.
- Encrypt sensitive audit archives at rest.
- `deletion-manifest.json` lists local paths, hashes, storage services, provider `store` behavior and remote copies that cannot be deleted locally.
- Hermes receives reviewed derived memories and references, never the raw bundle automatically.

## Existing package assessment

`@danchamorro/pi-handoff-agent@0.2.0` is a useful interim reference. It registers `/handoff-export`, reads the live Pi branch, preserves tool evidence and raw pre-compaction history, removes thinking blocks and writes JSON/Markdown. It has no permanent model tool or background process.

It is not the final canonical implementation because it does not capture the complete capability manifest, content-addressed artifacts, factory gates, hosted-tool evidence provenance, deletion inventory or full foreign-harness process tree. Trial it manually only until the shared exporter exists; do not maintain two production handoff formats.

## Acceptance suite

1. Export after at least one compaction; verify raw earlier messages and readable compaction lineage.
2. Export a session containing long/spilled Bash output; retrieve the decisive raw artifact without copying secrets.
3. Export after native and foreign child delegation; recover exact readable task/permissions and returned evidence.
4. Export research using browser/search; compare local passages/snapshots to what the source agent used.
5. Remove original provider credentials and continue the next phase with a different provider.
6. Change one tool/profile/policy field; confirm native resume is rejected and portable cold-start succeeds.
7. Delete the bundle using its deletion manifest; verify no local referenced copy remains.
8. Confirm export causes no parent prompt-prefix mutation, model-tool schema change or additional per-turn injection.

## Sources

- [The Session You Cannot Take With You](https://earendil.com/posts/session-portability/)
- [Pi session file format](https://pi.dev/docs/latest/session-format)
- [Pi sessions and JSONL import/export](https://pi.dev/docs/latest/usage)
- [Pi compaction](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/compaction.md)
- [`@danchamorro/pi-handoff-agent`](https://pi.dev/packages/%40danchamorro/pi-handoff-agent)
