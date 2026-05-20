#!/usr/bin/env bash
# scripts/codex-prompt.sh — Print the assembled Codex prompt for a given SDD phase.
#
# Why this script exists:
# - AGENTS §3.4 mandates "prompt MUST include full context, not summary".
# - Hand-assembling the prompt is error-prone (easy to summarize by accident).
# - This script auto-inlines proposal.md / design.md / spec.md verbatim per
#   the three templates in docs/codex-handoff.md, then prints to STDOUT.
# - It does NOT call codex. It only prints. The actual call still goes through
#   Claude Code's codex:rescue subagent (or your AI agent's equivalent).
# - It does NOT replace the AGENTS rule — only makes compliance easier.
#
# Usage:
#   bash scripts/codex-prompt.sh --phase proposal --change <id>
#   bash scripts/codex-prompt.sh --phase design   --change <id> [--question "<one-line current question>"]
#   bash scripts/codex-prompt.sh --phase spec     --change <id> [--capability <name>]
#
# Examples:
#   bash scripts/codex-prompt.sh --phase proposal --change add-user-login
#   bash scripts/codex-prompt.sh --phase design   --change add-user-login \
#        --question "選用 JWT 還是 session cookie"
#   bash scripts/codex-prompt.sh --phase spec     --change add-user-login
#
# Output: assembled prompt to STDOUT between BEGIN/END markers. Pipe to
# pbcopy / clip.exe / xclip if you want it on the clipboard, or `> /tmp/x`
# and review before pasting into codex:rescue.

set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

phase=""
change=""
capability=""
question=""

usage() {
  cat <<'EOF'
Usage: codex-prompt.sh --phase <proposal|design|spec> --change <id> [options]

Options:
  --phase       proposal | design | spec   (required)
  --change      OpenSpec change id          (required)
  --question    For design phase: one-sentence current decision question
  --capability  For spec phase: which capability under specs/ (auto-detect if exactly one)

Examples:
  bash scripts/codex-prompt.sh --phase proposal --change add-user-login
  bash scripts/codex-prompt.sh --phase design --change add-user-login --question "選用 JWT 還是 session cookie"
  bash scripts/codex-prompt.sh --phase spec --change add-user-login
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --phase)       phase="$2";       shift 2 ;;
    --change)      change="$2";      shift 2 ;;
    --question)    question="$2";    shift 2 ;;
    --capability)  capability="$2";  shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [ -z "$phase" ] || [ -z "$change" ]; then
  usage
  exit 2
fi

change_dir="$repo_root/openspec/changes/$change"
if [ ! -d "$change_dir" ]; then
  # Also tolerate running from examples/ for testing
  alt_dir="$repo_root/examples/$change"
  if [ -d "$alt_dir" ]; then
    change_dir="$alt_dir"
  else
    echo "ERROR: change directory not found: $change_dir" >&2
    echo "       (also tried: $alt_dir)" >&2
    exit 1
  fi
fi

today="$(date +%Y-%m-%d)"

# Extract "## Decisions" through (exclusive) next "## " heading or EOF.
extract_decisions() {
  awk '/^## Decisions/{p=1; print; next} /^## /{p=0} p' "$1"
}

case "$phase" in
  proposal)
    file="$change_dir/proposal.md"
    if [ ! -f "$file" ]; then
      echo "ERROR: $file does not exist; write proposal.md first." >&2
      exit 1
    fi
    cat <<EOF
═══════════════════════════════════════════════════════════════
  CODEX PROMPT — proposal adversarial-review for $change
  Copy everything between the BEGIN/END markers into your
  codex:rescue invocation (or paste as the prompt argument to
  Agent(subagent_type="codex:codex-rescue", prompt=...)).
═══════════════════════════════════════════════════════════════

────── BEGIN CODEX PROMPT ──────
--fresh

You are an adversarial reviewer for an SDD proposal. Read the full proposal below, then push back hard — your job is to find weaknesses, not to validate.

## Context: Full proposal (原文保留, do not translate)

EOF
    cat "$file"
    cat <<'EOF'

## Review focus

For each of the four dimensions, give 1-2 adversarial points (weaknesses, not validations):

1. **Is the "Why" defensible?** — Is the pain overstated? Are there cheaper non-engineering options (process / training / existing tooling)?
2. **Does "What Changes" scope correctly?** — Critical changes missing? Unnecessary scope creep?
3. **Are "Capabilities" sliced sensibly?** — Is the new-vs-modified boundary right? Any overlap or gaps?
4. **Is "Impact / risk" honest?** — Top two under-estimated risks? Are mitigations actually feasible?

Format: bulleted, one-sentence conclusion + one-sentence reason per point. No essays. Total under 250 字.

**Reply in 繁體中文.** This review will be written directly into the audit trail of proposal.md and may trigger proposal revisions.
────── END CODEX PROMPT ──────

EOF
    cat <<EOF
After consultation, paste this audit trail to the TOP of proposal.md
(before "## Why"):

  <!-- 對抗性審查來源: codex (adversarial-review, $today, 已傳遞: 完整 proposal) -->

If you skip consultation (e.g. pure bugfix / pure rename), the audit
trail MUST give a CONCRETE reason (not "不需要" / "N/A"):

  <!-- 對抗性審查來源: 無 (理由: <一句具體原因>) -->
EOF
    ;;

  design)
    proposal_file="$change_dir/proposal.md"
    design_file="$change_dir/design.md"
    if [ ! -f "$proposal_file" ]; then
      echo "ERROR: $proposal_file does not exist; write proposal.md first." >&2
      exit 1
    fi
    has_decisions=0
    if [ -f "$design_file" ] && grep -q '^## Decisions' "$design_file"; then
      has_decisions=1
    fi
    cat <<EOF
