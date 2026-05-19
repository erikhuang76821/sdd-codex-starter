## Context

舊版後台是 jQuery + PHP 多頁式樣板, 新人接手成本高、無 TypeScript、無設計系統。本次選型必須兼顧:

- 既有 PHP API、SSO、權限系統不會重寫, 前端要能無痛整合
- 未來 5 年仍有社群動能、人才招募容易
- 後台場景: 大量表格、表單、權限頁面, 不是 marketing site

第二意見來源: codex (codex:rescue, 2026-05-19), 內容已納入下列 Decisions。

## Goals / Non-Goals

**Goals:**
- 選定主框架 + UI + 狀態 + 資料層四項技術
- 每項決策都有「為何不選其他候選」的理由
- 標註已知最大風險與 mitigation

**Non-Goals:**
- 不在本次決定 monorepo / build pipeline / 測試框架
- 不在本次重寫 PHP API 或 SSO

## Decisions

### D1. 主框架: Next.js (App Router)

- 選擇理由: SSR 成熟、TypeScript 一等公民、React 生態與人才池最廣, 適合企業後台長期維護。
- 不選 Nuxt: 團隊需轉 Vue, React UI 元件與人才較不利。
- 不選 Remix / SvelteKit: 企業後台生態較窄、5 年維護風險高。

### D2. UI 元件庫: Ant Design

- 選擇理由: 後台表格、表單、權限頁面內建完整, 降低自建成本。
- 不選 shadcn/ui: 需自行組裝表格/表單, 短期工時暴增。
- 不選 Mantine: 社群動能與企業案例少於 Ant Design。

### D3. 狀態管理: Redux Toolkit

- 選擇理由: SSO、權限、跨頁狀態需可追蹤治理 (devtools + middleware), RTK 樣板已大幅簡化。
- 不選 Zustand / Jotai: 後台中後期權限與審計需求需要中心化 store, 輕量庫長期會自製 middleware。

### D4. 資料層: TanStack Query

- 選擇理由: 與既有 PHP REST API 直接整合, 快取失效/重試/分頁/樂觀更新原生支援。
- 不選 SWR: 功能子集, 後台複雜失效策略較吃力。
- 不選 tRPC: 需後端 TypeScript, 既有 PHP API 無法配合。

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
