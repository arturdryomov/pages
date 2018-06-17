---
title: "Mobile Developer Morning Fun"
description: "You build it — you run it! Mobile version."
date: 2018-06-16
slug: mobile-developer-morning-fun
---

Do you read this article on a phone? No? Well, I’m pretty sure you have a phone.
Fun fact — I’ve bought the best phone I ever had, the Nexus 5X, from Amazon.
Another fun fact — there is a pretty good chance you’ve bought something from Amazon too since
[it grabbed 4% of US retail sales in 2017](https://www.cnbc.com/2018/01/03/amazon-grabbed-4-percent-of-all-us-retail-sales-in-2017-new-study.html).
That’s a lot!

Amazon not only sells things but hosts
a significant portion of internet resources thanks to
[Amazon Web Services](https://aws.amazon.com/). In other words,
the company has software developers working on a massive infrastructure
we use every day without noticing it. How do they keep it together?
There is a great phrase from Amazon CTO which we are going
to explore.

# You Build It — You Run It

Mobile developers are not as familiar with this sentence as much as backend ones.
The reason is simple — mobile does not face the underlying issue on a regular basis.

In a traditional backend environment software developers work on a solution,
then hand it to the operations team. This might not be true for small and medium teams,
but more people you have the higher the chance it will be something like that.
There is an issue though. Developers in this setup do not run the software
they created, it is done by the operations team. Of course, rising issues are eventually
delivered to developers and the cycle repeats.

Unfortunately, this is extremely dangerous. Especially from a psychological
standpoint. Handling over _some_ part of the process
eliminates the moral responsibility for it. Arising issues related to this
sphere are immediately thrown out of the window as _non-essential_ since
there is no liability for them.

This effect can be related not only to the development-operations cycle
but to the development-QA one. If the development team does no QA procedures
and delegates this task to the QA team it will lead to unforeseen consequences.
The worst case scenario — developers would not test their code at all
since in their minds it is not their duty. The best case — corner cases
would not be checked by developers themselves,
leading to potential under-development of the scope.

This is where we come back to Amazon.

> The traditional model is that you take your software to the wall
> that separates development and operations, and throw it over and then forget about it.
> Not at Amazon. _You build it, you run it_. This brings developers into contact
> with the day-to-day operation of their software.
>
> — [_Werner Vogels_](https://queue.acm.org/detail.cfm?id=1142065)

DevOps culture is all about that. Involving developers in the running cycle
[brings a lot of benefits](https://aws.amazon.com/blogs/enterprise-strategy/enterprise-devops-why-you-should-run-what-you-build/),
such as systems design focused on production, transparency, efficient automation
and tighter customer-developer feedback loop.

Not everyone shares this belief though. Especially developers. Of course!
It requires extra work, precision and effectiveness. But let’s face a fact —
if there is an anxiety about being on-call and in the running cycle,
there is definitely something not healthy with the overall process.

> On-call isn’t a silo. It’s in many ways the microcosm of the engineering skills
> of an organization (resilience of the systems being built as well as
> the quality of monitoring, alerting and automation) which in turn is
> a reflection of the quality of management and prioritization (engineering culture).
>
> — [_Cindy Sridharan_](https://medium.com/@copyconstruct/on-call-b0bd8c5ea4e0)

# Going Mobile

The thing is, mobile developers already live in the _You Build It — You Run It_ reality.
Mostly because such teams are usually small or medium-sized.
There is no infrastructure needed to be run since
Google and Apple do that themselves. Plus, it is rare to see a dedicated support team
responding to users. As a result, the development-running loop is pretty tight.
Developers often oversee the development process itself, deployment and running.

At the same time, [we can do better](https://www.youtube.com/watch?v=SLILjDx0SO0).

# On-call

> :book: Reading material on the topic:
> [Testing in Production](https://medium.com/@copyconstruct/testing-in-production-the-safe-way-18ca102d0ef1) and
> [On-call Doesn’t Have to Suck](https://medium.com/@copyconstruct/on-call-b0bd8c5ea4e0).

Internally we call it _Daily Duty_ because...

* On-call actions are performed in a 24-hour window.
* Every 24 hours are assigned to a next person in the rotation cycle.
  There are many ways to handle it — having a separate calendar
  or following a procedure or a ritual even. The team I’m working in
  passes an [Android figurine](http://www.deadzebra.com/project/android-collectibles/)
  around to mark a person currently on the duty.
* The monitoring should be constant but some tasks can be done once a day.
  The morning is a perfect time for that since a person is not yet
  in the flow and is not occupied by other tasks.

Don’t think that there is no need in picking a dedicated person since everybody is always on-call.
That’s not true. Everybody on-call means that nobody is on-call.

Necessary actions would be different for each team.
I recommend documenting them so the on-call person can act using a step-by-step guide.
As a neat bonus, it simplifies the onboarding process.

## Crash Reporting

Crash reporting became essential in the mobile development world almost from the beginning of times.
Platforms such as Google Play and App Store have it integrated but there are third-party solutions as well.

Make sure that there is an alerting system in place that will notify
everyone about unusual crash spikes. These should be patched
[ASAP](https://en.wikipedia.org/wiki/ASAP_Rocky).

The on-call person should check all current crashes and non-fatal issues. A good practice is
to create Jira issues automatically for everything. All of them
should be researched and closed this way or another — either by a patch
or a different resolution. Yep, let’s face it — the OS platform itself
might produce an issue. This kind of problems should be reported upstream —
both Apple and Google have platforms for that. Don’t be lazy — if nobody
reports an issue, nobody is gonna resolve it.

## Analytics and Metrics

Platforms supply a form of analytics via Google Play
and App Store. Install and uninstall rates, devices, OS versions and even reviews —
all of them are direct audience metrics. All unusual fluctuations
should be researched and reacted.

A lot of applications collect their own analytics.
Most likely these relate to business values, but they
serve as a great indicator. We are doing a business after all.

Technical metrics should be monitored as well. It can be anything:
startup average time, memory consumption, backend data
deserialization errors and even threads count.
Such things help with retrospecting changes in the codebase not
related to the business logic. One day you may find out that a new SDK
caused a spike in memory consumption. That’s not good.

All of this help to understand what is going on in the production world
and to eliminate any assumptions. Sometimes the place with the least
attention brings most horrific results. Even if it was _obvious_
that it shouldn’t happen in real life.

The on-call person should keep an eye on various dashboards and track
the current state of the production environment. Automate
this and set up alerts. It is not always possible though,
especially when it comes to deciding what is unusual and what is expected.

## Dependency Updates

This might be an obvious task, but it requires time and effort.
At the same time, it is essential to keep the codebase in shape.
Don’t forget about security updates and bug-resolving versions.
The sooner the newer dependency version is integrated, the less
becomes a future effort to update it to a next one.

The procedure can be semi-automated. There is
[a Gradle plugin](https://github.com/ben-manes/gradle-versions-plugin)
showing dependency updates. The final decision
should be made by the on-call person since sometimes changes
are too major to apply immediately. Such situations
become good opportunities to discuss the long-term approach for the upgrade.

# Be Involved

* Don’t distance the development process from the running process.
* Be with the audience.
* Make both proactive and reactive decisions.
* Create and optimize your own routine.

These rules are simple and at the same time not so easy to adapt.
But it is worth it — both from the technical and psychological standpoint.
It will not only make you a better specialist — but
[a better person](https://www.youtube.com/watch?v=-DSVDcw6iW8).

---

PS Bonus points to everyone who got [the Futurama reference](https://en.wikipedia.org/wiki/Saturday_Morning_Fun_Pit) :wink:
