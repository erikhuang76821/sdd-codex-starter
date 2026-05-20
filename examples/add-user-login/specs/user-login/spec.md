<!-- approved-by: erikhuang 2026-05-20
     notes: pilot 範例 spec, 用於 sdd-codex-starter 純新功能參考 -->
<!-- 完備性審查來源: codex (review, 2026-05-20, 已傳遞: spec + design Decisions) -->

## ADDED Requirements

### Requirement: 使用者以帳號 + 密碼登入

系統 SHALL 透過 `POST /api/auth/login` 接受帳號 + 密碼, 由 server 端驗證後發放 session cookie。瀏覽器端 MUST 不得自行 hash 或預處理密碼, MUST 不得將密碼存入任何瀏覽器儲存。

#### Scenario: 使用者送出有效帳密

- **WHEN** 使用者在登入頁送出有效 email + 密碼
- **THEN** server MUST 回 200 並 Set-Cookie: `session=<opaque>; HttpOnly; Secure; SameSite=Lax`, 前端 MUST 導向 `/dashboard`

#### Scenario: [異常] 密碼錯誤

- **IF** 帳號存在但密碼錯誤
- **THEN** server MUST 回 401, 訊息 MUST 為「帳號或密碼錯誤」(不得分別洩漏「帳號不存在」與「密碼錯」), 且 MUST 對該 `userId` 的 `failedCount` +1, 當前同事頁面 MUST 留住已填的 email 但清空密碼欄

#### Scenario: [異常] 帳號不存在

- **IF** 帳號不存在
- **THEN** server MUST 回 401 並用與「密碼錯」**完全相同**的訊息與回應時間 (常數時間比對), 不得讓攻擊者由錯誤訊息或回應延遲推斷帳號是否存在

### Requirement: 失敗 5 次後鎖定 15 分鐘

系統 SHALL 對連續登入失敗達 5 次的帳號鎖定 15 分鐘。節流 MUST 由 server 端強制, 前端僅同步 UI。

#### Scenario: 第 5 次失敗後鎖定

- **WHEN** 同一個 `userId` 在 15 分鐘視窗內連續登入失敗達 5 次
- **THEN** server MUST 回 423 (Locked), 訊息含「請 15 分鐘後再試或變更密碼解鎖」, 前端 MUST disable 登入表單並顯示倒數

#### Scenario: [異常] 鎖定期間仍嘗試送出

- **IF** 帳號處於鎖定狀態, 同事直接打 API (繞過 disabled 表單)
- **THEN** server MUST 仍回 423 (不得因「前端有 disable」而放行), 且 MUST 不重置剩餘鎖定時間 (不延長, 也不縮短)

#### Scenario: [異常] Redis / 計數儲存失敗

- **IF** 節流計數的儲存層暫時不可用 (Redis down / 連線錯誤)
- **THEN** server MUST 採「拒絕該次登入」的降級策略 (回 503, 訊息「系統暫時無法處理登入請求, 請稍候再試」), MUST 不假設「沒記錄就是 0 次失敗」放行, 也 MUST 不無限重試導致請求堆積

### Requirement: 登出立即失效 session

系統 SHALL 提供 `POST /api/auth/logout`, 收到請求後立即廢止對應 session 並清 cookie。

#### Scenario: 使用者點登出

- **WHEN** 已登入使用者點任一頁面的「登出」按鈕
- **THEN** server MUST 將該 session 在儲存層標記為 revoked, 回應 MUST Set-Cookie: `session=; Max-Age=0`, 前端 MUST 清空 Redux auth slice 並導向 `/login`

#### Scenario: [異常] 已 revoked 的 session 再次被使用

- **IF** 同事在裝置 A 登出後, 裝置 B (同 session) 仍嘗試呼叫受保護的 API
- **THEN** server MUST 回 401, 前端攔截後 MUST 自動導向 `/login` 並顯示「您已在其他裝置登出, 請重新登入」

### Requirement: Session 預留 2FA 欄位

系統 SHALL 在 session payload 中預留 `mfaVerified: boolean` 欄位, 本 change 內 server 一律設為 `true` (尚無 2FA), 但欄位 MUST 已存在以便未來 capability 接續。

#### Scenario: 本 change 內所有成功登入

- **WHEN** server 發放新 session
- **THEN** session payload MUST 含 `mfaVerified: true`, 即使本期未啟用 2FA

#### Scenario: [異常] 未來 2FA capability 上線後本欄位被誤讀

- **IF** 某未來 capability 嘗試讀取 `mfaVerified` 並基於該欄位做權限判斷
- **THEN** 本 change 的 Open Questions MUST 已警示此欄位的「本期僅佔位」性質, 該未來 capability MUST 在自己的 spec 內明示 `mfaVerified` 行為轉變的觸發點, 且 MUST 不依賴本期任何 `true` 預設值
