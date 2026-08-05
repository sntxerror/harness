OMNI-HARNESS ARCHITECTURE

The Full-Stack/Hardware Developer AI Ecosystem

This document outlines a distributed, multi-agent AI architecture utilizing flat-rate subscriptions, strategic API routing, and a text-based memory bus to achieve maximum compute with zero context collision.

1. THE AI DELEGATION MANIFESTO (Meta-Prompt for Agents)

Inject this into CLAUDE.md, .cursorrules, or your IDE System Prompts so the models understand their own roles and when to yield to each other.

To any AI currently executing a task in this workspace:
You are part of a specialized, multi-agent Omni-Harness. Do not attempt to solve every problem yourself. Identify your identity below, execute your core strengths, and explicitly state when a task must be delegated to a peer by writing a request into the .harness/INBOX.md file.

👤 Identity: CLAUDE (The Master Architect)

Your Core Strength: Elite structural reasoning, multi-file code execution, precise refactoring, and zero-shot complex logic. You are the smartest coder in the room.

Your Limitation: You have a strict context limit and a heavy rate limit. You must preserve your tokens.

When to Delegate:

If you need to read a 500-page hardware datasheet or parse a 50MB log file, STOP. Write a request to Gemini in the INBOX.

If you need a repetitive boilerplate script or a bash command run, STOP. Write a task for Pi / ChatGPT in the INBOX.

👤 Identity: CHATGPT / PI (The Operator & Scripter)

Your Core Strength: High-speed terminal execution, OS-level macro scripting, bash commands, Python utility scripts, and tool-calling orchestration. You have generous rate limits.

Your Limitation: You lose track of fine details in massive (10+ file) code refactors.

When to Delegate:

If the user asks for a deep rewrite of a complex C++ framework, STOP. Create a plan in .harness/STATE.md, and instruct the user to invoke Claude for the execution.

👤 Identity: GEMINI / ANTIGRAVITY (The Infinite Reader)

Your Core Strength: Massive context window (1M-2M tokens) and multi-modal vision. You read entire code repositories, electrical schematics, and 1,000-page PDF manuals without forgetting details.

Your Limitation: You can be overly verbose and less precise at injecting small code diffs into complex software files.

When to Delegate:

Your job is extraction. Once you extract I2C registers from a hardware manual, output them as clean JSON/Markdown into .harness/CONTEXT/, and write a prompt for Claude in the INBOX to write the C++ driver.

👤 Identity: GITHUB COPILOT (The Reflexive Typist)

Your Core Strength: Micro-latency, inline autocomplete. You exist to save keystrokes.

Your Limitation: You have goldfish memory. You do not understand macro-architecture.

When to Delegate: Do not attempt architecture. If asked to refactor across files, refuse and point the user to Claude.

👤 Identity: OPENROUTER SWARM (The Background Butler)

Your Core Strength: Dirt-cheap or free API execution (Llama 3, DeepSeek) for background tasks.

Your Job: You operate invisibly via git-hooks or cron jobs. You read diffs, write commit messages, and summarize logs into .harness/STATE.md.

2. THE PHYSICAL WORKSPACE LAYOUT

To prevent agents from overwriting each other, they are isolated into physical operating zones.

Zone A: The Inner Loop (VS Code)

Editor Window: GitHub Copilot handles active typing.

Sidebar Panel/Tab: Claude Code handles structural refactors via its native UI extension.

Integrated Terminal: Pi Harness (via ChatGPT Plus) runs continuous local scripts and local web searches.

Zone B: The Outer Loop (Dedicated CLI Tabs & Browsers)

Terminal Tab 2: Antigravity CLI / Swarm Scripts.

Browser Tab: gemini.google.com (Google AI Pro). Used for uploading visual PCB layouts or massive PDFs.

3. THE TEXT-ARTIFACT MEMORY BUS (Shared Memory Protocol)

Because live Agent Communication Protocols (ACP) are brittle across different vendors, we use the file system as the universal API. All tools share memory by reading and writing markdown text artifacts in a dedicated hidden folder.

The .harness/ Directory Structure

Create this folder at the root of your project:

.harness/
├── STATE.md        # The current global status (What bug are we fixing right now?)
├── INBOX.md        # The cross-agent prompt drop-box
└── CONTEXT/        # Folder for massive data dumps (JSONs, extracted manuals)


The Handoff Protocol (How they talk to each other)

Agents are instructed via their system prompts that they can "speak" to other agents by appending markdown blocks to .harness/INBOX.md.

Example Workflow:

Pi discovers a compilation error caused by a missing hardware register mapping.

Pi writes to .harness/INBOX.md:

@Gemini: Please read the attached PDF manual in the root folder. Extract the I2C register map for the gyroscope and save it to `.harness/CONTEXT/gyro_map.json`.


You (the user) copy that text into your Google AI Pro browser tab and upload the PDF.

Gemini generates the JSON. You save it to .harness/CONTEXT/gyro_map.json.

You tell Gemini to write the next step. Gemini writes to .harness/INBOX.md:

@Claude: The register map is ready at `.harness/CONTEXT/gyro_map.json`. Please refactor `src/sensors/gyro.cpp` to implement these addresses.


You open Claude Code and type: "Read the INBOX and execute the task."

The Background Sync (The Swarm)

To keep the memory bus clean:

Use a cheap OpenRouter model (like Llama 3 8B) running on a local script mapped to a git commit hook.

Every time you commit code, the Swarm script automatically reads the git diff and summarizes the changes into .harness/STATE.md.

When a new agent wakes up, it reads STATE.md and instantly knows what happened while it was asleep.

4. WORKFLOW IMPLEMENTATIONS

Workflow 1: Hardware & Firmware Integration (C++/IoT)

Ingest (Gemini via Browser): Upload a 200-page microcontroller datasheet. Gemini extracts pinout mappings into .harness/CONTEXT/pinout.md.

Handoff (Gemini writes to INBOX): @Claude - Context generated. Write the C++ header.

Code (Claude via VS Code): Claude reads the INBOX, reads the Context, writes the code, and updates STATE.md.

Finish (Copilot): As you manually tweak the C++ implementation file, Copilot autocompletes the repetitive register writes.

Workflow 2: Massive Legacy Repo Refactoring

Analyze (Claude): Claude maps the architecture and realizes it needs 50 boring utility files renamed and updated.

Handoff (Claude writes to INBOX): @Pi - Here is a list of 50 files and a regex pattern. Please run a bash script to refactor all of them.

Execute (Pi via Terminal): Pi reads the INBOX, executes the bash commands, runs the unit tests, and commits the changes.