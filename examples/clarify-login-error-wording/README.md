# clarify-login-error-wording

「合法跳過 Codex 三 audit」範例: 純 spec scenario 文字修正, 不涉及任何方向決定或新行為。

**示範什麼**:

- 一個**合法**的「全部 3 個 Codex audit 都寫 `無 (理由: <具體>)`」案例
- AGENTS [§3.1](../../AGENTS.md) / [§3.3](../../AGENTS.md) 例外條款 (純 spec 文字修正、無方向風險) 的實際長相
- **不接受**: `無 (理由: 不需要)` / `無 (理由: N/A)` / `無 (理由: 無)` — hook + CI 會擋
- **接受**: `無 (理由: 純 scenario 文字修正, error 行為與 status code 未變)` 一類具體說明

**為什麼這個 change 仍走 SDD?**

因為它**改動 spec scenario 文字** (即使行為不變)。AGENTS [§0](../../AGENTS.md) 「不觸發 SDD」的例外清單只涵蓋:

- 純 bugfix (改幾行 code, **對應現有 spec scenario 無需改動**)
- 純 rename / 樣式調整 / 文件更新
- 問答 / 解釋

本 change 屬「修改既有行為的描述」 → 走 SDD, 但 Codex 介入合法跳過。

**對照** [`../add-user-login/`](../add-user-login/) (全套 audit 都跑) — 同樣是 SDD 流程, audit 行為不同, 結構不變。
