## Why

舊版後台是 jQuery + 多頁式 PHP 樣板, 維運成本高且新人接手困難。需要為新版後台選定一個能支援 SSR、TypeScript、設計系統共用、未來 5 年仍有社群動能的前端技術棧。

## What Changes

- 評估並選定主要前端框架 (候選: Next.js / Nuxt / SvelteKit / Remix)
- 決定 UI 元件庫 (候選: shadcn/ui、Ant Design、Mantine)
- 決定狀態管理 (候選: Zustand / Redux Toolkit / Jotai)
- 決定資料層 (候選: TanStack Query、SWR、tRPC)
- 確認與既有 PHP API、SSO、權限系統的整合介面

## Capabilities

### New Capabilities
- `admin-frontend-stack`: 新後台前端框架、UI、狀態與資料層的選型紀錄與依據

### Modified Capabilities
<!-- 無 -->

## Impact

- 影響: 新後台前端專案 (尚未建立)、CI/CD pipeline、設計系統倉庫
- 依賴: 既有 PHP API、SSO、權限系統
- 風險: 選錯框架會造成 12+ 個月重寫成本
