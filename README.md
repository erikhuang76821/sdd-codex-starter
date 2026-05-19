# sdd-codex-starter

[![validate-openspec](https://github.com/erikhuang76821/sdd-codex-starter/actions/workflows/validate.yml/badge.svg)](https://github.com/erikhuang76821/sdd-codex-starter/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

把 **Spec-Driven Development (OpenSpec)** 與 **Codex 第二意見介入** 兩件事
封裝成一份「拷到任何專案就能跑」的最低底線骨架。

不是 framework, 沒有腳手架腳本, 就是一個 directory + 一份 AGENTS.md。

## 它解決什麼

- 新功能/技術選型一開工就先寫 code, 等 demo 才發現方向錯了
- AI 寫 proposal/spec 時格式不一, 後續無法 validate 或 archive
- 技術選型靠單一視角決定 (你 + Claude / 你 + Codex), 缺少對抗性檢查
- Codex 輸出與 AI 自己的補充混在一起, 讀者分不清誰講的

## 把它放到新專案

```bash
# 1. 把整個 sdd-codex-starter/ 內容複製到目標專案 root
cp -r sdd-codex-starter/. <your-project>/

# 2. 確認 openspec CLI 裝好
npm i -g @fission-ai/openspec
openspec --version

# 3. 第一個 change
cd <your-project>
openspec new change <kebab-id> --description "<一句話>"
```

之後讓 AI 讀 `AGENTS.md` 走流程即可。

## 目錄結構

```
sdd-codex-starter/
├── README.md                          ← 你正在看的這份
├── AGENTS.md                          ← AI 必讀: 4 階段流程 + 何時叫 codex + 輸出格式
├── openspec/
│   ├── changes/
│   │   └── archive/                   ← archive 後的 change 落腳處
│   └── specs/                         ← 已 archive 進主規格的 capability
├── docs/
│   ├── spec-writing.md               ← EARS 對應、Scenario 模板、異常路徑要求
│   ├── codex-handoff.md              ← 呼叫 Codex 的 prompt 範本與時機
│   └── output-formatting.md          ← Codex 回覆視覺格式 (含範例)
└── examples/
    └── select-admin-frontend-stack/   ← 完整 reference change (validate --strict 通過)
```

## 最低底線承諾

這個 starter 故意小:

| 有 | 沒有 |
|---|---|
| openspec 目錄骨架 | npm/git 設定 |
| AI 工作守則 (AGENTS.md) | CI/CD 模板 |
| codex 介入 prompt 範本 | hook scripts |
| 一個 validate 過的 reference change | 自動腳手架腳本 |

加什麼自己加, 但這四件不要拿掉, 否則整個流程會破。

## 可選: Codex A/B regression test

`.github/workflows/codex-ab-test.yml` 提供一個手動觸發的工作流, 跑兩次同主題的第二意見諮詢:

- **Run A**: 只給摘要 (舊的、錯誤做法)
- **Run B**: 完整貼 proposal + 已決 Decisions (新規則)

跑完輸出對照表, 證明「完整 context」確實讓回覆更深入 (含 D1-aware 關鍵字、更長、不含資訊不足免責)。
作為**規則漂移的 regression guard** — 若哪天 docs 退化回「給摘要」, 這個 workflow 會持續抓到。

### 啟用步驟

1. 在 Anthropic console 取一把 API key
2. Repo Settings → Secrets and variables → Actions → New secret:
   - Name: `ANTHROPIC_API_KEY`
   - Value: `sk-ant-...`
3. 手動觸發:
   ```bash
   gh workflow run codex-ab-test.yml --repo <owner>/sdd-codex-starter
   gh run watch  # 看 step summary 對照表
   ```
4. 排程: 每週一 02:00 UTC 自動跑一次 (可在 yml 內改 cron)

### 不啟用也沒差

不設 secret, workflow 在啟動時就會 fail 並提示。不影響其他 workflow 與本機開發。
這個 workflow 是「diagnostic」性質, 不是上線必備。

## 進一步閱讀

- OpenSpec CLI: `openspec --help` / `openspec instructions <artifact> --change <id>`
- 工作守則: [`AGENTS.md`](AGENTS.md)
- Spec 寫作 (EARS 對應、異常路徑): [`docs/spec-writing.md`](docs/spec-writing.md)
- Codex 介入細節: [`docs/codex-handoff.md`](docs/codex-handoff.md)
- 輸出格式: [`docs/output-formatting.md`](docs/output-formatting.md)
- 真實範例: [`examples/select-admin-frontend-stack/`](examples/select-admin-frontend-stack/)
