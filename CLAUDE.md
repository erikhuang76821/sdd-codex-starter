# CLAUDE.md

This project uses **sdd-codex-starter** — spec-driven development with adversarial Codex second opinion.

> **STOP. Before any task, read [`AGENTS.md`](AGENTS.md).** `AGENTS.md` is the authoritative ruleset and is short (~200 lines). Reading it is non-negotiable.

## Quick triggers (full table in [AGENTS.md §0](AGENTS.md))

When the user says any of the following, you MUST start SDD flow immediately (`openspec new change <id>` → proposal → design → spec → tasks), without asking for confirmation:

| 訊號 | 範例 |
|---|---|
| 新增功能 | 「加一個 X」「做一個 X」「實作 ...」「I want to add ...」「build a ...」 |
| 修改既有行為 | 「把 X 改成 Y」「重構 ...」「升級 ...」「migrate ...」 |
| 技術選型 | 「選什麼 X」「評估 A vs B」「pick a framework」 |
| 設計題目 | 「設計 ...」「規劃 ...」「architecture for ...」 |

## DO NOT skip SDD because:

- ❌ 「這太簡單」「太小不必走流程」「toy / demo / POC / 練習」 — **任務大小不是觸發條件, 任務類型才是**
- ❌ 「先寫個 prototype, 之後再補 spec」 — spec MUST 先於 code
- ❌ 「先實作一個簡單版」 — 同上
- ❌ 自行判斷「使用者大概不需要這麼正式」 — 預設要走, 例外才在 audit trail 寫理由

只要符合上面 4 類訊號之一, 不論大小, 一律啟動 SDD。

## Codex 第二意見

進入 design 階段時,若符合 [AGENTS.md §3](AGENTS.md) 的 4 個條件 (技術選型 / 跨系統邊界 / 效能-安全 trade-off / 使用者明示),**自動**叫 Codex,不要先問。即使判斷不必叫,也 MUST 在 `design.md` 的 `## Decisions` 區頂端寫一行 `第二意見來源: 無 (理由: <具體一句>)`。

呼叫前 MUST 先輸出一行「呼叫 codex 輔助分析中...」給 CLI 視覺結構,並在 prompt 開頭加 `--fresh` token (見 [docs/codex-handoff.md](docs/codex-handoff.md))。

## Unsure?

Default to **yes, run SDD**. The cost of one extra `openspec new change` is tiny; the cost of skipping is "AI shipped without spec → human review surface lost".
