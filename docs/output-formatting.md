# Output Formatting — Codex 回覆的視覺呈現

這份文件補充 [`../AGENTS.md`](../AGENTS.md) 第 4 節。

## 規則

呈現 Codex (或任何「外部第二意見來源」) 的回覆給使用者時:

1. 上下各一條 `---` 水平線
2. 整段內容用 `>` blockquote 包起來 → 終端機/Markdown 渲染左側出現 vertical bar
3. blockquote 第一行: `╭─ ▼ Codex 回覆 ▼ ──────────────────────────────`
4. blockquote 最後一行: `╰─ ▲ Codex 回覆結束 ▲ ──────────────────────────`
5. AI 自己的補充/評論寫在 blockquote 之外

## 範例

```markdown
我問 codex 對前端框架的第二意見, 結果如下:

---

> ╭─ ▼ Codex 回覆 ▼ ──────────────────────────────
>
> ## 第二意見：前端技術棧選型
>
> ### 推薦主框架
>
> - 推薦: **Next.js** — 最適合 SSR、TypeScript、React 生態與企業後台長期維護。
> - 不選 Nuxt: 團隊需轉 Vue；React UI 與人才池較不利。
> - 不選 Remix / SvelteKit: 企業後台生態較窄；5 年維護風險較高。
>
> ### UI / 狀態 / 資料層
>
> - **UI: Ant Design**
> - **狀態管理: Redux Toolkit**
> - **資料層: TanStack Query**
>
> ### 最大踩雷風險 + Mitigation
>
> 1. SSR 與 PHP session/SSO 邊界混亂 → BFF 層統一 cookie/CSRF/token
> 2. 前後端權限邏輯重複分歧 → 後端權威, 前端讀 manifest
>
> ╰─ ▲ Codex 回覆結束 ▲ ──────────────────────────

---

我的看法: Next.js + AntD 同意, 但 RTK 對這個專案太重, 建議改 Zustand。
```

## 為什麼這樣設計

| 訊號 | 用途 |
|---|---|
| 上下 `---` 水平線 | 切出明確區段邊界 |
| `>` blockquote | 終端機左側 vertical bar, 一眼看出「這不是 AI 主敘述」 |
| `╭─ ▼ / ╰─ ▲` 邊界文字 | 即使在不支援 blockquote 樣式的渲染器也能讀出邊界 |
| 區塊外的補充 | 讓使用者看到「AI 對 codex 建議的判斷」, 而不是照抄 |

三重訊號是冗餘設計, 為了相容不同 Markdown 渲染器 (CLI / web / 純文字 log)。

## 不要這樣做

- ❌ 用 \`\`\`code fence\`\`\` 包整段 → 內部的 markdown 結構會失效, 列表/標題渲染不出來
- ❌ 只用水平線, 不加 blockquote → 上下分隔但中間和 AI 文字字型相同, 仍會看混
- ❌ 把 codex 內容拆段, 中間插自己的話 → 失去「這整段是 codex 講的」原樣性
- ❌ 改寫 codex 用字遣詞 → 失去第二意見的原始證據價值

## 寫進檔案的場合 (例如 design.md)

寫進 `.md` 檔案時 **不需要** blockquote + 邊界文字 — 改用 Decisions 區頂端註明來源:

```markdown
## Decisions

第二意見來源: codex (codex:rescue, 2026-05-19), 內容已納入下列 Decisions。

### D1. 主框架: Next.js
- 選擇理由: ...
- Codex 第二意見: 同意, 因為 ...
- 不選 Nuxt: ...
```

對話視窗呈現 vs. 寫進規格檔, 是兩個用途, 兩種格式都對。
