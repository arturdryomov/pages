---
title: "Superior Testing: Stop Stopping"
description: "The introduction to the series of articles about testing. Unfortunately, the required one."
date: 2019-01-27
slug: superior-testing-stop-stopping
---

Let’s start with confessions. The initial idea to kick-off a series of articles
about testing was the shortest article ever. A single phrase. _Just do it_.
I mean, isn’t it obvious that testing is awesome and useful?

Unfortunately, after talking to dozens of developers
I’ve come to the shocking fact that most of them don’t write tests.
_Our customer doesn’t pay for tests_. _We don’t have time_.
_The codebase is impossible to test_. I’ve heard
[these words](https://www.youtube.com/watch?v=EvycNBSQ798) over and over again.

At the same time, I realized that both [Nike](https://en.wikipedia.org/wiki/Just_Do_It) and
[Shia LaBeouf](https://knowyourmeme.com/memes/shia-labeouf-s-intense-motivational-speech-just-do-it)
failed to inspire humanity with the _Just do it_ phrase — who am I to make it happen?
I’ll make arguments instead — ideological and pragmatical.

# Ideology

## Magic

This article forced me to remember the first test suite I wrote.
I think it was a Java practice session at the university.
The task was semi-complex so I decided to struggle with setting up
JUnit instead of running the program again and again to check
its correctness. I’ve spent like half an hour with Maven
(Gradle wasn’t cool then) but in the end
it led to a miracle. I wrote the code, the test, run it in IDE
and... I still remember the picture of the test tree with green dots.
It felt like magic.

> Any sufficiently advanced technology is indistinguishable from magic.
>
> — [_Arthur C. Clarke_](https://en.wikipedia.org/wiki/Clarke%27s_three_laws)

At the end of the session I knew that the code I wrote was correct and
I can check it at any time using tests.
The magic transformed into the confidence. This feeling cannot be bought.

## Empathy

There is [a great talk by Michael Feathers called _Empathy is Code Deep_](https://vimeo.com/293912618/5ccecc85d4).
Please watch it, then come back and continue reading because I’m going to spoil it otherwise.

All right, welcome back! The closing words of the talk are extremely
important for every developer.

> * Code is a way you treat your coworkers.
> * We interact through the things we make.

What is better — having a test or not having a test? The answer is obvious —
any test is better than no tests at all. I think everybody came to this conclusion
eventually, especially being in a need to change a tricky piece of code.
It is certainly not desirable to break something along the way — tests help to avoid that.
Let’s be honest — we are pleased to know that tests are available.

What is the reason behind not writing tests then? Isn’t it opposite of empathy?
It is like not washing dishes — the tableware is still in place but the next person
using it will feel disgusted. Is it really a way people would like to interact with each other?
This makes no sense.

# Pragmatism

## Time

Not gonna lie — there are no terabytes of raw data to prove this,
but I’m certain that tests save development time.
This includes both long-term metrics like maintenance and short-term like code-compile-run.

Long-term benefits are obvious. More checks available — less time stumbling in the dark.
Savings grow exponentially with the code complexity. Just imagine a newbie
taking a grip on the codebase. Is it safer to ask him to make changes
in a component with tests or in another one without them?
I guess this is a rhetorical question...
At the same time, a new person would adapt better when tests are available —
tests improve confidence in the ability to not break things.

Short-term benefits are arguable, but let’s do the math with hypothetical numbers
for Android platform.

Step          | Application | Test       | Description
--------------|-------------|------------|----
Assemble      | 1 minute    | 40 seconds | Tests don’t need DEX files.
Install       | 10 seconds  | 1 second   | Tests don’t need APK transfer and installation.
Check         | 30 seconds  | 1 second   | Tests don’t need manual clicking and comparison.

140 vs. 42 seconds. I. e. manual checks consume ×3.3 more time than tests.
Let’s multiply it by an approximate number of changes a developer makes daily — like, 50.
Tests might save 1 hour 20 minutes a day! Crazy, right? Yep, I know numbers are from my head,
but I can vouch that savings are real.

## Maintenance

I’m going to cheat and avoid explaining how it is possible to fight
the codebase to make it testable. Why? Because it is a solved problem.

Michael Feathers (the author of the talk I’ve mentioned earlier)
wrote a wonderful book called
[_Working Effectively with Legacy Code_](https://www.amazon.com/dp/0131177052).
Don’t let the name fool you. The book is actually about maintaining all codebases,
primarily focusing on tests. It is named this way because the author calls legacy code
a code without tests.

I wish everyone reads this book at the beginning of a software developer career.
Take a look at this piece:

> Well, here’s a news flash: requirements change.
> Designs that cannot tolerate changing requirements are poor designs to begin with.
> It is the goal of every competent software developer to create designs that tolerate change.
>
> ...
>
> Code without tests is bad code. It doesn’t matter how well written it is;
> it doesn’t matter how pretty or object-oriented or well-encapsulated it is.
> With tests, we can change the behavior of our code quickly and verifiably.
> Without them, we really don’t know if our code is getting better or worse.

The book covers every topic related to _I cannot write tests because..._
Take a look at [the TOC](https://www.oreilly.com/library/view/working-effectively-with/0131177052/#toc-start) —
chapter names are direct pointers to solutions:

* Dependencies on Libraries Are Killing Me;
* I Need to Change a Monster Method and I Can’t Write Tests for It;
* We Feel Overwhelmed. It Isn’t Going to Get Any Better.

Seriously, almost every technical issue related to making things testable is covered in the book.

## Money

All right, this is a hard one. The most popular excuse I’ve heard is simple
and insanely forgiving for all participants. _The customer doesn’t pay for tests_.
What is the silver bullet for asking a customer for permission to write tests?
Prepare for the hard truth. There isn’t one. In fact, the question should not
be even asked in the first place.

Customers ask providers for a quality product. I don’t know a single person
who wants a crappy product. _Give me a glass of your crappiest wine, please_.
Sure. We, as providers of software, should provide a quality product.
The quality is controlled by expected behavior which should be checked, i. e. tested.
[Professionals have standards](https://wiki.teamfortress.com/wiki/Meet_the_Sniper).

# Reality

I’ve spent a lot of time writing tests. I do it every day. Honestly saying,
it is one of these things that keep me going. Tests are a way to automate our
actions. Not every industry allows to do that — it is either expensive or unreal.
We have it at our disposal and yet we tend to forget about it.
Testing brings magic, confidence and empathy. It saves time and money.
Just do it.

---

Superior in the name of the series is a reference to
[Superior Iron Man](https://marvel.fandom.com/wiki/Superior_Iron_Man_Vol_1_1)
and
[Superior Spider-Man](https://marvel.fandom.com/wiki/Superior_Spider-Man) series.
