# Changelog

本檔案記錄 `sdd-codex-starter` 的版本變更。格式參考 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/), 版本號參考 [Semantic Versioning](https://semver.org/lang/zh-TW/).

語意對應:

- **MAJOR**: AGENTS.md 條款不向後相容 (例: 改變 audit trail 欄位名稱、移除 `對抗性審查來源:`)
- **MINOR**: 新增規則 / 新範例 / 新 helper, 既有 repo 拷新版**不會破現有 change**
- **PATCH**: 文件 / 排版 / 內部測試擴充, 不影響使用者可見的規則

---

## [0.1.0] — 2026-05-20

第一個 tagged release。Codex 對抗審查後落地的 starter 優化首批。

### Added

- `scripts/codex-prompt.sh` — 輔助腳本, 自動按 `docs/codex-handoff.md` 三模板組裝 prompt, 原文 inline proposal / design Decisions / spec, 印到 stdout。**僅輔助, 不繞 AGENTS §3.4 規則**, 不打 codex API。
- `examples/add-user-login/` — 純新功能範例 (全套 Codex audit 都跑 + 4 階段全)
- `examples/enable-2fa/` — MODIFIED Requirements 範例 (示範 AGENTS §1「整段 copy 原 Requirement 再改」規則)
- `examples/clarify-login-error-wording/` — 合法 audit-skip 範例 (示範 `無 (理由: <具體>)` 的正當寫法, 對照 hook 擋住的 `無 (理由: 不需要)` 等模糊寫法)
- `docs/testing.md` 「測試矩陣」章節 — fork-maintainer 入口, 列出 9 群組 + Unit 4 主題 / Int 2 hook 負向 / Unit 4b codex-prompt 組裝的明細
- `docs/codex-handoff.md` 「衝突解決啟發式」段 — 6 類 (安全 / 漏 scenario / 選型 trade-off / 美學 / 規格不清 / scope) 的處理啟發式, 明示「非 AGENTS 硬規」
- README 「與 multi-agent orchestrator 的相容性」章節 — 闡明 SDD 紀律與 orchestration 正交
- `scripts/test.sh` 新增 **Unit 4b** (11 條): `codex-prompt.sh` 組裝正確性 (proposal/design/spec 原文 inline / Decisions range 偵測 / 錯誤路徑)
- `scripts/test.sh` 新增 **Unit 6** (1 條): 測試矩陣一致性 — grep `預設約 **N 條測試**` 與實際 PASS 計數比對, 強制每加新測試就更新矩陣
- `scripts/test.sh` 新增 **Unit 7** (1 條): AGENTS.md 指令量預算 — grep AGENTS.md 強指令行數, >180 hard fail, 守規則密度不漂移過 LLM stable band
- `scripts/test.sh` 擴 **Integration 1** 從 1 條 → 4 條: 4 個 examples 都跑 strict-validate

### Changed

- `scripts/test.sh` 總測試數 47 → 79 (反映 starter 自身規則密度提升 + 新增 Unit 7 指令預算自驗)
- README 「指令量約束」改為**機器驗證**版本: 從靜態宣稱「約 130 條」改為「AGENTS.md <100 條, Unit 7 強制 <=180」, 與實際量測對齊
- `README.md` 結構表加入 `scripts/codex-prompt.sh` + 4 個 examples 連結 + 反映 78 條 test
- `docs/testing.md` 反映 4 個 examples + 矩陣一致性檢查機制

### Migration / Upgrade Notes

升級指南見 [README 「How to upgrade」](README.md#how-to-upgrade-from-an-earlier-copy)。

---

## [pre-0.1.0] — 歷史 (2026-05-19 及之前)

`v0.1.0` 之前未 tag, 累計 22 commits 建立 starter 骨架:

- AGENTS.md 11 節 (§0~§11) + 4 階段 OpenSpec 流程
- 三階段 Codex audit (proposal 對抗性 / design 第二意見 / spec 完備性) + audit trail 格式
- design.md Decision 分層描述 4-marker 規範 (跨職能可讀)
- `hooks/pre-commit` 結構 grep 守門
- `.github/workflows/validate.yml` CI
- `examples/select-admin-frontend-stack/` 第一個 reference change
- `scripts/test.sh` 47 條 unit + integration 測試

詳細 commit log: `git log --oneline v0.1.0`

[0.1.0]: https://github.com/erikhuang76821/sdd-codex-starter/releases/tag/v0.1.0
