## 1. DB 與加密

- [ ] 1.1 帳號表加 `totpSecret BLOB NULL` 欄位 → verified by: 無 (理由: schema migration, 與行為解耦)
- [ ] 1.2 接入 KMS 並實作 envelope encryption 包裝 → verified by: scenario "[異常] TOTP secret 解密失敗"

## 2. 註冊流程

- [ ] 2.1 `app/setup-2fa/page.tsx` 顯示 QR (otpauth URI) → verified by: scenario "使用者掃 QR 並送回正確 6 碼"
- [ ] 2.2 `app/api/auth/setup-2fa/route.ts` 驗證 6 碼並寫加密 secret → verified by: scenario "使用者掃 QR 並送回正確 6 碼"
- [ ] 2.3 6 碼錯誤訊息 + 表單保留 QR → verified by: scenario "[異常] 6 碼錯誤"

## 3. 驗證流程

- [ ] 3.1 `app/verify-2fa/page.tsx` 輸入 6 碼表單 → verified by: scenario "已註冊 TOTP 的使用者驗證 6 碼"
- [ ] 3.2 `app/api/auth/verify-2fa/route.ts` 升級 session → verified by: scenario "已註冊 TOTP 的使用者驗證 6 碼"
- [ ] 3.3 5 次錯誤後廢止 session, 與密碼失敗節流分開計 → verified by: scenario "[異常] 6 碼錯誤達 5 次"

## 4. Session 規則變更

- [ ] 4.1 登入流程在發 session 時依 `totpSecret` 是否存在決定 `mfaVerified` 初始值 → verified by: scenario "已註冊 TOTP 但尚未通過驗證"
- [ ] 4.2 middleware: `mfaVerified: false` 僅可訪問 `/setup-2fa` 與 `/verify-2fa` → verified by: scenario "已註冊 TOTP 但尚未通過驗證"
- [ ] 4.3 上線時把所有舊 session 視為過期 (session 版本號 +1) → verified by: scenario "[異常] 嘗試以舊版 session 訪問受保護路徑"
- [ ] 4.4 未註冊 TOTP 的舊帳號首次登入強制導向 /setup-2fa → verified by: scenario "[異常] 未註冊 TOTP 的舊帳號首次登入"

## 5. 收尾

- [ ] 5.1 對全公司公告「下次登入要設 2FA」並附手機 app 推薦清單 → verified by: 無 (理由: 溝通動作, 無使用者可觀察的系統行為)
- [ ] 5.2 archive: `openspec archive enable-2fa` → verified by: 無 (理由: 流程動作)
