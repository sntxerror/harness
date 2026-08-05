Unified AI Development Infrastructure: The Single-Brain, Dual-Frontend Blueprint

1. Strategic Architectural Vision: The "Single-Brain, Dual-Frontend" Paradigm

The "Single-Brain, Dual-Frontend" approach is a strategic architectural evolution designed to eliminate context fragmentation in AI-augmented development. In traditional "Fragmented Agent" setups, developers juggle isolated AI instances in the Terminal and the IDE, leading to "split-brain" syndrome—where history, tool-access, and learned architectural context are trapped in silos. This blueprint centralizes the Intelligence Layer (model routing, shared middleware, and tool logic) into a unified core while deliberately isolating the Interface Layer (Session state, history, and workspace-specific telemetry).

The goal is C2 (Command and Control) Isolation: we share the "brain" (the intelligence) but partition the "history" to prevent session poisoning—ensuring that high-noise terminal activity (like npm test logs) does not pollute the refined reasoning tree required for complex IDE-based refactoring.

Table 1: Infrastructure Maturity Comparison

Metric Fragmented Agent Setup Unified Blueprint (C2 Isolation)
Context Parity Low; history and state are siloed per interface. High; Shared Core ensures identical logic/prompts.
Resource Efficiency Low; duplicated LSP/MCP processes. High; Centralized Docker-based tool multiplexing.
Tool Availability Inconsistent; varying capabilities. Absolute; Universal access via MCP-over-HTTP.
Transport Protocol Local stdio (brittle) MCP Streamable HTTP (2025-06-18 Spec)

By decoupling the Intelligence Layer from the Interface Layer, the local environment remains minimalist. Heavy lifting—database connections, browser automation, and multi-tier failover—is offloaded to an environment-agnostic infrastructure hub.

1. Layer 1: The God Proxy (Centralized Infrastructure Hub)

The God Proxy serves as the persistent background daemon and MCP Multiplexer. Hosting this hub in a Docker container ensures that the AI's "nervous system" remains immune to local OS quirks and resource-heavy process duplication.

Upstream Provider Management

The proxy leverages LiteLLM to act as a universal gateway to Anthropic, Google AI Studio, and OpenRouter. This provides a single OpenAI-compatible /v1/chat/completions endpoint for all frontends. For advanced operators, the pi-antigravity-rotator sidecar handles Tier R2 rotation: percentage-based account rotation and ban evasion, ensuring the agent never "goes blind" due to rate limits.

The Lazy-MCP Multiplexer

The God Proxy implements a Lazy-MCP Host. Instead of the "Context Tax" imposed by traditional MCP setups—where agents are force-fed 50+ tool schemas (15k–50k tokens) upon connection—the Proxy exposes a single meta-tool. Following the latest MCP Streamable HTTP transport standards, tool schemas are discovered on-demand. Persistent connections to heavy tools (Postgres, Playwright, Docker) are maintained within the Proxy, ensuring that both the Terminal and VS Code share the same warm resource pool.

Deferred Superpowers

The architecture is designed for future activation of the following components once the MVP is stabilized:

1. Redis State Layer: Centralized quota tracking and cross-session tool state.
2. Time-Travel Interceptor: A network-level token scanner for silent retries of malformed JSON outputs.

3. Layer 2: Shared Local Extension (The Intelligence Bridge)

The pi-shared-core package is a version-controlled, git-based "private app store" for agent capabilities. It bridges the God Proxy to the local workspace, ensuring that safety guardrails and optimized reading tools are applied universally.

Bash-Guard & Middleware Interception

To secure the shell, we integrate pi-denoish (utilizing principles from @aslamplr/pi-safe-shell). This middleware intercepts high-noise commands like find, cat, and grep. Instead of raw execution, it performs Argument Mutation:

* find is automatically injected with -not -path "*/node_modules/*".
* cat is piped through a Truncation Stream that enforces a 50KB/2000-line hard cap.
* Noisy build logs (e.g., dotnet build) are passed through reducers that strip boilerplate, leaving only errors and warnings.

Smart-Read & Context Minimization

We utilize context-mode to achieve a 98% reduction in context window usage. Rather than reading raw text, this layer indexes tool output into a per-project SQLite FTS5 database. Large files are handled via pi-lens and ast-grep, performing structural analysis to return signatures and interfaces rather than implementation bloat.

