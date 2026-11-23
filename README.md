# raine-works/agents

The rules agents follow in every `raine-works` repository, and the automation that holds them to it: one place to
change both.

| Path | What |
| :--- | :--- |
| [`AGENTS.md`](AGENTS.md) | The shared rules, synced into the top of every repository's `AGENTS.md` |
| [`.github/workflows/code-review.yml`](.github/workflows/code-review.yml) | Claude's code review, reusable: reviews every pull request against `AGENTS.md`, and approves it when nothing it found is left open |
| [`.github/workflows/docs-sync.yml`](.github/workflows/docs-sync.yml) | Docs sync, reusable: after CI passes on `master`, a pull request fixing any doc the new commits made wrong |
| [`.github/workflows/claude.yml`](.github/workflows/claude.yml) | `@claude` on issues and pull requests, reusable |
| [`templates/`](templates) | Each repository's own workflows that call them |
| [`repos.json`](repos.json) | The repositories, and the checks each one's ruleset requires |
| [`rulesets/`](rulesets), [`scripts/apply-rulesets.sh`](scripts/apply-rulesets.sh) | `master`'s protection, applied to every repository |
| [`scripts/sync.sh`](scripts/sync.sh), [`.github/workflows/sync.yml`](.github/workflows/sync.yml) | Brings every repository's copy of the rules up to date, by pull request |

## How a repository is held to the rules

- **`AGENTS.md`** opens with the shared rules, between `BEGIN raine-works/agents` and `END raine-works/agents`
  markers, then has the repository's own. `CLAUDE.md` is a link to it, so Claude Code reads it too. Agents read the
  file in the repository, so the rules work offline and every repository's copy is versioned with its code.
- **Code review**: every pull request is reviewed by Claude (`code-review / review`). When its review of the latest
  commit is done and none of its findings is open, `code-review / approve` approves the pull request as
  `github-actions[bot]`. That's a check of the review's own summary and threads, not something Claude decides or a
  pull request can ask for.
- **Rulesets** on `master`: every change through a pull request, with one approval of its last push and every review
  thread resolved; the review and the repository's own checks must pass, on a branch up to date with `master`. The
  repository's admins can bypass them, only to merge a pull request.
- This repository also needs its owner's review (`.github/CODEOWNERS`): a change here changes every repository's review.

## Changing the rules

Change `AGENTS.md` here, by pull request. Once it's merged, the Sync workflow opens a pull request in every repository
updating its copy; each is reviewed and merged like any other. Never edit the shared block in a repository: the next
sync replaces it.

To change a repository's required checks, change `repos.json` and run `scripts/apply-rulesets.sh <repo>`
(`--dry-run` first to see what it would send).

## Adding a repository

1. Copy `templates/*.yml` into its `.github/workflows/`, filling in its CI workflow's name (`docs-sync.yml`) and its
   checks' setup and commands (`claude.yml`).
2. Install the [Claude GitHub App](https://github.com/apps/claude) and the docs-sync app (`raineworks-doc-sync`) on it.
3. Give it the docs-sync app's credentials:
   `gh variable set DOCS_SYNC_APP_CLIENT_ID -R raine-works/<repo> --body <client id>` and
   `gh secret set DOCS_SYNC_APP_PRIVATE_KEY -R raine-works/<repo> < key.pem`.
4. Make sure Anthropic's workload identity federation rule accepts the repository's OIDC tokens (the Anthropic
   Console: the rule `fdrl_015cLigViCEJyWAtahH5ytSC`).
5. Add it to `repos.json` with its pull request checks (only checks that run on every pull request: a required check
   with a `paths` filter would block every pull request it skips), run `scripts/sync.sh <repo>`, merge that pull
   request and the workflows', then `scripts/apply-rulesets.sh <repo>`.
