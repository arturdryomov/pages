---
title: "Acceptance Criteria Bureaucracy"
description: "Organizing the development process with a sweet boring documentation."
date: 2019-01-20
slug: acceptance-criteria-bureaucracy
---

Cooperation! It sure sounds better than bureaucracy.
A released product is a result of cooperation between the Business and the Tech.
There is an obvious issue though. Both sides have different mindsets.
The misunderstanding is inevitable. How do we solve this?
Well, there are still wars on the planet so apparently humanity wasn’t able to find a solution.

What about establishing not world peace
but a good communication channel? Agile methodologies establish such artifact as
Acceptance Criteria (AC). AC is a specification for how the product should work.
Sounds good and the motivation is solid, but there is a catch —
there are no explicit requirements. AC can consist of memes and be distributed by birds —
the sky is the limit (literally). Let’s take a look at the evolution and
trace our path to the bureaucracy nirvana.

# Stone Age

AC are exchanged as a bunch of text.
Let’s face it — a lot of teams deal with this on a regular basis.
The file format might be as basic as `.txt` or as fancy as `.pdf` —
it doesn’t change the picture.
This is ridiculous but it actually works.
At the same time, it is sad that so many people are forced
to work with this format.

The multiplier for everything bad
related to this approach is a potential lack of a centralized
source of truth. Email messages might be used instead.
A nightmare, but it is workable.

```
There is the Infinity Gauntlet. It requires Infinity Gems to work.

* 5 gems are in place: it is possible to erase half of the universe via finger snapping.
* 1—4 gems are in place: the behavior is inherited from available gems.
* 0 gems are in place: nothing happens.
```

Believe it or not, this is a pretty good AC. It is possible to start the development using it.

# Bronze Age: Formalization

AC tend to grow. Just like flowers. Or global nuclear arsenal. Your pick.

Organizing a good amount of text is never easy. This is where
[formal specifications](https://en.wikipedia.org/wiki/Formal_specification#Software_tools)
come into play. There is a number of methods to transform a wall of text
into a step-by-step guide. I’ve heard about:

* writing conventions (do not scale with a number of people involved);
* syntax and DSL (usefulness depends on discipline);
* block diagrams (awesome but might not be practical);
* nothing (anarchy at its core).

The middle ground is defining a syntax
and following it. This way non-technical people are able to read and write
AC and technical people feel more comfortable since it looks and feels like
a barbaric programming language. Fortunately enough [Cucumber](https://cucumber.io/)
already defined such syntax named [Gherkin](https://docs.cucumber.io/gherkin/reference/).

```gherkin
Feature: Infinity Gauntlet

  Given 5 gems are in place
  When fingers are snapped
  Then erase half of the universe

  Given 1—4 gems are in place
  When gem-specific intent is performed
  Then perform gem-specific action

  Given 0 gems are in place
  When any intent is performed
  Then do nothing
```

Much better. Attentive readers might notice that the declaration enforced us
to explicitly describe when actions are actually performed. This was missed
in the original text-based AC. Actually, I’m thinking right now what should be done
on non-snap when 5 gems are in place...

# Iron Age: Sharing

Hopefully, at some point people involved in the process start to understand
that email-based sharing is a no-go.
[Jira](https://www.atlassian.com/software/jira) is the obvious replacement.
It even has [a dedicated input field for AC](https://www.atlassian.com/blog/jira-software/8-steps-to-a-definition-of-done-in-jira)!

Jira is far better than exchanging emails but it falls short in a couple of areas.

* Duplication. There are products available on two or more platforms
  (Android, iOS, web). Ideally, AC on all of these should be
  more or less the same excluding platform-specific behavior.
  Since each platform most likely has its own Jira project —
  the copy-pasting is inevitable. It gets worse with following
  updates and corrections — AC should be re-copy-pasted everywhere again and again.
* Discussion. Jira does not support inline comments. There is no comment tree as well.
  As a result, multiple conversations transform into a shouting across a room
  full of different people.
  Honestly saying it is email exchanging all over again, just with a bit
  of centralized storage for the discussion topic.

There is another product from Atlassian which can be used to mitigate
the Jira pain — [Confluence](https://www.atlassian.com/software/confluence).

* Inline comments are fully supported, including resolving when the comments thread is no longer relevant.
* Nesting is available so it is possible to group AC by feature or screen.

    ```
    .
    ├── Fighting
    │   ├── Mjölnir
    │   └── Stormbreaker
    └── Universe Destruction
        ├── Infinity Gauntlet
        └── The Ultimate Nullifier
    ```

Using Confluence instead of Jira actually makes more sense.
The purpose of Jira issues, as I understand it, is to introduce changes
and track their implementation progress. Jira was never intended to be
a knowledge base (it is completely terrible at that).

# The Future

Effective AC management is a good step in achieving confidence in the overall
development process. Both business-oriented and tech-oriented people
should have a unified view on the future of the product. This future
is a combination of changes. These changes, in their turn, are defined by AC.

I think the most important factor is collaboration. It is achieved via unidirectional
knowledge sharing about the product and the technology standing behind it.
At the same time, this knowledge should be kept in sync using explicit
declarations without implicit behavior. It is achieved via formalization
and centralized knowledge storage.

In ideal world, AC should be an input for automated testing.
Gherkin is the missing link between AC and full-blown
[acceptance testing](https://en.wikipedia.org/wiki/Acceptance_testing),
but there is still a gap in the social aspect (implementation details
are unavoidable) and the tech one (integration tests are tricky).
Just imagine the following:

1. Business people create AC using Gherkin.
1. AC introduction is done via a pull request.
1. The pull request gets reviewed by tech people.
1. The adjusted pull request gets merged.
1. AC is treated as an acceptance test.

Sounds awesome, isn’t it? A bit utopian, but let’s see how it goes :wink:
