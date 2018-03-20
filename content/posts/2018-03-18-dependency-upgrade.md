---
title: "The Art of a Dependency Upgrade"
description: "A walk to a technical marvel without breaking a leg or two."
date: 2018-03-18
slug: art-of-a-dependency-upgrade
---

[RxJava](https://github.com/ReactiveX/RxJava) `1.x` reaches EOL on March 31, 2018,
meaning no further development. That’s not surprising since the `1.x` was
in a bugfix-only mode since June 1, 2017.

This is an interesting event in a software lifetime, since not so many libraries
actually live and prosper long enough to produce a superior version, at the same time handling
support for an older version for so long. Fortunately enough, RxJava is one of these lucky projects
with maintainers actually caring about users.
Thank you, RxJava maintainers, you are [real human beings and real heroes](https://www.youtube.com/watch?v=-DSVDcw6iW8).

RxJava `1.x` → `2.x` serves as a good example of a _major_ dependency upgrade.
Developers actually update dependencies pretty frequently, but that’s mostly the case with _minor_ upgrades,
when things are (usually) nice, cozy and feel like a walk in a park.
Major upgrades can change API drastically.

Another example of such an upgrade is [Retrofit](https://github.com/square/retrofit/) `1.x` → `2.x` —
basically, everything was reworked, repackaged and restructured. Good times.
This kind of change can (and actually will) break your code if the upgrade was reckless.
It gets worse with medium-to-large teams and corresponding codebases.

After doing a bunch of impactful upgrades — including RxJava, Retrofit, Spek, Mockito —
I’ve pointed out a couple of patterns which might help with major dependency upgrades.
These suggestions can be applied to internal refactorings as well — this proved to be
the case with removing Dagger from the project, but that’s another story.

# Asking the Right Question

> Are you sure?

That’s the first question you should ask yourself before migrating to a new shiny dependency.
Actually, you will answer this not only to yourself but to your management, since such
migrations usually consume a considerable amount of time which can be spent on evolving
a product from the consumer perspective.

Let’s split this vague question to simpler ones.

* What benefits the migration will bring to the table?
* How much time will it take?
* How will it affect the development process?

Answers like _the new one is just better_ do not work in real life.

Our example --- the RxJava upgrade --- unfortunately has a huge impact on a project,
especially if it is practically based on RxJava and every component uses it one way or another.

* There are some performance benefits, but the previous version is fine.
* It will most likely take a huge amount of time (don’t forget to double it taking tests into account).
* Developers have to adapt to new rules (no `null` usage at all is the biggest one).
* Errors you make will most likely rise in runtime.

It is always easier to sell huge performance boosts or improved development experience.
Know all pros and cons. The truth might be harsh. Every developer wants to have nice new things,
but when your backlog is filled with product-oriented tasks the reality kicks in.

# Know Your Enemy

* Take a closer look at changes and get really familiar with them.
  Prepare to become a person who will be addressing all rising questions and issues,
  at least in the beginning.
* Open a text editor of choice and start working on your RFC.
  Put all pros and cons there, as well as a high-level changes overview.
  You will be surprised, but not everyone on your team knows all details as well as you do.
* Think about scheduling a meeting or something similar where you can set up
  an improvised QA session. You will be surprised again, but your RFC might be
  not as clear as you’ve imagined it in your mind.

At this point, you might ask yourself an interesting question.

> Why bother with all this team communication? I can upgrade everything myself!

The answer is... teamwork!

* Your changes will affect the codebase and the development process.
* Everyone on the team will review your changes (hopefully), so it is always better to be on the same page.
* As a bonus, there might be interesting thoughts or points you haven’t considered yourself.

For example, RxJava brings [a huge amount of changes](https://github.com/ReactiveX/RxJava/wiki/What's-different-in-2.0).
The most notorious one is throwing the `NullPointerException` if a stream has `null` value in it.
This amount of changes will affect everyone on your team, especially if you use RxJava heavily.

Retrofit might be simpler in that regard even though [changes are not so small](https://github.com/square/retrofit/blob/master/CHANGELOG.md#version-200-2016-03-11).
The reason is simple — scope of the dependency. Retrofit affects your network layer, but not every developer
actually needs to know how network calls work if you have proper abstractions in place.

# Brace for Impact

Take a step back. Look at the bigger picture. Do you see some patterns here and there? Good.

The thing is, some preparation actions can be done beforehand. As I’ve mentioned before, RxJava `2.x`
does not allow `null` values in streams. You already can refactor the code to prepare for that,
most likely using [some kind of `Optional` values](https://github.com/gojuno/koptional).

Using the Retrofit example `RequestInterceptor` was replaced with OkHttp `Interceptor`.
It is possible to do the refactoring using the Retrofit `1.x` doing no harm at all.

Be pragmatic, it helps! Like, in life!

# Don’t be a Hero

The obvious approach is to make a huge refactoring, but if you have such thoughts
better take a deep breath and save your soul before it’s too late.

* Code review of a huge refactoring is essentially a huge Skip button.
  No one on the planet is capable of thinking clearly about something affecting basically everything.
* Since some non-deterministic conditions can lead to runtime errors
  a global refactoring is far too dangerous to do in one sitting.
  Plus your QA department (if you have one) will not be happy to do a full regression.
  Since it is not focused some edge cases might become broken and be easily missed
  even for an experienced eye.

## Brick by Brick

Do the migration gradually. Even better — pick the area of the project with the least impact
and do experiments there. Is is extremely trivial to do so with RxJava. Pretty much
the same can be done with Retrofit — just move a subset of API declaration
to another `interface` and you are ready to go. Live with the migrated subset
for a couple of releases, take a look at metrics (the most trivial one is the crash rate)
and refine your approach. This is not a sprint but a marathon. You should have
a single goal in mind — maintain the product quality at all costs.

## Side by Side

The gradual migration requires different artifacts and package names to avoid conflicts.
[Jake has this topic covered pretty well](http://jakewharton.com/java-interoperability-policy-for-major-version-updates/).
Both RxJava `2.x` and Retrofit `2.x` actually apply this policy, allowing using two versions of a library
in parallel. Some libraries do not follow it though. In such cases, I suggest to repackage
the previous version using a custom package name and publish a local artifact. This way you can just remove
the old artifact after the migration is done.

## Less is More

Another word of advice related to the gradual migration is following the hierarchy from the bottom to the top level.
For example, let’s imagine your project has two virtual layers: service and presentation.
A single service can provide data to multiple presentation components. What would you migrate first?
Yep, the least impactful component, i. e. a single presentation component. This way you can gradually
apply changes. An alternative would be to change a service, but this way you are affecting all components you have.

# Celebrate!

Got to say this. The most satisfying part of a long-running migration is deleting obsolete dependencies
and realizing that the project works totally fine without them. This is an awesome feeling!

---

Title is a reference to [The Art of War](https://en.wikipedia.org/wiki/The_Art_of_War) and, of course,
to [The Deadpool’s Art of War](http://marvel.wikia.com/wiki/Deadpool%27s_Art_of_War_Vol_1).

---

Thanks to [Artem Zinnatullin](https://twitter.com/artem_zin) for the review!
