---
title: "Abandon Jenkins for Great Good!"
description: "Reducing CI cost (both in time and money) with Bitrise (or anything)."
date: 2018-12-09
slug: abandon-jenkins
---

CI and CD techniques are a part of all good happened to the software development.
Having CI in place means better productivity and higher confidence
in the result of the everyday work. Sounds kind of obvious, right?
Well, let’s take a look at
[the dark side of the Moon](https://en.wikipedia.org/wiki/The_Dark_Side_of_the_Moon).

Do you have a person on the team who occasionally curses Gradle or (and) Maven,
Android SDK or (and) NDK? Maybe someone who knows everything about
these weird Shell scripts you have in the repository? You know, the one
who doesn’t like mentions about broken nightly builds, looks at the `htop`
from time to time? Yeah, the tooling person. The fancy name nowadays
is a Developer Experience Engineer. Right. The question is — do you want to be
this person? No worries — I already know the answer.

# Nope

[This is fine](https://knowyourmeme.com/memes/this-is-fine).
Not a lot of people want to be occupied with fighting constant fires.
It is a special skill of knowing
how things work, preferably from different angles — from Linux kernel IO API
to VCS hooks. The development process involves a lot of tools and issues
might arise from each one of them. Gradle compile times suffer?
Need to profile, compare different Gradle versions, check build scripts,
analyze Java and Kotlin compilers and find out that it was
a [Linux kernel feature](https://lkml.org/lkml/2018/11/19/37) or a SSD failure.
Sounds fun, right? Don’t get me started on how much time these things consume.
Imagine a weird code issue which takes hour after hour and multiply
it by a factor of uncontrolled external tools and environments.

> :warning: I have to note this explicitly — I’m describing a situation related to small teams.
> Big companies have dedicated units to manage all of this and not a single person.

Some people might think it is cool to be that person — the only one who knows
how the toolchain works. Well, it is really not.

* From a personal perspective, it is either a direct ego booster or
  a line into the depression zone (since not a lot of people understand
  the work you do).
* From a team perspective, this situation is
  [a bus factor](https://en.wikipedia.org/wiki/Bus_factor) at least.
  More importantly — a developer occupied by the infrastructure
  is a developer not working on improving the product directly and
  sometimes it is more important than maintaining tech.

I was this person and it felt... strange. One day I’ve caught myself
on a realization that I hadn’t written a single line of product-related code
for a week. That’s when I’ve started to question myself and the work I do.
Does it really matter for the product or for my coworkers productivity?
What is the point of all this? Can it be optimized without losing benefits?

The first part of the solution was
[rethinking UI tests]({{< ref "2018-05-26-androids-dream.md" >}}).
The second one was related to...

# Jenkins

It is perfect for scalable environments. Open source,
plugin system, both declarative and GUI configuration, artifacts storage,
battle-tested, familiar across the board and so much more.

There is a catch though — someone has to maintain it. Even the simplest
setup — with only a couple of plugins — will eventually break
(after a minor version update of course).

* Some Unicode characters in a Git branch name might break a workspace cleanup
  procedure for all jobs since weird internal Java methods do that instead
  of `rm`.
* Fetching a specific Git `refspec` might stop working since `git fetch`
  is done in a weird way.
* Long pull request descriptions might break the cloning procedure because
  _argument list is too long_ or whatever.

Basically every plugin update might break something. At the same time
it is hard to ignore them because a lot include Security Issue warnings.
Frequent security issues is not a good sign for any more or less serious system,
but we’ll leave it for now.

Oh, and do not forget that Jenkins needs to be run somewhere.
Amazon AWS helps but still — someone has to maintain it.
And there is no isolation out of the box. Need to cache something across
jobs? Either install globally (and suffer consequences) or reinvent
a Docker-driven wheel over and over again.

Jenkins is a DIY product — it is the main strength and the main weakness
at the same time.

# Delegate

Human nature pushes us to be responsible for our own lives. At the same time...

> Human beings are generally not capable of managing more than six to ten people,
> particularly when things go sideways and inevitable contingencies arise.
>
> — _[Extreme Ownership](https://www.amazon.com/dp/B00VE4Y0Z2)_

The same can be applied to the tools we use. There is a limit on how many
things a small development team can manage on its own without losing
the primary goal — to improve the business value of a product.

Fortunately enough, talking about CI, there is a variety of options to delegate
this task:
[Travis](https://travis-ci.org/),
[Circle](https://circleci.com/),
[Bitrise](https://www.bitrise.io/) and more.

* The maintenance is done not by a team itself but a dedicated unit.
  Not the same thing as a unit in the same company though —
  it will be necessary to adapt to the CI platform instead of adapting
  the platform for the team. At the same time, there are benefits of a free
  market. Not satisfied with the platform — move to another one.
* Surprisingly it is actually cheaper than having an in-house solution.
  Jenkins does not automatically start and stop itself. That means
  always working server which results in whooping Amazon AWS bills.
  Dedicated services optimize costs via starting and stopping isolated
  containers on demand.

# Bitrise

It was a natural choice for the team because it is the only service that works
with [Bitbucket Server](https://www.atlassian.com/software/bitbucket/server)
([not the same thing as the cloud version](https://confluence.atlassian.com/confeval/development-tools-evaluator-resources/bitbucket/bitbucket-cloud-vs-server)).
Interesting fact — Bitbucket Server support
[was added by an open source contributor](https://github.com/bitrise-io/bitrise-webhooks/pull/67).
It is possible because Bitrise components are [open source](https://github.com/bitrise-io).

[Pricing is reasonable](https://www.bitrise.io/pricing). I like that
the hardware configuration is not hidden away from customers.
At the same time there is an opt-in for Elite machines with better specs.
For some reason a lot of services hide that kind of information and do not
allow to upgrade the hardware. I was told that Linux machines are provided
via Google Compute Engine. Amazon instances for Jenkins costed us $1000
a month, Bitrise Elite costs $360 for basically the same hardware.
Plus no human resources to support Jenkins!

Since Bitrise people understand that caching is important for shorter
build times there is a multi-level configurable caching. For Android projects
basically everything `sdkmanager` provides is bundled into the underlying
Docker image — I haven’t seen a single issue with missing SDK packages.
At the same time, it is possible to reuse files across builds, which can
be adapted to include Gradle build cache, dependencies — you name it.

Of course the configuration is declarative and understandable.
There is no need to be a DevOps to read it.

```yaml
trigger_map:
- tag: "v*"
  workflow: release

workflows:
 release:
    steps:
    - git-clone:
        title: "Clone Git repository."
    - cache-pull:
        title: "Pull cache."
    - script:
        title: "Run."
        inputs:
        - content: "bash ci/jobs/release.sh"
    - deploy-to-bitrise-io:
        title: "Attach artifacts."
        is_always_run: true
        inputs:
        - deploy_path: "artifacts/"
        - is_enable_public_page: "false"
```

The transition from Jenkins to Bitrise was seamless. For a while we used
both in parallel and after a month I’ve quetly shut down Jenkins with no
consequences for the team.

# Adapt

We stumble upon a lot of things every day. The tricky part is habit.
Hitting the same thing over and over again eventually will become familiar.
This can lead to unforeseen consequences — like using Jenkins when it is not
really necessary. Do not be afraid to change things. Mutations and selection
formed the human race as it is right now. Who said it cannot form
the best workflow for the team?

---

Title is a reference to the wonderful
[Lean You a Haskell for Great Good!](http://learnyouahaskell.com/).
