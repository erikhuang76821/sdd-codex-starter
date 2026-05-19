# Codex Handoff — 何時呼叫、怎麼呼叫、怎麼用回來的內容

這份文件補充 [`../AGENTS.md`](../AGENTS.md) 第 3 節 (觸發時機) 與 第 8 節 (audit trail)。

## 三種 Codex 介入角色

Codex 在 SDD 流程中扮演**三種不同角色**, 對應三個階段 — prompt 角度、context 內容、留證欄位都不同, 但走的是同一條技術路徑 (本機 `codex:rescue` subagent + `--fresh`)。

| 階段 | 角色 | 工作流標籤 | 對應留證欄位 |
|---|---|---|---|
| proposal | 對抗性審查員 — 壓力測試論點 | `/codex:adversarial-review proposal.md` | `對抗性審查來源:` |
| design | 技術第二意見 — 對抗性檢查決策 | `/codex:review design.md` | `第二意見來源:` |
| spec | 完備性審查員 — 找漏掉的情境 | `/codex:review spec.md` | `完備性審查來源:` |

「工作流標籤」是給人類溝通用的稱呼, **底下都是同一個 codex:rescue 呼叫**, 差別只在 prompt 的角色定位與 context 內容。

## 觸發時機 (必呼叫)

### proposal 階段 — 預設要審

寫完 proposal.md (Why + What + Capabilities + Impact) 後, **不問**「要不要對抗性審查」, 直接走。例外 (允許跳過但 audit trail 必須具體記理由): 純 bugfix / 純 rename 衍生的 spec 改動, 沒有方向性決定。

### design 階段 — 進到 Decisions 區段時若符合下列任一條件

1. **技術選型**: 「選了難回頭」的決定 (主框架 / DB / runtime / 雲廠商 / 通訊協定)
2. **跨系統邊界**: BFF / SSO / 權限 / 微服務拆分 等「畫錯線就重寫」的設計
3. **效能/安全 trade-off**: 本地無法跑 benchmark 或 threat model 驗證
4. **使用者明示**: 「get a second opinion」「let codex check」「找 codex 確認」

不需要呼叫: bugfix / rename / 純文件 / 純樣式 / refactor。

### spec 階段 — 預設要審

spec.md 寫完且 `openspec validate --strict` 通過後, 在請人類 approver 前, **不問**「要不要完備性審查」, 直接走。Codex 在此扮演「找漏」角色, 對抗 happy-path bias 與 error scenario 走形式的傾向。例外 (允許跳過但 audit trail 必須具體記理由): 純文件 spec、純 rename, 沒有新行為。

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

## 諮詢路徑限制 (硬性)

Codex 諮詢 MUST 限定在「本機 AI 工具 + 使用者已 auth 的 ChatGPT OAuth session」這條路徑。

**禁止做法:**

- ❌ 在 GitHub Actions / 任何雲端 CI 加 step 直接呼叫 Anthropic / OpenAI API 模擬 Codex
- ❌ 要求使用者設定 `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` 等 secret
- ❌ 任何「定期 LLM regression test」用 API token 計費的設計

**為什麼:**

使用者通常已用 ChatGPT 訂閱付費, 本機 Codex 呼叫不需額外帳單。API key 是不同
billing model + 多了 secret rotation surface, 對個人 / 小團隊專案無 ROI。
規則退化偵測應該用 deterministic grep against 規則文件本身, 不打 LLM API。

## 呼叫前置 (CLI 視覺結構)

呼叫 codex 之前, MUST 在 AI 自己的文字輸出**單獨一行**:

```
呼叫 codex 輔助分析中...
```

(或等價語句, 例如「Codex 第二意見諮詢中...」「叫 codex 給對抗性意見...」)

目的: 讓使用者在 CLI 上看到接下來的 tool call 時, 立刻知道是 codex 諮詢,
不是其他工具呼叫。**這條規則對任何 AI agent 環境通用**。

### Claude Code 環境特定

在 Claude Code + `codex:codex-rescue` subagent 環境下, 另外:

- **不要先跑** `codex-companion.mjs task-resume-candidate --json` helper
  (該 helper 對 fresh session 永遠回 `available: false`, 對使用者是純 CLI 干擾)
