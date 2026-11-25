---
name: raineworks-base
description: Adopt or update Raineworks' shared base rules (base.md from raine-works/agents) in the current repository - copy them to .raineworks/base.md, import them from AGENTS.md, make CLAUDE.md a symlink to AGENTS.md, add the callers of Raineworks' shared workflows (base rules check, Claude code review, docs sync, rules audit, reusable workflows in raine-works/agents) in place of any copies of them, and check the repository against the rules. Use this whenever someone wants a raine-works repository set up with or brought up to date with the base rules or the shared workflows, mentions raineworks-base, .raineworks/base.md or the shared workflows, or a base rules check in CI fails because the copy is out of date or a caller is missing - even if they don't name the skill.
---

# Adopt Raineworks' base rules

Raineworks keeps one set of rules for every repository in `base.md`, in `raine-works/agents`. Each repository carries
a copy of it in its own file, `.raineworks/base.md`, and keeps `AGENTS.md` short: it points to the copy and holds only
the repository's own rules. `CLAUDE.md` is a symlink to `AGENTS.md`, so every agent reads the same file.

```
.raineworks/base.md   the copy: never edited here (the sync overwrites it, the check fails on any difference)
AGENTS.md             title, a short "Raineworks base rules" section that imports the copy, then the repository's own rules
CLAUDE.md  ->         AGENTS.md
```

The `Raineworks base rules` section of `AGENTS.md` reads:

```md
## Raineworks base rules

This repository follows Raineworks' base rules, in [`.raineworks/base.md`](.raineworks/base.md): read them before
changing anything. They're a copy of `base.md` in `raine-works/agents`, kept current by its sync: change them there,
not here. Where this file is more specific, it wins.

@.raineworks/base.md
```

The link is for people and agents that don't follow imports; the `@.raineworks/base.md` line, on a line of its own,
makes Claude Code load the rules with `AGENTS.md` (through the `CLAUDE.md` symlink) without anyone having to open them.

You need `gh`, logged in (`gh auth status`); `raine-works/agents` is public. If it isn't logged in, stop and ask the
person to run `gh auth login`.

## 1. Read the rules, then branch

Fetch `base.md` and read it before changing anything; you're about to work under it, and step 4 needs it:

```bash
gh api -H 'Accept: application/vnd.github.raw' repos/raine-works/agents/contents/base.md
```

Then follow its git rules: start a branch off an up-to-date `master` (`chore/adopt-raineworks-base`, or
`chore/update-raineworks-base` when `.raineworks/base.md` is already there). If the repository's default branch isn't
`master`, don't rename it yourself: tell the person, and carry on from the default branch.

## 2. Wire up `AGENTS.md` and `CLAUDE.md`

- **No `AGENTS.md`:** create one with a `# Agent guidance for <repo>` title, the section above, and a
  `## This repository` section holding the repository's own rules: what it is, its layout, how to build, test and
  release it, and the rules its code already follows that the base doesn't state (read the code, the README, `docs/`
  and CI to find them; write only what you've checked). If `CLAUDE.md` has real content, that content is the
  repository's own rules: move it under `## This repository` before step 3 replaces the file.
- **`AGENTS.md` without the section:** add it after the title and any short intro, before the repository's own rules.

Then make `CLAUDE.md` a symlink: `ln -sf AGENTS.md CLAUDE.md`. Not a copy or an import: a symlink can't drift.

## 3. Write the copy

Run the script beside this file from the repository's root (if you're following this skill from GitHub instead of an
installed copy, fetch `skills/raineworks-base/scripts/sync-base.sh` from `raine-works/agents` the same way as
`base.md`):

```bash
bash <skill dir>/scripts/sync-base.sh
```

It writes `.raineworks/base.md` and exits 2 if `AGENTS.md` doesn't import it or `CLAUDE.md` isn't the symlink. Use it
rather than writing the file yourself: a copy that differs by one character fails the check. `--check` changes
nothing and fails when the copy is out of date, which is what CI runs.

