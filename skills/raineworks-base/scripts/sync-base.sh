#!/usr/bin/env bash
# Keeps a repository's copy of Raineworks' base rules current: .raineworks/base.md is base.md from raine-works/agents, under a
# one-line header saying not to edit it, and AGENTS.md imports it (CLAUDE.md being a symlink to AGENTS.md).
#
# Usage: sync-base.sh           write .raineworks/base.md from the current base.md
#        sync-base.sh --check   change nothing; fail if the copy is out of date or the wiring is missing (for CI)
# Run from the repository's root. RAINEWORKS_BASE_REF picks the ref of raine-works/agents (default master).
# Exit: 0 current (or updated), 1 out of date or failed, 2 AGENTS.md or CLAUDE.md not wired up.
set -euo pipefail

copy=.raineworks/base.md
ref="${RAINEWORKS_BASE_REF:-master}"
header='<!-- Copy of base.md from raine-works/agents, kept current by its sync. Change base.md there, not this file. -->'
check=false
[[ "${1:-}" == --check ]] && check=true

wiring=0
if ! grep -qxF "@$copy" AGENTS.md 2>/dev/null; then
  echo "AGENTS.md must import the base rules on a line of its own: @$copy" >&2
  wiring=2
fi
if [[ ! -L CLAUDE.md || "$(readlink CLAUDE.md)" != AGENTS.md ]]; then
  echo "CLAUDE.md must be a symlink to AGENTS.md (ln -s AGENTS.md CLAUDE.md)" >&2
  wiring=2
fi

want=$(mktemp)
trap 'rm -f "$want"' EXIT
{
  echo "$header"
  echo
  gh api -H 'Accept: application/vnd.github.raw' "repos/raine-works/agents/contents/base.md?ref=$ref"
} >"$want"
if [[ $(wc -l <"$want") -lt 3 ]]; then
  echo "fetched an empty base.md from raine-works/agents@$ref" >&2
  exit 1
fi

if cmp -s "$want" "$copy"; then
  echo "$copy is current (raine-works/agents@$ref)"
elif $check; then
  echo "$copy isn't the current base.md from raine-works/agents@$ref: merge the sync pull request, don't edit the copy" >&2
  exit 1
else
  mkdir -p "$(dirname "$copy")"
  cp "$want" "$copy"
  echo "$copy updated to base.md from raine-works/agents@$ref"
fi
exit "$wiring"
