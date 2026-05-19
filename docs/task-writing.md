# Task Writing — 獨立可驗證的執行契約

這份文件補充 [`../AGENTS.md`](../AGENTS.md) 第 6 節, 詳細說明如何寫
`tasks.md`, 讓每個 task 都是獨立、可驗證、有明確完成判定的執行單位。

## 為什麼需要這份規範

OpenSpec 的 `tasks.md` 只規定 `- [ ]` checkbox 格式, 沒有規定「怎樣才算完成」。
實務上常見的爛 task:

- `- [ ] 重構 user 模組` — 完成判定? 沒有。
- `- [ ] 優化效能` — 目標? 沒有。
- `- [ ] 加上必要的測試` — 「必要」是誰定義?

這類 task 在 AI agent 接手時尤其危險: agent 會自己編一個完成標準, 寫完 commit,
然後人類發現「啊這不是我要的」, 卻已經是 main branch 的歷史。

## 必填欄位

每個 task MUST 包含:

| 欄位 | 範例 | 用途 |
|---|---|---|
| 組號.項號 | `4.3` | 排序與 traceability |
| 動作 (祈使句) | `掛 QueryClientProvider` | 描述要做什麼 |
| `→ verified by:` | `scenario "列表頁讀資料"` | 對應的 spec scenario 名稱 |

格式:
```markdown
- [ ] <組號>.<項號> <動作> → verified by: scenario "<scenario name>"
```

## verified-by 三種合法形式

### 1. 對應到 spec scenario (預設)

```markdown
- [ ] 4.3 在 root 掛 QueryClientProvider → verified by: scenario "列表頁讀資料"
```

完成判定: 該 scenario 描述的 WHEN/THEN 行為在實作後可被觀察 / 測試。

### 2. 對應到 [異常] error scenario

```markdown
- [ ] 4.5 加上 API 失敗重試邏輯 → verified by: scenario "[異常] API 回 5xx 或網路錯誤"
```

跟 1 同, 但對應 error-path scenario。

### 3. 顯式無 scenario 對應 (僅限基礎建設 task)

```markdown
- [ ] 1.1 建立 admin-frontend repo 並 init Next.js 15 → verified by: 無 (理由: 純 repo 初始化, 無 scenario 對應)
```

限定場合: repo init、CI 設定、依賴安裝等**不直接實作任何使用者行為**的工作。
理由 MUST 寫, 不接受空白。

如果你發現太多 task 都是「無 (理由: ...)」, 那是 spec 寫得不夠細, 不是 task 多。

## 獨立性: 每個 task 可單獨拉出來做

判斷 task 是否獨立的測試:

> 如果只把這一個 task 交給一位不知道全貌的開發者, 他能完成嗎?

| 不獨立 (反例) | 獨立 (正解) |
|---|---|
| `4. 完成資料層` (含 4 個子工作但沒拆) | `4.1 安裝 react-query` / `4.2 設 QueryClient` / `4.3 寫 useApiQuery wrapper` |
| `6.1 完成使用者清單頁` (太大) | `6.1.a 設 route 與 layout` / `6.1.b 接 useQuery 取資料` / `6.1.c AntD Table 渲染` |

每個 task 應該在**一個 session 內 (約 30-90 分鐘)** 能完成。超過就拆。

## 順序與依賴

如果 task 4.3 必須在 task 4.2 之後做, 排序時把 4.2 寫在前面即可,
不需要寫 `(depends on 4.2)` — checkbox 順序就是依賴順序。

跨組依賴 (例如 task 6.1 依賴整個 §2 BFF 完成) 在組標題或 README 註明,
不在每個 task 內重複。

## Anti-patterns

### ❌ 模糊動作

```markdown
- [ ] 5.1 改善權限系統
```
**問題**: 「改善」沒終點。改寫成具體動作: `- [ ] 5.1 撰寫 usePermission(key) hook 從 RTK store 讀 manifest`。

### ❌ 主觀完成判定

```markdown
- [ ] 6.2 確保表單體驗良好 → verified by: scenario "..."
```
**問題**: 「體驗良好」不可驗證。換成具體行為: `- [ ] 6.2 表單失敗時保留欄位值並顯示 AntD notification`。

### ❌ 沒有 verified-by

```markdown
- [ ] 3.2 建立共用 AdminLayout
```
**問題**: CI grep 會擋。補上 `→ verified by: ...`。

### ❌ verified-by 對應到不存在的 scenario

```markdown
- [ ] 7.1 寫架構文件 → verified by: scenario "文件齊全"
```
**問題**: spec.md 裡沒有這條 scenario。改寫: `→ verified by: 無 (理由: 內部文件, 無使用者可觀察行為)`。

### ❌ 把多個 scenario 塞一個 task

```markdown
- [ ] 4.1 完成資料層 → verified by: scenario "列表頁讀資料" + scenario "[異常] API 回 5xx"
```
**問題**: 該拆兩個 task。每個 task 一個 scenario, 利於 PR 拆分與回滾。

## 檢查清單 (送 tasks.md PR 前自查)

- [ ] 每個 task 是 `- [ ]` checkbox 格式
- [ ] 每個 task 含 `→ verified by:` 標記
- [ ] verified-by 對應到 spec.md 真實存在的 scenario, 或顯式 `無 (理由: ...)`
- [ ] 沒有「改善 / 優化 / 確保 / 處理好」這類無終點動作
- [ ] 沒有「完成 X 模組」這種未拆解的大顆 task
- [ ] 估計每個 task 30-90 分鐘可完成
- [ ] CI 的 task verify-by 檢查通過

## 進一步閱讀

- Spec 寫作 (對應的 scenario 從哪來): [`spec-writing.md`](spec-writing.md)
- 完整範例: [`../examples/select-admin-frontend-stack/tasks.md`](../examples/select-admin-frontend-stack/tasks.md)
