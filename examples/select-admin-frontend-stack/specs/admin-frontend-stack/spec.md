<!-- approved-by: erikhuang 2026-05-19
     notes: pilot 範例 spec, 用於 sdd-codex-starter reference change -->
<!-- 完備性審查來源: codex (review, 2026-05-19, 已傳遞: spec + design Decisions) -->

## ADDED Requirements

<!-- 寫作規範: 每個 Requirement 至少要有一條正常路徑 (WHEN/THEN) 與一條異常路徑 (IF/THEN)。
     詳見 sdd-codex-starter/docs/spec-writing.md (EARS 對應)。 -->

### Requirement: 主框架選定為 Next.js (App Router)

新版後台前端 SHALL 使用 Next.js (App Router) 作為主框架, 並啟用 TypeScript strict mode。所有頁面 MUST 透過 App Router 建立, 不得新增 Pages Router 頁面。

#### Scenario: 新建頁面使用 App Router

- **WHEN** 開發者要新增一個後台頁面
- **THEN** 該頁面 MUST 建立在 `app/` 目錄下並使用 React Server Component 作為預設模式

#### Scenario: TypeScript 型別檢查阻擋 commit

- **WHEN** 開發者送出帶有 TypeScript 錯誤的程式碼
- **THEN** pre-commit hook MUST 阻擋該 commit 並輸出 tsc 錯誤

#### Scenario: [異常] 嘗試新增 Pages Router 頁面

- **IF** 開發者在 `pages/` 目錄新增任何 `.tsx` / `.ts` 檔案
- **THEN** ESLint 規則 `no-pages-router` MUST 報錯, 且 CI MUST 於 lint 階段失敗並阻擋 merge

### Requirement: UI 元件統一使用 Ant Design

所有後台 UI 元件 (表格、表單、Modal、按鈕、Layout) MUST 優先使用 Ant Design。客製樣式 MUST 透過 Ant Design `ConfigProvider` 注入 design tokens, 不得直接覆寫元件內部 class。

#### Scenario: 表格頁面使用 AntD Table

- **WHEN** 開發者建立資料列表頁面
- **THEN** 該頁面 MUST 使用 `<Table>` from `antd`, 不得自行手刻表格元件

#### Scenario: 客製主題透過 ConfigProvider

- **WHEN** 需要套用設計系統色票
- **THEN** 顏色 token MUST 透過 `<ConfigProvider theme={...}>` 注入, 不得在元件層級寫 inline style 覆寫

#### Scenario: [異常] 引入第二套 UI 元件庫

- **IF** `package.json` 出現 `@mui/material`、`@chakra-ui/*`、`@mantine/core` 等與 antd 重疊用途的依賴
- **THEN** CI 的 `dependency-policy` 步驟 MUST 失敗, 並阻擋 PR 合併直到該依賴被移除或經架構評審紀錄豁免

### Requirement: 狀態管理使用 Redux Toolkit

跨頁、跨元件共享的狀態 (使用者身份、權限 manifest、全域通知) MUST 存於 Redux Toolkit store。單一頁面內部 transient state 不在此限, 可使用 `useState`。

#### Scenario: 使用者登入後寫入 store

- **WHEN** SSO 登入成功
- **THEN** 使用者身份與權限 manifest MUST 被寫入 RTK store 的 `auth` slice, 並可被任一頁面 `useSelector` 讀取

#### Scenario: 頁面內部 UI state 不上 store

- **WHEN** 元件僅需追蹤本地展開/收合狀態
- **THEN** 該狀態 MUST 使用 `useState`, 不得寫入 Redux store

#### Scenario: [異常] SSO 成功但 manifest 為空

- **IF** SSO 回傳合法 user 但 `permissions` 為 `null` 或 `[]`
- **THEN** `auth` slice MUST 將 `status` 設為 `restricted`, 路由 MUST 將使用者導向 `/no-access` 頁面, 且 MUST 不快取此狀態超過 5 分鐘

