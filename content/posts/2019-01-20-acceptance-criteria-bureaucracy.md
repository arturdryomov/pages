---
title: "Acceptance Criteria Bureaucracy"
description: "Organizing the development process with a sweet boring documentation."
date: 2019-01-20
slug: acceptance-criteria-bureaucracy
---

# Stone Age

AC are exchanged as documents with a bunch of text.
Let’s face it — a lot of teams deal with this on a regular basis.
The file format might be as basic as `.txt` or as fancy as `.pdf` —
it doesn’t change the picture.

This is ridiculous but it actually works.
At the same time, it is sad that so many people are forced
to work with this format. The multiplier for everything bad
related to this approach is a potential lack of the centralized
source of truth. For example, AC might be sent via email
at any given point of time. Of course, emails might be blocked
by spam filters, forgotten, batch removed and so on.
A nightmare, but it is workable.

```
There is the Infinity Gauntlet. It requires Infinity Gems to work.

* All gems are in place: it is possible to erase half of the universe
  via finger snapping.
* Some (but not all) gems are in place: the behavior is inherited
  from available gems.
* None gems are in place: nothing happens.
```

Believe it or not, this is a pretty good AC.
It is possible to start the development process using it.

# Bronze Age: Formalization

AC tend to grow. Just like flowers. Or global nuclear arsenal. Your pick.
Organizing a good amount of text is never easy. That where
[formal specifications](https://en.wikipedia.org/wiki/Formal_specification#Software_tools)
come into play. There is a number of methods to transform a wall of text
to a understandable step-by-step guide. I’ve heard about:

* writing conventions (do not scale with a number of people involved);
* syntax and DSL (usefulness depends on discipline);
* block diagrams (awesome but might be not practical);
* nothing (anarchy at its core).

From the experience I have the middle ground is defining a syntax
and following it. This way non-technical people are able to read and write
AC and technical people feel more comfortable since it looks and feels like
a distant programming language. Fortunately enough [Cucumber](https://cucumber.io/)
already defined such syntax named [Gherkin](https://docs.cucumber.io/gherkin/reference/).

```gherkin
Feature: Infinity Gauntlet

  Given all gems are in place
  When fingers are snapped
  Then erase half of the universe

  Given some (not all) gems are in place
  When gem-specific intent is performed
  Then perform gem-specific action

  Given none gems are in place
  When any intent is performed
  Then do nothing
```

Much better. Attentive readers might notice that the declaration enforced us
to explicitly describe when actions are actually pefromed. This was missed
in original text-based AC.

# Iron Age: Sharing

Hopefully at some point people involved in the process start to understand
that email-based sharing is a no-go.
[Jira](https://www.atlassian.com/software/jira) is an obvious choice.
It even has [a dedicated input field for AC](https://www.atlassian.com/blog/jira-software/8-steps-to-a-definition-of-done-in-jira)!

Jira is far better than exchanging emails but it falls short in a couple of areas.

* Duplication. There are products available on two or more platforms.
  For example, Android, iOS and web. Ideally AC on all of these should be
  more or less the same excluding platform-specific behavior.
  Since each platform most likely has its own Jira project this leads
  to copy-pasting AC back and forth. It gets worse with following
  updates and corrections — AC should be re-copy-pasted everywhere again and again.
* Discussion. At the moment of writing Jira does not support inline comments.
  There is a box on the bottom without comments tree (Reddit style).
  As a result mutliple conversations transform into a shouting across a room
  full of different people. There is no resolving for comment sub-trees.
  Honestly saying it is email exchanging all over again, just with a bit
  of centralized storage for the discussion topic.

There is another product from Atlassian which can be used to mitigate
the phantom Jira pain — [Confluence](https://www.atlassian.com/software/confluence).

* Inline comments are fully supported, including resolving when the comments thread is no longer relevant.
* Nesting is available so it is possible to group AC by feature or screen.

Using Confluence instead of Jira actually makes more sense.
The purpose of Jira issues, as I understand it, is to introduce changes
and track their implementation progress. Jira was never intended to be
a knowledge base (it is completely terrible at that).

# The Future

Effective AC management is a good step in achieving confidense in the overall
development process. Both product-oriented and tech-oriented people
should have a unified view on the future of the product. This future
is a combination of changes. These changes, in their turn, are defined by AC.

I think the most imporant factor is collaboration. It is achieved via unidirectional
knowledge sharing about the product and about the technology that stands behind it.
At the same time, this knowledge should be kept in sync using explicit
declarations without implicit behavior. It is achieved via formalization
and centralized knowledge storage.

In ideal world AC should be an input for automated testing.
Actually it is possible to do that using Cucumber and Gherkin
but there is still a gap in the social aspect (product-oriented people
might not be familiar with implementation details) and the tech one
(integration tests are tricky). Let’s see how it goes though :wink:
