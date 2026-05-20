# add-user-login

純新功能範例: 為後台新增「使用者登入 + session 管理」capability。

**示範什麼**:

- 4 階段全跑 (proposal → design → spec → tasks)
- 全部 3 個 Codex audit 都實際諮詢 (proposal 對抗性審查 / design 第二意見 / spec 完備性審查)
- 只有 `## ADDED Requirements`, 沒有 MODIFIED — 因為這是全新 capability
- spec 含正常 + 異常 4 類路徑 (auth-permission / upstream / missing-data / degradation) 完整覆蓋

對照 [`../select-admin-frontend-stack/`](../select-admin-frontend-stack/) (技術選型) vs 本範例 (新功能) — 兩種觸發類型, 同套 SDD 紀律。
