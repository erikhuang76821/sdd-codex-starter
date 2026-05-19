# Decision Writing — design.md 的分層描述格式

這份文件補充 [`../AGENTS.md`](../AGENTS.md) 第 3.5 節, 規範 `design.md` 內每個 `### D<n>.` Decision 的 output 結構, 目的是讓**企劃 / PM / 跨職能 reviewer** 都能讀懂選項背後的取捨, 而不只是工程一人的決策黑盒。

## 為什麼需要這份規範

`design.md` 表面是工程文件, 但 SDD 流程裡企劃會在下列場合接觸到它:

- review Open Questions / Risks / Migration Plan 時, 需要先理解 Decisions 的取捨
- 跟業務窗口溝通「這個選擇對 launch 時程 / 招募 / 維運成本的影響」時, 需要從 Decisions 直接拿話術
- audit 一個技術選擇是否考慮過業務代價時, 需要明確的「為何不選」業務理由

**現況反模式** (改進前的 D1):

```markdown
### D1. 主框架: Next.js (App Router)

- 選擇理由: SSR 成熟、TypeScript 一等公民、React 生態與人才池最廣, 適合企業後台長期維護。
- 不選 Nuxt: 團隊需轉 Vue, React UI 元件與人才較不利。
- 不選 Remix / SvelteKit: 企業後台生態較窄、5 年維護風險高。
```

企劃看到「SSR / TypeScript / React / Vue」就出戲 — 等於整段 D1 對非工程角色是空白。

## 4 個 marker 規範

每個 `### D<n>.` Decision 區段內 MUST 依序出現下列 marker。前 3 個強制, 第 4 個可選 (推薦但不強制)。

### Marker 1: `**一句話**:` (強制, 一行)

給非技術讀者一句話複述: 「我們挑了什麼, 對誰好, 5 年後不會變垃圾」。
這句話 MUST 不含工程 jargon (框架名、協議縮寫、CS 概念), 用比喻或可觀察的事物描述。

### Marker 2: `**對使用者 / 企劃看得見的影響**:` (強制, 條列)

量化優先, 給 3-5 個 bullet。每條描述「使用者 / 同事 / 業務窗口可以直接量出來的差異」。

合格範例:
- 頁面載入: 預期比舊後台快 30-50% (首屏 + 切頁)
- 找新人接手: 招募市場上會這套的人, 比另兩個候選多約 5-10 倍
- 5 年後的風險: 低 — 是全球後台主流, 不太可能淘汰

不合格範例 (太工程):
- ❌ 提升 React Hydration 效率
- ❌ 改善 TTI / FCP / CLS
- ❌ 減少 bundle size

### Marker 3: `**為何不選**:` (強制, 條列)

每個未被選的候選 1 條。MUST 至少**前半段用業務語言**, 工程理由可加在 `→` 之後當補充。

合格範例:
- Nuxt: 跟現有團隊技能不合, 等於要全組重學, 三個月後新人才能上手 → 開發進度延後
- Remix / SvelteKit: 概念新穎, 但寫後台的人少, 5 年後可能變孤兒專案 → 屆時無人可接

不合格範例 (純工程理由, 企劃看不懂):
- ❌ Nuxt: Vue ecosystem 不如 React 廣
- ❌ Remix: SSR strategy 太激進

### Marker 4: `**技術層理由 (給工程 review)**:` (可選, 條列)

純工程細節留證, 讓工程 reviewer 不必猜為什麼選這個。Marker 1-3 應該已含足夠決策資訊, 這段是 "show your work"。

範例:
- SSR 成熟、TypeScript 一等公民、React 生態與人才池最廣, 適合企業後台長期維護
- App Router 比 Pages Router 更貼合未來 Server Component 方向

## 完整範例

