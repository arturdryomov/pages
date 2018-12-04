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