## 3b. Call the shared workflows

The required workflows (the base's "Required workflows") are reusable workflows in `raine-works/agents`; the
repository keeps only a short caller for each, from `templates/workflows/` beside this file (fetch them from
`skills/raineworks-base/templates/workflows/` in `raine-works/agents` if you're following this skill from GitHub):

| Caller | Calls |
| --- | --- |
| `check-base.yml` | the Base rules check |
| `code-review.yml` | Claude code review, which approves a pull request when nothing it found is open |
| `docs-sync.yml` | docs sync, after the repository's CI workflow |
| `rules-audit.yml` | the rules audit, weekly and after the repository's CI workflow |

1. Copy each into `.github/workflows/` under the same name, with `AGENTS_SHA` replaced by `master`'s commit in
   `raine-works/agents`: `gh api repos/raine-works/agents/commits/master --jq .sha`. Change nothing else but the
   inputs and, in `docs-sync.yml` and `rules-audit.yml`, the name of the workflow they follow.
2. **The workflow they follow** is the one that tests a push to `master` (its `name:`, e.g. `Test`, `CI`). Set it in
   both callers' `workflow_run.workflows`. If the repository has none, both follow `Base rules` instead (the Base rules check
   runs on every push to `master`; Claude's action doesn't take `push` events).
3. **Replace any copy** of one of these workflows the repository already has (a `code-review.yml`,
   `claude-review.yml`, `docs-sync.yml`, `check-base.yml`, whatever its name: read the files) with its caller. Before
   you delete one, carry what was specific to this repository into the caller's inputs (`with:`): its review
   checklist into `focus`, the docs it syncs into `docs`, extra rules files into the audit's `rules`, what to search
   the source for into its `checklist`. Anything else it did differently, list in the pull request; don't keep it.
4. Their checks report as `Base rules / check` and `Code review / review`. Once this merges, the owner adds the
   repository to `raine-works/agents`' `repos.json` (with the repository's own pull request checks) and runs
   `scripts/apply-rulesets.sh <repo>`, which makes them required; not before, or every pull request waits on checks
   that don't run yet. Say so in the pull request.

Four more aren't required, and the Base rules check doesn't ask for them. `issue-to-pr.yml` calls Issue to PR: an
issue the owner opens, one labelled `claude` (the rules audit labels its own), or an open issue the owner or a
collaborator comments `@claude` on is worked into a pull request by Claude, which then answers the checks and the
review until it's approved. A caller made before the `@claude` start lacks its trigger: add `issue_comment: types:
[created]` under `on:`, as the template has it (without it, `claude.yml` keeps answering those comments). Set its `workflow_run.workflows` to `[Code review, <the CI workflow's
name>]` (just `[Code review]` without CI) and `allowed-commands` to the repository's checks, and make sure the
repository has a `claude` label (`gh label create claude --description "Claude works this issue"`). `claude.yml` calls the shared @claude
workflow: mention `@claude` in a pull request's comment or review, or on an issue, and Claude answers or makes the
change, as `claude[bot]` (the Claude GitHub App, which Code review needs too). Where `issue-to-pr.yml` starts on it,
a mention on an open issue is Issue to PR's instead. If the repository has its own @claude workflow, replace it with
`templates/workflows/claude.yml` the same way, carrying the commands it let Claude run into `allowed-commands` (unless
they're a Bun project's, the default); otherwise offer it, and don't add it unasked.

`image-pins.yml` calls Image pins, for a repository whose workflows run a container image directly, pinned by digest with the tag and date in a comment (`uses: docker://<image>@sha256:<digest> # <tag>, <date>`): weekly, it opens a pull request moving any pin whose tag has moved. Add it alongside such a pin; otherwise don't.

The last is `release.yml`, the caller of the shared release note workflow (`release-note.yml`), for a repository with
releases. If the repository has its own copy of it, replace it with `templates/workflows/release.yml` the same way,
and otherwise offer it; don't add it unasked. Set `name` to the project's name, then:

