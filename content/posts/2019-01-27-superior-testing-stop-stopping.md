---
title: "Superior Testing: Stop Stopping"
description: "The introduction to the series of articles about testing. Unfortunately, the required one."
date: 2019-01-27
slug: superior-testing-stop-stopping
---

Let’s start with confessions. The initial idea to kick-off a series of articles
about testing was the shortest article ever. A single phrase. _Just do it_.
I mean, isn’t it obvious that testing is awesome and useful?

Unfortunately, after interviewing and talking to dozens of developers
I’ve come to the shocking realization that most of them don’t write tests.
_Our customer doesn’t pay for tests_, _We don’t have time_,
_The codebase is impossible to test_. I’ve heard these words over and over again.
All of these are not really arguments, [just excuses](https://www.youtube.com/watch?v=EvycNBSQ798).

At the same time I realised that both [Nike](https://en.wikipedia.org/wiki/Just_Do_It) and
[Shia LaBeouf](https://knowyourmeme.com/memes/shia-labeouf-s-intense-motivational-speech-just-do-it)
failed to inspire the humanity with the _Just do it_ phrase — who am I to make it happen?
I’ll make detailed arguments instead — ideological and pragmatical.

# The Magic

This article forced me to remember the first test suite I wrote.
I think it was a Java practice session at the university.
The task was semi-complex so I decided to struggle with setting up
JUnit tests instead of running the program again and again to check
correctness. I’ve spent like half an hour juggling dependencies but
after that there was a miracle. I wrote the code, the test, run it in IDE
and... I still remember the picture of the test tree with green dots.
It felt like magic.

> Any sufficiently advanced technology is indistinguishable from magic.
>
> — [_Arthur C. Clarke_](https://en.wikipedia.org/wiki/Clarke%27s_three_laws)

At the end of the session I’ve shown test results instead of a regular program run.
Public perception didn’t matter for me though — I knew that the code I wrote was correct and
I can check it at any time. The magic transformed to the confidence.

# The Empathy

There is [a great talk by Michael Feathers called _Empathy is Code Deep_](https://vimeo.com/293912618/5ccecc85d4).
Please watch it, then come back and continue reading because I’m going to spoil it for you otherwise.

All right, welcome back! I hope you remember closing words which are extremely
important for every developer on the planet.

> * Code is a way you treat your coworkers.
> * We interact through the things we make.

What is better — having a test for not having a test? The answer is obvious —
any test is better than no tests at all. I think everybody came to this conclusion
eventually, especially being in a need to change a tricky peace of code.
It is certainly not desirable to break something along the way — tests help to avoid that.

What is the reason behind not having tests then? Isn’t it an opposite of empathy?
It is like not washing dishes — the tableware is still in place but the next person
using it will feel disgusted. Is it really a way people would like to interact with each other?
This makes no sense.
