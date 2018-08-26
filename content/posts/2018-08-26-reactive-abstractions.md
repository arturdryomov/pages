---
title: "Reactive Abstractions in Android World"
description: "Platform interactions can be abstracted and tested — who knew?"
date: 2018-08-26
slug: reactive-abstractions-in-android-world
---

Nobody knows how many test suites were not created because of a classic argument.

> It cannot be tested — it uses a platform call!

Well, it actually depends. Testing something that only human eye and neural networks
can catch — like animations and transitions — totally doesn’t make a lot of sense.
On other hand, retrying a network request on re-established connection
can and should be tested. And it is possible to gain a couple of perks on the way here.

# Theory

The first advice I can give to Android developers regarding testing —
start thinking about the codebase as a platform-agnostic environment.
But not in a ridiculous way but a more pragmatic one — otherwise it is too
simple to slip onto a dark cross-platform path.

The second one — embrace the platform and abstractions you have on hand.
This article will be based on RxJava usage but it is possible to replace it
with `Future`, `Promise`, Kotlin coroutines or just a barebones thin layer.

Like it or not — platform interactions leak into business logic decisions.
Hopefully everyone understands that it is essential to test the logic
of the final product — otherwise there will be no product at all.

# Practice
