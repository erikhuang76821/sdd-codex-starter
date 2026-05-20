## Context

`user-login` capability 已存在 (見 add-user-login change)。session payload 已有 `mfaVerified` 欄位但本期才實際使用。新增 TOTP 註冊 + 驗證流程, 並修改 session 發放規則。

## Goals / Non-Goals

**Goals**:
- 決定 2FA 演算法 (TOTP vs WebAuthn)
- 決定既有 session 的失效策略 (本 change 上線時)

**Non-Goals**:
- 不在本次設計 admin reset 流程 (失手機 / 換手機的恢復)
- 不在本次處理 backup codes (進階流程, 另案)

## Decisions

第二意見來源: codex (codex:rescue, 2026-05-20, 已傳遞: proposal + 首個決策)

### D1. 2FA 演算法: TOTP (RFC 6238)

**一句話**: 用「同事手機 Google Authenticator 每 30 秒換一組 6 碼」這套老牌做法, 學習曲線最低、不依賴硬體 key、所有同事的手機都能用。

**對使用者 / 企劃看得見的影響**:
- 同事學習成本: 低 — 90% 的人已用過 Google / GitHub 的 6 碼驗證
- 採購成本: 0 — 不需發放硬體 key
- 5 年後的風險: 中 — TOTP 對釣魚抗性比 WebAuthn 弱, 但短期內企業仍主流

**為何不選**:
- WebAuthn / FIDO2: 抗釣魚能力最強, 但每位同事要硬體 key 或瀏覽器內建 platform authenticator, 採購 + 訓練成本本期吃不下 → 明年 review 後可再評估升級
- SMS OTP: 一般人最熟, 但 SIM swap 攻擊 + 簡訊成本 + 國際同事訊號不穩 → 不符合 2026 安全標準

**技術層理由 (給工程 review)**:
- RFC 6238 標準成熟, Node.js 端有多個成熟 library (otplib)
- 與既有 session 機制無耦合, 只在登入流程中插入一道閘
