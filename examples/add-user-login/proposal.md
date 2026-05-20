<!-- 對抗性審查來源: codex (adversarial-review, 2026-05-20, 已傳遞: 完整 proposal) -->

## Why

後台目前無使用者登入機制, 任何人連到 URL 都能操作。在開放給多人使用前, 必須先有可審計、可撤銷、可分權的登入系統, 否則所有後續權限 / 操作記錄 / 稽核需求都無從建立。

## What Changes

- 新增使用者登入流程 (email + 密碼 → server 驗證 → 發放 session)
- 新增 session 持久化機制 (跨頁、跨 tab、可主動登出)
- 新增登入失敗的限制 (5 次後鎖定 15 分鐘)
- 新增登出機制 (清除 session, 任一頁面均可觸發)
- 預留 2FA 接口但本次不實作 (列入 Open Questions)

## Capabilities

### New Capabilities
- `user-login`: 使用者帳密登入、session 管理、登入失敗節流、登出

### Modified Capabilities
<!-- 無 — 此 capability 為全新建立 -->

## Impact

- 影響: 新後台前端 (尚未上線)、既有 PHP 帳號表 (讀取, 不改 schema)、稽核 log pipeline
- 依賴: 既有 SSO 不在本次範圍 (與 SSO 整合屬未來 capability)
- 風險: 密碼處理錯誤會造成全帳號外洩 — Mitigation: 密碼僅在 server 端 hash, 前端絕不存; 失敗節流必須在 server 端強制, 非僅前端 disable 按鈕

## Open Questions

- 2FA 設計 (TOTP / WebAuthn / SMS) — 列入後續 change, 本次預留 session 欄位但不啟用
- 密碼複雜度策略 — 引用既有 PHP API 策略, 不在本 change 重定
