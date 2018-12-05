---
title: "Abandon Jenkins for Great Good"
description: "Reducing CI cost (both in time and money) with Bitrise (or anything)."
date: 2018-11-19
slug: abandon-jenkins
---

CI and CD techniques are a part of all good happenned to the software development.
Having CI (at least) in place means better productivity and higher confidence
in the result of the everyday work. Sounds kinda obvious, right?
Well, let’s take a look at
[the dark side of the Moon](https://en.wikipedia.org/wiki/The_Dark_Side_of_the_Moon).

Do you have a person on the team who occasionally curses Gradle or (and) Maven,
Android SDK or (and) NDK? Maybe someone who knows everything about
these weird Shell scripts you have in the repository? You know, the one
who doesn’t like mentions about broken nightly builds, looks at the `htop`
from time to time, tries to throw something out of a window when
someone mentions horrible compile times? Yeah, _the tooling person_. The fancy name nowadays
is a _Developer Experience Engineer_. Right. The question is — do you want to be
this person? No worries — I already know the answer.

# Nope

[That’s fine](https://en.wikipedia.org/wiki/Gunshow_(webcomic)#%22This_is_Fine%22).
Not a lot of people want to be occupied with fighting constant fires.
This is not something being taught at school. It is a special skill of knowing
how things work, preferrably from different angles — from Linux kernel IO API
to VCS hooks. The development process involes a lot of tools and issues
might arise from each and every one of them. Gradle compile times suffer?
Need to profile, compare different Gradle versions, check build scripts,
analyze Java and Kotlin compilers and find out that it was
a [Linux kernel feature](https://lkml.org/lkml/2018/11/19/37) or a SSD failure.
Sounds fun, right? Don’t get me started on how much time these things consume.
Imagine a weird code issue which consumes hour after hour and multiply
it by a factor of uncontrolled external tools and environments.

> :warning: I have to note this explicitly — I’m describing a situation related to small teams.
> Big companies have separate teams to manage all of this and not a single person.

Some people might think it is cool to be that person — the only one who knows
how the toolchain works. Well, it is really not.

* From a personal perspective it is either a direct ego booster or
  a line into the depression zone (since not a lot of people understand
  the work you do).
* From a team perspective this situation is
  [a bus factor](https://en.wikipedia.org/wiki/Bus_factor) at least.
  More importantly — a developer occupied by the infrastructure
  is a developer not working on improving the product directly and
  sometimes it is more important than maintaining tech.

I was this person and it felt... strange. One day I’ve caught myself
on a realization that I hadn’t wrote a single line of product-related code
for a week. That’s when I’ve started to question myself and the work I do.
Does it really matter for the product or for my coworkers productivity?
What is the point of all this? Can it be optimized without losing benefits?

The first part of the solution was
[rethinking UI tests]({{< ref "2018-05-26-androids-dream.md" >}}).
The second one was related to...

# Jenkins

Is is perfect for environments that need to be scaled. OSS, flexible
plugin system, both declarative and GUI configuration, artifacts storage,
battle-tested, familiar across the board and so much more.

There is a catch though — someone has to maintain it. Even the simplest
setup — with only a Git and Pipeline plugins — will eventually fail and break
(after a minor version changes of course).

* Some Unicode characters in a Git branch name might break a workspace cleanup
  procedure for all jobs since weird internal Java methods do that instead
  of `rm`.
* Long pull request description might break the cloning procedure because
  _argument list is too long_ or whatever.
* Fetching a specific Git `refspec` might stop working since `git fetch`
  is done in a weird way.

Basically each plugin update might break something. At the same time
it is hard to ignore them because of _Security Issue_ warnings.
Jenkins is a DYI product — it is the main strength and the main weakness
at the same time.

Oh, and do not forget that Jenkins needs to be run somewhere.
Amazon AWS helps but still — someone has to maintain it.

