---
title: "How the Pull Request is Built"
description: "Not breaking the master branch with your changes."
date: 2018-07-29
slug: how-the-pull-request-is-built
---

A friend of mine contact information mentions that he doesn’t have Facebook or Twitter,
but he is available at a _really cool_ social network — GitHub.
Actually GitHub is a kind of a social network, it even had direct private messages
[until April 2012](https://blog.github.com/2012-04-03-spring-cleaning/#private-messaging).
I remember using them because I had created a profile
[on February 2, 2010](https://api.github.com/users/ming13). Damn, that was a long time ago.

The developer community should be grateful to GitHub not only for
[awesome Octocats](https://octodex.github.com/) but for the popularizing a concept
of pull requests. It is taken for granted now and we tend
to forget that the closest thing before was sending a patch via email.

The evolution continued and the development ecosystem became even better.
A shining beacon of light became a true Helios in a form of easily accessible CI platforms such as
[Travis](https://travis-ci.org/). Putting a YAML configuration file into a repository was
a warp jump ahead of setting up a Jenkins machine — and it still is,
especially for non-enterprise-level-complicated scenarios.

Pull requests and CI work extremely well together.

1. Create a _source_ branch with necessary changes.
1. Open a PR to a _target_ branch — usually the _stable_ branch, such as `master`.
1. CI automagically starts a build.
1. Build status is reported back.
1. Voilà — PR reviewers can see if changes are buildable.
1. Even better — GitHub can block the merge until CI gives a green light.

# The Devil is in the Detail

What exactly CI builds for a pull request? Well, there are two approaches.

* Build the source branch itself.
* Build the merge result of the source branch into the target branch.

Is there a difference though? Let’s take a look at the example.

There is a file named `colors.xml`.

```xml
<colors>
    <color name="white">#fffafa</white>
</colors>
```

Let’s say I need to use it in a brand new UI screen.

```xml
<View
    android:background="@color/white"
    android:layout_width="match_parent"
    android:layout_height="match_parent"/>
```

I create a Git branch, commit changes and open a pull request. But! While the PR
is opened someone had merged the following change.

```diff
-   <color name="white">#fffafa</white>
+   <color name="snow_white">#fffafa</white>
```

This change actually makes sense — `#fffafa` indeed isn’t a white per se,
but [a shade of white](https://en.wikipedia.org/wiki/Shades_of_white#Snow).

Merging the PR with the new screen at this point can break the target branch,
depending on a CI configuration.

* CI builds source branches: CI gives a green light, PR is merged,
  target branch is broken because there is no `white` color referenced by the screen file.
* CI builds merge results: CI gives a red light since there is no `white` color
  on a target branch.

The first situation can be easily resolved in a long run by introducing a _rebase rule_ —
everything should be rebased on the target branch before the merge. In fact
[it can be directly configured for GitHub repositories](https://help.github.com/articles/enabling-required-status-checks/).
Personally I don’t really like this approach since it introduces a tedious
manual procedure for developers.

Fortunately enough Travis (for example) supports both approaches and actually
[applies both of them by default](https://docs.travis-ci.com/user/pull-requests/#double-builds-on-pull-requests).

# Merging on CI

That’s where things start to get really interesting. Turns out Travis
[does not merge source branches to target branches on its own](https://docs.travis-ci.com/user/pull-requests/#my-pull-request-isnt-being-built):

> We rely on the merge commit that GitHub transparently creates between the changes
> in the source branch and the upstream branch the pull request is sent against.

This special reference has a format of `+refs/pull/PR_NUMBER/merge`
and actually can be fetched by anyone. This is actually a great thing since
CI platforms can easily use this reference instead of merging branches on its own.

Unfortunately GitHub considers it as
[an undocumented feature](https://discourse.drone.io/t/github-claims-that-merge-refs-are-undocumented-feature/1100):

> The `/merge` refs that are being used here are an undocumented feature and
> you shouldn’t be relying on them. Because it’s undocumented –
> the behavior might change at any time and those refs might completely go away without warning.
> My recommendation is that if you need a merge commit between the base and head refs,
> you create that merge commit yourself in the local clone instead of relying on merge commits from GitHub.

Just to be sure I’ve contacted GitHub support and received a direct confirmation:

> This remains an undocumented feature and shouldn’t be relied on since it is subject to change at anytime.

Since Travis directly mentiones these references in the documentation but, at the same time,
GitHub declares these as unsupported and unreliable I’ve decided to contact Travis as well and
received a reply with a confirmation of awareness of this dichotomy.

> Regarding this type of reference being unsupported by GitHub,
> you are quite right to notice an implication in the discrepancy between GitHub’s response to you,
> and the needs of the Travis-CI architecture. I would like to assure you
> that Travis-CI and GitHub do have a close relationship with respect to these topics,
> and will continue to work together in the future.

# Keeping Status Up to Date

There is a catch with building merge results. The screen-color example used above
will not be protected from ongoing changes to target branch. Opening a PR
triggers a successful build, after that someone changes the target branch,
whoomp, here it is — it is possible to break the target branch via merging.

This situation might happen because Travis (and CI platforms in general)
[do not rebuild PR branches on changes to target branch](https://github.com/travis-ci/travis-ci/issues/1620#issuecomment-28622720).

# [Bog of the Forgotten](http://godofwar.wikia.com/wiki/Bog_of_the_Forgotten)

Being unlucky enough it is possible to be stuck on a platform without technological
marvels of the future.

Turns out, Travis and basically every SaaS CI platform
does not support Bitbucket Server (do not confuse it with Bitbucket, those are different products).
Fortunately enough Jenkins nowadays is pretty good, especially with
[Multibranch Pipelines](https://wiki.jenkins.io/display/JENKINS/Pipeline+Multibranch+Plugin).

It is possible to define a Jenkins pipeline which will scan Bitbucket merge references
(similar to GitHub ones) once a minute. This solves the keeping-up-to-date issue.
Unfortunately, since we are relying on a time interval to determine outdated branches
and trigger rebuild, it is possible to merge multiple pull requests at once if all of them
had a green light beforehand and the merge is performed in a time window.

BTW Bitbucket merge references [are also unsupported](https://community.atlassian.com/t5/Bitbucket-questions/Difference-of-refs-pull-requests-lt-ID-gt-merge-and-refs-pull/qaq-p/772142):

> I want to point out that this is an internal implementation detail,
> and not part of our API. Anything you build that depends on these files
> may stop working after an upgrade to Bitbucket Server without warning.

# This Is Confusing

Yes, it is.

* Building pull request merge result on CI seems to be a better approach
  than building pull request branch in isolation.
* GitHub and Bitbucket have special references to merge results,
  but they are essentially internal implementation detail with no guarantees.
* CI platforms do not rebuild merge results on target branch changes.

Two thoughts can come to mind.

* No idea how it works for so many people without breaking stable branches all the time.
* I guess the _rebase rule_ is not so bad, eh?

Honestly saying, I don’t really have a universal solution. Since the team I’m working in
gradually moves from Jenkins to [Bitrise](https://www.bitrise.io/) we’ve been forced
to abandon Jenkins time-interval branch scanning. Intead of that I’ve created
a [Ktor](https://ktor.io/)-based server named Bitbroker which listens to Bitbucket Server
for changed branches, searches for pull requests targetting the changed branch
and triggers a pull request rebuild. Since it is specific to a combination
of Bitrise and Bitbucket Server it is not open source, but it can be if anyone
shows an interest.

# Awareness Is the Key

When time comes to a combination of tools there is no silver bullet.
At the same time, it is always possible to evaluate the approach and
address painpoints of the team.

---

PS Title is not really a Futurama reference, but
let’s call it [an inspiration](https://en.wikipedia.org/wiki/Where_the_Buggalo_Roam) :wink:

