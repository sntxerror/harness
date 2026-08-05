when i use vscode with copilot claude code and codex extensions all together, whre should i store ontext files prompts skills and so on so all harnesses will have access to the,?

When you run multiple AI assistants on the same codebase — like GitHub Copilot for in-editor completions, Claude Code for repo-level delivery, and Codex-powered extensions or autonomous harnesses (like Aider, Cline, or OpenCode) for execution — the biggest risk is context fragmentation. Each tool looks for its baseline instructions in a different default location.

The most resilient architecture is the Hub-and-Spoke pattern: store all actual knowledge in a single centralized folder, and use the tool-specific files simply as pointers to that folder.

The Hub: Your Source of Truth
Create a dedicated directory at the root of your project (e.g., .context/ or .agent/) to hold all plain-text context files. This prevents you from maintaining duplicate rules across different tools.

A strong structure looks like this:

.context/tech-stack.md: Define the exact stack and versions (e.g., Next.js frontend, Strapi headless CMS, and PostgreSQL, all orchestrated via Docker Compose).

.context/architecture.md: Detail how the components interact, including custom Linux system configurations or API gateway routing rules.

.context/coding-standards.md: Establish formatting rules, naming conventions, and preferred OpenRouter endpoint interaction patterns.

.context/skills/: A folder containing reusable code patterns, terminal-native automation scripts, or specific Dockerfile snippets.

.context/PICKUP.md: A rolling session state file detailing what was just finished, what is currently broken, and what needs to happen next.

The Spokes: Wiring the Tools
With your knowledge centralized, configure each harness to read from the hub. Keep these entry files extremely brief — their only job is to route the AI to the source of truth.

GitHub Copilot
Copilot reads from a specific markdown file in the .github directory. Create .github/copilot-instructions.md with a strict directive:

Markdown
You are assisting with this repository. Before suggesting code, answering architectural questions, or reviewing files, you MUST read the following:
- `.context/tech-stack.md`
- `.context/architecture.md`
- `.context/coding-standards.md`
Codex Extensions and Autonomous Harnesses
Most autonomous terminal agents and VS Code extensions (including Aider, Cline, and OpenCode) respect standard rule files placed at the project root. Create a .cursorrules or .aiinstructions file:

Markdown
# Project Context
Do not guess the tech stack or architectural patterns. 
Always read `.context/PICKUP.md` to understand current session state before making edits.
Read the guidelines in the `.context/` directory before writing or modifying code.
Claude Code
Claude operates exceptionally well with explicit "intent" files and meta-guides. When invoking the CLI, you can point it directly to your context files:

Bash
claude "Read .context/architecture.md and the current state in .context/PICKUP.md, then implement the new API route."
Alternatively, you can create an AGENT.md file at the root that acts as a meta-directory, explaining to Claude exactly what lives inside the .context/ folder and when to retrieve it.

Preventing Collisions
When orchestrating multiple tools, never let them write to the repo at the exact same time. Use the .context/PICKUP.md file as a baton pass.

For example: Have Claude Code draft the initial architecture and update PICKUP.md with what it built. Then, when you switch to Copilot or Cline to debug a specific Node.js route or refine a container configuration, they read PICKUP.md and know exactly where Claude left off.