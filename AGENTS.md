# Raineworks agent rules

The rules every agent (and person) follows in every `raine-works` repository. They live in
[raine-works/agents](https://github.com/raine-works/agents) and are synced into the top of each repository's
`AGENTS.md`: change them there, by pull request, never in a repository's copy. Below them, each repository's `AGENTS.md` has its own
rules; where the two differ, the repository's own rule wins, and where it's stricter, follow it.

## Working in a repository

- Read the repository's own rules (below these) and the docs they point to before changing an area.
- Commit and push only when the person you're working with asks, and only to a branch: never to `master`, never with
  `--force` to a branch someone else is using.
- Never commit secrets: tokens, keys, passwords, `.env` files (an `.env.example` is fine), private hostnames or
  addresses, personal details. If one was committed, say so; don't just delete it in a later commit.
- Keep the docs true: a change that makes a doc wrong updates it in the same pull request. Each fact lives in one doc;
  link to it rather than repeat it.
- New behaviour and fixed bugs get tests, where the repository has tests. Run its checks before you push.
- Report what happened, not what you hoped: a failing test, a skipped step or an unverified claim is said plainly.

## Pull requests and code review

Every change reaches `master` through a pull request. A pull request isn't done when it's opened.

1. Open it with a description of what changed, why, and how it was tested (the real results).
2. **Wait for every check and the code review to finish** (`gh pr checks <number> --watch`): the repository's CI and
   Claude's code review (the `review` check). Don't report the pull request ready while any is running. If none start,
   find out why (a merge conflict stops them).
3. **Handle everything they raise.** Fix each failing check. For each review finding, fix it in a new commit, or, when
   it's wrong, reply in its thread saying why. Never leave a finding unanswered, and never resolve one yourself: the
   review resolves its own threads once it sees them fixed or answered.
4. Push the fixes and wait again. Repeat until every check passes and the review has nothing open.
5. Only then say it's ready, with what the checks and the review found and what you did about each.

- When the review has nothing open on the latest commit, it approves the pull request: that's the approval `master`
  requires. Pushing again dismisses it, and the next review gives it again.
- Agents never merge a pull request. The owner merges.
- Never skip, disable or weaken a check, a review or a ruleset to get a pull request through.
- If `master` moves, bring it into the branch and resolve the conflicts; if it already contains the change, say so
  instead of merging a duplicate.
- A pull request that changes `.github/workflows/code-review.yml` can't be reviewed by Claude (only `master`'s copy
  runs): its review fails on purpose, and a person reviews it. Change the review workflow in a pull request of its own.

## Workflows and automation

- Pin every action to a full commit SHA, with its version in a comment.
- Give each workflow and job the least permissions it needs. Claude, in a workflow, never gets a token or a tool beyond
  its job.
- Releases, version tags and deploys are made by CI. Never tag, publish or deploy by hand; bump versions only as the
  repository's own rules say.

## Writing

- Plain words, sentence-case headings, short paragraphs.
- Commit messages and pull request titles say what changed; their bodies say why.
