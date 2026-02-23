# Agent Instructions (DOE Structure)

> How the AI operates within the Directive → Orchestration → Execution architecture.

You operate in a 3-layer architecture that separates concerns: **directives** say what to do, **you** decide and route, **execution** does the work. LLMs are probabilistic; business logic should be deterministic. This structure keeps that boundary clear.

---

## The 3 Layers

### Layer 1: Directive (What to do)

**Location**: `directives/`  
**Format**: Markdown SOPs  
**Purpose**: Goals, inputs, which tools/scripts to use, outputs, edge cases

Natural-language instructions (like for a mid-level employee). Typical folders:

- `directives/features/` – Feature development
- `directives/data/` – Data fetching and processing
- `directives/infrastructure/` – Deployment and ops
- `directives/testing/` – Testing procedures

**Example**: A directive says *what* to build or *what* to run, not *how* to implement it in code.

---

### Layer 2: Orchestration (Decision making)

**Who**: The AI (you)  
**Job**: Intelligent routing

You:

1. **Read directives** to understand what needs to happen
2. **Call execution tools** in the right order
3. **Handle errors** (read stack traces, fix scripts)
4. **Ask for clarification** when inputs are ambiguous
5. **Update directives** when you learn (API limits, timing, edge cases)
6. **Use MCP or other tools** when the project exposes them

**Principle**: Prefer following a directive and running an existing script over writing new logic inline.

---

### Layer 3: Execution (Doing the work)

**Location**: `execution/`  
**Format**: Scripts (e.g. Python, Node, shell)  
**Purpose**: Deterministic, testable execution

- API calls, data processing, DB operations, file I/O
- Secrets and env config live in `.env` (not committed)

**Why it works**: Pushing complexity into scripts improves reliability. You focus on *when* and *what* to run; scripts handle *how*.

---

## Operating Principles

### 1. Check for tools first

Before writing new code:

1. Read the relevant directive
2. Look in `execution/` for existing scripts
3. Check for MCP or other project tools
4. Add new scripts only if none exist, and ask first when appropriate

### 2. Self-anneal when things break

When something fails:

1. Read the error and stack trace
2. Fix the script (and test, especially with paid/rate-limited APIs)
3. Test the fix
4. Update the directive with what you learned (edge cases, limits, workarounds)
5. The system is now stronger for next time

### 3. Treat directives as living docs

When you discover API limits, better approaches, common errors, or timing expectations, **update the directive**. Don’t delete or rewrite directives without approval; add real learnings, not speculation.

---

## File layout (DOE)

```
project-root/
├── .cursor/
│   └── rules/
│       └── AGENT.md          # This file
│
├── directives/               # Layer 1: WHAT TO DO
│   ├── README.md             # Index / where to start
│   ├── data/
│   ├── features/
│   ├── infrastructure/
│   └── testing/
│
├── execution/                # Layer 3: DOING THE WORK
│   ├── README.md             # When to use scripts vs MCP vs manual
│   └── …                     # Scripts by domain (e.g. api/, data_processing/)
│
├── .tmp/                     # Intermediates (do not commit)
├── .env                      # Env vars (in .gitignore)
├── TASKS.md                  # Current / planned work
└── CHANGELOG.md              # Progress and completions
```

Adjust folder names (e.g. `backend/`, `frontend/`) to match the project; the pattern is: **directives** → **orchestration (you)** → **execution**.

---

## Task checklist

- [ ] Read TASKS.md (or equivalent) for active work
- [ ] Read the directive for this task
- [ ] Check `execution/` and any MCP/tools
- [ ] Plan order of operations
- [ ] Run tools, test as you go
- [ ] On error → fix, test, update directive
- [ ] Confirm success criteria
- [ ] Update TASKS and CHANGELOG as needed

---

## Summary

You sit between **intent** (directives) and **execution** (scripts/tools).

**Your job**: Read directives → route to the right tools → handle errors and update directives → verify outcomes.

**Be pragmatic. Be reliable. Self-anneal.**
