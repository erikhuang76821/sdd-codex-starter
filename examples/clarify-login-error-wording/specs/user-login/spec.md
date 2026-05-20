<!-- approved-by: erikhuang 2026-05-20
     notes: 純文案修正範例, 三 audit 合法跳過 -->
<!-- 完備性審查來源: 無 (理由: 純 scenario 錯誤訊息文字修正, 行為 / status code / 常數時間比對等異常路徑屬性全部未變, 無新增覆蓋面可審) -->

## MODIFIED Requirements

<!-- 規則 (AGENTS §1): MODIFIED Requirement MUST copy 整段原 requirement 再改, 不得只寫差異。
     此 change 僅改錯誤訊息文字 (「錯誤」→「有誤」), 行為不變。
     仍 MUST 完整 copy 原 Requirement, 不可只貼 diff。 -->

### Requirement: 使用者以帳號 + 密碼登入

系統 SHALL 透過 `POST /api/auth/login` 接受帳號 + 密碼, 由 server 端驗證後發放 session cookie。瀏覽器端 MUST 不得自行 hash 或預處理密碼, MUST 不得將密碼存入任何瀏覽器儲存。

#### Scenario: 使用者送出有效帳密

- **WHEN** 使用者在登入頁送出有效 email + 密碼
- **THEN** server MUST 回 200 並 Set-Cookie: `session=<opaque>; HttpOnly; Secure; SameSite=Lax`, 前端 MUST 導向 `/dashboard`

#### Scenario: [異常] 密碼錯誤

- **IF** 帳號存在但密碼錯誤
- **THEN** server MUST 回 401, 訊息 MUST 為「帳號或密碼有誤」(不得分別洩漏「帳號不存在」與「密碼錯」), 且 MUST 對該 `userId` 的 `failedCount` +1, 當前同事頁面 MUST 留住已填的 email 但清空密碼欄

#### Scenario: [異常] 帳號不存在

- **IF** 帳號不存在
- **THEN** server MUST 回 401 並用與「密碼錯」**完全相同**的訊息 (「帳號或密碼有誤」) 與回應時間 (常數時間比對), 不得讓攻擊者由錯誤訊息或回應延遲推斷帳號是否存在
