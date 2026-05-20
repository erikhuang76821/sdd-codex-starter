# enable-2fa

MODIFIED Requirements 範例: 在已存在的 `user-login` capability 上啟用 TOTP 2FA, 改變既有「Session 預留 2FA 欄位」Requirement 的行為。

**示範什麼**:

- 同一份 `specs/user-login/spec.md` 內同時出現 `## MODIFIED Requirements` 與 `## ADDED Requirements`
- 遵守 [`AGENTS §1`](../../AGENTS.md) 規則: **MODIFIED Requirement 整段 copy 原 requirement 再改, 不只寫差異**
- design 階段只做一個 Decision (TOTP vs WebAuthn), 第二意見 audit 仍跑
- 對比 [`../add-user-login/`](../add-user-login/) — 那邊 `mfaVerified` 是預留欄位, 本 change 才實際接上邏輯
