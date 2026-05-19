# sdd-codex-starter

> 把 **Spec-Driven Development** 與 **AI 對抗性第二意見** 變成可重現的工作流, 拷到任何專案就能跑。

[![validate-openspec](https://github.com/erikhuang76821/sdd-codex-starter/actions/workflows/validate.yml/badge.svg)](https://github.com/erikhuang76821/sdd-codex-starter/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

不是 framework, 沒有腳手架腳本 — 一個 directory + 一份 `AGENTS.md`, AI 讀完自己照規矩走。

---

## 解決五件事

| 痛點 | 對策 |
|---|---|
| 一開工就寫 code, 等 demo 才發現方向錯 | OpenSpec 強制 `proposal → design → specs → tasks` |
| AI 寫 spec 格式不一、漏異常路徑 | EARS 對齊 + CI 強制每 Requirement 有 `[異常]` scenario |
| 提案論點 / 技術選型 / 規格完備性 靠單一 AI 視角 | Codex 三階段審查 (對抗性 + 第二意見 + 完備性), 跑在獨立 context, 各階段必留 audit trail |
| 企劃 / PM 讀不懂 design.md 的選型理由 → 失去跨職能 review | 每個 Decision 強制分層描述: **一句話 / 對使用者影響 / 為何不選 (業務語言) / 技術理由** |
| Task 太大顆、完成判定模糊 | 每項 task 對應到 scenario, 客觀驗收 |

## 工作流

```mermaid
flowchart LR
    Need([需求]) --> P[proposal.md<br/>Why + What<br/>+ Capabilities + Impact]
    P -. 預設要審 .-> Cxp[Codex 對抗性審查<br/>/codex:adversarial-review]
    Cxp -. audit trail .-> P
    P --> D[design.md<br/>Decisions]
    D -. 技術選型 .-> Cxd[Codex 第二意見<br/>/codex:review<br/>完整 proposal + 已決 Decisions]
    Cxd -. audit trail .-> D
    D --> S[spec.md<br/>EARS + 異常路徑<br/>approved-by:]
    S -. 預設要審 .-> Cxs[Codex 完備性審查<br/>/codex:review<br/>完整 spec + design Decisions]
    Cxs -. audit trail .-> S
    S --> T[tasks.md<br/>每項 verified by:]
    T --> Code([實作 + CI 守門])
```

每個箭頭都有機器層與規則層雙重守門:

| Gate | 機器層 | 規則層 |
|---|---|---|
| proposal → Codex | grep `對抗性審查來源:` | AGENTS §3.1 §8.1 |
| design → Codex | grep `第二意見來源:` | AGENTS §3.2 §8.2 |
| spec → Codex | grep `完備性審查來源:` | AGENTS §3.3 §8.3 |
| design output → 跨職能可讀 | grep 3 個分層描述 marker / Decision | AGENTS §3.5 |
| design → spec | `openspec validate --strict` | AGENTS §1 §2 |
| spec → tasks | grep `approved-by:` | AGENTS §7 |
| tasks → commit | grep `→ verified by:` | AGENTS §6 |
| commit → push | `hooks/pre-commit` + CI | AGENTS §9 |

## 安裝 & 跨機遷移

初次設置與「換電腦繼續用」是**同一套流程**。所有規則都在 repo 內, 沒有「藏在哪台機器」的隱藏依賴。

### Prereq (機器級, 一次性裝)

| 工具 | 用途 | 怎麼裝 |
|---|---|---|
| Node.js 20+ | 跑 OpenSpec CLI 與 Codex 插件 | 官網下載或 `nvm install 24` |
| OpenSpec CLI | SDD 工具本體 | `npm install -g @fission-ai/openspec` |
| Claude Code | 主要 AI agent (任何 OpenAI Codex CLI / Cursor / Aider 也可) | 從 Claude 官網裝 |
| ChatGPT 登入 (codex 用) | Codex 第二意見透過 OAuth, 不需 API key | Claude Code 內跑 `/codex:setup`, 開瀏覽器登入 |
| git | 必備 | 系統內建 |

### 步驟

```bash
# 1. 拷 starter (或 git clone 到新專案 root)
git clone https://github.com/erikhuang76821/sdd-codex-starter.git
cp -r sdd-codex-starter/. <your-project>/
cd <your-project>

# 2. 確認 OpenSpec CLI 在 PATH
openspec --version

# 3. (可選但建議) 啟用本機 pre-commit hook
ln -s ../../hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# 4. 驗證 starter 完整 — 應該 47/47 全綠
bash scripts/test.sh
```

`scripts/test.sh` 全綠 = **客觀的「規則齊全」證明**。任何 link 斷裂、章節缺漏、關鍵規則被改錯, 這份測試都會抓到。

### AI agent 怎麼讀規則

| Agent | 自動載入的檔名 | 行為 |
|---|---|---|
| Claude Code | [`CLAUDE.md`](CLAUDE.md) | 一進工作目錄自動讀 → 指向 AGENTS.md |
| Codex CLI / Aider | `AGENTS.md` | 通常主動掃 AGENTS 命名 |
| Cursor | `.cursorrules` / `.cursor/rules` (需自加 stub `→ 讀 AGENTS.md`) | 不會自動讀 AGENTS, 需要薄 stub |
| 其他 | — | 跟 AI 講一句「請讀 `AGENTS.md`」即可 |

### 規則的可攜性 (跨機要點)

| | 在 repo 內 | 跨機可攜 |
|---|---|---|
| SDD 流程、Codex 介入、EARS、Audit Trail、CI 守則 | ✅ AGENTS.md / docs/ / hooks/ / .github/ | ✅ `git clone` 就完整 |
| 47 條自驗測試 | ✅ scripts/test.sh | ✅ 跨機可驗 |
| 個人偏好 (Claude Code memory) | ❌ 本機 `~/.claude/.../memory/` | ⚠ 不會跟 repo 一起搬, 但**進 starter 內 memory 是冗餘的**, 因為規則已 lift 到 AGENTS.md |

意思是: **在 sdd-codex-starter 工作的情境, 完全不依賴本機 memory**。新電腦 clone repo + 裝 prereq 就齊全。

## 開工

直接跟 AI 講你要做什麼 — **不必先說「請走 SDD 流程」**, 也**不必下 `openspec` 指令**:

| 你說 | AI 自動做的事 |
|---|---|
| 「加一個用戶登入功能」 | `openspec new change add-user-login` → 寫 proposal → 進 design → 必要時叫 Codex → 寫 spec → 寫 tasks |
| 「選前端框架, 候選 Next.js / Nuxt / SvelteKit」 | 同上, design 階段自動叫 Codex 給對抗性第二意見 |
| 「重構訂單流程支援多幣別」 | 同上, 跨系統邊界自動觸發 Codex |
| 「製作貪食蛇」 | 即使是小遊戲也走 SDD ([AGENTS.md](AGENTS.md) §0「規則沒有例外」) |
| 「把按鈕顏色改成藍色」 | 跳過 SDD, 直接 patch (純樣式) |

觸發信號定義在 [`AGENTS.md`](AGENTS.md) §0; 你只負責 spec 階段加 `<!-- approved-by: -->` 與審 Codex 的第二意見內容。

## 結構

| 路徑 | 用途 |
|---|---|
| [`AGENTS.md`](AGENTS.md) | AI 必讀工作守則 (入口 + 11 節, 階段細節連到 docs) |
| [`docs/spec-writing.md`](docs/spec-writing.md) | EARS 5 pattern + 異常路徑強制 |
| [`docs/task-writing.md`](docs/task-writing.md) | 獨立可驗證 task 規則 |
| [`docs/codex-handoff.md`](docs/codex-handoff.md) | Codex 三階段介入觸發時機 + 完整 context 模板 (A/B/C) |
| [`docs/decision-writing.md`](docs/decision-writing.md) | design.md Decision 的 4-marker 分層描述格式 (跨職能可讀) |
| [`docs/output-formatting.md`](docs/output-formatting.md) | Codex 回覆視覺區塊格式 |
| [`docs/testing.md`](docs/testing.md) | 怎麼跑 starter 自驗 + 加新測試 |
| [`hooks/`](hooks/) | 本機 `pre-commit` + 安裝指南 |
| [`scripts/test.sh`](scripts/test.sh) | 63 條單元 + 整合測試 (本機 / CI 共用) |
| [`.github/workflows/validate.yml`](.github/workflows/validate.yml) | CI: strict validate + 7 個結構 grep + 跑 scripts/test.sh |
| [`examples/select-admin-frontend-stack/`](examples/select-admin-frontend-stack/) | 完整 reference change (strict validate 通過, D1-D4 含分層描述) |
| `openspec/changes/archive/`, `openspec/specs/` | 空骨架, `openspec` CLI 預期路徑 |

## 設計原則

- **最低底線** — 不含 npm/git 設定、CI/CD 模板、腳手架腳本; 加什麼自己加
- **規則 in code, 證據 in repo** — `AGENTS.md` 寫規則, `examples/` 留證據, `validate.yml` 守規則
- **Auto 模式安全** — 規則寫到不需人類在當下提醒; LLM 在 yolo / no-confirm 模式仍會 follow
- **自驗** — 63 條 unit + integration 測試 ([`scripts/test.sh`](scripts/test.sh)) 守規則文件本身不漂移 (連結、章節編號、關鍵字、hook 行為、bootstrap 流暢度)
- **零隱藏依賴** — 規則全在 repo 內, 無本機 memory / 帳號 secret / 雲端 API key 依賴; `git clone` 即完整
- **跨職能可讀** — design.md 不只給工程看, 每個 Decision 強制分層描述 (`**一句話** / **對使用者影響** / **為何不選** / 工程理由`), 讓 PM / 企劃也能參與 review
- **指令量約束** — 約 130 條硬性指令, 落在 LLM 穩定遵守的 ~200 條安全帶內

## License

MIT — 見 [LICENSE](LICENSE)
