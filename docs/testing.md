# Testing — Starter 自驗

本 starter 不是「使用者要實作的功能」, 而是一份規則 + 範例骨架。所以「測試」
要驗的是: **規則沒漂移、範例仍能跑、hook 能擋住違規 commit**。

## 一鍵跑

```bash
bash scripts/test.sh
```

回傳 0 = 全綠, 非 0 = 至少一條 fail (每條 fail 在 stdout 有具體訊息)。

預設約 **55 條測試**, 跑完約 15-30 秒 (含 fresh-bootstrap 那段較慢)。

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
| 2 | Hook negative tests | 故意壞 proposal / design / spec / tasks 餵給 `hooks/pre-commit`, **必須**被拒 — 5 個 negative case |
| 3 | Fresh-project bootstrap | 把整個 starter 拷到 tmp dir 跑 `openspec new change`, 確認新使用者上手流暢 |

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
