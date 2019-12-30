---
title: "On Technical Writing"
description: "How I make it work (or not)"
date: 2019-12-30
slug: on-technical-writing
---

Books were the internet for me before the real one became accessible.
Authors wrote a thing and I’ve read it, consuming the information behind the text.
First, I’ve read each book we had at home.
Then everything meaningful from a kids’ section of the local library.
And then I’ve been introduced into the serious stuff. I think
[The Hobbit](https://en.wikipedia.org/wiki/The_Hobbit)
was the beginning. Then [The Three Musketeers](https://en.wikipedia.org/wiki/The_Three_Musketeers),
[The Adventures of Sherlock Holmes](https://en.wikipedia.org/wiki/The_Adventures_of_Sherlock_Holmes)...

There were no recommendation engines of course so I went through everything,
itching to consume experiences left behind by humanity.
Sounds like an addiction, right? Well, it kinda was.
Nowadays we have different drugs — news, movies, TV series, games.
There is no time for books. Kids certainly don’t give a damn about them either.
Anyways, we are talking about me, right?

# On Writing

Fast-forward to the last year of school. I’ve started writing.
It was nothing special really, short fictional stories there and there.
For some weird reason I was brave enough to publish them on the internet and
show them to friends. And... people liked them. Which made me show a couple
of stories to teachers and ask for advice on the text rhythm and structure.
As I remember this, the experience feels like a bright stark of empathy.
Such a wonderful feeling.

> :bulb: Don’t hesitate to ask for advice and opinion. That’s how we evolve.

Being a dumb youngling, at a certain point, I’ve decided to stop this
enterprise and delete everything I wrote. I don’t even remember the motivation
behind such destructive action. Never do that.

# On Serious Writing

Fast-forward to the first day of the university. We were given a tour
around facilities and were suggested to pick an activity. This was the moment
I saw a position at the university newspaper. After a short trial period
I was in. It was a weird feeling since I’ve studied IT and had zero experience
with news and regular publications.

I have a lot of stories to share about this period but we’ll skip to the end of it.
After a year of being a kind-of-journalist I’ve decided to abandon the ship
for a number of reasons.

* Doing a newspaper is not a hobby, it is a job.
  No matter how many things there are in life, the piece (or pieces)
  should be done in time. I’ve decided to code more instead,
  focusing on the career.
* The paper was printed, not published on the internet. It was evident
  to everyone that print days are numbered. Students preferred
  social networks to ink on dead trees even then.

Also — never half-ass two things, always full-ass a single thing.
Especially if it is about shaping the future.

# On Technical Writing

Fast-forward to December 2017. I had a lot of technical ideas to talk about.
At the same time, I’ve understood that giving a public talk to 100 people
is extremely ineffective when we have the internet. So I’ve decided to write again.
See, you are reading these words, so it worked.

> :book: BTW — [conferences and events are dead](https://marco.org/2018/01/17/end-of-conference-era).

The following books inspired me and I can recommend them to everyone — with or without writing ambitions.

* [Stephen King. On Writing: A Memoir of the Craft](https://en.wikipedia.org/wiki/On_Writing:_A_Memoir_of_the_Craft).
* [William Strunk Jr. and E. B. White. The Elements of Style](https://en.wikipedia.org/wiki/The_Elements_of_Style).
* [Warren Ellis. Transmetropolitan](https://en.wikipedia.org/wiki/Transmetropolitan).

## The Process

### Ideas

I don’t have a universal idea source, to be honest.
A lot of them occur while I’m working on something and want to explore further.
Then I write the idea down. From time to time I look over them
and check if they are still relevant and interesting to me.
This is when a good portion of them are scorched from the face of Earth.

A number of passes determine survivors which are blessed to become a research.
During the research I look around, in fields I’m not familiar with —
to avoid narrowing the field of view. Eventually, the research becomes a document
with a number of notes and links.

### Schedule

In 2018 I’ve set a goal of a single article per month. It was a good idea since
it forced me to start working on a piece, at the same time leaving me
enough space for freedom. The scheduling might sound boring but it serves
as a good push for learning more and advancing the skill forward.

> :movie_camera: [Deadlines make you creative](https://www.youtube.com/watch?v=MckHLBWuz7E).

In 2019 I’ve made a mistake of demanding two articles per month from myself —
one short one and one long one. That’s why I’ve started the Superior Testing
series. Unfortunately, it burned me out a bit in a way the newspaper did.
Too much pressure, cannot recommend it.

### Writing

I use [MacVim](https://github.com/macvim-dev/macvim) without Markdown previews or anything. That’s how we roll:

```
+-----------------------------------------------------+
|~ # On Technical Writing                             |
|~                                                    |
|~                                                    |
|~                                                    |
|~                                                    |
|~                                                    |
|~                                                    |
|~                                                    |
|~                                                    |
+-----------------------------------------------------+
| INSERT | article.md         markdown | utf-8 | unix |
+-----------------------------------------------------+
```

Since I use [Hugo](https://gohugo.io/) for publishing I use it to preview an article
when (I think) I’m done. Then I refine the text and cut a good portion of it
to be on point as much as possible.

That’s basically it! I know people who use
[fancy Markdown workflows](https://thesweetsetup.com/apps/favorite-markdown-writing-app-mac/)
but I prefer things to be as lean as possible.
I’ve tried to use [the Hemingway checker](http://www.hemingwayapp.com/)
but it cuts a lot of character from the text so I cannot recommend it.
The Vim built-in spellchecker is enough.

### Publishing

> :book: [Medium is a poor choice for blogging](https://tonsky.me/blog/medium/).

As I’ve mentioned, I use Hugo and [GitHub Pages](https://pages.github.com/).
I’ve built a Hugo theme from scratch using pure HTML / CSS and automated the workflow
([everything is open source](https://github.com/arturdryomov/pages)).

* I open a GitHub PR per article. This assembles the website on CI as a general check.
  Also sometimes I ask people to review the article.
* Merging the PR to the `master` branch triggers the deployment to GitHub Pages.

This approach gives a lot of benefits.

* Everything is optimized to the limit. Opening an article takes less than a second on average.
  [Chrome Lighthouse](https://developers.google.com/web/tools/lighthouse) gives
  100 / 100 performance points.
* Markdown makes the content portable. Moving from Hugo would be a breeze.
  In fact, it is possible to read articles directly on GitHub.
* [`system-ui`](https://caniuse.com/#feat=font-family-system-ui) and
  [`prefers-color-scheme`](https://caniuse.com/#feat=prefers-color-scheme) make
  articles look familiar on all platforms and follow a system theme.

The article link is submitted to
[Hacker News](https://news.ycombinator.com/),
[Android Weekly](https://androidweekly.net/),
[Kotlin Weekly](http://www.kotlinweekly.net/)
and relevant [Reddit](https://www.reddit.com/) communities.
The submissions count depends on the content of the article.
For example, this one has nothing to do with neither Android nor Kotlin,
so it wouldn’t be there. Of course, the submission doesn’t mean approval.
Weekly editors might skip an article, Hacker News and Reddit might downvote it
to oblivion.

### Stats

First of all, I want to note that writing articles for a number of views is pointless.
It is tempting to follow trends but it is a dark path.
However, it is fun to get an overview.

So here we go, there are some numbers for two years of running the blog.

Article                          | Views
---------------------------------|------
Kotlin: The Problem with `null`  | 16 300
A Dagger to Remember             | 9 200
Designing Errors with Kotlin     | 6 300
Superior Testing: Stop Stopping  | 5 600
Do Androids Dream of UI Testing? | 5 600
...                              | ...
Merge Git Authors                | 320


It is problematic to count sources but here are approximate numbers.

Source        | Views
--------------|------
Hacker News   | 9 800
Twitter       | 2 600
Reddit        | 1 400
...           | ...
Google Groups | 10

# On Future Writing

The technical writing gave me back the good feeling of working with text.
At the same time, it forced me to streamline a bunch of thoughts I had over months
in text. This transformed thoughts into arguments that can be reused and shared.
I hope it helped someone else, not just me.

Thank you for reading this article and for doing so for months and years.
Let’s continue the journey!