Client-Side Lazy Loading

Integration via pi-mcp-adapter (v2.10.0) ensures that the frontend only ingests tool definitions when they are actively called. This hides 50+ schemas behind a single proxy tool, preserving VRAM and reducing API costs.

1. Layer 3: Dual-Instance Deployment (Terminal vs. VS Code)

Deployment follows a C2 Isolated Brain strategy: one global pi binary, but two independent agent directories. This prevents history entanglement and allows for different model-selection policies.

Instance Configuration Matrix

Feature Instance A: Terminal CLI Instance B: VS Code (cdervis/vscode-pi)
Logic Source pi-shared-core (git) pi-shared-core (git)
Agent Dir ~/.pi/agent/ ~/.vscode-pi/agent/
LSP Layer Standalone pi-lsp / pi-lens Native VS Code Extension APIs
Primary Goal Fast scratchpad / scripting Complex multi-file engineering

The cdervis/vscode-pi extension serves as the primary IDE bridge, configured via the pi.agentDir lever to maintain a separate session history from the CLI. This ensures that terminal "noise" never poisons the IDE's reasoning tree. Behavioral parity is maintained because both instances consume the same pi-shared-core and God Proxy.

1. Intelligent Model Routing and Failover Cascade

A multi-tiered routing policy balances reasoning depth against cost. This system is split between the frontend extension (Tier R1) and the infrastructure proxy (Tier R2).

Tier R1 vs. Tier R2 Routing Logic

graph TD
    A[User Prompt] --> B{Tier R1: Pi Extension}
    B -- failover --> C[Free Google/AI Studio]
    B -- failover --> D[Free OpenRouter]
    B -- primary --> E[God-Proxy /v1/]

    E --> F{Tier R2: God Proxy Hub}
    F -- rotation --> G[Antigravity Account Pool]
    F -- failover --> H[Paid OpenRouter/Anthropic]

Routing Policy

* Tier R1 (Cross-Provider): Handled via pi-multi-pass inside the Pi agent. It manages the cascade from free tiers to the infrastructure hub.
* Tier R2 (Intra-Provider): Handled via pi-antigravity-rotator inside the God Proxy. It manages account-level thresholds (e.g., 20% quota drops) invisibly to the agent.
* Project-Level Pinning: .pi/settings.json overrides allow high-complexity projects (e.g., Rust) to default to "Heavy Reasoning" models (Claude 3.5 Sonnet) while web projects use "Fast/Cheap" models (Gemini Flash).

1. Implementation Roadmap and Configuration Hierarchy

The infrastructure is governed by a 3-Repo structure: The Proxy Server, the Shared Core, and the Projects.

The Ultimate Configuration Tree

~/
├── .pi/ (Global Terminal Brain)
│   ├── auth.json                  # Primary credentials vault
│   └── settings.json              # Global defaults (defaultModel: gemini-flash)
├── .vscode-pi/ (Isolated IDE Brain)
│   └── agent/                     # Isolated history/sessions
├── pi-proxy-server/ (Repo 1: Docker)
│   ├── docker-compose.yml         # LiteLLM + MCP Multiplexer
│   └── mcp-registry.json          # Shared tool definitions
├── pi-shared-core/ (Repo 2: Intelligence)
│   ├── pi.config.json             # Multi-pass failover cascade
│   └── APPEND_SYSTEM.md           # Immutable safety guardrails
└── <project-name>/ (Repo 3: Workspace)
    └── .pi/
        ├── AGENTS.md              # Project-specific context
        └── settings.json          # Pinning (defaultModel: claude-sonnet)

Critical Setup Commands

1. Global Engine: npm install -g @earendil-works/pi-coding-agent
2. Isolated IDE Initialization: Set pi.agentDir in VS Code to ~/.vscode-pi/agent/.
3. Intelligence Deployment: pi install git:github.com/<user>/pi-shared-core (Run in both Terminal and IDE contexts).
4. Community Integration: pi install npm:pi-mcp-adapter npm:context-mode npm:pi-multi-pass.

This blueprint transforms the workstation into a "God Mode" environment—where the AI is no longer a siloed tool, but a unified, workspace-aware infrastructure that delivers precision and efficiency across every development frontend.
