# sdd-codex-starter

> 把 **Spec-Driven Development** 與 **AI 對抗性第二意見** 變成可重現的工作流, 拷到任何專案就能跑。

[![validate-openspec](https://github.com/erikhuang76821/sdd-codex-starter/actions/workflows/validate.yml/badge.svg)](https://github.com/erikhuang76821/sdd-codex-starter/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

不是 framework, 沒有腳手架腳本 — 一個 directory + 一份 `AGENTS.md`, AI 讀完自己照規矩走。

---

## 解決四件事

| 痛點 | 對策 |
|---|---|
| 一開工就寫 code, 等 demo 才發現方向錯 | OpenSpec 強制 `proposal → design → specs → tasks` |
| AI 寫 spec 格式不一、漏異常路徑 | EARS 對齊 + CI 強制每 Requirement 有 `[異常]` scenario |
| 技術選型靠單一 AI 視角 | Codex 對抗性第二意見, 跑在獨立 context, 必留 audit trail |
| Task 太大顆、完成判定模糊 | 每項 task 對應到 scenario, 客觀驗收 |

## 工作流

```mermaid
flowchart LR
    Need([需求]) --> P[proposal.md<br/>Why]
    P --> D[design.md<br/>Decisions]
    D -. 技術選型 .-> Cx[Codex 第二意見<br/>獨立 context<br/>完整 proposal + 已決 Decisions]
    Cx -. audit trail .-> D
    D --> S[spec.md<br/>EARS + 異常路徑<br/>approved-by:]
    S --> T[tasks.md<br/>每項 verified by:]
    T --> Code([實作 + CI 守門])
```

每個箭頭都有機器層與規則層雙重守門:

| Gate | 機器層 | 規則層 |
|---|---|---|
| design → Codex | grep `第二意見來源:` | AGENTS §3 §8 |
| design → spec | `openspec validate --strict` | AGENTS §1 §2 |
| spec → tasks | grep `approved-by:` | AGENTS §7 |
| tasks → commit | grep `→ verified by:` | AGENTS §6 |
| commit → push | `hooks/pre-commit` + CI | AGENTS §9 |

## 上手 (3 分鐘)

```bash
# 1. 拷到新專案
git clone https://github.com/erikhuang76821/sdd-codex-starter.git
cp -r sdd-codex-starter/. <your-project>/
cd <your-project>

# 2. 裝 OpenSpec CLI
npm install -g @fission-ai/openspec

# 3. (可選) 啟用本機 pre-commit hook
ln -s ../../hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

### 開工

直接跟 AI 講你要做什麼 — **不必先說「請走 SDD 流程」**, 也**不必下 `openspec` 指令**:

| 你說 | AI 自動做的事 |
|---|---|
| 「加一個用戶登入功能」 | `openspec new change add-user-login` → 寫 proposal → 進 design → 必要時叫 Codex → 寫 spec → 寫 tasks |
| 「選前端框架, 候選 Next.js / Nuxt / SvelteKit」 | 同上, design 階段自動叫 Codex 給對抗性第二意見 |
| 「重構訂單流程支援多幣別」 | 同上, 跨系統邊界自動觸發 Codex |
| 「把按鈕顏色改成藍色」 | 跳過 SDD, 直接 patch (純樣式) |

觸發信號定義在 [`AGENTS.md`](AGENTS.md) §0; AI 進到 repo 後讀 AGENTS.md 自動執行,
你只負責 spec 階段加 `<!-- approved-by: -->` 與審 Codex 的第二意見內容。

### Claude Code 的自動載入

Claude Code 進到工作目錄會**自動讀 `CLAUDE.md`**(不會自動讀 `AGENTS.md`)。
本 starter 內 [`CLAUDE.md`](CLAUDE.md) 是 35 行的薄重定向, 內容是「→ 讀 AGENTS.md」+ 觸發條件精簡版 + toy/demo 不可降級提醒, 確保 Claude Code 用戶不必手動 prompt「請讀 AGENTS.md」也能正確啟動 SDD。

其他 AI agent (Cursor / Aider / Continue 等) 用各自慣例:
- Cursor → `.cursor/rules` 或 `.cursorrules` (可自行加上 `→ 讀 AGENTS.md` 的 stub)
- Codex CLI / Aider → 通常會主動掃 `AGENTS.md`

## 結構

| 路徑 | 用途 |
|---|---|
| [`AGENTS.md`](AGENTS.md) | AI 必讀工作守則 (入口 + 11 節, 階段細節連到 docs) |
| [`docs/spec-writing.md`](docs/spec-writing.md) | EARS 5 pattern + 異常路徑強制 |
| [`docs/task-writing.md`](docs/task-writing.md) | 獨立可驗證 task 規則 |
| [`docs/codex-handoff.md`](docs/codex-handoff.md) | Codex 觸發時機 + 完整 context 模板 |
| [`docs/output-formatting.md`](docs/output-formatting.md) | Codex 回覆視覺區塊格式 |
| [`docs/testing.md`](docs/testing.md) | 怎麼跑 starter 自驗 + 加新測試 |
| [`hooks/`](hooks/) | 本機 `pre-commit` + 安裝指南 |
| [`scripts/test.sh`](scripts/test.sh) | 46 條單元 + 整合測試 (本機 / CI 共用) |
| [`.github/workflows/validate.yml`](.github/workflows/validate.yml) | CI: strict validate + 4 個結構 grep + 跑 scripts/test.sh |
| [`examples/select-admin-frontend-stack/`](examples/select-admin-frontend-stack/) | 完整 reference change (strict validate 通過) |
| `openspec/changes/archive/`, `openspec/specs/` | 空骨架, `openspec` CLI 預期路徑 |

## 設計原則

- **最低底線** — 不含 npm/git 設定、CI/CD 模板、腳手架腳本; 加什麼自己加
- **規則 in code, 證據 in repo** — `AGENTS.md` 寫規則, `examples/` 留證據, `validate.yml` 守規則
- **Auto 模式安全** — 規則寫到不需人類在當下提醒; LLM 在 yolo 模式仍會 follow
- **指令量約束** — 約 108 條硬性指令, 落在 LLM 穩定遵守的 ~200 條安全帶內

## License

MIT — 見 [LICENSE](LICENSE)
