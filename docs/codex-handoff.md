# Codex Handoff — 何時呼叫、怎麼呼叫、怎麼用回來的內容

這份文件補充 [`../AGENTS.md`](../AGENTS.md) 第 2 節。

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

其他 agent / 環境: 任何能拿到 GPT-5.x 等異質模型回覆的 channel 都可。
重點是「**不同模型的對抗性檢查**」, 不是工具品牌。

## Prompt 模板

不要丟整份 proposal/design 過去。Codex 拿不到本地檔案, 給它純文字摘要 + 明確的回答結構即可。

```
<change-id> 進入 design 階段, 需要對 <主題> 給出第二意見。

背景:
- 用途: <一兩句>
- 候選 A / B / C / D
- 已知約束: <既有系統 / 團隊技能 / 時程>
- 風險: <選錯的代價>

請以「<具體場景>」場景給出:
1. 推薦選項 + 兩個明確不選的理由
2. 配套子決策各推薦一個 (UI / 狀態 / 資料層 等)
3. 最大的兩個踩雷風險 + mitigation

回覆精簡、條列式即可, 不需要長篇 essay。
這個第二意見會直接寫進 openspec design.md 的 Decisions 區域。
```

重點:

- **明確場景** (「企業內部後台」「面向 C 端高流量」) — 否則回覆會泛泛而談
- **要 elimination 而不只是 ranking** — 「為何不選」比「為何選」更有資訊量
- **要 mitigation 配對風險** — 沒 mitigation 的風險清單沒用
- **限制體裁** (條列、不要 essay) — 否則 token 浪費且難取用

## 收到回覆後的處理

1. **呈現給使用者時**用 [`output-formatting.md`](output-formatting.md) 的視覺區塊
2. **寫進 design.md 時** 在 Decisions 區頂端加一行:
   ```
   第二意見來源: codex (codex:rescue, YYYY-MM-DD), 內容已納入下列 Decisions。
   ```
3. **不要照抄**, 要在每個 Decision 加上「為何接受/不接受 codex 的建議」
4. **衝突時**: codex 與你的判斷不同, 明確記下兩方理由與最終選擇, 不要默默忽略

## 反模式

- ❌ 把整份 proposal.md/design.md 丟給 codex 要它「review 一下」→ 太散, 拿不到 actionable 答案
- ❌ Codex 回什麼就照抄, 不留審判視角 → 那就只是換個模型寫單方意見, 沒對抗性
- ❌ 在 proposal 階段就叫 codex → 太早, 連問題定義都還沒收斂
- ❌ Bugfix / refactor 也叫 codex → 浪費 token, 流程僵化
