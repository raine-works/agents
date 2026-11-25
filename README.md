# agents

Raineworks' shared rules for coding agents, and the reusable workflows every `raine-works` repository runs.
[base.md](base.md) is the one source of the rules. Each repository carries a copy of it in its own file, and keeps
`AGENTS.md` short:

```
.raineworks/base.md   the copy of base.md, never edited there
AGENTS.md             a short section that links to and imports the copy (@.raineworks/base.md), then the repository's own rules
CLAUDE.md  ->         AGENTS.md (a symlink)
```

The `@.raineworks/base.md` line makes Claude Code load the rules with `AGENTS.md`; the link is for other agents and
people.

Edit `base.md` here, through a pull request. Don't edit the copy in another repository: its Base rules check opens the
pull request that updates it, and fails on any difference.

## Adopt the rules in a repository

From the repository's root, run this. Claude copies `base.md` to `.raineworks/base.md`, imports it from `AGENTS.md`,
makes `CLAUDE.md` a symlink to `AGENTS.md`, adds the shared workflows' callers, checks the repository against the
rules, and opens a pull request:

```sh
claude "Fetch skills/raineworks-base/SKILL.md from raine-works/agents with gh api and follow it to adopt Raineworks' base rules in this repository"
```

Run the same thing again to bring an existing copy up to date. Then add the repository to [`repos.json`](repos.json)
and apply its [rulesets](#rulesets).

## Shared workflows

The required workflows (the base rules' "Required workflows") live here, in [`.github/workflows/`](.github/workflows/),
as reusable workflows, so every repository runs the same ones:

| Workflow | Does |
| --- | --- |
| [`check-base.yml`](.github/workflows/check-base.yml) | **Base rules**: the base rules are wired up, every caller is there, and `.raineworks/base.md` is current. On `master` it opens `raineworks/base-sync` with the current copy, and `raineworks/workflows-sync` moving the callers' pins when these workflows change |
| [`code-review.yml`](.github/workflows/code-review.yml) | **Code review**: Claude reviews each pull request against the rules (input `focus`: what matters most in that repository); `approve` approves it once Claude's review of its latest commit has nothing open |
| [`docs-sync.yml`](.github/workflows/docs-sync.yml) | **Docs sync**: after `master`'s CI (or its Base rules check, without CI), Claude fixes docs the new commits made wrong, in a pull request that later runs add to rather than replace (input `docs`) |
| [`rules-audit.yml`](.github/workflows/rules-audit.yml) | **Rules audit**: weekly and when the rules change, Claude audits `master` (including rules in `AGENTS.md` that only repeat `base.md`) and keeps a `rules-audit` issue open while something breaks them; where the repository calls Issue to PR, it labels the issue `claude` (as the docs-sync app) when it's opened or its findings change, so Claude fixes them in a pull request (inputs `rules`, `checklist`) |

Four more are shared but not required:

| Workflow | Does |
| --- | --- |
| [`issue-to-pr.yml`](.github/workflows/issue-to-pr.yml) | **Issue to PR**: an issue the owner opens (or any issue once it's labelled `claude`, or that the owner comments `@claude` on) is worked by Claude into a pull request, which Claude then sees through its checks and Code review's findings until it's approved, with nobody starting it; after five rounds it asks for a person (input `allowed-commands`: the repository's checks). Claude pushes only to its own `claude/issue-<n>` branch and never merges; where it stops for a person it says why and labels the issue or pull request `needs-person`, which `needs-person.yml` here lists daily in one issue |
| [`claude.yml`](.github/workflows/claude.yml) | **Claude**: mention `@claude` in an issue, a comment or a review and Claude answers there (on an open issue, where the repository's Issue to PR caller starts on the mention, that workflow answers instead, with a pull request), or makes the change on a branch, as `claude[bot]` so its branches run the checks (input `allowed-commands`: the commands it may run, a Bun project's by default). Code review leaves replies that mention `@claude` to it |
| [`release-note.yml`](.github/workflows/release-note.yml) | **Release note**: Claude writes a release's note from what changed since the last, when there's something the project's users would notice (otherwise none). In a repository that keeps its notes in a folder (`notes-dir`), it's the next release's, in a pull request; in one that doesn't, it goes on a tag's GitHub release (inputs `name`, `notes-dir`, `version-command`, `check-command`, `tag`, `guide`) |
| [`release-pr.yml`](.github/workflows/release-pr.yml) | **Release pull request**: on every push to `master`, keeps one pull request, `Release v<version>`, open with the next version (major for a breaking change, minor for a `feat`, patch for anything else that ships) written into the version files and what's in it, as the docs-sync app; and the changelog's `## Unreleased` heading renamed to the version, if it has one; merging it is the release, which the repository's own release workflow publishes (inputs `version-files`, `paths`, `ignore`, `changelog`, `name`) |
| [`image-pins.yml`](.github/workflows/image-pins.yml) | **Image pins**: for a repository whose workflows run a container image directly, pinned by digest (`uses: docker://<image>@sha256:<digest> # <tag>, <date>`, such as Home Assistant's hassfest and HACS validators), weekly it asks each image's registry where the tag points now and, when it has moved, opens `raineworks/image-pins` moving the pin, as the docs-sync app (Workflows write); the pull request's checks run the new image, and it merges itself once approved and green |

And three that a repository's CI wires together with its own checks, for one that releases container images
(`raine-works/raineworks`' `ci.yml` is the reference: `plan`, then its checks beside the images, then the release):

| Workflow | Does |
| --- | --- |
| [`release-plan.yml`](.github/workflows/release-plan.yml) | **Plan**: the version the next release takes, each image's inputs, which changed since the last release, which aren't in the registry yet, and whether a push to `master` is a release (inputs `image-prefix`, `version-command`, `notes-check-command`, `plan-command`, `release-if`) |
| [`release-images.yml`](.github/workflows/release-images.yml) | **Images**: builds what the plan says isn't built yet, smoke-tests an image that has a test, and on `master` pushes to the GitHub Container Registry (inputs `images`, `version`, `push`, `rebuild`, `image-prefix`) |
| [`release-publish.yml`](.github/workflows/release-publish.yml) | **Release**: tags every image with the version, `latest` and its commit, tags the repository and publishes its GitHub release, from its note if there is one (inputs `name`, `version`, `services`, `changed`, `image-prefix`, `notes-dir`, `notes-command`, `before-command`, `after-tag-command`) |

Each repository has only a short caller for each, from
[`skills/raineworks-base/templates/workflows/`](skills/raineworks-base/templates/workflows/), pinned to a commit
here. Change a workflow here, through a pull request; the Base rules check in each repository then opens the pull
request that moves its pins. A caller sets its triggers, permissions and inputs, nothing else.

Their checks report as `<caller> / <job>`: `Base rules / check`, `Code review / review`, `Code review / approve`.

When Claude's run fails, the run says why in an error annotation, "Why Claude's run failed" (Code review's own:
"Claude's run failed"): the API's error (`billing_error`, `rate_limit`, `authentication_failed`…) and its message,
which the action's output hides. A run that failed later names only its failure (`error_max_turns`), and a working
run nothing, since their words can hold what Claude's tools read.

What they need, set once per repository:

- **The Claude GitHub App** ([github.com/apps/claude](https://github.com/apps/claude)), installed on every repository
  that calls Code review or Claude: they post, and Claude commits, as `claude[bot]`. Without it they fail with "Claude
  Code is not installed on this repository".
- **The docs-sync GitHub App** (`raineworks-doc-sync`), installed on every repository, with **Contents**, **Pull
  requests**, **Workflows** and **Issues** write (Workflows to move the pins, Issues for the rules audit to hand its
  issue to Issue to PR). Docs sync, the Base rules check's syncs and release notes open their pull requests as it, and
  the rules audit labels its issue as it: what a workflow's own token does starts no other workflow. Each repository
  has its client ID as the `DOCS_SYNC_APP_CLIENT_ID` variable and a private key as the `DOCS_SYNC_APP_PRIVATE_KEY`
  secret, which callers pass on with `secrets: inherit`:
  `gh variable set DOCS_SYNC_APP_CLIENT_ID -R raine-works/<repo> --body <client id>`,
  `gh secret set DOCS_SYNC_APP_PRIVATE_KEY -R raine-works/<repo> < key.pem`.
- **Anthropic workload identity federation**: Claude's steps exchange the job's GitHub OIDC token (`id-token: write`)
  for a short-lived Anthropic one, so there is no Anthropic secret. The federation rule, service account and workspace
  are named in each workflow; the rule (Claude Console) has to accept every repository that calls these. **Actions →
  anthropic-wif-test** ([`anthropic-wif-test.yml`](.github/workflows/anthropic-wif-test.yml)) checks the exchange on
  its own, from this repository.
- **GitHub Actions may approve pull requests** (Settings → Actions → General), for Code review's `approve`:
  `scripts/apply-rulesets.sh` turns it on.

## Rulesets

[`rulesets/`](rulesets/) holds how GitHub protects every repository's `master`, as the JSON GitHub's API takes, and
[`repos.json`](repos.json) lists the repositories with the checks each one's ruleset requires. `raine-works` is a
personal account, which has no organization rulesets, so [`scripts/apply-rulesets.sh`](scripts/apply-rulesets.sh)
applies them to each repository:

| Ruleset | Does |
| --- | --- |
| **Protect master** ([`protect-master.json`](rulesets/protect-master.json)) | no deleting or force-pushing it; changes only by pull request, with one approval of the last push (Code review's `approve` gives it), stale approvals dismissed and every review thread resolved. For this repository, also its code owner's review (`.github/CODEOWNERS`): a change here changes every repository's review |
| **`<repo>` checks** | `Base rules / check`, `Code review / review` and the repository's own pull request checks (`repos.json`) pass (the branch needn't be up to date with `master`) |

The repository's admins (the owner) can bypass both when merging a pull request, never to push. Only list a check that
runs on every pull request: a required check with a `paths` filter never reports on the pull requests it skips, and
blocks them.

Change a file here by pull request, then the owner applies it (rulesets change who can do what, so a person does,
never a workflow):

```sh
scripts/apply-rulesets.sh --dry-run <repo>   # what it would send
scripts/apply-rulesets.sh <repo>             # or every repository in repos.json, with none named
```

It updates each ruleset by name, or makes it. Then remove what the rulesets replace: the repository's old branch
protection (`gh api -X DELETE repos/raine-works/<repo>/branches/master/protection`), if it has any.

## Skills

[`skills/`](skills/) holds the source of Raineworks' skills:

| Skill | Does |
| --- | --- |
| [`raineworks-base`](skills/raineworks-base/SKILL.md) | Adopts or updates the base rules in a repository. [`scripts/sync-base.sh`](skills/raineworks-base/scripts/sync-base.sh) writes the copy, or checks it with `--check`. |

Change them here, through a pull request.

This repository is also a Claude Code plugin marketplace (`.claude-plugin/`), named `raineworks`, whose one plugin,
`raineworks`, carries these skills. Install it with:

```sh
/plugin marketplace add raine-works/agents
/plugin install raineworks@raineworks
```

It has no `version`, so an install follows `master`: every merged change reaches it at the next update. For everyone in
the organization at once, Claude Code's managed settings (the claude.ai admin console's Claude Code settings, or a
`managed-settings.json`) register and turn it on, with updates:

```json
{
  "extraKnownMarketplaces": {
    "raineworks": { "source": { "source": "github", "repo": "raine-works/agents" }, "autoUpdate": true }
  },
  "enabledPlugins": { "raineworks@raineworks": true }
}
```

Add a skill under `skills/<name>/SKILL.md` and the plugin picks it up; no manifest changes.
