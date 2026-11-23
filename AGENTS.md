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
- `actionlint` (with shellcheck) passes on every workflow and template, and `shellcheck` on every script.