- **不要用 AskUserQuestion 問** "Continue current thread / Start new thread"
  (codex skill 預設行為, 但每次都要選新 thread 很煩)
- 直接呼叫 `Agent(subagent_type="codex:codex-rescue", prompt="...")`,
  並在 prompt 開頭加 `--fresh` token

codex skill instruction 明文支援這個繞過: 「If the request includes `--fresh`,
do not ask whether to continue.」

### 例外: 延續性意圖

若使用者明確說「接續上次 codex 討論」「resume codex thread」「continue codex」,
改帶 `--resume` 而非 `--fresh`。此時保留 helper 與詢問流程 (codex skill 預設行為),
因為 user 需要選擇要 resume 哪個 thread。

## 完整 Context 傳遞 (硬性要求)

無論哪個階段, **prompt MUST 包含對應階段所需的完整 context**, 一段都不能省。三個階段的 context 組成不同:

| 階段 | Context 段 |
|---|---|
| proposal 對抗性審查 | proposal.md 全文 + 當前壓力測試焦點 |
| design 第二意見 | proposal.md 全文 + 已決 Decisions 全文 + 當前題目 |
| spec 完備性審查 | spec.md 全文 + 對應 design Decisions 全文 + 完備性檢查清單 |

### 不可改寫、不可摘要

不論哪段, 來自 `openspec/changes/<id>/*.md` 的內容 MUST 原文複製貼上, **不要改寫、不要摘要**。摘要會讓 codex 在資訊不對等下作答, 失去第二意見價值。

### 為何 design 段 codex 必須看到已決 Decisions

例: 若主框架已選 Next.js, 現在要問 UI 元件庫, codex 必須看到主框架是 Next.js, 否則它可能推薦只與 Vue 配合的 UI 庫。

### 為何 spec 段 codex 必須看到 Decisions

design 已決的技術選型 (例如「狀態管理 = Redux Toolkit」「BFF 層由 Next.js Route Handlers 承載」) 會限制 spec scenario 的合理形狀。codex 沒看到這些, 可能要求一些已被 design 排除的情境覆蓋, 浪費 review 火力。

## Prompt 模板

### 模板 A — proposal 對抗性審查 (`/codex:adversarial-review proposal.md`)

```
你是 SDD 提案的對抗性審查員。下面是完整 proposal, 讀完後給壓力測試意見。

## Context: 完整 proposal

<從 openspec/changes/<id>/proposal.md 全文貼進來, 不省略>

## 審查焦點

請對以下四面向各給 1-2 條對抗性意見 (找弱點, 不是肯定):

1. **Why 是否站得住腳** — 痛點是否被誇大? 是否還有更便宜的非工程解法 (流程 / 教育訓練 / 既有工具)?
2. **What Changes 是否抓對範圍** — 是否漏了關鍵變動? 是否塞了不必要的範圍?
3. **Capabilities 切分是否合理** — 新 capability vs modified capability 邊界對嗎? 是否有重複或漏項?
4. **Impact / 風險評估是否誠實** — 最大的兩個被低估的風險是什麼? Mitigation 是否實際可行?

體裁: 條列, 每點一句結論 + 一句理由, 不寫 essay, 全段不超過 250 字。
這份審查會直接寫進對應 proposal.md 的 audit trail, 並可能觸發 proposal 內容修訂。
```

### 模板 B — design 技術第二意見 (`/codex:review design.md`)

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

### 模板 C — spec 完備性審查 (`/codex:review spec.md`)

