<!-- 對抗性審查來源: codex (adversarial-review, 2026-05-20, 已傳遞: 完整 proposal) -->

## Why

`add-user-login` change 預留了 `mfaVerified` 欄位但本期一律設為 `true`, 等同沒 2FA。法遵 / 資安團隊要求所有後台帳號 MUST 啟用第二因素驗證, 否則無法通過下次年度稽核。本 change 將該欄位接上實際的 TOTP 驗證流程, 並把既有「session 永遠 mfaVerified=true」的 Requirement 改成「session 必須通過 TOTP 才能 mfaVerified=true」。

## What Changes

- 新增 TOTP secret 註冊流程 (首次登入時引導使用者掃 QR code 並驗證一次 6 碼)
- 新增 TOTP 驗證 endpoint (登入後尚未 mfaVerified 時必須先過此關)
- **改變既有「Session 預留 2FA 欄位」Requirement**: 從「一律設為 true」改為「TOTP 驗證通過才設 true」
- 保留 backward compat: 未註冊 TOTP 的既有帳號首次登入時走「強制註冊」分支, 不能跳過

## Capabilities

### New Capabilities
<!-- 無 — 全部變更歸入 user-login 既有 capability -->

### Modified Capabilities
- `user-login`: 新增 TOTP 註冊 + 驗證 (ADDED Requirements), 並修改 session 發放時 `mfaVerified` 的設值規則 (MODIFIED Requirements)

## Impact

- 影響: 所有後台使用者首次登入流程變長 (多一道 TOTP); 既有 session 需強制重登
- 依賴: TOTP secret 儲存 (與密碼同 DB, 但欄位獨立加密)
- 風險: TOTP secret 外洩 = 全帳號 2FA 失效 — Mitigation: secret 用 envelope encryption, 解密金鑰由 KMS 管, 應用程式只能解單筆不能匯出全表

## Open Questions

- 同事手機壞掉 / 換手機怎麼還原 TOTP — 走 admin reset 流程 (admin 介面另案), 本 change 暫不處理
- WebAuthn 取代 TOTP — 未來考量, 本期僅 TOTP
