## Context

`user-login` capability 從零建立。瀏覽器端為 Next.js (見 `select-admin-frontend-stack` D1), server 端為 Next.js Route Handlers (BFF), 後方仍是既有 PHP 帳號表。

## Goals / Non-Goals

**Goals**:
- 決定 session 載體 (cookie vs token)
- 決定登入失敗節流的實作層
- 決定密碼驗證走 server-to-server 還是直連 DB

**Non-Goals**:
- 不在本次設計 2FA 細節
- 不在本次重寫 PHP 密碼 hash 演算法

## Decisions

第二意見來源: codex (codex:rescue, 2026-05-20, 已傳遞: proposal + 首個決策)

### D1. Session 載體: HttpOnly Secure Cookie

**一句話**: 把「同事登入過」這件事存在瀏覽器一個看不到也偷不到的小餅乾裡, 而不是寫在前端 JavaScript 拿得到的地方, 出包時被盜風險最低。

**對使用者 / 企劃看得見的影響**:
- 換頁 / 重整: 不會被登出 (cookie 跨頁活著)
- 被攻擊風險: 低 — 即使前端網頁被注入惡意 script, 也讀不到 session
- 與既有後台共存: 不會互相覆蓋 (cookie 名稱與 PHP 後台分離)

**為何不選**:
- localStorage 存 JWT: 前端 script 能直接讀, 一旦被 XSS 等於同事帳號被盜 → 稽核會出大事
- sessionStorage: 換 tab 就消失, 同事要重新登入很多次 → 體感差且易誤觸發節流

**技術層理由 (給工程 review)**:
- HttpOnly + Secure + SameSite=Lax, 同時阻斷 XSS 讀取與大部分 CSRF
- 與既有 BFF Route Handler 設計天然契合, 不必引入 token refresh 機制

### D2. 失敗節流: server 端強制 + 前端僅輔助

**一句話**: 同一個帳號連續打錯密碼 5 次就鎖 15 分鐘, 這個鎖**只信 server 自己算的**, 不靠瀏覽器, 怕同事或攻擊者直接繞過前端。

**對使用者 / 企劃看得見的影響**:
- 攻擊者跑暴力破解: 5 次後就被擋, 即使換瀏覽器 / 換裝置也擋得住
- 一般同事打錯密碼: 前 4 次提示, 第 5 次顯示「請 15 分鐘後再試」, 不會永久鎖
- 帳號鎖定後的恢復: 同事可改密碼解鎖 (走另一條路徑), 不必等 15 分鐘

**為何不選**:
- 純前端節流 (disable 按鈕 + 計時器): 攻擊者直接打 API 端, 前端鎖等同沒鎖 → 等於沒做
- IP-based 節流: 同辦公室共用 NAT 出口時會誤鎖無辜同事 → 客服處理量大增

**技術層理由 (給工程 review)**:
- BFF Route Handler 內維護 `{userId: {failedCount, lockedUntil}}` (Redis 或記憶體, 視部署)
- 計數 key 用 `userId` 而非 IP, 避開 NAT 誤傷
