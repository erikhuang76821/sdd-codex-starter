# Spec Writing — EARS 對應、Scenario 模板、反模式

這份文件補充 [`../AGENTS.md`](../AGENTS.md) 第 2 節, 詳細說明如何在 OpenSpec
的 `WHEN/THEN` 模板下寫出符合 EARS (Easy Approach to Requirements Syntax) 的
acceptance criteria, 並確保異常路徑 (error path) 不被遺漏。

## 為什麼要 EARS

純自然語言 requirement 容易長這樣:

> 「系統應該處理 API 錯誤。」

讀的人不知道:**什麼樣的 API 錯誤? 處理是怎樣? 給誰看? 重試幾次?**

EARS 用 5 個固定句型把要求結構化, 每個 requirement 都長得像可被測試的句子。
OpenSpec scenario 用 `WHEN/THEN` 模板, 剛好對應 EARS 的 event-driven pattern,
但容易讓人以為「scenario 只能寫 WHEN」, 結果**異常路徑全漏掉**。

實務上發現: OpenSpec validator 對 `IF/WHILE/WHERE` 也接受 (--strict 通過), 所以
可以放心用全套 EARS。

## 5 個 EARS pattern

### 1. Ubiquitous (恆真)

永遠成立的約束, 沒有觸發條件。
寫在 `### Requirement:` 的描述段, 不需要 scenario 重複。

```markdown
### Requirement: API 必須使用 HTTPS

所有對外 API endpoint MUST 使用 TLS 1.2+ 加密傳輸。
```

### 2. Event-driven — `WHEN ... THEN ...` (Happy path)

某事件發生 → 系統做出對應反應。**這是 happy path 的標準寫法。**

```markdown
#### Scenario: 使用者送出登入表單
- **WHEN** 使用者點擊登入按鈕
- **THEN** 系統 MUST 送出 POST `/api/auth/login` 並等待回應
```

### 3. State-driven — `WHILE ... THEN ...` (狀態持續)

在某狀態持續中, 系統需要維持某行為。

```markdown
#### Scenario: 載入中按鈕禁用
- **WHILE** mutation 處於 `pending` 狀態
- **THEN** 提交按鈕 MUST 處於 disabled 狀態, 並顯示 spinner
```

### 4. Unwanted behaviour — `IF ... THEN ...` (異常路徑 ⭐ 必寫)

不該發生但會發生的情境 → 系統如何回應。**每個 requirement 至少要有一個。**

```markdown
#### Scenario: [異常] API 回 5xx
- **IF** 請求回 5xx 或網路中斷
- **THEN** TanStack Query MUST 重試最多 3 次 (指數退避),
  失敗後 MUST 由上層 `<ErrorBoundary>` 渲染重試 UI
```

### 5. Optional feature — `WHERE ... THEN ...` (條件性)

僅當某功能被啟用時才適用的行為。

```markdown
#### Scenario: 啟用 SSO 時跳過密碼欄
- **WHERE** 環境變數 `AUTH_PROVIDER=sso`
- **THEN** 登入頁 MUST 不渲染密碼輸入框, 改顯示「使用公司 SSO 登入」按鈕
```

## 異常路徑必涵蓋的四類

每個 requirement 的 `[異常]` scenario 至少要踩到下列其中一類:

| 類別 | 例子 |
|---|---|
| 上游失敗 | API 5xx、network timeout、第三方服務 down |
| 認證/權限 | 401、403、token 過期、CSRF 不符 |
| 資料缺失或不合法 | manifest 空、必填欄位缺、enum 不在範圍 |
| 重試耗盡 / 降級 | 重試 3 次仍失敗、cache 過期且無法重抓 |

只寫「正向行為」與「不要做 X」的 spec 不算 OK。

## 命名規範

| | 名稱範例 |
|---|---|
| Happy path | `#### Scenario: 使用者送出登入表單` |
| Error path | `#### Scenario: [異常] 表單欄位驗證失敗` |
| State-driven | `#### Scenario: [狀態] 載入中按鈕禁用` (可選前綴) |

`[異常]` 前綴是強制的, 讓 reviewer 與 grep 都能立刻找到所有 error scenario。

## 反模式

### ❌ 全部寫 happy path

```markdown
### Requirement: 表單送出

#### Scenario: 使用者送出表單
- **WHEN** 使用者送出表單
- **THEN** 系統 MUST 儲存資料

#### Scenario: 儲存成功顯示通知
- **WHEN** 儲存成功
- **THEN** 系統 MUST 顯示成功通知
```

**問題**: 兩個 scenario 都是 happy path, 失敗情境 (網路斷、驗證錯、衝突) 全缺。

### ❌ error scenario 只寫「系統 log 錯誤」

```markdown
#### Scenario: [異常] API 失敗
- **IF** API 回 500
- **THEN** 系統 MUST 將錯誤寫入 log
```

**問題**: 「寫 log」是內部行為, 不是 acceptance criteria。**使用者看到什麼?**
重試嗎? 顯示什麼訊息? 表單值會留嗎? 沒答, 就沒驗收標準。

### ❌ 用 WHEN 描述異常觸發

```markdown
#### Scenario: API 失敗時
- **WHEN** API 回 500
- **THEN** 重試
```

**問題**: 語法上 OpenSpec 不會擋, 但讀者分不清這是正常事件還是異常情境。
凡是「不期待但會發生」的情境 → 用 `IF`, 不要用 `WHEN`。

### ❌ 一個 scenario 塞太多

```markdown
#### Scenario: 各種失敗的處理
- **IF** API 失敗 或 timeout 或 401 或 CSRF 錯
- **THEN** 重試或重導向或顯示錯誤
```

**問題**: 不可測試。每個失敗條件對應的 expected behaviour 不一樣, 拆成多條 scenario。

## 檢查清單 (送 spec PR 前自查)

- [ ] 每個 `### Requirement:` 至少 1 個 happy + 1 個 `[異常]` scenario
- [ ] 每個 `[異常]` scenario 用 `IF/THEN`, 不是 `WHEN/THEN`
- [ ] 每個 `[異常]` scenario 涵蓋上游失敗 / 認證權限 / 資料缺失 / 降級 之一
- [ ] error scenario 描述「對使用者的可觀察影響」, 而不只是「系統 log」
- [ ] 規範用語 SHALL / MUST, 沒出現 should / may
- [ ] `openspec validate <change-id> --strict` 通過

## 進一步閱讀

- EARS 原始論文: Mavin et al., *Easy Approach to Requirements Syntax (EARS)*, RE 2009
- 完整範例: [`../examples/select-admin-frontend-stack/specs/admin-frontend-stack/spec.md`](../examples/select-admin-frontend-stack/specs/admin-frontend-stack/spec.md)
