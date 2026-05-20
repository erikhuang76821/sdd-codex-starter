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
# Unit 4b: codex-prompt.sh assembly correctness — the helper script must
#          inline proposal/design/spec content verbatim (no summary drift).
#          Uses the reference example as a stable fixture.
# ---------------------------------------------------------------------------
section "Unit 4b: codex-prompt.sh assembly"

prompt_script="scripts/codex-prompt.sh"
if [ ! -f "$prompt_script" ]; then
  fail "scripts/codex-prompt.sh missing"
else
  pass "scripts/codex-prompt.sh present"

  # Stage reference example so the script can find it
  ref_change="select-admin-frontend-stack"
  ref_staged=false
  if [ ! -d "openspec/changes/$ref_change" ]; then
    cp -r "examples/$ref_change" "openspec/changes/"
    ref_staged=true
  fi

  # Proposal phase: must inline a known sentence verbatim
  proposal_out=$(bash "$prompt_script" --phase proposal --change "$ref_change" 2>&1)
  if echo "$proposal_out" | grep -qF "舊版後台是 jQuery + 多頁式 PHP 樣板"; then
    pass "codex-prompt proposal phase inlines proposal.md verbatim"
  else
    fail "codex-prompt proposal phase did NOT inline proposal.md content (possible summary drift)"
  fi
  if echo "$proposal_out" | grep -qF "BEGIN CODEX PROMPT" \
     && echo "$proposal_out" | grep -qF "END CODEX PROMPT"; then
    pass "codex-prompt proposal phase has BEGIN/END markers"
  else
    fail "codex-prompt proposal phase missing BEGIN/END markers"
  fi
  if echo "$proposal_out" | grep -qF "對抗性審查來源: codex (adversarial-review"; then
    pass "codex-prompt proposal phase emits audit trail template"
  else
    fail "codex-prompt proposal phase missing audit trail template"
  fi

  # Design phase: must inline proposal + Decisions, and stop before Risks
  design_out=$(bash "$prompt_script" --phase design --change "$ref_change" --question "test" 2>&1)
  if echo "$design_out" | grep -qF "D1. 主框架: Next.js" \
     && echo "$design_out" | grep -qF "D4. 資料層"; then
    pass "codex-prompt design phase inlines all 4 Decisions"
  else
    fail "codex-prompt design phase did NOT inline all 4 Decisions"
  fi
  if echo "$design_out" | grep -qF "## Risks / Trade-offs"; then
    fail "codex-prompt design phase leaked Risks section (should stop at next ## heading)"
  else
    pass "codex-prompt design phase correctly stops before ## Risks"
  fi
  if echo "$design_out" | grep -qF "Decisions D1-D4"; then
    pass "codex-prompt design phase auto-detects decisions range"
  else
    fail "codex-prompt design phase did NOT auto-detect decisions range (D1-D4)"
  fi

  # Spec phase: must auto-detect single capability and inline spec
  spec_out=$(bash "$prompt_script" --phase spec --change "$ref_change" 2>&1)
  if echo "$spec_out" | grep -qF "完備性審查來源: codex (review"; then
    pass "codex-prompt spec phase emits audit trail template"
  else
    fail "codex-prompt spec phase missing audit trail template"
  fi
  if echo "$spec_out" | grep -qF "Completeness checklist"; then
    pass "codex-prompt spec phase includes completeness checklist"
  else
    fail "codex-prompt spec phase missing completeness checklist"
  fi

  # Error path: nonexistent change must exit nonzero
  if bash "$prompt_script" --phase proposal --change does-not-exist-xyz >/dev/null 2>&1; then
    fail "codex-prompt accepted nonexistent change (should exit nonzero)"
  else
    pass "codex-prompt rejects nonexistent change"
  fi

  # Missing required args must exit nonzero
  if bash "$prompt_script" --phase proposal >/dev/null 2>&1; then
    fail "codex-prompt accepted missing --change (should exit nonzero)"
  else
    pass "codex-prompt rejects missing --change"
  fi

  # Cleanup
  if [ "$ref_staged" = "true" ]; then
    rm -rf "openspec/changes/$ref_change"
  fi
fi

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
# Integration 1: All examples must pass openspec validate --strict.
#                Each example covers a different SDD trigger shape:
#                  - select-admin-frontend-stack : technical-selection (4 Decisions, 6 Reqs)
#                  - add-user-login              : pure new feature (full Codex audits)
#                  - enable-2fa                  : MODIFIED Requirements (copy-then-modify rule)
#                  - clarify-login-error-wording : legitimate Codex audit-skip ("無 (理由: 具體)")
# ---------------------------------------------------------------------------
section "Integration 1: all examples strict validate"

examples_list=(
  select-admin-frontend-stack
  add-user-login
  enable-2fa
  clarify-login-error-wording
)

if ! command -v openspec >/dev/null 2>&1; then
  echo "  SKIP  openspec CLI not available, skipping integration tests"
else
  for example_id in "${examples_list[@]}"; do
    staged=false
    if [ ! -d "openspec/changes/$example_id" ]; then
      cp -r "examples/$example_id" openspec/changes/
      staged=true
    fi

    if openspec validate "$example_id" --strict >/dev/null 2>&1; then
      pass "examples/$example_id passes openspec validate --strict"
    else
      fail "examples/$example_id FAILS openspec validate --strict"
      openspec validate "$example_id" --strict 2>&1 | sed 's/^/        /'
    fi

    if [ "$staged" = "true" ]; then
      rm -rf "openspec/changes/$example_id"
    fi
  done
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
# Unit 6: matrix consistency — the "預設約 **N 條測試**" number in
#         docs/testing.md must equal the actual count of tests run by
#         this script. Forces matrix to be updated alongside test changes.
# ---------------------------------------------------------------------------
section "Unit 6: testing.md matrix consistency"

documented=$(grep -oE '預設約 \*\*[0-9]+ 條測試\*\*' docs/testing.md | grep -oE '[0-9]+' | head -1)

if [ -z "$documented" ]; then
  fail "docs/testing.md missing '預設約 **N 條測試**' line"
else
  # test_count at this point excludes this very test. +1 accounts for the
  # pass/fail call this branch is about to make.
  expected=$((test_count + 1))
  if [ "$documented" -eq "$expected" ]; then
    pass "docs/testing.md documents $documented tests, matches actual $expected"
  else
    fail "docs/testing.md says $documented tests but actual is $expected — update the matrix + total"
  fi
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
