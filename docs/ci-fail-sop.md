# CI Fail SOP — Lint / Validate / Hook 失敗的處理流程

這份文件補充 [`../AGENTS.md`](../AGENTS.md) 第 9 節。

AI agent 在 CI 紅燈、本機 hook 拒絕 commit、或 `openspec validate` 失敗時, 必須走
本 SOP, 不得用「重新 push」「再跑一次」「disable assert」當作修法。

## 流程

### 1. commit 前: 本機自驗 (預防型)

```bash
openspec validate <change-id> --strict
```

若安裝過本機 hook (`hooks/pre-commit`), `git commit` 會自動跑這條 + 三個 grep
規則 (audit trail / approved-by / verified-by)。**未安裝 hook 不影響 push, 但會把
失敗發現點延後到 CI**。

### 2. CI fail 時: MUST 讀完整 log

```bash
gh run view --log-failed --repo <owner>/<repo>
# 或指定 run id:
gh run view <run-id> --log-failed --repo <owner>/<repo>
```

**禁止只看 "X failed" 摘要就動手改**。失敗訊息可能是:
- `openspec validate` 拋的 strict mode 錯誤 (例: missing scenario)
- assertion step 的 `::error::` (例: 異常 scenario 數 < requirement 數)
- 失敗的 grep (例: design.md 缺 `第二意見來源:`)

每種失敗的修法不同。

### 3. 找根因

問自己:
- 失敗訊息明確指向哪個檔案 + 哪一行?
- 是 spec 缺結構? 缺 audit trail? 缺 verified-by? 還是真的 strict validate 不過?
- 這是規則本身有問題, 還是我這次改動破壞了規則?

**禁止猜測, 禁止亂改**。不確定就再讀一遍 log + 再讀對應 docs/*.md。

### 4. 本機重現 + 修

```bash
# 在本機跑跟 CI 完全相同的指令
openspec validate <change-id> --strict

# 跑跟 CI 一樣的 grep
grep -c "^### Requirement:" path/to/spec.md
grep -c "^#### Scenario: \[異常\]" path/to/spec.md
grep "對抗性審查來源:" path/to/proposal.md
grep "第二意見來源:" path/to/design.md
grep "完備性審查來源:" path/to/spec.md
grep "approved-by:" path/to/spec.md
grep -cE "^- \[[ x]\] .*→ verified by:" path/to/tasks.md
```

確認本機綠了, 才能 push。

### 5. push, 等 CI 再次跑

`gh run watch <run-id> --exit-status` 阻塞等結果。

## 禁止行為

| 行為 | 為什麼錯 |
|---|---|
| 不看 log 直接 `git push --force-with-lease` 賭一把 | 失敗訊號沒被讀, 同樣的錯誤會再次發生 |
| `git commit --amend` 後 `git push --force` 再看 CI | 與上面同, 只是把賭注變大 |
| 在 workflow yml 內 disable / comment out 失敗的 assert | 規則沒了; 即使「暫時 disable 後續補」永遠不會補 |
| 加 `if: ${{ always() }}` / `continue-on-error: true` 避開紅燈 | 同上, CI 變裝飾 |
| 用 `--no-verify` 繞過本機 hook | 規則沒了; AI agent **明文禁止** (見 AGENTS §9) |
| 在 spec.md 加假 scenario 衝數量過 grep | 比上面更糟, 同時破壞 spec 真實性與 CI 信用 |

## 例外: 規則本身真的需要改

如果讀完 log + 根因分析後, 發現**規則本身是錯的** (例如某 grep 規則 false positive 太多, 真實有效的 spec 也被擋), 那:

1. **不**改該 CI step (還是要先讓它過)
2. 開一個獨立的 openspec change, 例如 `fix-ci-grep-false-positive`
3. 走完 SDD 流程, design 階段解釋為什麼規則錯
4. CI 規則修好後再回頭處理被擋住的工作

換句話說: **規則改動本身也走 SDD 流程**, 不在 CI fail 的當下臨時放鬆規則。

## Q: AI agent 在 auto 模式撞到 CI 紅燈怎辦?

按本文件流程走:
1. MUST 跑 `gh run view --log-failed`
2. MUST 在回應中引述失敗訊息 (證明真的讀了 log)
3. MUST 提出根因假設 + 修法
4. MUST 本機重現 + 修
5. push, watch run, 報告結果

「我重新跑一次」「應該是 transient flake」**不是合法解釋**, 除非 log 真的指向 runner 環境問題 (e.g. timeout 拉 npm package), 而這種情況也要在回應中明示。
