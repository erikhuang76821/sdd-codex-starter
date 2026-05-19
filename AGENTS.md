# AGENTS.md — Spec-Driven Development + Codex 第二意見

這份檔案是給 AI agent (Claude Code、Codex、Cursor 等) 讀的工作守則。
凡是進到本專案做需求/設計/規格層級的工作, 一律遵守下列規則。

## 1. 工作流: OpenSpec 4 階段

任何「新功能、改變既有行為、決定技術選型」的任務 MUST 走 OpenSpec 流程, 不得直接動 code。

```
proposal  →  design  →  specs  →  tasks
   Why         How       What       Do
```

| 階段 | 檔案 | 重點 |
|---|---|---|
| proposal | `openspec/changes/<id>/proposal.md` | Why + What Changes + Capabilities + Impact |
| design | `openspec/changes/<id>/design.md` | Decisions (含「為何選 X 而非 Y」) + Risks/Trade-offs + Migration |
| specs | `openspec/changes/<id>/specs/<capability>/spec.md` | ADDED/MODIFIED/REMOVED Requirements + Scenario (WHEN/THEN) |
| tasks | `openspec/changes/<id>/tasks.md` | 可勾選的實作 checklist |

操作 CLI:
```bash
openspec new change <kebab-id> --description "<一句話>"
openspec instructions <proposal|design|specs|tasks> --change <id>
openspec validate <id> [--strict]
openspec status --change <id>
openspec archive <id>   # 全部 tasks 勾完才執行
```

### 硬性規定

- 每個 spec 的 `### Requirement:` 至少要有一個 `#### Scenario:` (4 個 hashtag, 不是 3 個)
- 規範用語: SHALL / MUST, 避免 should / may
- `MODIFIED Requirements` 要 copy 整段原 requirement 再改, 不能只寫差異
- archive 前 `openspec validate <id> --strict` 必須過

## 2. 何時必須呼叫 Codex 第二意見

進到 **design 階段** 且符合下列任一條件時, MUST 透過 `codex:rescue` (或等價的 Codex handoff) 取得第二意見, 不得自己單方面決定:

1. **技術選型**: 主框架/資料庫/部署平台/通訊協定 等「選了難回頭」的決定
2. **跨系統整合邊界**: BFF、SSO、權限、多服務拆分這類「畫錯線就重寫」的決策
3. **無法本地驗證的效能/安全 trade-off**
4. **使用者明確要求第二意見** ("get a second opinion", "let codex check")

不必呼叫的場合: 純 bugfix、refactor、命名調整、文件、樣式。

呼叫方式與 prompt 範本見 `docs/codex-handoff.md`。

## 3. Codex 回覆的呈現格式

Codex 回覆 MUST 用視覺區塊與我自己的文字明顯區隔, 避免讀者分不清誰講的。

格式 (在對話視窗呈現時):

```
---

> ╭─ ▼ Codex 回覆 ▼ ──────────────────────────────
>
> <codex 原始輸出, 完全不改寫>
>
> ╰─ ▲ Codex 回覆結束 ▲ ──────────────────────────

---
```

- 上下各一條 `---` 水平線
- 整段用 `>` blockquote (終端機左側會出現 vertical bar)
- 第一行與最後一行加 `╭─ ▼ Codex 回覆 ▼ ─` / `╰─ ▲ Codex 回覆結束 ▲ ─` 邊界文字
- AI 自己的補充寫在區塊外

寫進檔案 (例如 design.md) 時不用包邊界, 但要在 Decisions 區明確標註「第二意見來源: codex (yyyy-mm-dd)」。

完整範例見 `docs/output-formatting.md`。

## 4. 任務追蹤

- 進入新階段 (proposal → design → specs → tasks) 前用 TaskCreate 建追蹤項
- 跨多步驟工作一律先列 task list, 再 in_progress / completed 滾動更新
- 不要把使用者已說過的決策再問一次, 翻 proposal / design 自己讀

## 5. 參考範例

`examples/select-admin-frontend-stack/` 是一個完整、`openspec validate --strict` 通過的 reference change, 涵蓋:

- 真實技術選型題目 (前端框架 + UI + 狀態 + 資料層)
- design.md Decisions 內含 codex 第二意見
- spec 含 6 條 Requirements / 14 個 Scenario
- tasks.md 含 22 個可勾選實作項

新 change 卡住時先看這個範例怎麼寫。
