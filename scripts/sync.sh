#!/usr/bin/env bash
# Syncs the shared rules (AGENTS.md here) into each repository in repos.json (or those named): the block between the
# markers at the top of its AGENTS.md is replaced with them (or put there, above the repository's own rules, if it has
# none yet; an AGENTS.md is made if there isn't one), and CLAUDE.md is made a link to AGENTS.md if it doesn't exist,
# so Claude Code reads it too. Each repository with a change gets a pull request, `agents-sync`, updated in place by
# the next sync while it's open. Run by the Sync workflow when the rules change, with the docs-sync app's token; or by
# hand, with yours. With --dry-run it prints each repository's new AGENTS.md instead.
#
#   scripts/sync.sh [--dry-run] [repo...]
set -euo pipefail

cd "$(dirname "$0")/.."
root="$PWD"
dry_run=
if [ "${1:-}" = --dry-run ]; then
	dry_run=1
	shift
fi
owner="$(jq -r .owner repos.json)"
if [ $# -eq 0 ]; then
	repos=()
	while IFS= read -r repo; do repos+=("$repo"); done < <(jq -r '.repos | keys[] | select(. != "agents")' repos.json)
else
	repos=("$@")
fi
source_sha="$(git rev-parse HEAD)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

for repo in "${repos[@]}"; do
	dir="$work/$repo"
	gh repo clone "$owner/$repo" "$dir" -- --quiet --depth 1
	python3 "$root/scripts/shared-block.py" "$root/AGENTS.md" "$dir/AGENTS.md" "$repo"
	if [ ! -e "$dir/CLAUDE.md" ] && [ ! -L "$dir/CLAUDE.md" ]; then
		ln -s AGENTS.md "$dir/CLAUDE.md"
	fi

	if [ -z "$(git -C "$dir" status --porcelain)" ]; then
		echo "$repo: up to date"
		continue
	fi
	if [ -n "$dry_run" ]; then
		echo "===== $repo: would change $(git -C "$dir" status --porcelain | awk '{print $2}' | paste -sd ' ' -)"
		git -C "$dir" --no-pager diff
		continue
	fi

	git -C "$dir" switch --quiet -c agents-sync
	git -C "$dir" add AGENTS.md CLAUDE.md
	git -C "$dir" -c user.name="${GIT_AUTHOR_NAME:-raineworks-doc-sync[bot]}" \
		-c user.email="${GIT_AUTHOR_EMAIL:-raineworks-doc-sync[bot]@users.noreply.github.com}" \
		commit --quiet -m "Sync agent rules from raine-works/agents" \
		-m "The shared rules at the top of AGENTS.md, from raine-works/agents@$source_sha."
	git -C "$dir" push --quiet --force origin agents-sync
	if [ -z "$(gh pr list -R "$owner/$repo" --head agents-sync --state open --json number --jq '.[].number')" ]; then
		gh pr create -R "$owner/$repo" --head agents-sync --title "Sync agent rules from raine-works/agents" --body \
			"The shared rules at the top of \`AGENTS.md\` changed in [raine-works/agents](https://github.com/$owner/agents/commit/$source_sha): this brings this repository's copy up to date. Only the block between the markers changes; the repository's own rules below it don't."
	fi
	echo "$repo: synced"
done
