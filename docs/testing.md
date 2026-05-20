# Testing — Starter 自驗

本 starter 不是「使用者要實作的功能」, 而是一份規則 + 範例骨架。所以「測試」
要驗的是: **規則沒漂移、範例仍能跑、hook 能擋住違規 commit**。

## 一鍵跑

```bash
bash scripts/test.sh
```

回傳 0 = 全綠, 非 0 = 至少一條 fail (每條 fail 在 stdout 有具體訊息)。

預設約 **79 條測試**, 跑完約 15-30 秒 (含 fresh-bootstrap 那段較慢)。

## 測試內容

### 單元 (Unit)

| # | 名稱 | 守什麼 |
|---|---|---|
| 1 | Link integrity | 所有 markdown 連結指向的相對路徑必須存在 |
| 2 | AGENTS.md section completeness | §0 ~ §11 必須全在 |
| 3 | Cross-reference consistency | docs/* 內引用「AGENTS §X」「第 X 節」, X 必須真有對應章節 |
| 4 | Key phrase regression | AGENTS / CLAUDE / docs 必須含特定關鍵字 — 防 docs 被改錯而靜默退化 |
| 5 | openspec CLI 存在 | 預設工具齊備 |

### 整合 (Integration)

| # | 名稱 | 守什麼 |
|---|---|---|
| 1 | Reference example strict validate | `examples/select-admin-frontend-stack/` 永遠應 strict-validate 通過 |
| 2 | Hook negative tests | 故意壞 proposal / design / spec / tasks 餵給 `hooks/pre-commit`, **必須**被拒 — 7 個 negative case |
| 3 | Fresh-project bootstrap | 把整個 starter 拷到 tmp dir 跑 `openspec new change`, 確認新使用者上手流暢 |

## 測試矩陣 (fork-maintainer 入口)

每條測試守一個 invariant。本表讓 fork-maintainer 在「我改 X 行會壞哪條測試」「為什麼有這條測試」之間秒解 — 不必逐行讀 `scripts/test.sh`。

### 總覽 (11 群組 = 79 條)

| 群組 | 條數 | 守的 invariant | 對應 AGENTS § | 故意壞它的最小擾動 |
|---|---|---|---|---|
| **Unit 1** Link integrity | 1 | 所有 markdown 相對連結都解到實際檔 (skips `http(s):` / `mailto:` / `#anchor`) | — | 把任何相對連結改成不存在的路徑 |
| **Unit 2** AGENTS 章節齊全 | 12 | AGENTS.md `## 0.` 到 `## 11.` 全在 | §0~§11 | 刪掉 `## 5. 任務追蹤` 整段 |
| **Unit 3** 跨檔引用一致 | 9 | docs / hooks/README / CLAUDE 出現的「AGENTS §N」或「第 N 節」, N 必為真實章節 | — | 在 docs/spec-writing.md 加一句引用不存在的 AGENTS 章節編號 |
| **Unit 4** 關鍵字回歸 | 29 | 防 docs 被改錯而靜默退化, 守 6 大主題 (見下方明細) | §0 §3 §6 §7 §8 | 刪 docs/codex-handoff.md 的 "proposal.md 全文" 一句 |
| **Unit 4b** codex-prompt 組裝 | 11 | `scripts/codex-prompt.sh` 原文 inline, 無 summary drift | §3.4 | 把 `cat "$file"` 換成 `head -5 "$file"` |
| **Unit 5** openspec CLI | 1 | 機器上有 `openspec` 可執行 | — | `npm uninstall -g @fission-ai/openspec` |
| **Int 1** Examples strict validate | 4 | 4 個 examples (technical-selection / new-feature / MODIFIED / legitimate-skip) 全部 strict-validate 過 | §1 §2 | 從任一 example 的 spec.md 刪一個 `### Requirement:` |
| **Int 2** Hook negative tests | 8 | `hooks/pre-commit` 攔得住 7 種違規 + 1 baseline 不誤殺 | §3.5 §6 §7 §8 | 見下方明細, 每行刪一種 |
| **Int 3** Fresh-bootstrap | 2 | 拷到新目錄 + `openspec new change` 仍可用 | — | 刪 `openspec/` 骨架資料夾 |
| **Unit 6** 矩陣一致性 | 1 | 本表「總計 N 條」與 `scripts/test.sh` 實際 PASS 數相符 | — | 加新測試但不更新本表 |
| **Unit 7** AGENTS 指令預算 | 1 | AGENTS.md 強指令行數 (`MUST` / `SHALL` / `不得` / `禁止` / `❌` / `一律`) <= 180 (~200 LLM 穩定帶 - on-demand docs 預留) | — | 在 AGENTS.md 連續加 130+ 個 MUST/SHALL |

### Unit 4 關鍵字回歸明細 (依主題, 29 條)

| 主題 | 守的 phrase | 檔案 | AGENTS § |
|---|---|---|---|
| §0 觸發語意 | `立即啟動 SDD 流程` / `規則沒有例外` / `太簡單` (AGENTS) + `太簡單` (CLAUDE) | AGENTS / CLAUDE | §0 |
| §3.1 §3.3 角色標籤 | `/codex:adversarial-review proposal.md` / `/codex:review spec.md` / `完備性審查員` | docs/codex-handoff | §3.1 §3.3 |
| §3.4 完整 context | `proposal.md 全文 + 已決 Decisions 全文` (AGENTS) + `proposal.md 全文` / `只給摘要` / `auto / yolo / no-confirm` (docs) | AGENTS / docs/codex-handoff | §3.4 |
| §3.4 失敗處理 | `Codex 呼叫失敗時 MUST 停止對應階段流程` / `not authenticated` / `is not installed` / `npm install -g @openai/codex` | AGENTS / docs/codex-handoff | §3.4 |
| §3.5 Decision marker | `**一句話**` / `**對使用者 / 企劃看得見的影響**` / `**為何不選**` (×2: docs + examples 參考實作) | docs/decision-writing + examples 6 條 | §3.5 |
| §6 §7 §8 audit grep | `對抗性審查來源` / `第二意見來源` / `完備性審查來源` (AGENTS) + `→ verified by:` (docs/task-writing) + `IF` / `[異常]` (docs/spec-writing) | AGENTS / docs | §6 §7 §8 |
| CLAUDE stub | `AGENTS.md` / `STOP` (CLAUDE 指向主 ruleset + STOP directive) | CLAUDE | — |

### Int 2 Hook 負向測試明細 (8 條 = 1 baseline + 7 negatives)

| # | 故意刪的東西 | hook 應拒絕的理由 | AGENTS § |
|---|---|---|---|
| 2.0 | (無, baseline) | hook 不能誤殺 clean reference example | — |
| 2.1 | design.md 的 `第二意見來源:` 整行 | §8.2 design audit grep | §8.2 |
| 2.2 | design.md 的 `**一句話**:` 全數 | §3.5 Decision marker 1 | §3.5 |
| 2.3 | design.md 的 `**為何不選**:` 全數 | §3.5 Decision marker 3 | §3.5 |
| 2.4 | spec.md 的 `approved-by:` 整行 | §7 human review gate | §7 |
| 2.5 | spec.md 的 `完備性審查來源:` 整行 | §8.3 spec audit grep | §8.3 |
| 2.6 | proposal.md 的 `對抗性審查來源:` 整行 | §8.1 proposal audit grep | §8.1 |
| 2.7 | tasks.md 任一行的 `→ verified by:` 後綴 | §6 task verified-by 格式 | §6 |

### Unit 4b codex-prompt 組裝明細 (11 條)

| # | 斷言 | 故意壞它 |
|---|---|---|
| 4b.1 | `scripts/codex-prompt.sh` 檔案存在 | `git rm` 該檔 |
| 4b.2 | proposal 階段 inline 原句 (`舊版後台是 jQuery + 多頁式 PHP 樣板`) | 改腳本用 `head -5` 截斷 |
| 4b.3 | proposal 階段印出 `BEGIN/END CODEX PROMPT` marker | 刪 marker line |
| 4b.4 | proposal 階段尾巴附 audit trail 模板 | 刪 `對抗性審查來源: codex (adversarial-review,` |
| 4b.5 | design 階段全部 4 個 Decisions (D1-D4) 都 inline | 在 `extract_decisions` 加 `head -20` |
| 4b.6 | design 階段在下一個 `## ` heading 前停 (不洩 `## Risks`) | 把 awk 規則 `/^## /{p=0}` 移除 |
| 4b.7 | design 階段自動偵測 decisions range (`D1-D4`) | 刪 `grep -oE '^### D[0-9]+\.'` 一行 |
| 4b.8 | spec 階段尾巴附 audit trail 模板 | 刪 `完備性審查來源: codex (review,` |
| 4b.9 | spec 階段含 `Completeness checklist` 段 | 刪 here-doc 內該段落 |
| 4b.10 | 錯誤路徑: 不存在的 change → exit 非 0 | 把 `exit 1` 改成 `exit 0` |
| 4b.11 | 必選參數缺 `--change` → exit 非 0 | 把 `[ -z "$change" ]` 改成永遠 false |

### 加新測試時的契約

加一條 PASS 就必須:

1. **在矩陣相應群組** (Unit X / Int X) 補一行,寫明守的 invariant + 故意壞它的方法
2. **更新本檔開頭「預設約 N 條測試」的 N**
3. Unit 6 會自動 grep N 與實際 PASS 計數,**不更新就 fail**

設計理由: 矩陣不被機器守會立刻過時 — Unit 6 就是這層守護。

## CI 跑同一份

`.github/workflows/validate.yml` 的最後一個 step 是 `bash scripts/test.sh`,
跟本機跑的是**完全同一份**。任何在本機過的測試, CI 也會過; 反之亦然。

設計理由: 不要本機 / CI 各自一套, 否則漂移風險高。

## 加新測試

### 新增單元測試 (新 phrase / 新章節 / 新檔案)

編輯 `scripts/test.sh`, 在對應 section 加新 `check_phrase` 或 `pass/fail` 呼叫。
`check_phrase` 接三個位置參數: 目標檔案、必含字串、輸出標籤 — 直接看現有用法當範本。

### 新增整合測試

在 `scripts/test.sh` 適當位置加 `section "Integration N: ..."` 並寫測試邏輯,
記得用 `pass "..."` / `fail "..."` 計分。

### 反模式

- ❌ 不要在 `scripts/test.sh` 內呼叫 codex / 任何 LLM — 那要 OAuth, 無法在 CI 跑
- ❌ 不要把 fixture 放在 `openspec/changes/` 根 — 會被 openspec CLI 認到, 干擾使用者; 用 `mktemp -d` 隔離
- ❌ 測試不要直接修改 `examples/` — 用 `cp` + tmp dir, 改完不要回寫

## 失敗時看哪

`scripts/test.sh` 每條測試 print 一行 `PASS` 或 `FAIL: <reason>`。
找 `^  FAIL` 就能定位:

```bash
bash scripts/test.sh 2>&1 | grep "^  FAIL"
```

CI 失敗時依 [`ci-fail-sop.md`](ci-fail-sop.md) 處理:
讀 `gh run view --log-failed`, 找根因, 本機修, 再 push。

## 為什麼用 bash 而不是 bats / shellspec / Jest

- starter 已用 bash hook (`hooks/pre-commit`), 同個語言一致
- 不引入新依賴 (bats 要 `brew install`, 跨平台麻煩)
- 規則檢查本身就是 grep + 結構 check, 不需要重型框架
- CI 環境 ubuntu-latest 自帶 bash, 零安裝
