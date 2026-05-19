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

### 完整 Context 傳遞 (硬性)

Codex subagent 跑在**獨立 context**, 看不到 Claude 主對話歷史, 也讀不到本地檔案 (sandbox)。
所以呼叫時, prompt MUST 包含:

1. **proposal.md 全文** (從本地檔案複製貼上, 不省略)
2. **design.md 中已決定的 Decisions** (若這不是首個 Decision, 把前面 D1..Dn 完整貼進去)
3. **當前題目 + 場景 + 體裁限制**

僅給「摘要」或「候選清單」是**禁止行為** — 那會讓 codex 在資訊不對等下評審,
回覆會附「proposal 無法讀取」之類的免責, 喪失對抗性檢查價值。

在 auto / yolo 模式下這條規則是唯一保險, 因為沒人在當下提醒貼脈絡。

呼叫方式、完整 prompt 範本、反模式見 [`docs/codex-handoff.md`](docs/codex-handoff.md)。

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

## 6. Task 寫作: 獨立可驗證

`tasks.md` 不是 brainstorm list, 是執行契約。每個 task MUST:

1. **獨立可執行**: 不依賴其他未完成 task, 一個 session 內能做完
2. **客觀可驗證**: 完成的判定不是「我覺得做完了」, 而是有具體驗證方法
3. **對應到 spec scenario**: 末尾加 `→ verified by: scenario "<scenario name>"`
   - 若該 task 不對應任何 scenario (例如 repo 初始化), 寫 `→ verified by: 無 (理由: <一句話>)`
4. **格式**: `- [ ] <組號>.<項號> <動作> → verified by: scenario "<name>"`

範例:
```markdown
- [ ] 4.3 在 root 掛 QueryClientProvider 並設預設 staleTime → verified by: scenario "列表頁讀資料"
- [ ] 1.1 建立 admin-frontend repo 並 init Next.js 15 → verified by: 無 (理由: 純 repo 初始化, 無 scenario 對應)
```

禁止寫法 (anti-pattern):

- ❌ `- [ ] 重構 X 模組` (沒有完成判定)
- ❌ `- [ ] 優化效能` (沒有目標數值)
- ❌ `- [ ] 確保品質` (主觀)

詳見 [`docs/task-writing.md`](docs/task-writing.md)。

## 7. Spec → Code 的 Human Review Gate

`openspec validate --strict` 是**機器層**檢查 (格式、缺漏), 不是**人類層**確認
(spec 描述的行為是否真的是團隊要的)。

硬性規定:

1. specs 寫完且 `--strict` 通過後, MUST **等人類在 spec 頂端寫 `approved-by:` 標記**, 才能進 tasks 撰寫或實作。
2. AI agent 在 specs 階段完成後 MUST 主動提醒「請 review 並加上 approved-by」, 不得自動接著寫 tasks。
3. approved-by 格式: 寫在 spec.md 頂端, `## ADDED Requirements` 之前:
   ```markdown
   <!-- approved-by: <human-name> <YYYY-MM-DD>
        notes: <若有 caveat 寫一句; 否則省略> -->
   ```
4. 若 approver 不同意 spec, MUST 退回 design 或 specs 重寫, 不得「以 commit comment 表達不同意」蒙混。
5. CI grep 守: spec.md 缺 `approved-by:` 標記 → CI fail (允許 `approved-by: PENDING` 暫態, 但 archive 前必須換成真名)。

## 8. Codex Audit Trail (第二意見留證)

§3 規定**何時必須呼叫 codex**。本節規定**留證**: 即便最終決定不諮詢, 也要在 design.md 明記理由, 不得無聲跳過。

硬性規定:

1. `design.md` 的 `## Decisions` 區頂端 MUST 含一行:
   ```
   第二意見來源: <codex (codex:rescue, YYYY-MM-DD, 已傳遞: proposal + Decisions <範圍>) | 無 (理由: <一句話>)>
   ```
   - `Decisions <範圍>` 是當時已 commit 的 Decision 編號 (例: `D1` 或 `D1-D2`), 或 `首個決策`
   - 此欄位讓人類審計時能快速判斷 codex 是否拿到完整脈絡
2. 「無」是合法選項, 但理由 MUST 具體 (例: `無 (理由: 純 bugfix, 不涉及技術選型)`), 不接受 `無 (理由: 不需要)`、`N/A`、空白。
3. 若諮詢結果與最終決定衝突, design.md 個別 Decision 下 MUST 寫「Codex 建議 X, 採 Y, 因為 ...」。
4. CI grep 守: 凡 `design.md` 內出現 `## Decisions` 區但前面沒有「第二意見來源:」一行 → CI fail。

設計理由: 不強制「行為」(must call codex), 強制「留證」(must record decision rationale)。
留證可被 grep, 行為很難 grep。

## 9. Lint / CI Fail 處理 SOP

AI 不得用「重新 push」或「重跑 CI」當作修法。流程:

1. **commit 前**: MUST 在本機跑 `openspec validate --strict <change-id>`; 若有 git hook 安裝指南 (`hooks/pre-commit`), 應該安裝。
2. **CI fail 時**: MUST 先讀 log:
   ```
   gh run view --log-failed
   ```
3. **找根因**: 失敗訊息是什麼? 哪個 step? 哪一行? 不得猜測, 不得隨機改。
4. **修完本機驗證**: 本機重現 CI 的檢查 (例如 `openspec validate --strict`、grep 規則), 確認綠燈再 push。
5. **禁止**:
   - 不得單純 `git commit --amend` 後 `git push --force` 再看 CI (那只是再賭一次)
   - 不得 disable failing assert 來「修」 CI
   - 不得跳過 hook (`--no-verify`)

## 10. 參考範例

`examples/select-admin-frontend-stack/` 是一個完整、`openspec validate --strict` 通過的 reference change, 涵蓋:

- 真實技術選型題目 (前端框架 + UI + 狀態 + 資料層)
- design.md Decisions 內含 codex 第二意見
- spec 含 6 條 Requirement / 12 個 happy-path + 8 個 [異常] error-path scenario (EARS 對齊)
- tasks.md 含 22 個可勾選實作項

新 change 卡住時先看這個範例怎麼寫。
