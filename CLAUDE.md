# CLAUDE.md

This project uses **sdd-codex-starter** — spec-driven development with adversarial Codex second opinion.

> **STOP. Before any task, read [`AGENTS.md`](AGENTS.md).** It is the authoritative ruleset, short (~280 lines), and reading it is non-negotiable. Full trigger table, Codex three-stage rules, audit trail formats, exception clauses — all in there.

## What this stub guarantees (so you don't skip AGENTS.md)

If the user describes a task that **creates** / **modifies behaviour of** / **chooses technology for** / **designs** something, you MUST start SDD flow immediately (`openspec new change <id>` → proposal → design → spec → tasks). Don't ask "should we use SDD?" — see [`AGENTS.md`](AGENTS.md) §0 for the full trigger table.

Crucially: **task size is NOT a trigger condition** — 「太簡單」/ toy / demo / POC / "I'll write a quick prototype first" are all **anti-patterns**, not legitimate skips. The exception clauses (pure bugfix / rename / docs) are listed in [`AGENTS.md`](AGENTS.md) §0「不觸發的場合」.

For Codex three-stage (proposal adversarial / design second-opinion / spec completeness) and audit trail formats: see [`AGENTS.md`](AGENTS.md) §3 and §8.

**Default to yes, run SDD.** The cost of one extra `openspec new change` is tiny; the cost of skipping is "AI shipped without spec → human review surface lost".
