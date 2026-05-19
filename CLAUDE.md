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

## Codex 三階段審查

Codex 在 SDD 流程中**自動介入三次**, 角色與留證欄位不同 (見 [AGENTS.md §3](AGENTS.md) 與 [§8](AGENTS.md)):

| 階段 | 角色 | 工作流標籤 | 留證欄位 |
|---|---|---|---|
| proposal | 對抗性審查 (壓力測試 Why/What/Impact) | `/codex:adversarial-review proposal.md` | `<!-- 對抗性審查來源: ... -->` |
| design | 技術第二意見 (對抗性檢查決策) | `/codex:review design.md` | `第二意見來源: ...` |
| spec | 完備性審查 (找漏掉的情境) | `/codex:review spec.md` | `<!-- 完備性審查來源: ... -->` |

- **proposal / spec 階段**: 預設要審, **不問**「要不要審」, 直接走
- **design 階段**: 符合 §3.2 四條件 (技術選型 / 跨系統邊界 / 效能-安全 trade-off / 使用者明示) 自動審
- 三階段例外允許 (但留證 MUST 寫具體理由), `無 (理由: 不需要 | N/A)` 模糊寫法 CI 會擋
- 呼叫前 MUST 輸出一行「呼叫 codex 輔助分析中...」給 CLI 視覺結構, 並在 prompt 開頭加 `--fresh` token (見 [docs/codex-handoff.md](docs/codex-handoff.md))
- 三種 prompt 模板與「完整 context」段組成見 [docs/codex-handoff.md](docs/codex-handoff.md)

## Unsure?

Default to **yes, run SDD**. The cost of one extra `openspec new change` is tiny; the cost of skipping is "AI shipped without spec → human review surface lost".
