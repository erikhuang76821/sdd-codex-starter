# Codex Handoff — 何時呼叫、怎麼呼叫、怎麼用回來的內容

這份文件補充 [`../AGENTS.md`](../AGENTS.md) 第 3 節 (觸發時機) 與 第 8 節 (audit trail)。

## 觸發時機 (必呼叫)

進入 `design.md` 的 `## Decisions` 區段時, 若符合下列任一條件:

1. **技術選型**: 「選了難回頭」的決定 (主框架 / DB / runtime / 雲廠商 / 通訊協定)
2. **跨系統邊界**: BFF / SSO / 權限 / 微服務拆分 等「畫錯線就重寫」的設計
3. **效能/安全 trade-off**: 本地無法跑 benchmark 或 threat model 驗證
4. **使用者明示**: 「get a second opinion」「let codex check」「找 codex 確認」

不需要呼叫: bugfix / rename / 純文件 / 純樣式 / refactor。

## 呼叫方式

Claude Code 環境下:

```
透過 codex:rescue skill 觸發, 或直接 Agent(subagent_type="codex:codex-rescue")
```

Codex 跑在**完全獨立的對話 context**, 沒有 Claude 主對話的歷史, 也讀不到本地檔案
(sandboxed)。這是 by design — 對抗性檢查的價值就在於 codex 不被 Claude 的判斷
路徑污染。

但這也意味著: **Claude MUST 主動把所有相關脈絡塞進 prompt**, 否則 codex 是在
資訊不對等下作答。

## 完整 Context 傳遞 (硬性要求)

呼叫 codex 時, prompt MUST 包含下列三段, 一段都不能省:

### 段 1: proposal.md 全文

直接從本地檔案複製貼上。**不要改寫、不要摘要**。

### 段 2: design.md 中已決定的 Decisions (若有)

若這不是 design 階段的第一個 Decision, MUST 把前面已 commit 的 Decision 標題與
理由完整貼進去, 讓 codex 知道:

- 已經決定了什麼 (限制了當前題目的解空間)
- 為什麼那樣決 (約束鏈條)

例: 若主框架已選 Next.js, 現在要問 UI 元件庫, codex 必須看到主框架是 Next.js,
否則它可能推薦只與 Vue 配合的 UI 庫。

### 段 3: 當前題目與限制體裁

- 明確問題 (要回答什麼)
- 明確場景 (企業內部後台 / C 端高流量 / 一次性活動)
- 明確結構要求 (推薦 + elimination + 風險 + mitigation)
- 明確體裁 (條列, 不要 essay)

## Prompt 模板

```
你是技術選型第二意見。下面是完整脈絡, 讀完後給對抗性意見。

## Context: 完整 proposal

<從 openspec/changes/<id>/proposal.md 全文貼進來, 不省略>

## Context: 已決定的 Decisions

<從 openspec/changes/<id>/design.md 的 ## Decisions 區貼進來,
 只貼當前題目以前已 commit 的 Decision; 若這是第一個 Decision, 寫「(本題為首個決策)」>

## 當前題目

我們要在這個 change 內決定 <主題>。候選: A / B / C / D。

請以「<場景一句話>」場景給出:

1. 推薦選項 + 兩個明確不選的 elimination
2. 配套子決策各推薦一個 (若有)
3. 最大的兩個踩雷風險 + mitigation

體裁: 條列, 不寫 essay, 不超過 200 字。
這個第二意見會直接寫進 openspec design.md 的 Decisions 區域。
```

## 收到回覆後的處理

1. **呈現給使用者時**用 [`output-formatting.md`](output-formatting.md) 的視覺區塊
2. **寫進 design.md 時** 在 Decisions 區頂端加一行 (AGENTS §8):
   ```
   第二意見來源: codex (codex:rescue, YYYY-MM-DD, 已傳遞: proposal + Decisions <範圍>)
   ```
   - `Decisions <範圍>` 是當時已 commit 的 Decision 編號 (例: `D1`), 或 `首個決策`
3. **不要照抄**, 要在每個 Decision 加上「為何接受/不接受 codex 的建議」
4. **衝突時**: codex 與你的判斷不同, 明確記下兩方理由與最終選擇, 不要默默忽略

## 反模式

- ❌ **只給摘要, 不貼完整 proposal** → codex 在資訊不對等下作答; 回覆會附「proposal 在沙箱無法讀取」之類的免責, 喪失第二意見價值
- ❌ **省略已決定的 Decisions** → codex 可能推薦與既決選項不相容的方案 (例: 主框架選 Next.js 後問 UI, 不告知主框架 → 可能推薦 Vue-only 庫)
- ❌ **無焦點丟「review 一下」** → 拿不到 actionable 答案; 完整 context 必須配明確問題
- ❌ **Codex 回什麼就照抄** → 失去對抗性, 變成「換個模型寫單方意見」
- ❌ **在 proposal 階段就叫 codex** → 太早, 連問題定義都還沒收斂
- ❌ **Bugfix / refactor 也叫 codex** → 浪費 token, 流程僵化

## 為何 Auto 模式必須遵守

在 Claude Code auto / yolo / no-confirm 模式下, Claude 不會逐 prompt 與人類確認。
這時上面的「完整 context 傳遞」規則是唯一保險:

- 沒人在當下提醒「記得把 proposal 貼進去」
- Claude 會依文件規則自動執行
- 規則若寫「給摘要」 → codex 永遠看不到全貌 → 第二意見永遠是半瞎
- 規則若寫「貼完整 proposal + Decisions」 → 即使沒人盯, codex 也拿得到應有的脈絡

所以本文件的硬性要求 = auto 模式下唯一不會崩的閘門。
