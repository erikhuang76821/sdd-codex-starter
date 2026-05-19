# Git Hooks

本目錄提供 git hook 範本, 配合 `AGENTS.md` 第 9 節「Lint / CI Fail 處理 SOP」使用。

## pre-commit

每次 `git commit` 前自動跑下列檢查 (對 `openspec/changes/` 內所有非 archive 的 change):

1. `openspec validate --strict` — 結構 / Scenario / EARS 規則
2. `design.md` 有 `## Decisions` 時, MUST 含 `第二意見來源:` 一行 (AGENTS §8)
3. 每份 `specs/**/spec.md` MUST 含 `approved-by:` 標記 (AGENTS §7)
4. `tasks.md` 每行 `- [ ] ...` MUST 含 `→ verified by:` (AGENTS §6)

## 安裝

### macOS / Linux

```bash
cd <your-project>
ln -s ../../hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Windows (PowerShell)

```powershell
cd <your-project>
Copy-Item hooks\pre-commit .git\hooks\pre-commit
# Git for Windows runs the hook via its bundled bash, no chmod needed.
```

### 確認安裝成功

```bash
git commit --allow-empty -m "test hook"
# 應該看到 "[pre-commit] No active changes; skipping validation." 或實際驗證輸出
```

## 繞過 (不建議)

```bash
git commit --no-verify
```

AGENTS §9 明文禁止 AI agent 使用 `--no-verify` 繞過, 但人類在 emergency 時可用。
繞過後 push, CI 仍會擋 — 規則不會逃逸。

## Prereq

- `git` (廢話)
- `bash` (macOS/Linux 原生; Windows 用 Git Bash, 隨 Git for Windows 安裝即有)
- `openspec` CLI (`npm install -g @fission-ai/openspec`)