```
你是 SDD spec 的完備性審查員。下面是完整 spec 與相關 design Decisions,
讀完後檢查 Requirements 與 scenario 是否完備。

## Context: 完整 spec

<從 openspec/changes/<id>/specs/<capability>/spec.md 全文貼進來, 不省略>

## Context: 對應 design Decisions

<從 openspec/changes/<id>/design.md 的 ## Decisions 區全文貼進來,
 讓 codex 看見已決技術選型的約束>

## 完備性檢查清單

請逐條檢查並列出**找到的漏洞**, 沒漏洞的條目直接跳過, 不要寫「OK」:

1. **每個 Requirement 是否至少 1 happy + 1 `[異常]` scenario?**
2. **異常路徑是否覆蓋 4 類 (上游失敗 / 認證權限 / 資料缺失 / 重試耗盡降級)?**
   挑出只覆蓋一類交差的 Requirement。
3. **error scenario 是否寫「對使用者的可觀察影響」?**
   挑出只寫「系統 log 錯誤」「記錄事件」這類內部行為的條目。
4. **是否漏寫使用者實際會撞到但 happy path 想不到的情境?**
   例: race condition / 超時 / 部分成功 / 跨 tab 競爭 / 退回上一步狀態回填 等。
5. **是否有 scenario 用 WHEN 描述異常觸發 (應該用 IF)?**

體裁: 條列, 每點一句說「哪個 Requirement / Scenario 漏了什麼」, 不寫 essay, 全段不超過 300 字。
這份審查會直接寫進對應 spec.md 的 audit trail, 並 MUST 觸發 spec 內容修訂 (不只記 audit, spec 內容也要補)。
```

## 收到回覆後的處理

### 通用步驟

1. **呈現給使用者時**用 [`output-formatting.md`](output-formatting.md) 的視覺區塊
2. **不要照抄**, 要記下「為何接受/不接受 codex 的建議」
3. **衝突時**: codex 與你的判斷不同, 明確記下兩方理由與最終選擇, 不要默默忽略

### 階段別寫進檔案

| 階段 | 寫進哪份檔 | Audit trail 格式 |
|---|---|---|
| proposal | `proposal.md` 頂端 HTML 註解 | `<!-- 對抗性審查來源: codex (adversarial-review, YYYY-MM-DD, 已傳遞: 完整 proposal) -->` |
| design | `design.md` 的 `## Decisions` 區頂端 | `第二意見來源: codex (codex:rescue, YYYY-MM-DD, 已傳遞: proposal + Decisions <範圍>)` |
| spec | `spec.md` 頂端 HTML 註解 (與 approved-by 同處檔案開頭) | `<!-- 完備性審查來源: codex (review, YYYY-MM-DD, 已傳遞: spec + design Decisions) -->` |

### spec 完備性審查的特殊要求

完備性審查若指出漏洞, **MUST 修 spec 內容** (補 scenario), 不只記在 audit trail。
若決定不採 codex 某條建議, MUST 在 spec.md 末尾或 design.md Open Questions 內寫「Codex 建議補 X, 不採, 因為 ...」。
完備性審查不是「跑個流程留證」, 是「找漏 → 補漏」的閉環。

## Codex 不可用時 (Fallback SOP)

當 codex:rescue subagent 回覆失敗訊息或拋錯時, 不得當作「使用者沒設定 codex」
就跳過諮詢。MUST 停止 design 流程, 直到使用者修好。

### 自我診斷工具

讓使用者跑下面這個指令拿結構化狀態, 立刻定位問題:

```bash
node "$HOME/.claude/plugins/cache/openai-codex/codex/<version>/scripts/codex-companion.mjs" setup --json
# Windows: C:\Users\<user>\.claude\plugins\cache\openai-codex\codex\<version>\scripts\codex-companion.mjs
```

或在 Claude Code 內直接跑 `/codex:setup` slash command (等價包裝)。

#### Happy path 範例

```json
{
  "ready": true,
  "node":  { "available": true, "detail": "v24.x.x" },
  "npm":   { "available": true, "detail": "11.x.x" },
  "codex": { "available": true, "detail": "codex-cli 0.130.x; advanced runtime available" },
  "auth":  { "available": true, "loggedIn": true, "detail": "ChatGPT login active for <email>" }
}
```

`ready` = `node.available && codex.available && auth.loggedIn` 的 AND。
**只要 `ready: false`, 看哪一段是 false 就知道修哪裡**:

- `node.available: false` → 沒裝 Node.js
- `codex.available: false` → 沒裝 codex CLI 或 advanced runtime 不可用 (見下一節 keyword `is not installed`)
- `auth.loggedIn: false` → ChatGPT 沒登入或過期 (見下一節 keyword `not authenticated` / `requires OpenAI authentication`)

