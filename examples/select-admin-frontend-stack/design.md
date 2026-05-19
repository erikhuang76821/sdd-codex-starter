## Context

舊版後台是 jQuery + PHP 多頁式樣板, 新人接手成本高、無 TypeScript、無設計系統。本次選型必須兼顧:

- 既有 PHP API、SSO、權限系統不會重寫, 前端要能無痛整合
- 未來 5 年仍有社群動能、人才招募容易
- 後台場景: 大量表格、表單、權限頁面, 不是 marketing site

## Goals / Non-Goals

**Goals:**
- 選定主框架 + UI + 狀態 + 資料層四項技術
- 每項決策都有「為何不選其他候選」的理由
- 標註已知最大風險與 mitigation

**Non-Goals:**
- 不在本次決定 monorepo / build pipeline / 測試框架
- 不在本次重寫 PHP API 或 SSO

## Decisions

第二意見來源: codex (codex:rescue, 2026-05-19, 已傳遞: proposal + 首個決策), 內容已納入下列 Decisions。

### D1. 主框架: Next.js (App Router)

**一句話**: 挑了一套大家都在用的後台「主結構」, 換人接手或找新人補位都比較好找, 5 年後也還有人在用、不會變成沒人維護的孤兒。

**對使用者 / 企劃看得見的影響**:
- 頁面載入: 預期比舊後台快 30-50% (首屏 + 切頁)
- 找新人接手: 招募市場上會這套的人, 比另外兩個候選多約 5-10 倍
- 5 年後的風險: 低 — 是全球後台主流, 不太可能淘汰

**為何不選**:
- Nuxt: 跟現有團隊技能不合, 等於要全組重學, 三個月後新人才能上手 → 開發進度延後
- Remix / SvelteKit: 概念新穎, 但寫後台的人少, 5 年後可能變孤兒專案 → 屆時無人可接

**技術層理由 (給工程 review)**:
- SSR 成熟、TypeScript 一等公民、React 生態與人才池最廣, 適合企業後台長期維護

### D2. UI 元件庫: Ant Design

**一句話**: 挑了一套「現成的後台積木」, 表格、表單、權限頁面開箱即用, 不用工程從零畫每個按鈕。

**對使用者 / 企劃看得見的影響**:
- 首版 pilot 頁面交付時程: 預估從 6 週 → 3 週 (省掉自畫元件)
- 設計系統落地一致性: 高 — 同事在不同後台頁面看到的表格 / 表單長一樣
- 客製深度: 中等 — 顏色 / 字體 / spacing 能改, 但元件內部結構是固定的

**為何不選**:
- shadcn/ui: 看起來漂亮但要自己組表格 / 表單, 短期內工時暴增 → pilot 交付延後 1-2 個月
- Mantine: 用過的台灣企業少, 出問題時 Stack Overflow / 社群解答稀疏 → 卡關時找人問會很慢

**技術層理由 (給工程 review)**:
- 後台表格、表單、權限頁面內建完整, 降低自建成本
- ConfigProvider 機制能注入設計系統 token, 不必硬刻

### D3. 狀態管理: Redux Toolkit

**一句話**: 挑了一個能「全公司所有同事的登入身分 + 權限」放在一個中央倉庫的工具, 之後做審計或 debug 都能直接看到「這個人為什麼能/不能做這個動作」。

**對使用者 / 企劃看得見的影響**:
- 權限稽核: 高 — DevTools 能逐步重播任何使用者操作, 出包時釐清原因從幾天 → 幾小時
- 跨頁狀態一致性: 高 — 同事換頁不會看到登入身分忽然不見或權限閃爍
- 寫程式的工時: 比輕量庫多約 10-15%, 但中後期改動成本低 (有 middleware 統一管)

**為何不選**:
- Zustand / Jotai: 短期省力, 但後台中後期權限與審計需求出現後, 會自製 middleware 重新長成一個輕量 Redux → 等於走兩次, 多花 2-3 個月
- 沒有中央 store: 跨頁傳資料靠 URL / localStorage, 出包時無從追蹤 → 客服處理使用者 ticket 的時間翻倍

**技術層理由 (給工程 review)**:
- SSO、權限、跨頁狀態需可追蹤治理 (devtools + middleware), RTK 樣板已大幅簡化
- Slice pattern 對審計事件記錄 / time-travel debug 友好

### D4. 資料層: TanStack Query

**一句話**: 挑了一個「自動幫你管 API 資料」的工具, 同事點頁面時自動快取、網路斷了會自動重試、表單送出失敗會留住資料, 工程不必每支 API 都手寫一遍。

**對使用者 / 企劃看得見的影響**:
- 同事重複開同頁面: 從重新打 API → 即時顯示 (有快取), 體感速度提升 2-3 倍
- 網路不穩時: 自動重試 3 次, 同事不會看到白畫面或要手動重整
- 表單送出失敗: 表單內容自動保留, 同事不必重打一次

**為何不選**:
- SWR: 功能比較少, 後台複雜的「資料失效規則」(例: 改完 A 表後刷新 B/C 表) 寫起來吃力 → 後續每個複雜頁要多寫 30-50% 的程式
- tRPC: 要求後端也用 TypeScript, 但既有 PHP API 不可能改 → 用不了
- 自己手寫 fetch: 每支 API 都要重寫 loading / error / cache / retry 邏輯 → 工程時數浪費在重複造輪子

**技術層理由 (給工程 review)**:
- 與既有 PHP REST API 直接整合, 快取失效 / 重試 / 分頁 / 樂觀更新原生支援
- 與 RTK 並存無衝突 (server-state 由 TanStack Query, client-state 由 RTK)

## Risks / Trade-offs

- **R1. SSR 與 PHP session/SSO 邊界混亂** → Mitigation: 建立 BFF 層 (Next.js Route Handlers) 統一處理 cookie、CSRF、token forwarding, 不讓瀏覽器直接打 PHP。
- **R2. 前後端權限邏輯重複分歧** → Mitigation: 後端為權威, 前端只讀「權限 manifest」(API 回傳的 permission list), 不在前端硬寫角色判斷。
- **R3. Ant Design 與 Tailwind/design system 整合摩擦** → Mitigation: 設計系統 token 透過 ConfigProvider 注入, 不混用兩套樣式系統。

## Migration Plan

1. 新後台獨立 repo 起 Next.js 骨架, 不動既有 PHP
2. 第一支 BFF route 串既有 PHP login + SSO, 跑通 session
3. 一個 pilot 頁面 (e.g. 使用者清單) 驗證 Ant Design + TanStack Query + RTK 全鏈路
4. 站穩後再逐頁遷移舊功能, 舊 PHP 後台與新後台並存到全部頁面搬完

## Open Questions

- BFF 是放 Next.js Route Handlers 還是另起獨立 Node 服務? (傾向前者, 但需確認 SSO provider 限制)
- 是否需在 pilot 階段就導入 E2E 測試? (建議是, 但工具選型另案)
