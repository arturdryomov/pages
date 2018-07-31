---
title: "How the Pull Request is Built"
description: "Not breaking the master branch with your changes."
date: 2018-07-29
slug: how-the-pull-request-is-built
---

Contact information of a friend of mine mentions that he doesn’t have Facebook or Twitter accounts,
but he is available at a _really cool_ social network called... GitHub.
Actually, GitHub _is_ a social network, it even had direct private messages
[until April 2012](https://blog.github.com/2012-04-03-spring-cleaning/#private-messaging).

The developer community should be grateful to GitHub not only for
[awesome Octocats](https://octodex.github.com/) but for the popularizing a concept
of pull requests. It is taken for granted now and we tend
to forget that the closest thing before was sending a patch via email.

The evolution continued and the development ecosystem became even better.
A shining beacon of light became a true Helios in a form of easily accessible CI platforms such as
[Travis](https://travis-ci.org/). Putting a YAML configuration file into a repository was
a warp jump ahead of setting up a Jenkins machine. And it still is,
especially for non-enterprise-level-complicated scenarios.

Pull requests combined with CI provide a great collaborative experience.

1. Create a _source_ branch with necessary changes.
1. Open a PR to a _target_ branch — usually the _stable_ branch, such as `master`.
1. CI automagically starts a build, the status is reported back.
1. Voilà — PR reviewers can see if changes are buildable.
1. Even better — GitHub can block the merge until CI gives a green light.

# The Devil is in the Detail

What exactly does the CI build for a pull request? Well, there are two approaches.

* Build the source branch itself.
* Build the merge result of the source branch to the target branch.

Is there a difference though? Let’s take a look at the example.

There is a file named `colors.xml` with a color resource named `white`.

```xml
<colors>
    <color name="white">#fffafa</white>
</colors>
```

Let’s say I need to use it in a brand-new screen.

```xml
<View
    android:background="@color/white"
    android:layout_width="match_parent"
    android:layout_height="match_parent"/>
```

I create a Git branch, commit changes and open a pull request. But! When the PR
was being prepared someone had merged the following change.

```diff
-   <color name="white">#fffafa</white>
+   <color name="snow_white">#fffafa</white>
```

It actually makes sense — `#fffafa` isn’t a white per se,
but [a shade of white](https://en.wikipedia.org/wiki/Shades_of_white#Snow).

Merging the PR with the new screen can break the target branch at this point,
depending on a CI configuration.

* CI builds source branches.
    * CI gives a green light, PR is merged,
      the target branch is broken because there is no `white` color referenced by the screen file.
* CI builds merge results.
    * CI gives a red light since there is no `white` color
      on a target branch.

The first situation can be resolved in a long run by introducing a _rebase rule_ —
source branches should be rebased on the target branch before the merge. In fact,
[it can be directly configured for GitHub repositories](https://help.github.com/articles/enabling-required-status-checks/).
Personally, I don’t like this approach since it introduces a tedious
ritual for developers.

There is a catch with building merge results though. The screen-color example used above
will not be protected from ongoing changes on the target branch. Opening a PR
triggers a successful build, after that someone changes the target branch,
whoomp, here it is — it is possible to break the target branch via merging.
This situation might happen because Travis (and CI platforms in general)
[does not rebuild source branches on changes to the target branch](https://github.com/travis-ci/travis-ci/issues/1620#issuecomment-28622720).

# Merging on CI

This is where things start to get really interesting. Turns out Travis
[does not merge source branches to target branches on its own](https://docs.travis-ci.com/user/pull-requests/#my-pull-request-isnt-being-built):

> We rely on the merge commit that GitHub transparently creates between the changes
> in the source branch and the upstream branch the pull request is sent against.

This special reference has a format of `+refs/pull/PR_NUMBER/merge`
and can be fetched by anyone. This is great since
CI platforms can easily use this reference instead of merging branches on its own.

Unfortunately, GitHub considers it as
[an undocumented feature](https://discourse.drone.io/t/github-claims-that-merge-refs-are-undocumented-feature/1100):

> The `/merge` refs that are being used here are an undocumented feature and
> you shouldn’t be relying on them. Because it’s undocumented –
> the behavior might change at any time and those refs might completely go away without warning.
> My recommendation is that if you need a merge commit between the base and head refs,
> you create that merge commit yourself in the local clone instead of relying on merge commits from GitHub.

Just to be sure I’ve contacted GitHub support and received a direct confirmation:

> This remains an undocumented feature and shouldn’t be relied on since it is subject to change at anytime.

Moreover, [merge references are created in an async manner](https://developer.github.com/v3/pulls/#get-a-single-pull-request)
and can be unavailable when a CI platform needs it:

> The value of the `mergeable` attribute can be `true`, `false`, or `null`.
> If the value is `null`, then GitHub has started a background job to compute the mergeability.
> After giving the job time to complete, resubmit the request. When the job finishes,
> you will see a non-`null` value for the `mergeable` attribute in the response.

Since Travis directly mentions these references in the documentation but, at the same time,
GitHub declares those as unsupported and unreliable I’ve decided to contact Travis and
received a reply with a confirmation of awareness of this dichotomy:

> Regarding this type of reference being unsupported by GitHub,
> you are quite right to notice an implication in the discrepancy between GitHub’s response to you,
> and the needs of the Travis-CI architecture. I would like to assure you
> that Travis-CI and GitHub do have a close relationship with respect to these topics,
> and will continue to work together in the future.

BTW Bitbucket has similar references which
[are also undocumented](https://community.atlassian.com/t5/Bitbucket-questions/Difference-of-refs-pull-requests-lt-ID-gt-merge-and-refs-pull/qaq-p/772142):

> I want to point out that this is an internal implementation detail,
> and not part of our API. Anything you build that depends on these files
> may stop working after an upgrade to Bitbucket Server without warning.

# This is Confusing

Yes, it is.

* Building merge results on CI seems to be a better approach
  than building branches in isolation.
* GitHub and Bitbucket have special references for merge results,
  but they are undocumented and unreliable in the long run.
* CI platforms do not rebuild merge results on target branch changes.

Two thoughts come to mind.

* How on Earth does it work for so many people without breaking stable branches all the time?
* I guess the _rebase rule_ is not so bad, eh?

# Conclusions

## Branches vs. Merge Results

The goal of both approaches should be the same — check pull requests
reliability. To achieve this both methods require some actions.

* Enforce source branch rebasing on a target branch when relying on branches.
  It is tedious for developers but it works.
* Create a separate server which will listen to GitHub (Bitbucket, GitLab) events
  and trigger rebuild for source branches on target branch change when relying
  on merge results.

## Travis vs. Jenkins, GitHub vs. Bitbucket

Travis gives the majority of necessary tools to check pull requests.
Unfortunately, it is not available for Bitbucket. Even worse —
sometimes there is a Jenkins instance to maintain.

In such cases, it is advisable to not use merge references and perform
the merge by hand. Yes, it adds an extra operation to maintain,
but it will work in the long run.

## Iterate and Automate

When the time comes to a combination of tools, there is no silver bullet.
At the same time, it is always possible to evaluate the approach and
address pain-points of the team.

Track encountered issues and ask for teammates opinion. People tend
to get used to many things, even to rebasing branches for hours and
closing eyes to broken stable branches. Be better!

---

PS Title is not really a Futurama reference, but
let’s call it [an inspiration](https://en.wikipedia.org/wiki/Where_the_Buggalo_Roam) :wink:

---

Thanks to [Artem Zinnatullin](https://twitter.com/artem_zin) for the review!
