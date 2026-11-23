# Agent guidance for raine-works/agents

This repository holds Raineworks' base rules ([`base.md`](base.md)) and the shared workflows every `raine-works`
repository runs. The base rules apply here too:

@base.md

## This repository

- A change here reaches every repository: the rules agents follow, and the review that approves their pull requests.
  Every pull request needs the owner's review as well as Claude's (`.github/CODEOWNERS`).
- `base.md` changes reach each repository by its own Base rules check, by pull request; the workflows by the pins it
  moves. Never push a change into another repository from here.
- When `skills/raineworks-base/scripts/sync-base.sh` changes, move `SYNC_BASE_SHA` in `check-base.yml` to the commit
  that changed it, in a pull request of its own once that's merged.
- Keep the README, the skill and the templates in step with the workflows' inputs, outputs and check names.
- This repository runs its own shared workflows from `master` (`@master`, never a commit): `review.yml` (Code review),
  `mention.yml` (`@claude`) and `issues.yml` (Issue to PR), with its checks (actionlint, shellcheck, jq) as their
  commands and `.github/actions/setup` installing actionlint. Claude can't edit `.github/workflows/` there either.
- `needs-person.yml` (this repository's own) keeps one issue listing what's waiting on a person across every
  repository in `repos.json`: issues and pull requests labelled `needs-person`, and approved pull requests waiting to
  be merged.
- `actionlint` (with shellcheck) passes on every workflow and template, and `shellcheck` on every script.