- **It keeps its notes in a folder** (an app that shows them): `notes-dir`, `version-command` (prints the next
  release's version) and `check-command` (fails on a malformed note), unless they're raineworks', the defaults. The
  note is opened as a pull request; what merging it does is the repository's own CI's.
- **It doesn't:** nothing else. The note is written for a tag and put on that tag's GitHub release.

Whatever its old workflow told Claude about the notes (who reads them, their format, what never to mention) goes in
`guide`. A repository that releases container images can also call the shared `release-plan.yml`,
`release-images.yml` and `release-publish.yml` from its CI (`raine-works/raineworks`' `ci.yml` is the reference).

`release-pr.yml` calls Release pull request, for a repository that releases when a version in a file changes (a Home
Assistant integration's manifest, with its own release workflow publishing on that): on every push to `master` it
keeps one pull request, `Release v<version>`, open with the next version (major for a breaking change, `type!:`;
minor for a `feat`; patch for anything else that ships) and what's in it, opened as the docs-sync app; merging it is
the release. Add it to such a repository, with `paths` (and `ignore`) set to what ships and `version-files` to every
file that carries the version, when they aren't an integration's (the defaults). A repository with a `CHANGELOG.md`
adds each change's entry under `## Unreleased`, which the pull request renames to the version (`changelog` names
another file). A version that isn't
major.minor.patch (one that follows another project's) can't use it.

What the workflows need set up once per repository (the apps, the variable and the secret, the federation rule) is in
`raine-works/agents`' README, "Shared workflows". This step changes workflow files, so pushing it needs a token with
the `workflow` scope.

## 4. Fit the repository's own rules to the base

Read `## This repository` against `base.md`:

- **Repeats a base rule:** remove it; the base says it now. This is most of what keeps `AGENTS.md` short.
- **Stricter or more specific than the base** (a stack detail, a hardware constraint, a rule about commits): keep it.
  That's what the section is for, and where it's more specific it wins.
- **Contradicts the base** (`main` instead of `master`, unpinned versions): don't resolve it silently either way. Keep
  it, and list it in the pull request for a person to decide.

Keep the rest of the file's wording as it is; this change is about the base, not a rewrite.

## 5. Check the repository against the base, but don't fix it here

Look, and report what you find in the pull request:

- **`master` protected** on GitHub: `gh api repos/<owner>/<repo>/rules/branches/master --jq '[.[].type] | unique'`
  lists every rule that applies to it. It's protected when that includes `deletion`, `non_fast_forward`,
  `pull_request` and `required_status_checks`, which `scripts/apply-rulesets.sh` gives it. Branch protection set the
  old way (`branches/master/protection`) should go once the rulesets are on: say if it's there.
- **`docs/`** folder, with a `docs/README.md` index, and a `README.md` that orients.

Anything missing gets its own pull request later. Offer to do those; don't fold them into this one. Rulesets change
who can do what, so any change to them needs the person's go-ahead.

## 6. Open the pull request

Commit only `.raineworks/base.md`, `AGENTS.md`, `CLAUDE.md` and the workflows step 3b added or replaced, and open the
pull request as the base's "Pull requests and code review" section says, then see it through its checks and review.
The description says:

- which `base.md` commit it copied, and the commit of `raine-works/agents` the callers are pinned to,
- which workflows it replaced with callers, what of each moved into the caller's inputs, and anything it did that the
  shared workflow doesn't,
- which of the repository's rules you removed as repeats, and any that contradict the base,
- what step 5 found missing, and which follow-up pull requests you offered,
- that the owner then adds the repository to `repos.json` and applies the rulesets.

Its Code review check fails on this pull request (it adds the review's own caller, which only runs once it's on
`master`): the owner reviews it and merges it with the bypass. Once it's merged, the repository's Base rules check
keeps `.raineworks/base.md` and the callers' pins current on its own, by pull request.
