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
- 每個 Requirement **MUST 至少包含一個 happy-path scenario (WHEN/THEN) 與一個 error-path scenario (IF/THEN)** (詳見第 2 節)
- 規範用語: SHALL / MUST, 避免 should / may
- `MODIFIED Requirements` 要 copy 整段原 requirement 再改, 不能只寫差異
- archive 前 `openspec validate <id> --strict` 必須過

## 2. Spec 寫作: EARS 對應與異常路徑

OpenSpec 模板只給 `WHEN/THEN`, 容易讓所有 scenario 全部寫成 happy path、漏寫異常路徑。
本專案 MUST 對齊 EARS (Easy Approach to Requirements Syntax) 5 個 pattern, 並
強制每個 Requirement 至少要有一個異常路徑 scenario。

| EARS pattern | OpenSpec scenario 寫法 | 用途 |
|---|---|---|
| Ubiquitous (恆真) | 寫在 `### Requirement:` 描述用 SHALL/MUST | 永遠成立的約束 |
| Event-driven (事件) | `**WHEN** <trigger>` + `**THEN** <response>` | Happy path、正向觸發 |
| State-driven (狀態) | `**WHILE** <state>` + `**THEN** <response>` | 持續狀態下的行為 |
| **Unwanted behaviour (異常)** | `**IF** <trigger>` + `**THEN** <response>` | **錯誤、失敗、邊界條件** |
| Optional feature | `**WHERE** <feature included>` + `**THEN** <response>` | 條件性功能 |

OpenSpec validator 對 IF/WHILE/WHERE 都接受 (已驗證過 `openspec validate --strict`)。

### 硬性要求

1. 每個 `### Requirement:` 至少 **一個 WHEN/THEN (happy) + 一個 IF/THEN (error)**, 缺一不可。
2. error scenario 名稱 MUST 加 `[異常]` 前綴, 方便視覺辨識與 grep。
3. error 場景 MUST 涵蓋下列至少一類:
   - 上游失敗 (API 5xx、network、timeout)
   - 認證/權限 (401、403、CSRF、token 過期)
   - 資料缺失或不合法 (manifest 空、表單欄位缺、enum 不在範圍)
   - 重試耗盡 / 降級行為
4. error scenario MUST 寫出**對使用者的影響** (不是只寫「系統 log 錯誤」 — 那是內部行為, 不是 acceptance criteria)。

### 範本

```markdown
### Requirement: 資料層使用 TanStack Query

所有 API 呼叫 MUST 透過 TanStack Query 進行。

#### Scenario: 列表頁讀資料
- **WHEN** 列表頁掛載
- **THEN** 該頁 MUST 使用 `useQuery({ queryKey, queryFn })` 取資料

#### Scenario: [異常] API 回 5xx 或網路錯誤
- **IF** 請求回 5xx 或網路中斷
- **THEN** MUST 重試最多 3 次, 失敗後 MUST 由 `<ErrorBoundary>` 渲染重試 UI
```

完整範例見 `examples/select-admin-frontend-stack/specs/admin-frontend-stack/spec.md`
(6 個 Requirement / 14 happy + 8 error scenario, strict validate 通過)。

詳細模板與反模式見 [`docs/spec-writing.md`](docs/spec-writing.md)。

## 3. 何時必須呼叫 Codex 第二意見

進到 **design 階段** 且符合下列任一條件時, MUST 透過 `codex:rescue` (或等價的 Codex handoff) 取得第二意見, 不得自己單方面決定:

1. **技術選型**: 主框架/資料庫/部署平台/通訊協定 等「選了難回頭」的決定
2. **跨系統整合邊界**: BFF、SSO、權限、多服務拆分這類「畫錯線就重寫」的決策
3. **無法本地驗證的效能/安全 trade-off**
4. **使用者明確要求第二意見** ("get a second opinion", "let codex check")

不必呼叫的場合: 純 bugfix、refactor、命名調整、文件、樣式。

呼叫方式與 prompt 範本見 `docs/codex-handoff.md`。

## 4. Codex 回覆的呈現格式

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

## 5. 任務追蹤

- 進入新階段 (proposal → design → specs → tasks) 前用 TaskCreate 建追蹤項
- 跨多步驟工作一律先列 task list, 再 in_progress / completed 滾動更新
- 不要把使用者已說過的決策再問一次, 翻 proposal / design 自己讀

## 6. 參考範例

`examples/select-admin-frontend-stack/` 是一個完整、`openspec validate --strict` 通過的 reference change, 涵蓋:

- 真實技術選型題目 (前端框架 + UI + 狀態 + 資料層)
- design.md Decisions 內含 codex 第二意見
- spec 含 6 條 Requirement / 12 個 happy-path + 8 個 [異常] error-path scenario (EARS 對齊)
- tasks.md 含 22 個可勾選實作項

新 change 卡住時先看這個範例怎麼寫。