### Requirement: 資料層使用 TanStack Query

所有對既有 PHP API 的呼叫 MUST 透過 TanStack Query 的 `useQuery` / `useMutation` 進行, 不得直接 `fetch` 或 `axios.get` 後手動管 loading/error。

#### Scenario: 列表頁讀資料

- **WHEN** 列表頁掛載
- **THEN** 該頁 MUST 使用 `useQuery({ queryKey, queryFn })` 取資料, 並交給 TanStack Query 管理 cache 與重試

#### Scenario: 表單送出走 mutation

- **WHEN** 使用者送出表單
- **THEN** 該動作 MUST 透過 `useMutation` 執行, 成功後 MUST 呼叫 `queryClient.invalidateQueries` 失效相關 query

#### Scenario: [異常] API 回 5xx 或網路錯誤

- **IF** `useQuery` 觸發的請求回 5xx 或網路中斷
- **THEN** TanStack Query MUST 依預設策略重試最多 3 次 (指數退避), 全部失敗後 MUST 將 query 標為 `error` 並由上層 `<ErrorBoundary>` 渲染重試 UI, 不得讓使用者看見白畫面

#### Scenario: [異常] mutation 失敗

- **IF** `useMutation` 的請求最終失敗 (任何 4xx 或耗盡重試的 5xx)
- **THEN** MUST 不執行 `invalidateQueries`, MUST 透過 AntD `notification.error` 顯示後端訊息, 且 MUST 保留表單原值供使用者重送

### Requirement: 前後端透過 BFF 層整合 PHP

瀏覽器 MUST 不得直接呼叫既有 PHP API。所有對外請求 MUST 經由 Next.js Route Handlers (BFF 層) 轉發, 由 BFF 統一處理 cookie、CSRF token、SSO session 轉換。

#### Scenario: 瀏覽器呼叫 API

- **WHEN** 前端 component 需要打 API
- **THEN** 該請求 MUST 打到 `/api/*` (Next.js Route Handler), 由 Route Handler 再轉發至內部 PHP service

#### Scenario: SSO cookie 不外洩

- **WHEN** Route Handler 轉發請求至 PHP
- **THEN** PHP session cookie MUST 僅在 server-to-server 段流通, 不得回寫至瀏覽器

#### Scenario: [異常] CSRF token 不符

- **IF** BFF Route Handler 收到非 GET 請求且 `x-csrf-token` 標頭與 session 內值不符或缺少
- **THEN** BFF MUST 直接回 `403 Forbidden`, MUST 不轉發給 PHP, 且 MUST 將事件寫入 audit log

#### Scenario: [異常] PHP 回 401

- **IF** PHP 對 BFF 轉發的請求回 `401 Unauthorized`
- **THEN** BFF MUST 清除 Next.js session cookie, 統一回 `401` 給瀏覽器, 前端 MUST 攔截 401 並重導向 `/login`

### Requirement: 權限以後端為權威

前端 MUST 不得硬寫角色 → 權限對應表。權限判斷 MUST 由後端在登入時回傳的 `permissions` manifest 決定, 前端僅依該 manifest 決定 UI 顯隱。

#### Scenario: 隱藏無權限按鈕

- **WHEN** 使用者的 `permissions` manifest 不含 `user.delete`
- **THEN** 任何「刪除使用者」按鈕 MUST 不被渲染

#### Scenario: 新增權限不需改前端

- **WHEN** 後端新增一筆權限項目
- **THEN** 前端 MUST 不需改動程式碼, 僅透過 manifest 內容即可生效

#### Scenario: [異常] manifest 拉取失敗

- **IF** 登入後拉取 `permissions` manifest 的請求失敗 (network / 5xx / timeout)
- **THEN** 前端 MUST 以「最小權限預設」(全部受保護操作視為無權限) 運作, MUST 顯示頂端橫幅「權限資料暫時無法載入, 部分操作受限」與重試按鈕, 且 MUST 不嘗試從本地快取讀取舊 manifest 超過 24 小時
