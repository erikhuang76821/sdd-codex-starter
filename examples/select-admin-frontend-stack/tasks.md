## 1. Repo 與骨架

- [ ] 1.1 建立 `admin-frontend` repo 並 init Next.js 15 (App Router, TypeScript strict) → verified by: 無 (理由: 純 repo 初始化, 無 scenario 對應)
- [ ] 1.2 設定 ESLint + Prettier + tsc pre-commit hook → verified by: scenario "TypeScript 型別檢查阻擋 commit"
- [ ] 1.3 設 CI: lint + typecheck + build on PR → verified by: scenario "[異常] 嘗試新增 Pages Router 頁面"

## 2. BFF 與 SSO 整合

- [ ] 2.1 在 `app/api/auth/*` 建立 SSO callback Route Handler, 轉換為 Next.js session cookie → verified by: scenario "瀏覽器呼叫 API"
- [ ] 2.2 建立通用 proxy Route Handler `app/api/[...path]/route.ts`, 轉發至既有 PHP API 並注入 SSO token → verified by: scenario "瀏覽器呼叫 API"
- [ ] 2.3 確認 PHP session cookie 不外洩到瀏覽器 (Set-Cookie 過濾測試) → verified by: scenario "SSO cookie 不外洩"

## 3. UI 與設計系統

- [ ] 3.1 安裝 antd 並包一層 `<AppConfigProvider>` 注入設計系統 token → verified by: scenario "客製主題透過 ConfigProvider"
- [ ] 3.2 建立共用 `AdminLayout` (側邊欄 + 上方 navbar) 使用 AntD Layout → verified by: 無 (理由: 基礎 layout 元件, 不對應單一 scenario)
- [ ] 3.3 撰寫 lint rule 禁止直接覆寫 antd class → verified by: scenario "客製主題透過 ConfigProvider"

## 4. 狀態與資料層

- [ ] 4.1 安裝 @reduxjs/toolkit + react-redux, 建立 `auth` slice → verified by: scenario "使用者登入後寫入 store"
- [ ] 4.2 SSO 成功後將 user + permissions manifest 寫入 `auth` slice → verified by: scenario "使用者登入後寫入 store"
- [ ] 4.3 安裝 @tanstack/react-query, 在 root 掛 `QueryClientProvider` 並設預設 staleTime / retry → verified by: scenario "列表頁讀資料"
- [ ] 4.4 撰寫共用 `useApiQuery` / `useApiMutation` wrapper 走 BFF → verified by: scenario "列表頁讀資料"

## 5. 權限系統

- [ ] 5.1 撰寫 `usePermission(key)` hook 從 RTK store 讀 manifest → verified by: scenario "隱藏無權限按鈕"
- [ ] 5.2 撰寫 `<Can permission="...">` 包裝元件 (無權限不渲染 children) → verified by: scenario "隱藏無權限按鈕"
- [ ] 5.3 寫文件: 前端禁止硬寫角色判斷, 只能透過 `usePermission` / `<Can>` → verified by: scenario "新增權限不需改前端"

## 6. Pilot 頁面

- [ ] 6.1 完成「使用者清單」頁: AntD Table + useQuery + 權限隱藏刪除鈕 → verified by: scenario "列表頁讀資料"
- [ ] 6.2 完成「使用者編輯」頁: AntD Form + useMutation + invalidateQueries → verified by: scenario "表單送出走 mutation"
- [ ] 6.3 驗收: 與既有 PHP 後台同帳號登入, 資料一致 → verified by: 無 (理由: 端到端驗收, 涵蓋多 scenario)

## 7. 收尾

- [ ] 7.1 撰寫前端架構 README (技術棧決策摘要 + onboarding) → verified by: 無 (理由: 內部文件, 無使用者可觀察行為)
- [ ] 7.2 對其他組辦一次 30 分鐘技術 walkthrough → verified by: 無 (理由: 知識傳遞活動, 無 scenario)
- [ ] 7.3 archive openspec change: `openspec archive select-admin-frontend-stack` → verified by: 無 (理由: 流程動作)