### 失敗訊號分兩層

#### Setup 層 (codex-companion 自身狀態)

訊號出處: `setup --json` 的 `auth.detail` / `codex.detail` 欄位, 或 task 命令拋的 Error.message。
**訊息是 codex-companion 主動寫的, keyword 固定**:

| 真實訊息片段 (源碼) | 原因 | 修復路徑 |
|---|---|---|
| `"not authenticated"` (auth.detail default) | 從未登入或登入狀態被清掉 | `/codex:setup` (重新登入 ChatGPT) |
| `"requires OpenAI authentication"` (auth.detail) | provider 需 OAuth 但未登入 / token 過期 | `/codex:setup` (重新登入 ChatGPT) |
| `"Codex CLI is not installed or is missing required runtime support"` | codex CLI 沒裝或 advanced runtime 不可用 | `npm install -g @openai/codex` 然後 `/codex:setup` |
| `"advanced runtime unavailable: <reason>"` (codex.detail) | codex CLI 在但 app-server 跑不起來 | 同上, 或檢查 reason 訊息 |
| `error.message` 含 `ENOENT` / `ECONNREFUSED` | 找不到執行檔 / 連不上 codex broker | 重啟 codex / 檢查環境 |

#### Task 層 (codex 呼叫 OpenAI API 的失敗)

訊號出處: codex 把 prompt 送到 OpenAI 之後 API 回的錯誤。
**訊息來自 OpenAI API, keyword 不固定**, 常見可能模式 (推測, 視 API 回應):

| 可能訊號 | 原因 | 修復路徑 |
|---|---|---|
| `rate limit` / `429` / `too many requests` | 用量上限 | 等候或升級訂閱 |
| `subscription` / `quota exceeded` / `not entitled` | 訂閱問題或月度配額用完 | 重新訂閱 / 等月底 |
| `network` / `timeout` / `ECONNRESET` | 網路不穩 | 檢查網路重試 |

由於 task 層訊息**不是 codex-companion 寫的**, 不要硬比對 keyword。
原則: **原文引述給使用者, 並提示「這看起來像 task 層 API 問題, 跑 setup --json 確認 codex 自身仍 ready, 然後重試」**。

### SOP

1. **STOP** — design.md 不得繼續寫 Decisions, 不得進 spec 階段
2. **引述完整 subagent 回覆** 給使用者, 用 [`output-formatting.md`](output-formatting.md) 的視覺區塊呈現
3. **分類失敗** — 訊息含「自我診斷工具」範例的 setup 層 keyword? 還是 task 層 (rate limit / network)?
4. **指明修復路徑** — 對應失敗訊號表; 不確定時請使用者跑 `setup --json` 自我診斷
5. **等使用者回覆「修好了」/「重試」**, 才重新呼叫 codex
6. 若使用者選擇放棄諮詢 (例如 ChatGPT 訂閱取消), MUST 在 design.md audit trail 寫:
   ```
   第二意見來源: 無 (理由: Codex 不可用 — <一句具體原因>, 使用者選擇繼續)
   ```
   - 不接受 `無 (理由: Codex 失敗)` 這種模糊寫法 — 必須寫具體原因 (auth 過期 / 訂閱取消 / 網路 / 等)

### 禁止行為

- ❌ **跳過 codex 自己決定** — 即使任務急, 也要先 stop 與使用者溝通; 不可悄悄繼續寫 Decisions
- ❌ **「使用者沒設定 codex 那就跳過吧」** — 設定問題是 fixable, 不是不可用; SOP 是「stop + 指引修復」, 不是「降級流程」
- ❌ **重試 N 次 (`>3`) 後直接繼續** — 重試耗盡仍 stop, 不是 fallback to skip
- ❌ **改寫 codex 失敗訊息** — MUST 原文引述, 讓使用者看到工具實際說了什麼, 才能對症處理
- ❌ **`第二意見來源: 無 (理由: Codex 失敗)`** — 模糊理由不合格, 須寫具體 (見上方 audit trail 範例)
- ❌ **看到任何錯誤就直接套「rate limit / 訂閱問題」** — task 層 keyword 不固定, 要原文引述, 不要替使用者揣測

