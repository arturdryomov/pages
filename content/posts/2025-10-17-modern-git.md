---
title: "Modern Git for Modern Times"
description: "Modern problems require modern solutions"
date: "2025-10-17"
slug: "modern-git"
---

Git has been around for a long time — since April 2005. That’s 20 years!
Fun fact — [Bazaar](https://en.wikipedia.org/wiki/GNU_Bazaar) and
[Mercurial](https://en.wikipedia.org/wiki/Mercurial) were released around the same time as Git.
Not so fun facts — during this time
[Atlassian removed the Mercurial support from Bitbucket](https://www.atlassian.com/blog/bitbucket/sunsetting-mercurial-support-in-bitbucket)
and [Canonical retired Bazaar altogether](https://discourse.ubuntu.com/t/phasing-out-bazaar-code-hosting/62189).
Meanwhile, GitHub and GitLab are alive and well — safe to say, Git is here to stay.
In fact, we might see [Git 3.0](https://git-scm.com/docs/BreakingChanges#_git_3_0) soon — a new version for the new decade.

But what about new features? Surely there’s something useful for day-to-day workflows, right?

# Switch Branches

`git checkout` does the trick — but it’s much more than a branch switching tool.
Take a look at [the `man` page](https://git-scm.com/docs/git-checkout):

> Updates files in the working tree to match the version in the index or the specified tree.
> If no pathspec was given, `git checkout` will also update `HEAD` to set the specified branch as the current branch.

Kinda a mouthful, right?
`git switch` is an alternative with a more focused scope.
Take a look at [the `man` page](https://git-scm.com/docs/git-switch):

> Switch to a specified branch. The working tree and the index are updated to match the branch.
> All new commits will be added to the tip of this branch.

Simple and straightforward! To switch a branch (FYI — it auto-tracks remote branches):

```console
$ git switch BRANCH
```

To create and switch a branch in one go:

```console
$ git switch --create BRANCH
```

> :information_source: `git switch` is experimental from [v2.23](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.23.0.adoc) (August 2019),
> stable from [v2.51](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.51.0.adoc) (August 2025).

# Push Branches

Attempting to push a local branch results in a helpful message:

```console
$ git push BRANCH

fatal: The current branch BRANCH has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin BRANCH

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.
```

Git advertising [a new feature](https://git-scm.com/docs/git-config#Documentation/git-config.txt-pushautoSetupRemote)? Amazing!
Unfortunately, with all the noise these days, it's easy to miss.
It does work though — changing the config instructs Git to set upstream on its own:

```console
$ git config --global push.autoSetupRemote true
```

> :information_source: `push.autoSetupRemote` is available from [v2.37](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.37.0.adoc) (June 2022).

# Compare Changes

`git diff` is good, but it can be better — especilly when it comes to the _move_ kind of changes.

There is [a diff option](https://git-scm.com/docs/git-config#Documentation/git-config.txt-diffcolorMoved) for this, disabled by default:

```console
$ git config --global diff.colorMoved true
```

When configured, the diff output uses different colors to highlight moved content —
magenta (`tput` color #5) instead of red (#1) and cyan (#6) instead of green (#2).
Additions and deletions keep their usual red and green colors.

The option accepts [multiple modes](https://git-scm.com/docs/git-diff#Documentation/git-diff.txt---color-movedmode).
`dimmed-zebra` might be a good one — it dims _moves_, which might be not super important most of the time.

> :information_source: `diff.colorMoved` is available from [v2.15](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.15.0.adoc) (October 2017).

# Restore Changes

Restoring changes can be done with `git checkout` (as is switching branches and much more).
Following the same idea behind `git switch`, `git restore` is a simpler alternative.
Take a look at [the `man` page](https://git-scm.com/docs/git-restore):

> Restore specified paths in the working tree with some contents from a restore source.
> If a path is tracked but does not exist in the restore source, it will be removed to match the source.

To restore a file to its committed state:

```console
$ git restore PATH
```

Also take a look at `--staged` and `--worktree` arguments when dealing with more complex scenarios.

> :information_source: `git restore` is experimental from [v2.23](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.23.0.adoc) (August 2019),
> stable from [v2.51](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.51.0.adoc) (August 2025).

# What’s Next?

[The _How Core Git Developers Configure Git_ article](https://blog.gitbutler.com/how-git-core-devs-configure-git)
from the GitButler folks is a great read — it explores which options might be worth to have enabled by default.

New commands like `git switch` and `git restore` are easier for Git newbies to understand.
Not everyone has been using Git for 15+ years and is familiar with all `git checkout` nuances.

All in all, it’s amazing to see Git continue to grow and evolve. Here’s to the next 20 years!
