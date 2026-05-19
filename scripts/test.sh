#!/usr/bin/env bash
# scripts/test.sh — Unit + integration tests for the starter itself.
#
# Run locally:   bash scripts/test.sh
# Run in CI:     same command, no extra setup beyond openspec CLI.
#
# Exit code 0 = all tests pass; non-zero = at least one failure.
# Each test prints "PASS" or "FAIL: <reason>" so the output is grep-friendly.

set -u
# Don't `set -e` — we want every test to run even if earlier ones fail,
# and we tally failures at the end.

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

fail_count=0
test_count=0

pass() {
  test_count=$((test_count + 1))
  echo "  PASS  $1"
}

fail() {
  test_count=$((test_count + 1))
  fail_count=$((fail_count + 1))
  echo "  FAIL  $1"
}

section() {
  echo ""
  echo "=== $1 ==="
}

# ---------------------------------------------------------------------------
# Unit 1: Link integrity — every [text](path) in tracked markdown files
#         must point to a file that exists. Skips http/https links and
#         in-file anchors (#section).
# ---------------------------------------------------------------------------
section "Unit 1: link integrity"

# Collect markdown files (exclude .git)
mapfile -t md_files < <(find . -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" | sort)

for md in "${md_files[@]}"; do
  # Extract relative-path links (skip http, https, mailto, anchors)
  grep -oE "\]\([^)]+\)" "$md" 2>/dev/null \
    | sed -E 's/^\]\(//; s/\)$//' \
    | grep -vE "^(https?:|mailto:|#)" \
    | while read -r link; do
        # Strip anchor fragments
        link_path="${link%%#*}"
        [ -z "$link_path" ] && continue
        # Resolve relative to file's directory
        dir="$(dirname "$md")"
        target="$dir/$link_path"
        if [ ! -e "$target" ]; then
          echo "BROKEN: $md → $link"
        fi
      done
done > /tmp/sdd_link_check.txt 2>&1

if [ -s /tmp/sdd_link_check.txt ]; then
  while IFS= read -r line; do
    fail "$line"
  done < /tmp/sdd_link_check.txt
else
  pass "all markdown links resolve"
fi
rm -f /tmp/sdd_link_check.txt

# ---------------------------------------------------------------------------
# Unit 2: AGENTS.md section completeness — must contain §0 through §11
# ---------------------------------------------------------------------------
section "Unit 2: AGENTS.md section completeness"

for n in 0 1 2 3 4 5 6 7 8 9 10 11; do
  if grep -qE "^## ${n}\. " AGENTS.md; then
    pass "AGENTS.md §${n} present"
  else
    fail "AGENTS.md missing §${n}"
  fi
done

# ---------------------------------------------------------------------------
# Unit 3: Cross-reference consistency — every "AGENTS §X" or "第 X 節" in
#         docs/ must point to a section that actually exists in AGENTS.md
# ---------------------------------------------------------------------------
section "Unit 3: AGENTS cross-reference consistency"

# Build a set of valid section numbers
agents_sections=$(grep -E "^## [0-9]+\. " AGENTS.md | sed -E 's/^## ([0-9]+)\..*/\1/' | sort -u)

check_ref() {
  local file="$1"
  local ref_num="$2"
  if echo "$agents_sections" | grep -qx "$ref_num"; then
    return 0
  else
    fail "$file references AGENTS §${ref_num} but AGENTS.md has no such section"
    return 1
  fi
}

for f in docs/*.md hooks/README.md CLAUDE.md; do
  [ -f "$f" ] || continue
  # Match "AGENTS §X", "AGENTS.md §X", "AGENTS section X", "第 X 節"
  mapfile -t refs < <(grep -oE "AGENTS(\.md)? §[0-9]+|第 [0-9]+ 節" "$f" \
                       | grep -oE "[0-9]+" \
                       | sort -u)
  ok=true
  for n in "${refs[@]:-}"; do
    [ -z "$n" ] && continue
    if ! echo "$agents_sections" | grep -qx "$n"; then
      fail "$f references AGENTS §${n} but AGENTS.md has no such section"
      ok=false
    fi
  done
  if $ok; then
    pass "$f cross-references valid"
  fi
done

# ---------------------------------------------------------------------------
# Unit 4: Key phrase regression — these phrases protect critical rules.
#         If anyone edits them away, the rule has likely drifted.
# ---------------------------------------------------------------------------
section "Unit 4: key phrase regression"

check_phrase() {
  local file="$1"
  local phrase="$2"
  local label="$3"
  if grep -qF "$phrase" "$file"; then
    pass "$label present in $file"
  else
    fail "$label MISSING in $file (looking for: $phrase)"
  fi
}

# AGENTS.md anchors
check_phrase "AGENTS.md" "立即啟動 SDD 流程" "trigger semantics"
check_phrase "AGENTS.md" "規則沒有例外" "no-exception clause"
check_phrase "AGENTS.md" "太簡單" "anti-downgrade clause"
check_phrase "AGENTS.md" "proposal.md 全文 + 已決 Decisions 全文" "design-stage full context transfer rule"
check_phrase "AGENTS.md" "對抗性審查來源" "proposal adversarial-review audit format"
check_phrase "AGENTS.md" "第二意見來源" "design audit trail format"
check_phrase "AGENTS.md" "完備性審查來源" "spec completeness-review audit format"
check_phrase "AGENTS.md" "Codex 呼叫失敗時 MUST 停止對應階段流程" "codex failure stop condition"

# CLAUDE.md anchors
check_phrase "CLAUDE.md" "AGENTS.md" "CLAUDE.md points at AGENTS.md"
check_phrase "CLAUDE.md" "STOP" "STOP directive"
check_phrase "CLAUDE.md" "太簡單" "task-size is not a trigger"

# docs/codex-handoff.md anchors
check_phrase "docs/codex-handoff.md" "proposal.md 全文" "full proposal required"
check_phrase "docs/codex-handoff.md" "只給摘要" "no-summary-only anti-pattern"
check_phrase "docs/codex-handoff.md" "auto / yolo / no-confirm" "auto-mode preservation clause"
check_phrase "docs/codex-handoff.md" "not authenticated" "real source-code keyword (auth)"
check_phrase "docs/codex-handoff.md" "is not installed" "real source-code keyword (CLI)"
check_phrase "docs/codex-handoff.md" "npm install -g @openai/codex" "concrete fix path"
check_phrase "docs/codex-handoff.md" "/codex:adversarial-review proposal.md" "adversarial-review workflow label"
check_phrase "docs/codex-handoff.md" "/codex:review spec.md" "spec review workflow label"
check_phrase "docs/codex-handoff.md" "完備性審查員" "spec completeness reviewer role"

# docs/spec-writing.md anchors
check_phrase "docs/spec-writing.md" "IF" "EARS unwanted-behaviour pattern"
check_phrase "docs/spec-writing.md" "[異常]" "error-scenario prefix mandate"

# docs/task-writing.md anchors
check_phrase "docs/task-writing.md" "→ verified by:" "task verified-by format"

# docs/decision-writing.md anchors (AGENTS §3.5)
check_phrase "docs/decision-writing.md" "**一句話**" "Decision marker 1"
check_phrase "docs/decision-writing.md" "**對使用者 / 企劃看得見的影響**" "Decision marker 2"
check_phrase "docs/decision-writing.md" "**為何不選**" "Decision marker 3"

# reference example design.md — at least one D with all three markers
check_phrase "examples/select-admin-frontend-stack/design.md" "**一句話**" "reference D1-D4 use layered description"
check_phrase "examples/select-admin-frontend-stack/design.md" "**對使用者 / 企劃看得見的影響**" "reference layered marker 2"
check_phrase "examples/select-admin-frontend-stack/design.md" "**為何不選**" "reference layered marker 3"

# ---------------------------------------------------------------------------
# Unit 5: openspec CLI must be available (informational; CI installs it)
# ---------------------------------------------------------------------------
section "Unit 5: openspec CLI presence"

if command -v openspec >/dev/null 2>&1; then
  pass "openspec CLI on PATH ($(openspec --version 2>&1 | head -1))"
else
  fail "openspec CLI not on PATH; install with: npm install -g @fission-ai/openspec"
fi

# ---------------------------------------------------------------------------
# Integration 1: Reference example must always pass strict validate
# ---------------------------------------------------------------------------
section "Integration 1: reference example strict validate"

if ! command -v openspec >/dev/null 2>&1; then
  echo "  SKIP  openspec CLI not available, skipping integration tests"
else
  # Stage example into openspec/changes (idempotent)
  staged=false
  if [ ! -d "openspec/changes/select-admin-frontend-stack" ]; then
    cp -r examples/select-admin-frontend-stack openspec/changes/
    staged=true
  fi

  if openspec validate select-admin-frontend-stack --strict >/dev/null 2>&1; then
    pass "examples/select-admin-frontend-stack passes openspec validate --strict"
  else
    fail "examples/select-admin-frontend-stack FAILS openspec validate --strict"
    openspec validate select-admin-frontend-stack --strict 2>&1 | sed 's/^/        /'
  fi

  # Cleanup if we staged
  if [ "$staged" = "true" ]; then
    rm -rf openspec/changes/select-admin-frontend-stack
  fi
fi

# ---------------------------------------------------------------------------
# Integration 2: Hook negative tests — feed deliberately broken artifacts
#                to pre-commit and confirm it rejects them.
# ---------------------------------------------------------------------------
section "Integration 2: pre-commit hook rejects bad artifacts"

if [ ! -f hooks/pre-commit ]; then
  fail "hooks/pre-commit missing"
elif ! command -v openspec >/dev/null 2>&1; then
  echo "  SKIP  openspec CLI not available, skipping hook tests"
else
  # Set up a clean temp workspace mirroring this repo
  tmp_dir=$(mktemp -d)
  trap "rm -rf $tmp_dir" EXIT

  cp -r "$repo_root/." "$tmp_dir/"
  cd "$tmp_dir"
  git init -q -b main 2>/dev/null || git init -q 2>/dev/null
  cp -r examples/select-admin-frontend-stack openspec/changes/

  run_hook() {
    bash hooks/pre-commit >"$tmp_dir/hook.out" 2>&1
    return $?
  }

  # Baseline — clean reference change should pass
  if run_hook; then
    pass "hook passes on clean reference change"
  else
    fail "hook FAILS on clean reference change (baseline)"
    sed 's/^/        /' "$tmp_dir/hook.out"
  fi

  # Negative 1: remove "第二意見來源:" from design.md → expect fail
  cp openspec/changes/select-admin-frontend-stack/design.md design.md.bak
  grep -v "第二意見來源:" design.md.bak > openspec/changes/select-admin-frontend-stack/design.md
  if ! run_hook; then
    pass "hook rejects design.md without 第二意見來源"
  else
    fail "hook ACCEPTED design.md without 第二意見來源 (regression!)"
  fi
  mv design.md.bak openspec/changes/select-admin-frontend-stack/design.md

  # Negative 1b: remove "**一句話**:" markers from design.md → expect fail (AGENTS §3.5)
  design_file="openspec/changes/select-admin-frontend-stack/design.md"
  cp "$design_file" design.md.bak
  grep -v "^\*\*一句話\*\*:" design.md.bak > "$design_file"
  if ! run_hook; then
    pass "hook rejects design.md missing 一句話 marker on Decisions"
  else
    fail "hook ACCEPTED design.md missing 一句話 marker (regression!)"
  fi
  mv design.md.bak "$design_file"

  # Negative 1c: remove "**為何不選**:" markers from design.md → expect fail (AGENTS §3.5)
  cp "$design_file" design.md.bak
  grep -v "^\*\*為何不選\*\*:" design.md.bak > "$design_file"
  if ! run_hook; then
    pass "hook rejects design.md missing 為何不選 marker on Decisions"
  else
    fail "hook ACCEPTED design.md missing 為何不選 marker (regression!)"
  fi
  mv design.md.bak "$design_file"

  # Negative 2: remove approved-by from spec.md → expect fail
  spec_file="openspec/changes/select-admin-frontend-stack/specs/admin-frontend-stack/spec.md"
  cp "$spec_file" spec.md.bak
  grep -v "approved-by:" spec.md.bak > "$spec_file"
  if ! run_hook; then
    pass "hook rejects spec.md without approved-by"
  else
    fail "hook ACCEPTED spec.md without approved-by (regression!)"
  fi
  mv spec.md.bak "$spec_file"

  # Negative 2b: remove "完備性審查來源:" from spec.md → expect fail
  cp "$spec_file" spec.md.bak
  grep -v "完備性審查來源:" spec.md.bak > "$spec_file"
  if ! run_hook; then
    pass "hook rejects spec.md without 完備性審查來源"
  else
    fail "hook ACCEPTED spec.md without 完備性審查來源 (regression!)"
  fi
  mv spec.md.bak "$spec_file"

  # Negative 2c: remove "對抗性審查來源:" from proposal.md → expect fail
  proposal_file="openspec/changes/select-admin-frontend-stack/proposal.md"
  cp "$proposal_file" proposal.md.bak
  grep -v "對抗性審查來源:" proposal.md.bak > "$proposal_file"
  if ! run_hook; then
    pass "hook rejects proposal.md without 對抗性審查來源"
  else
    fail "hook ACCEPTED proposal.md without 對抗性審查來源 (regression!)"
  fi
  mv proposal.md.bak "$proposal_file"

  # Negative 3: remove "→ verified by:" from one task → expect fail
  tasks_file="openspec/changes/select-admin-frontend-stack/tasks.md"
  cp "$tasks_file" tasks.md.bak
  sed '1,/→ verified by:/{s/→ verified by:.*$//}' tasks.md.bak > "$tasks_file"
  if ! run_hook; then
    pass "hook rejects tasks.md task missing verified-by"
  else
    fail "hook ACCEPTED tasks.md task missing verified-by (regression!)"
  fi
  mv tasks.md.bak "$tasks_file"

  cd "$repo_root"
fi

# ---------------------------------------------------------------------------
# Integration 3: Fresh-bootstrap — simulate copying starter into a new
#                project and running `openspec new change`.
# ---------------------------------------------------------------------------
section "Integration 3: fresh-project bootstrap"

if ! command -v openspec >/dev/null 2>&1; then
  echo "  SKIP  openspec CLI not available, skipping bootstrap test"
else
  bootstrap_dir=$(mktemp -d)
  trap "rm -rf $bootstrap_dir $tmp_dir 2>/dev/null" EXIT

  cp -r "$repo_root/." "$bootstrap_dir/"
  cd "$bootstrap_dir"
  rm -rf .git

  if openspec new change ci-smoke-test --description "automated smoke test" >/dev/null 2>&1; then
    pass "openspec new change works in fresh-bootstrapped dir"
  else
    fail "openspec new change FAILED in fresh-bootstrapped dir"
  fi

  if [ -f "openspec/changes/ci-smoke-test/.openspec.yaml" ] \
     && [ -f "openspec/changes/ci-smoke-test/README.md" ]; then
    pass "new change skeleton created with expected files"
  else
    fail "new change skeleton missing expected files"
  fi

  cd "$repo_root"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
echo "  Total: $test_count    Failed: $fail_count"
echo "============================================================"

if [ "$fail_count" -eq 0 ]; then
  exit 0
else
  exit 1
fi
