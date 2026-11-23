#!/usr/bin/env bash
# Applies the rulesets to each repository in repos.json (or those named), as its owner:
#
# - "Protect master" (rulesets/protect-master.json): no deleting or force-pushing the default branch; every change
#   through a pull request, with one approval of its last push (stale approvals dismissed) and every review thread
#   resolved. A repository with `codeOwnerReview` (this one) also needs its code owner's review (CODEOWNERS).
# - "<repo> checks": Claude's review (repos.json `review`) and the repository's own checks (its `checks`) must pass,
#   with the pull request up to date with the default branch.
#
# Both let the repository's admins bypass them, only to merge a pull request. It also lets GitHub Actions approve pull
# requests (the review's `approve` job), keeping the repository's default workflow permissions as they are. Each
# ruleset is matched by name: changed if it's there, made if it isn't. With --dry-run it prints what it would send.
#
#   scripts/apply-rulesets.sh [--dry-run] [repo...]
set -euo pipefail

cd "$(dirname "$0")/.."
dry_run=
if [ "${1:-}" = --dry-run ]; then
	dry_run=1
	shift
fi
owner="$(jq -r .owner repos.json)"
if [ $# -eq 0 ]; then
	repos=()
	while IFS= read -r repo; do repos+=("$repo"); done < <(jq -r '.repos | keys[]' repos.json)
else
	repos=("$@")
fi

# upsert <repo> <ruleset json>: by its name.
upsert() {
	local repo="$1" ruleset="$2" name id
	name="$(jq -r .name <<< "$ruleset")"
	id="$(gh api "repos/$owner/$repo/rulesets" --jq ".[] | select(.name == \"$name\") | .id")"
	if [ -n "$dry_run" ]; then
		echo "$repo: would $([ -n "$id" ] && echo update || echo create) \"$name\":"
		jq -c '.rules[] | {type, parameters: (.parameters.required_status_checks // .parameters.required_approving_review_count // null)}' <<< "$ruleset"
	elif [ -n "$id" ]; then
		gh api -X PUT "repos/$owner/$repo/rulesets/$id" --input - <<< "$ruleset" --silent
		echo "$repo: updated \"$name\""
	else
		gh api -X POST "repos/$owner/$repo/rulesets" --input - <<< "$ruleset" --silent
		echo "$repo: created \"$name\""
	fi
}

for repo in "${repos[@]}"; do
	if ! jq -e --arg repo "$repo" '.repos | has($repo)' repos.json > /dev/null; then
		echo "$repo isn't in repos.json" >&2
		exit 1
	fi

	permissions="$(gh api "repos/$owner/$repo/actions/permissions/workflow" --jq .default_workflow_permissions)"
	if [ -n "$dry_run" ]; then
		echo "$repo: would let GitHub Actions approve pull requests (default permissions stay $permissions)"
	else
		gh api -X PUT "repos/$owner/$repo/actions/permissions/workflow" \
			-f default_workflow_permissions="$permissions" -F can_approve_pull_request_reviews=true --silent
		echo "$repo: GitHub Actions may approve pull requests"
	fi

	# A repository whose changes reach every other (this one) also needs its code owner's review: Claude's approval
	# isn't enough.
	code_owner="$(jq --arg repo "$repo" '.repos[$repo].codeOwnerReview // false' repos.json)"
	upsert "$repo" "$(jq --argjson code_owner "$code_owner" \
		'(.rules[] | select(.type == "pull_request") | .parameters.require_code_owner_review) = $code_owner' \
		rulesets/protect-master.json)"

	checks="$(jq -c --arg repo "$repo" '[.review[], .repos[$repo].checks[]] | map({context: ., integration_id: 15368})' repos.json)"
	upsert "$repo" "$(jq -n --arg name "$repo checks" --argjson checks "$checks" '{
		name: $name,
		target: "branch",
		enforcement: "active",
		conditions: { ref_name: { include: ["~DEFAULT_BRANCH"], exclude: [] } },
		rules: [{
			type: "required_status_checks",
			parameters: {
				strict_required_status_checks_policy: true,
				do_not_enforce_on_create: false,
				required_status_checks: $checks
			}
		}],
		bypass_actors: [{ actor_id: 5, actor_type: "RepositoryRole", bypass_mode: "pull_request" }]
	}')"
done
