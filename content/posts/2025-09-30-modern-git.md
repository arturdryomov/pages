---
title: "Modern Git for Modern Times"
description: "TBD"
date: "2025-09-30"
slug: "modern-git"
---

Git was around for a long time — since April 2005. 20 years!
Fun fact — [Bazaar](https://en.wikipedia.org/wiki/GNU_Bazaar) and
[Mercurial](https://en.wikipedia.org/wiki/Mercurial) were released almost at the same time as Git.
Not so fun facts — during this time
[Atlassian removed the Mercurial support from Bitbucket](https://www.atlassian.com/blog/bitbucket/sunsetting-mercurial-support-in-bitbucket)
and [Canonical outright retired Bazaar](https://discourse.ubuntu.com/t/phasing-out-bazaar-code-hosting/62189).
Given that GitHub and GitLab are alive and well, it can be said that Git is here to stay.
In fact, we might see [Git 3.0](https://git-scm.com/docs/BreakingChanges#_git_3_0) soon. A new version for the new decade...

But what about new features? There must be some useful ones for day-to-day workflows, right?

# Switch Branches

`git checkout` does the trick but it’s much more than a branch switching tool.
Take a look at [the `man` page](https://git-scm.com/docs/git-checkout):

> Updates files in the working tree to match the version in the index or the specified tree.
> If no pathspec was given, `git checkout` will also update `HEAD` to set the specified branch as the current branch.

Kinda a mounthful, right?
`git switch` is an alternative with a focused scope.
Take a look at [the `man` page](https://git-scm.com/docs/git-switch):

> Switch to a specified branch. The working tree and the index are updated to match the branch.
> All new commits will be added to the tip of this branch.

Simple and straightforward! To switch a branch (FYI — it auto-tracks remote branches):

```console
$ git switch BRANCH
```

To switch and to create a branch at the same time:

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

Git advertises [a new feature](https://git-scm.com/docs/git-config#Documentation/git-config.txt-pushautoSetupRemote), amazing!
Unfortunately we are drowned in noise these days so it’s easy to overlook it.
It works though — changing the config instructs Git to set upstream on its own:

```console
$ git config --global push.autoSetupRemote true
```

> :information_source: `push.autoSetupRemote` is available from [v2.37](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.37.0.adoc) (June 2022).

# Compare Changes

`git diff` is good, but it can be better. In particular, when it comes to the _move_ kind of changes.

There is [a diff option](https://git-scm.com/docs/git-config#Documentation/git-config.txt-diffcolorMoved), disabled by default:

```console
$ git config --global diff.colorMoved true
```

When configured, the following diff will have different colors —
magenta (`tput` #5) instead of red (`tput` #1) and cyan (`tput` #6) instead of green (`tput` #2).
Of course, additions and deletions will have regular (red and green) colors.

```diff
import (
-   "context"
    "math"
+   "context"
)
```

The option accepts [multiple modes](https://git-scm.com/docs/git-diff#Documentation/git-diff.txt---color-movedmode).
`dimmed-zebra` might be a good one — it dims such changes (and _moves_ might be not that important in general).

> :information_source: `diff.colorMoved` is available from [v2.15](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.15.0.adoc) (October 2017).

# Restore Changes

Restoring changes can be done with `git checkout` (as is switching branches and much more).
Following the same idea behind `git switch`, `git restore` is an alternative.
Take a look at [the `man` page](https://git-scm.com/docs/git-restore):

> Restore specified paths in the working tree with some contents from a restore source.
> If a path is tracked but does not exist in the restore source, it will be removed to match the source.

To restore a file to its commited state:

```console
$ git restore PATH
```

Also take a look at `--staged` and `--worktree` arguments when dealing with more complicated scenarios.

> :information_source: `git restore` is experimental from [v2.23](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.23.0.adoc) (August 2019),
> stable from [v2.51](https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.51.0.adoc) (August 2025).

# What’s Next?

[The _How Core Git Developers Configure Git_ article](https://blog.gitbutler.com/how-git-core-devs-configure-git)
from GitButler folks is a good exploration on what options might be useful to be enabled by default.

New commands — `git switch` and `git restore` — are easier to comprehend to Git newbies.
Not everyone used Git for 15+ years and is familiar with `git checkout` nuances.

Overall though — it’s amazing to see Git grow and be used for so long. Here’s to the next 20 years!
