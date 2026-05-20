<!-- approved-by: erikhuang 2026-05-20
     notes: MODIFIED Requirements 寫法範例, 重點看 "Session 預留 2FA 欄位" 整段如何被 copy + 改寫 -->
<!-- 完備性審查來源: codex (review, 2026-05-20, 已傳遞: spec + design Decisions) -->

## MODIFIED Requirements

<!-- 規則 (AGENTS §1): MODIFIED Requirement MUST copy 整段原 requirement 再改, 不得只寫差異。
     對照 examples/add-user-login/specs/user-login/spec.md 內的 "Session 預留 2FA 欄位"
     可看到「整段 copy + 修改」的具體形貌 — Requirement 名稱不變, 描述、scenario 全部改寫。 -->

### Requirement: Session 預留 2FA 欄位

系統 SHALL 在 session payload 中含 `mfaVerified: boolean` 欄位。本 change 上線後, 該欄位 MUST 反映實際的 TOTP 驗證狀態 (而非 add-user-login change 時的「一律 true」佔位策略)。新登入流程 MUST 經過 TOTP 驗證才能將 `mfaVerified` 設為 `true`; 未通過 TOTP 的 session MUST 為 `false` 並僅能訪問 `/setup-2fa` 與 `/verify-2fa` 兩條路徑。

#### Scenario: 已註冊 TOTP 的使用者成功登入並通過 TOTP

- **WHEN** 已註冊 TOTP 的使用者送出有效帳密, 接著在 `/verify-2fa` 送出正確 6 碼
- **THEN** server MUST 將 session 的 `mfaVerified` 升級為 `true`, 並導向 `/dashboard`

#### Scenario: 已註冊 TOTP 但尚未通過驗證

- **WHEN** 已註冊 TOTP 的使用者送出有效帳密但尚未送 6 碼
- **THEN** server MUST 發放 session 但 `mfaVerified: false`, 並導向 `/verify-2fa`, 任何訪問其他受保護路徑的請求 MUST 被導回 `/verify-2fa`

#### Scenario: [異常] 未註冊 TOTP 的舊帳號首次登入

- **IF** 使用者於本 change 上線前已存在但 `totpSecret` 為 `null`
- **THEN** server MUST 將該 session 設 `mfaVerified: false` 並強制導向 `/setup-2fa`, MUST 不允許跳過直接訪問 `/dashboard` 或其他業務頁面, 直到 TOTP 註冊完成

#### Scenario: [異常] 嘗試以舊版 session 訪問受保護路徑

- **IF** 使用者持有本 change 上線**前**發放的舊 session (`mfaVerified: true` 但 `totpSecret: null`)
- **THEN** server MUST 視該 session 為過期, 回 401 並清 cookie, 前端 MUST 導向 `/login` 並顯示「資安政策已更新, 請重新登入並設定 2FA」

## ADDED Requirements

### Requirement: 首次 TOTP 註冊流程

系統 SHALL 在 `/setup-2fa` 提供 QR code (含 otpauth URI) 給使用者掃描, 並驗證使用者能送回正確的 6 碼後, 才將 `totpSecret` 加密儲存。

#### Scenario: 使用者掃 QR 並送回正確 6 碼

- **WHEN** 使用者在 `/setup-2fa` 掃描 QR 後送出 6 碼且該碼在 ±30 秒視窗內有效
- **THEN** server MUST 將 `totpSecret` 透過 envelope encryption 寫入 DB, 將 session 升級為 `mfaVerified: true`, 並導向 `/dashboard`

#### Scenario: [異常] 6 碼錯誤

- **IF** 使用者送出的 6 碼不在 ±30 秒視窗內或格式錯誤
- **THEN** server MUST 不寫入 `totpSecret`, 回 400 並訊息「驗證碼錯誤, 請對齊手機時間後重試」, 表單 MUST 保留 QR 顯示讓使用者可立即重試

### Requirement: TOTP 驗證 endpoint

系統 SHALL 提供 `POST /api/auth/verify-2fa`, 接受已登入但 `mfaVerified: false` 的 session 送出 6 碼, 驗證後升級 session。

#### Scenario: 已註冊 TOTP 的使用者驗證 6 碼

- **WHEN** 持有 `mfaVerified: false` session 的使用者送出有效 6 碼
- **THEN** server MUST 將 session `mfaVerified` 升級為 `true`, 回 200, 前端 MUST 導向使用者原本要去的路徑 (若有, 否則 `/dashboard`)

#### Scenario: [異常] 6 碼錯誤達 5 次

- **IF** 同一個 session 在 15 分鐘內 6 碼錯誤累積 5 次
- **THEN** server MUST 廢止該 session (清 cookie + 標記 revoked), 回 401 「驗證失敗次數過多, 請重新登入」, 計數 MUST 與密碼登入失敗節流分開計 (避免兩種失敗互相干擾)

#### Scenario: [異常] TOTP secret 解密失敗

- **IF** 系統嘗試解密 `totpSecret` 時 KMS 不可用或金鑰旋轉導致暫時無法解
- **THEN** server MUST 回 503 「2FA 服務暫時無法驗證, 請稍候再試」, MUST 不假設「無法驗證 = 直接通過」, MUST 不嘗試 fallback 用 plaintext 比對