## 反模式

- ❌ **只給摘要, 不貼完整 proposal / spec** → codex 在資訊不對等下作答; 回覆會附「在沙箱無法讀取」之類的免責, 喪失審查價值
- ❌ **省略已決定的 Decisions** → codex 可能推薦與既決選項不相容的方案 (例: 主框架選 Next.js 後問 UI, 不告知主框架 → 可能推薦 Vue-only 庫)
- ❌ **無焦點丟「review 一下」** → 拿不到 actionable 答案; 完整 context 必須配明確角色 (對抗性 / 第二意見 / 完備性) 與明確問題
- ❌ **Codex 回什麼就照抄** → 失去對抗性, 變成「換個模型寫單方意見」
- ❌ **proposal 階段把 prompt 寫成「請給技術建議」** → 角色錯; proposal 階段 codex 是審 proposal 自己, 不是審技術選型
- ❌ **spec 完備性審查只記 audit trail, 不補 spec** → 留證但不修, 是規避; 必須補完 scenario 後再進 approved-by
- ❌ **Bugfix / refactor / 純文件 也叫 codex 三次** → 浪費 token, 流程僵化; 例外場合用「無 (理由: ...)」走 audit trail

## Token 帳本

每次 Codex 諮詢對 Claude **主 context** 的成本:

| 段 | Token 估計 | 進主 context? |
|---|---|---|
| Claude 寫 prompt (完整 context 段) | ~500-1500 | ✅ Claude 的 assistant message |
| Codex subagent 內部讀 prompt + 思考 + 寫回覆 | ~3000-8000 | ❌ Subagent 隔離 budget |
| Codex 回覆作為 tool_result 返回 | ~300-800 | ✅ 進主 context |

**單次成本 ≈ 1000-2000 tokens 進主 context**。
**一個 change 三次呼叫 (proposal + design + spec) ≈ 3000-6000 tokens 進主 context**。

對不同 context 容量的比例:

| Context window | 單次比例 | 一個 change × 3 階段審查 + 4 Decisions |
|---|---|---|
| Opus 1M | < 0.2% | < 2% |
| Standard 200K | < 1% | < 5% |
| Standard 32K | 3-6% | 25-50% (吃緊) |

### 為什麼「完整 context」是對的權衡

對比「只給摘要」版本:

| 版本 | 單次成本 | 省下 | 代價 |
|---|---|---|---|
| 完整 context (現規則) | ~1000 | — | — |
| 只給摘要 | ~500 | ~500 | Codex 失去脈絡覺, 回覆附「資訊不足」免責 |

省 500 tokens 等於 1M context 的 0.05%。為這個換掉對抗性檢查 — 失衡。

### Subagent 內部 token 不計

Codex 自己讀 prompt、思考、寫回覆的 3-8K tokens 是 **subagent 隔離 context budget**,
跟主 context 無關。不要把 subagent 內部成本算進主 context 預算。

### 何時該動 token 優化

- ❌ 1M / 200K context: 不必動, 三階段審查累積成本 < 5%
- ⚠ 32K 小模型: 一個 change 累積到 25-50%, 這時候做 spec-driven 本身就吃緊;
  若必須優化, 應該換大 context model, 不是改規則 — 或在 proposal / spec 階段用「無 (理由: 具體說明)」escape hatch, 而不是改全套規則

## 為何 Auto 模式必須遵守

在 Claude Code auto / yolo / no-confirm 模式下, Claude 不會逐 prompt 與人類確認。
這時上面的「完整 context 傳遞」規則是唯一保險:

- 沒人在當下提醒「記得把 proposal 貼進去」「記得三階段都要呼叫」
- Claude 會依文件規則自動執行
- 規則若寫「給摘要」 → codex 永遠看不到全貌 → 審查永遠是半瞎
- 規則若寫「proposal / spec 階段預設要審」 → 即使沒人盯, 也不會跳過; CI grep 兜底攔走

所以本文件的硬性要求 + AGENTS §8 的 audit trail grep = auto 模式下唯一不會崩的閘門。
