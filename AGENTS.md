# AGENTS.md — Spec-Driven Development + Codex 第二意見

這份檔案是給 AI agent (Claude Code、Codex、Cursor 等) 讀的工作守則。
凡是進到本專案做需求/設計/規格層級的工作, 一律遵守下列規則。

**設計原則:** 本檔案只記「不可違反的停止條件」與「進入階段時 MUST 開哪份 docs」, 不重貼程序細節。所有展開內容 (EARS 五 pattern、Codex prompt 模板、task verified-by 格式等) 在 `docs/` 內, AI 進到對應階段時 MUST 主動 Read 該檔案, 不得只憑記憶執行。

## 0. 觸發信號 (進到此 repo 後立即生效)

AI agent 收到下列任一訊號時, MUST **立即啟動 SDD 流程**, 不需使用者特別提醒、
不需先問「要不要走 spec-driven」、不需先問「要不要叫 codex」。

| 訊號類別 | 範例語句 |
|---|---|
| 新增功能 | 「加一個 X」「實作 ...」「做一個 ...」「I want to add ...」 |
| 修改既有行為 | 「把 X 改成 Y」「重構 ...」「升級 ...」「migrate ...」 |
| 技術選型 | 「選什麼 X」「決定用 ...」「評估 A vs B」「pick a framework」 |
| 設計題目 | 「設計 ...」「規劃 ...」「architecture for ...」 |

「立即啟動」= MUST 在第一個回應內:

1. 跑 `openspec new change <kebab-id>` 自己命名, 不用先徵詢
2. 進入 proposal 撰寫 (見 §1)
3. design 階段符合 §3 條件時自動叫 Codex, 不用先問人類

**禁止行為:**

- ❌ 直接動 code (跳過 spec)
- ❌ 問「要不要走 spec-driven 流程?」 — 預設要
- ❌ 問「要不要叫 Codex?」 — 符合 §3 條件時預設要
- ❌ 「我先實作一個簡單版, 之後再補 spec」 — 永遠不准
- ❌ 把 spec 階段壓到事後文件化 — 必須先於 code

**不觸發的場合** (這時純粹 patch / 答覆即可):

- 純 bugfix (改幾行、有對應現有 spec scenario)
- 純 rename / 樣式調整 / 文件更新
- 問答 / 解釋 / 程式碼閱讀
- 使用者明確說「不要走 SDD, 我只要 X」 (這時禮貌確認後跳過)

## 1. 工作流: OpenSpec 4 階段

任何「新功能、改變既有行為、決定技術選型」的任務 MUST 走 OpenSpec 流程, 不得直接動 code。

```
proposal  →  design  →  specs  →  tasks
   Why         How       What       Do
```

| 階段 | 檔案 | 進入此階段 MUST 開的 docs |
|---|---|---|
| proposal | `openspec/changes/<id>/proposal.md` | — (簡單階段, 直接寫即可) |
| design | `openspec/changes/<id>/design.md` | [`docs/codex-handoff.md`](docs/codex-handoff.md) (Codex 觸發 + 完整 context 規則) |
| specs | `openspec/changes/<id>/specs/<capability>/spec.md` | [`docs/spec-writing.md`](docs/spec-writing.md) (EARS 五 pattern + 異常路徑) |
| tasks | `openspec/changes/<id>/tasks.md` | [`docs/task-writing.md`](docs/task-writing.md) (verified-by 格式) |

操作 CLI:
```bash
openspec new change <kebab-id> --description "<一句話>"
openspec instructions <proposal|design|specs|tasks> --change <id>
openspec validate <id> [--strict]
openspec status --change <id>
openspec archive <id>   # 全部 tasks 勾完才執行
```

### 不可違反的停止條件 (跨階段)