═══════════════════════════════════════════════════════════════
  CODEX PROMPT — design technical second-opinion for $change
  Copy everything between the BEGIN/END markers into your
  codex:rescue invocation.
═══════════════════════════════════════════════════════════════

────── BEGIN CODEX PROMPT ──────
--fresh

You are a technical second-opinion reviewer for an SDD design decision. Read the full context below, then push back on the proposed choice.

## Context: Full proposal (原文保留, do not translate)

EOF
    cat "$proposal_file"
    cat <<EOF


## Context: Decisions already committed (原文保留)

EOF
    if [ "$has_decisions" -eq 1 ]; then
      extract_decisions "$design_file"
    else
      echo "(本題為首個決策)"
    fi
    cat <<EOF


## Current question

EOF
    if [ -n "$question" ]; then
      echo "$question"
    else
      cat <<'EOF'
<請手動補上當前題目, 例如:
We need to decide <主題> in this change. Candidates: A / B / C / D.
Scenario: <場景一句話>.>
EOF
    fi
    cat <<'EOF'


Provide:

1. Recommended option + two explicit eliminations
2. One recommendation for each sub-decision (if any)
3. Top two failure-mode risks + mitigations

Format: bulleted, no essays, under 200 字 total.

**Reply in 繁體中文.** This second opinion will be written directly into the Decisions section of design.md.
────── END CODEX PROMPT ──────

EOF
    decisions_range="首個決策"
    if [ "$has_decisions" -eq 1 ]; then
      last_d="$(grep -oE '^### D[0-9]+\.' "$design_file" | tail -1 | grep -oE '[0-9]+' || true)"
      if [ -n "${last_d:-}" ]; then
        if [ "$last_d" = "1" ]; then
          decisions_range="D1"
        else
          decisions_range="D1-D${last_d}"
        fi
      fi
    fi
    cat <<EOF
After consultation, add this audit trail to the TOP of the
"## Decisions" section in design.md:

  第二意見來源: codex (codex:rescue, $today, 已傳遞: proposal + Decisions $decisions_range)

If you decide not to consult, the audit MUST give a CONCRETE reason:

  第二意見來源: 無 (理由: <一句具體原因>)
EOF
    ;;

  spec)
    if [ -n "$capability" ]; then
      spec_file="$change_dir/specs/$capability/spec.md"
    else
      mapfile -t cap_dirs < <(find "$change_dir/specs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
      if [ "${#cap_dirs[@]}" -eq 0 ]; then
        echo "ERROR: no specs/ subdirectory under $change_dir" >&2
        exit 1
      elif [ "${#cap_dirs[@]}" -eq 1 ]; then
        spec_file="${cap_dirs[0]}/spec.md"
      else
        echo "ERROR: multiple capabilities under $change_dir/specs — pick one with --capability:" >&2
        for d in "${cap_dirs[@]}"; do
          echo "  - $(basename "$d")" >&2
        done
        exit 1
      fi
    fi
    design_file="$change_dir/design.md"
    if [ ! -f "$spec_file" ]; then
      echo "ERROR: $spec_file does not exist; write spec.md first." >&2
      exit 1
    fi
    cat <<EOF
═══════════════════════════════════════════════════════════════
  CODEX PROMPT — spec completeness-review for $change
  Copy everything between the BEGIN/END markers into your
  codex:rescue invocation.
═══════════════════════════════════════════════════════════════

────── BEGIN CODEX PROMPT ──────
--fresh

You are a completeness reviewer for an SDD spec. Read the full spec and the related design Decisions below, then check whether Requirements and scenarios are complete.

## Context: Full spec (原文保留, do not translate)

EOF
    cat "$spec_file"
    cat <<EOF


## Context: Related design Decisions (原文保留)

EOF
    if [ -f "$design_file" ] && grep -q '^## Decisions' "$design_file"; then
      extract_decisions "$design_file"
    else
      echo "(無 design.md 或 design.md 無 Decisions 區 — 此 change 未進 design 階段)"
    fi
    cat <<'EOF'


## Completeness checklist

Walk through each item below and list **only the gaps you find** — skip items with no issue (do not write "OK"):

1. **Does each Requirement have ≥ 1 happy + 1 `[異常]` scenario?**
2. **Do `[異常]` scenarios cover all four classes (upstream failure / auth-permission / missing-or-invalid data / retry exhaustion + degradation)?**
   Call out Requirements that only cover one class.
3. **Do error scenarios describe "user-observable impact"?**
   Flag scenarios that only say "system logs error" or "record event" — that's internal behaviour, not acceptance criteria.
4. **Any user-reachable scenarios that happy-path thinking misses?**
   Examples: race condition / timeout / partial success / cross-tab contention / back-button state restore.
5. **Any scenario using WHEN to describe an unwanted event (should be IF)?**

Format: bulleted; one sentence per gap saying "which Requirement / Scenario is missing what". No essays. Total under 300 字.

**Reply in 繁體中文.** This review will be written into the audit trail of spec.md AND MUST trigger spec content revision — recording the audit alone is not acceptable; the spec body itself must be updated.
────── END CODEX PROMPT ──────

EOF
    cat <<EOF
After consultation, paste this audit trail to the TOP of spec.md
(co-located with the approved-by comment):

  <!-- 完備性審查來源: codex (review, $today, 已傳遞: spec + design Decisions) -->

If Codex flags missing scenarios, you MUST add them to the spec body —
recording the audit trail without amending the spec is NOT acceptable
(AGENTS §8.3).
EOF
    ;;

  *)
    echo "ERROR: --phase must be proposal|design|spec, got: $phase" >&2
    usage
    exit 2
    ;;
esac