```markdown
### D1. 主框架: Next.js (App Router)

**一句話**: 我們挑了一套大家都在用的後台「主結構」, 換人接手或找新人補位都比較好找, 5 年後也還有人在用、不會變成沒人維護的孤兒。

**對使用者 / 企劃看得見的影響**:
- 頁面載入: 預期比舊後台快 30-50% (首屏 + 切頁)
- 找新人接手: 招募市場上會這套的人, 比另外兩個候選多約 5-10 倍
- 5 年後的風險: 低 — 是全球後台主流, 不太可能淘汰

**為何不選**:
- Nuxt: 跟現有團隊技能不合, 等於要全組重學, 三個月後新人才能上手 → 開發進度延後
- Remix / SvelteKit: 概念新穎, 但寫後台的人少, 5 年後可能變孤兒專案 → 屆時無人可接

**技術層理由 (給工程 review)**:
- SSR 成熟、TypeScript 一等公民、React 生態與人才池最廣, 適合企業後台長期維護
```

## 反模式

### ❌ Marker 1「一句話」夾雜工程名詞

```markdown
**一句話**: 用 Next.js App Router + RSC 模式跑 SSR, 降低 hydration cost。
```

**問題**: 一句話的對象是企劃, 整句沒一個詞她聽得懂。
**改成**: 「挑了一套大家都在用的後台結構, 載入快、找人補位也好找。」

### ❌ Marker 2 影響只有「更快 / 更好 / 更穩」

```markdown
**對使用者 / 企劃看得見的影響**:
- 速度更快
- 體驗更好
- 維護更容易
```

**問題**: 沒量化, 沒對象, 無法跟其他選項比較。
**改成**: 加數字、加比較對象 (vs 舊後台 / vs 候選 B)、加角色 (使用者 / 同事 / 客戶)。

### ❌ Marker 3 不選理由純工程

```markdown
**為何不選**:
- Vue 3 的 reactivity model 對 SSR 不夠成熟
```

**問題**: 企劃讀不到「對業務的代價是什麼」。
**改成**: 在工程理由前先寫業務代價 (「等於要全組重學, 進度延 3 個月」), 工程細節用 `→` 接在後面。

### ❌ 把所有東西塞進「選擇理由」一條

```markdown
### D1. 主框架: Next.js
- 選擇理由: SSR 成熟、TS 強型別、React 生態, 不選 Vue / Svelte 因為...
```

**問題**: marker 結構崩了, CI 會 fail, 跨職能讀者只能掃過 essay。
**改成**: 拆成 4 個明確 marker, 每個 marker 對應一種讀者需求。

## 自查清單 (送 design.md PR 前)

- [ ] 每個 `### D<n>.` 區段都有 `**一句話**:` 開頭, 且該句不含工程 jargon
- [ ] 每個 D 都有 `**對使用者 / 企劃看得見的影響**:` 條列, 至少 3 條, 量化優先
- [ ] 每個 D 都有 `**為何不選**:` 條列, 每個未選候選 1 條, 業務語言在前
- [ ] (可選) `**技術層理由 (給工程 review)**:` 補上純工程細節
- [ ] `hooks/pre-commit` / CI grep 守 3-marker 數量 ≥ Decision 數量 — 本機跑過綠燈

## 跟其他規則的關係

| 規則 | 對 Decision 寫作的要求 |
|---|---|
| AGENTS §3.5 (本節) | 4-marker 結構 |
| AGENTS §3.2 + §8.2 (Codex 第二意見 + audit trail) | `## Decisions` 頂端必須有 `第二意見來源:` 一行, 在第一個 `### D<n>.` 之前 |
| docs/codex-handoff.md 模板 B | Codex 回應寫進 Decision 時, MUST 在每條 Decision 加「為何接受/不接受 codex 的建議」 |

## 為什麼用 4 個固定 marker, 不用自由格式

- 固定 marker → 機器層可 grep 守門 (見 AGENTS §10 第 8 條 grep)
- 固定順序 → 讀者掃描成本最低; 不會今天 Decision A 把「為何不選」寫前面、明天 D2 寫最後
- 固定 phrasing → 跨 change 的多份 design.md 風格一致, 跨團隊 review 不必每次重新 onboard
- 留 1 個可選 marker (技術層理由) → 工程仍有空間記細節, 但不會反客為主把企劃讀者擠出去
