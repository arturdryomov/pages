---
title: "Merge Git Authors"
description: "In Soviet Russia Git merges you!"
date: 2019-03-19
slug: merge-git-authors
---

Stats! Stats are awesome. You can collect them, you can analyze and visualize them,
you can boil, grill and fry them... Wait, that’s not food, right?

# `git shortlog`

Let’s say we have a Git repository. We want to count commits per author.
There is a Git command for that!

```console
$ git shortlog --summary --numbered

  2  Bender Rodriguez
  2  Philip J. Fry
  1  Bending Unit 22
  1  Turanga Leela
```

There are actually three authors but since names are non-consistent
Git makes it look like there are four. It gets worse with emails.

```console
$ git shortlog --summary --numbered --email

  2  Philip J. Fry <philip.j.fry@planet-express.earth>
  1  Bender Rodriguez <bender.rodriguez@planet-express.earth>
  1  Bender Rodriguez <bending-unit-22@mom.corp>
  1  Bending Unit 22 <bender.rodriguez@planet-express.earth>
  1  Turanga Leela <turanga.leela@planet-express.earth>
```

Bender has three identities:

Name             | Email
-----------------|----------
Bender Rodriguez | bender.rodriguez@planet-express.earth
Bender Rodriguez | bending-unit-22@mom.corp
Bending Unit 22  | bender.rodriguez@planet-express.earth

This is a made-up repository but the underlying issue is very real.
Git history gets messed up. Reasons are different: a new computer,
multiple Git identities on a single machine, a company domain change, dog ate it.
The result is always the same — the history is not consistent.

The deal here is not actually stats-related (although it is useful).
A more frequent task is researching, finding a person who made a change and
the motivation behind it. I’m talking about `git blame` and
[tooling around it](https://www.jetbrains.com/help/idea/investigate-changes.html#annotate).

Fortunately enough Git provides an instrument to deal with such conditions.
It is called [`.mailmap`](https://github.com/git/git/blob/master/Documentation/mailmap.txt).
Like `HashMap` and `ConcurrentHashMap`, but `MailMap`.

The following `.mailmap` content will resolve our consistency issues.

```
Bender Rodriguez <bender.rodriguez@planet-express.earth>
Bender Rodriguez <bender.rodriguez@planet-express.earth> <bending-unit-22@mom.corp>
```

We are associating the primary name with the primary email address and
aliasing secondary email to the primary identity. Let’s check.

```console
$ git shortlog --summary --numbered

  3  Bender Rodriguez
  2  Philip J. Fry
  1  Turanga Leela

$ git shortlog --summary --numbered --email

  3  Bender Rodriguez <bender.rodriguez@planet-express.earth>
  2  Philip J. Fry <philip.j.fry@planet-express.earth>
  1  Turanga Leela <turanga.leela@planet-express.earth>
```

# `git log`

There is a catch. Log will not show mail-mapped values.

```console
$ git log --format="%an <%ae>: %s"

Bender Rodriguez <bending-unit-22@mom.corp>: 01101000 01110101 01101101 01100001 01101110 01110011
Philip J. Fry <philip.j.fry@planet-express.earth>: Delivering pizza to D. Frosted Wang.
Bending Unit 22 <bender.rodriguez@planet-express.earth>: 01100001 01101100 01101100
Bender Rodriguez <bender.rodriguez@planet-express.earth>: 01101011 01101001 01101100 01101100
Philip J. Fry <philip.j.fry@planet-express.earth>: Delivering pizza to I. C. Wiener.
Turanga Leela <turanga.leela@planet-express.earth>: Blast off!
```

The thing is — `git shortlog` uses `.mailmap` by default, so does `git blame`.
Not `git log` though.

* There is a `--use-mailmap` flag for `git log`
* There is a `git config` option — `git config --global log.mailmap true`.
* Custom `--format` ignores both options above and requires formatting arguments change.
  `%an` to `%aN` for author name, `%ae` to `%aE` for author email address.

Yeah, that’s complicated. It works though!

```console
$ git log --format="%aN <%aE>: %s"

Bender Rodriguez <bender.rodriguez@planet-express.earth>: 01101000 01110101 01101101 01100001 01101110 01110011
Philip J. Fry <philip.j.fry@planet-express.earth>: Delivering pizza to D. Frosted Wang.
Bender Rodriguez <bender.rodriguez@planet-express.earth>: 01100001 01101100 01101100
Bender Rodriguez <bender.rodriguez@planet-express.earth>: 01101011 01101001 01101100 01101100
Philip J. Fry <philip.j.fry@planet-express.earth>: Delivering pizza to I. C. Wiener.
Turanga Leela <turanga.leela@planet-express.earth>: Blast off!
```

# Tools

`.mailmap` is nice and all but tools handling is a hit-and-miss.

* [`tig`](https://jonas.github.io/tig/)
  has [a turned off by default option](https://github.com/jonas/tig/blob/93ea97087749d08fcb94f797d22948aaea16f50c/tigrc#L120).
* IntelliJ IDEA platform [kind of supports it for annotations](https://youtrack.jetbrains.com/issue/IDEA-121066)
  but [does not support it for history](https://youtrack.jetbrains.com/issue/IDEA-160677).
* Neither [Git Tower 3.3.0](https://www.git-tower.com/mac) nor
  [GitX 0.15](http://gitx.github.io/) seem to support it.

Nevertheless, it is better to have it than not. Such projects as
[Gradle](https://github.com/gradle/gradle/blob/master/.mailmap),
[SymPy](https://github.com/sympy/sympy/blob/master/.mailmap),
[TypeScript](https://github.com/Microsoft/TypeScript/blob/master/.mailmap)
and [Git itself](https://github.com/git/git/blob/master/.mailmap) have and maintain them.

# Preemptive Strike

`.mailmap` is an after-the-fact measure. Ideally it is better to have before-the-fact measures in place.

Bitbucket has [a plugin for that](https://marketplace.atlassian.com/apps/1211854/yet-another-commit-checker) —
it checks that a Git author email address matches Bitbucket account email address.
Surprisingly I haven’t found anything close for GitHub.

[A pre-commit Git hook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) will do the trick as well.

```bash
if [[ "$(git config user.email)" != *"@planet-express.earth" ]]; then
    echo "Danger! High Voltage!"
    exit 1
fi
```

Obviously such checks will not work in the OSS world but
for companies — seems like a way to go.