- `### Requirement:` 至少要有一個 `#### Scenario:` (4 個 hashtag)
- 每個 Requirement MUST 至少 1 happy (`WHEN/THEN`) + 1 error (`IF/THEN`) scenario
- 規範用語: SHALL / MUST, 禁用 should / may
- `MODIFIED Requirements` 要 copy 整段原 requirement 再改, 不得只寫差異
- archive 前 `openspec validate <id> --strict` 必須過

## 2. Spec 寫作 (EARS + 異常路徑)

**進入 specs 階段前 MUST 開** [`docs/spec-writing.md`](docs/spec-writing.md)。
規則密集 (五 pattern + 異常分類 + anti-patterns), 不重貼於此, 避免漂移。

不可違反的停止條件:

- 每個 `### Requirement:` 至少含一個 `[異常]` 前綴的 IF/THEN scenario, 否則 CI fail
- error scenario MUST 寫「對使用者的可觀察影響」, 不是只記「系統 log 錯誤」

## 3. 何時必須呼叫 Codex 第二意見

**進入 design 階段前 MUST 開** [`docs/codex-handoff.md`](docs/codex-handoff.md)。
Codex prompt 完整性是密集程序規則, 縮成一句必然漂移, 必須看完整版。

進到 **design 階段** 且符合下列任一條件時, **自動透過** `codex:rescue` 取得第二意見。
**默認是「要諮詢」**, 不得先問「要不要諮詢」 — 例外才需在 audit trail 寫理由 (見 §8)。

1. **技術選型**: 主框架 / 資料庫 / 部署平台 / 通訊協定 等「選了難回頭」的決定
2. **跨系統整合邊界**: BFF、SSO、權限、多服務拆分這類「畫錯線就重寫」的決策
3. **無法本地驗證的效能/安全 trade-off**
4. **使用者明確要求第二意見** ("get a second opinion", "let codex check")

不必呼叫的場合: 純 bugfix、refactor、命名調整、文件、樣式。

不可違反的停止條件:

- 呼叫 codex 的 prompt MUST 包含 proposal.md 全文 + 已決 Decisions 全文, 不得只給摘要
- 在 auto / yolo 模式這條規則是唯一保險, 沒人會在當下提醒貼脈絡

## 4. Codex 回覆呈現格式

**收到 Codex 回覆時 MUST 開** [`docs/output-formatting.md`](docs/output-formatting.md)。

不可違反的停止條件:

- 對話視窗呈現 Codex 回覆時 MUST 用 blockquote + 上下 `---` + `╭─ ▼ Codex 回覆 ▼ ─` / `╰─ ▲ Codex 回覆結束 ▲ ─` 邊界文字
- 寫進 design.md 等檔案時不需要視覺邊界, 但 Decisions 區頂端 MUST 標 `第二意見來源:` (見 §8)

## 5. 任務追蹤

- 進入新階段 (proposal → design → specs → tasks) 前用 TaskCreate 建追蹤項
- 跨多步驟工作一律先列 task list, 再 in_progress / completed 滾動更新
- 不要把使用者已說過的決策再問一次, 翻 proposal / design 自己讀

## 6. Task 寫作 (獨立可驗證)

**進入 tasks 階段前 MUST 開** [`docs/task-writing.md`](docs/task-writing.md)。
`→ verified by:` 是精確格式契約, 不重貼於此。

不可違反的停止條件:

- 每行 `- [ ]` task MUST 含 `→ verified by: scenario "<name>"` 或 `→ verified by: 無 (理由: <一句話>)`
- 缺 verified-by 的 task 行會被 hook / CI grep 擋住, 不准 commit
- 「無」的理由 MUST 具體, 禁止「無 (理由: 無需要)」

## 7. Spec → Code 的 Human Review Gate

`openspec validate --strict` 是**機器層**檢查 (格式、缺漏), 不是**人類層**確認
(spec 描述的行為是否真的是團隊要的)。

**這是動工前就要知道的啟動控制, 不能塞 docs**:

1. specs 寫完且 `--strict` 通過後, MUST **等人類在 spec.md 頂端寫 `<!-- approved-by: -->` 標記**, 才能進 tasks 撰寫或實作。
2. AI agent 在 specs 階段完成後 MUST 主動提醒「請 review 並加上 approved-by」, 不得自動接著寫 tasks。
3. approved-by 格式: 寫在 spec.md 頂端, `## ADDED Requirements` 之前:
   ```markdown
   <!-- approved-by: <human-name> <YYYY-MM-DD>
        notes: <若有 caveat 寫一句; 否則省略> -->
   ```
4. 若 approver 不同意 spec, MUST 退回 design 或 specs 重寫, 不得「以 commit comment 表達不同意」蒙混。
5. CI grep 守: spec.md 缺 `approved-by:` 標記 → CI fail (允許 `approved-by: PENDING` 暫態, 但 archive 前必須換成真名)。

## 8. Codex Audit Trail (第二意見留證)

§3 規定**何時必須呼叫 codex**。本節規定**留證格式**: 即便最終決定不諮詢, 也要在 design.md 明記理由, 不得無聲跳過。

**這是寫 design.md 前就要知道的契約, 不能塞 docs**:

1. `design.md` 的 `## Decisions` 區頂端 MUST 含一行:
   ```
   第二意見來源: <codex (codex:rescue, YYYY-MM-DD, 已傳遞: proposal + Decisions <範圍>) | 無 (理由: <一句話>)>
   ```
   - `Decisions <範圍>` 是當時已 commit 的 Decision 編號 (例: `D1` 或 `D1-D2`), 或 `首個決策`
   - 此欄位讓人類審計時能快速判斷 codex 是否拿到完整脈絡
2. 「無」是合法選項, 但理由 MUST 具體 (例: `無 (理由: 純 bugfix, 不涉及技術選型)`), 不接受 `無 (理由: 不需要)`、`N/A`、空白。
3. 若諮詢結果與最終決定衝突, design.md 個別 Decision 下 MUST 寫「Codex 建議 X, 採 Y, 因為 ...」。
4. CI grep 守: 凡 `design.md` 內出現 `## Decisions` 區但前面沒有「第二意見來源:」一行 → CI fail。

設計理由: 不強制「行為」(must call codex), 強制「留證」(must record decision rationale)。留證可被 grep, 行為很難 grep。

## 9. CI Fail / Hook 拒絕的處理

**CI fail 或本機 hook 拒絕 commit 時 MUST 開** [`docs/ci-fail-sop.md`](docs/ci-fail-sop.md)。

不可違反的停止條件:

- 不得用「重新 push」「再跑一次」當作修法
- MUST 先跑 `gh run view --log-failed` 讀失敗 log, 在回應中引述失敗訊息
- 禁止 disable failing assert、禁止 `--no-verify` 繞 hook、禁止在 yml 加 `continue-on-error`

## 10. 自動化的邊界 (CI 抓不到什麼)

CI grep 守 5 個結構性規則 (strict validate / 異常 scenario 覆蓋率 / approved-by / verified-by / 第二意見來源), 但**抓不到品質性問題**:

- ✗ 抓不到「task 寫了 `→ verified by:` 但實際不可獨立執行」 (例: `- [ ] 完成所有功能 → verified by: 無 (理由: 整體驗收)`)
- ✗ 抓不到「Codex 收到的 prompt 真的有貼完整 proposal」 (只能 grep audit trail 一行)
- ✗ 抓不到「scenario 描述對使用者影響, 而非僅內部 log」
- ✗ 抓不到「approved-by 後面寫的是真實 reviewer, 不是 AI 自己填的假名」

這些 limitation 由**人類 review + Codex 第二意見**負責。CI 是底線, 不是天花板。

## 11. 參考範例

[`examples/select-admin-frontend-stack/`](examples/select-admin-frontend-stack/) — 完整 `--strict` 通過的 reference change, 6 個 Requirement / 12 happy + 8 error scenario / 22 個 task 全含 verified-by。新 change 卡住時對照這份。
