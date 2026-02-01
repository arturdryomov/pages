---
title: "The Bus Factor of Zero"
description: "How to maintain projects health in the long run"
date: "2026-01-30"
slug: "bus-factor-of-zero"
---

Onboarding new developers to a team is an opportunity for introspection.
It’s one thing to share tribal knowledge, and another to realize
that the mere existence of such knowledge can be counterproductive.

Recently, I had an opportunity to onboard a new developer to one of our projects.
Fortunately, almost everything went right. In a couple of days, the developer
was able to contribute minor changes to the project, within a couple of weeks, major ones.
Of course, a good portion of this rapid involvement can be attributed to the developer,
but I believe the approaches described below helped a lot.

Is this a perfect formula? Of course not. However, these methods helped the team
maintain the project with minimal effort over time. The new hire’s progress
was a good validation that the team was on the right track.

# Documentation

_How to understand the past and prepare for the future?_

## Note on Location

Documentation should be accessible from the source code repository.
The exact form is a bit tricky.

* When it comes to technical documentation, it’s generally fine to write it
  as files and review the content using a regular change request cycle.
  GitHub and GitLab are great at this.
* Product-related documentation is not so simple. Often, it needs to be reviewed by managers,
  designers, operation specialists, and others. In these cases, it might be easier
  to use a collaboration platform with the ability to comment, such as Google Docs and Confluence.

In any case, accessing documents should be frictionless — URLs should
not be scattered across public and private messaging channels and personal bookmarks.

## [Product Requirement Documents](https://en.wikipedia.org/wiki/Product_requirements_document)

> A product requirements document (PRD) is a document containing all the requirements
> for a certain product. It is written to allow people to understand what a product should do.

PRDs serve as a source of truth for what the business needs from the technical implementation.
Usually, these requirements are reviewed by stakeholders. This provides a high-level picture
that is not tied to a specific technical implementation, although nothing prevents the author
from including technical pointers.

Having PRDs available and in the correct chronological order simplifies understanding
the project quite a bit. A new team member can read through them and see the evolution 
of the product over time. As a bonus, these documents can serve as food for thought —
sometimes even leading to suggestions for improvement.

## [Architectural Decision Records](https://adr.github.io)

> Architectural Decision Record (ADR) can help to understand
> the reasons for a chosen architectural decision, along with its trade-offs and consequences.

ADRs are more focused on technical details than PRDs. These documents are written
by developers for developers. In practice, however, it’s not always trivial
to define what qualifies as an ADR.

* Rewriting a Java service in Go? Yes, that sounds right.
* Moving from batch processing to streaming? Sure.
* Replacing a dependency with a couple of custom functions? Perhaps not?

ADRs help explain the inner workings of the codebase and reduce surprises in the long run.
A team may have made a decision that made total sense to everyone involved at the time,
but to a new hire it might sound questionable. This is where ADRs come in —
by laying out the pros and cons and documenting the reasoning behind trade-offs
in an objective structured manner.

## [Runbooks](https://en.wikipedia.org/wiki/Runbook)

Not talking about [Born to Run](https://en.wikipedia.org/wiki/Born_to_Run_(McDougall_book))!

Runbooks are about operations and observability. Ideally, they wouldn’t even exist —
everything would be resolved automatically and gracefully — but reality is rarely that simple.
PagerDuty describes runbooks well:

> A runbook is a detailed “how-to” guide for completing a commonly repeated task or procedure.
> Runbooks are created to provide everyone on the team — new or experienced — the knowledge
> and steps to quickly and accurately resolve a given issue.

Having issues with database upgrades? Write it down. Partners lose items
in inventory and require manual resolution? Write a script and document how to use it.
The world is full of paper cuts.

# Development

_How to make changes and be confident in their success?_

## Environment

It’s no secret that changes need to be observed, debugged, and tested.
Making this process as frictionless and unintimidating as possible is crucial.
It’s one thing to know that a project runs somewhere,
it’s another to make changes locally and observe their behavior without long deployment cycles.

It’s also important that all dependencies are runnable
in the local environment — databases, caches, configurations, and so on.
Tools like [Development Containers](https://containers.dev) and
[Tilt](https://tilt.dev) help a lot here.

## Tests

Test coverage provides confidence when making changes — the higher it is, the better.
Arguably, aiming for 100% test coverage is a useful goal — it leaves little room
for subjective judgment about what is acceptable to leave untested.
Of course, the 100% coverage does not guarantee correctness, due to the limitations
of coverage metrics. Still, if it raises confidence high enough,
why not let machines do the work?

It’s also important that tests run on every change in their entirety.
This usually means that tests must be fast and stable. Otherwise,
it’s easy to fall into a slippery slope of test avoidance caused
by hour-long runs and flakiness. Tests need to be trusted —
it’s hard to earn that trust and easy to lose it.

## Formatters and Checks

Automated, unified standards make the review flow smoother.
There’s no need to argue about formatting if the style is consistent across the codebase.
Go and its `go fmt` do this well, as does [Black](https://black.readthedocs.io/en/stable/)
for Python. Plenty of time will be spent on renaming variables and functions!

The same applies to detecting common issues. Python type hints are useful,
but without tools like [`mypy`](https://mypy-lang.org) running on every change,
their benefit is minimal. Many classes of problems can be caught automatically
with the right tooling. Utilities like [`pre-commit`](https://pre-commit.com)
can even serve as an umbrella for multiple checks, helping enforce standards and
catch errors before the review.

# One More Thing

A new hire is a positive trigger for introspection. Unfortunately, as layoffs in the industry
become more common, negative triggers are becoming widespread as well.
The bus factor is no longer a theoretical risk.

One moment, the most knowledgeable person on the team is available and ready to help —
the next hour (sometimes literally) there is no one left to ask. At the same time,
systems are becoming more complex. Think of multi-stage [ETLs](https://en.wikipedia.org/wiki/Extract,_transform,_load)
operating on billions of rows, where a single repeated attempt can take hours of compute time.
Now imagine taking over maintenance of such systems without training wheels.

Not long ago, firing key developers was unthinkable. Now it’s a common practice. It’s tough.
Proper approaches can alleviate at least part of this pain for the team.
The important thing to remember is that following them is a marathon, not a sprint.
