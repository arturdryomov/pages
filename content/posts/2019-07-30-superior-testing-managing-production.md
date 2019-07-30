---
title: "Superior Testing: Managing Production"
description: "Testing never sleeps."
date: 2019-07-30
slug: superior-testing-managing-production
---

The testing process does not magically stop after deploying an artifact.
[We’ve only just begun](https://en.wikipedia.org/wiki/We%27ve_Only_Just_Begun).
It is impossible to check everything in a sandboxed environment.
From a certain perspective it seems like the whole run time is the testing process.
How is it possible to check the correctness without tests?
Right — by running the thing. We do the same in production — just on a bigger scale and
with bigger risks.

Testing in a controlled environment is trivial. After all — we see the result.
If tests are in place we see it as a report or an output in an IDE.
If not — we can analyze the output like a UI or a text.
We don’t see things in production. Imagine the application as a pure function.
A user supplies inputs (files, text, clicks, swipes) and
consumes outputs (different files, UI, UX). The code is in between,
it owns neither inputs nor outputs. What do we do? Introduce side-effects
in a form of monitoring.

# Analytics

Business values usually are covered with analytics events.
Otherwise, it is tricky to identify good and not so good spots
in business-related flows. Technical metrics are important as well!
There is a small trick though — it is undesirable to mix
business and technical analytics in the same pool. Most of the time
product-related people do not care about technical details.

There are great tools on the market doing what we need —
like [Fabric Answers](https://fabric.io/kits/android/answers/features)
and [Google Analytics for Firebase](https://firebase.google.com/docs/analytics).
Both provide dedicated analytics storage for tech-specific needs.
What do we put there?

* Memory usage. On mobile it makes sense to track consumed heap percentage
  instead of absolute values since it might change from device to device.
  Spikes might help find unknown memory leaks.
* Threads count. Absolute values are fine since it shouldn’t change
  from device to device. Spikes might help find unusual resources utilization.
* Deserialization and network errors rate, external component versions
  (like Google Play Services), supported ABIs — everything useful goes there as well.

Such characteristics help to see a bigger picture and make argumented decisions.

# Logging

For reasons unknown a lot of developers neglect logs.
Do they match a category of archaic tech? No idea.
Well-structured logs are far more powerful than analytics.
The key to power is changing the logging mindset.
Think about logs not as a wall of text (OH HAI Android Logs)
but as a database.

Let’s imagine that we got a nasty crash. Having a stacktrace is helpful
but in non-obvious situations it is not trivial
to understand what went wrong. It is great to have logs in this scenario.
Having them as a plain text is not so great. What do we do if we want
to take a range from one date to another? Or take a look at all HTTP requests
made from a device this month? Or analyze how often we get `500` HTTP errors
from a specific endpoint?

Enter [the ELK (Elastic) Stack](https://www.elastic.co/what-is/elk-stack).
Extremely popular in the backend world it is not so well-known in the mobile one.
I’m gonna skip the general introduction — there is literally
an infinity of guides.

The idea from the client perspective is simple. Instead of logging plain text
we are gonna log... JSON!

```text
/v1/books returned 500
```
becomes
```json
{
    "application_version": "1.0.2",
    "os_version": "7.1.1",
    "thread": "main",
    "http_path": "/v1/books",
    "http_request_id": "87814f00-e3a4-41a6-ba21-174f2476bc75",
    "http_request_duration": 42,
    "http_response_code": 500
}
```

An enumeration of such elements is put into a file, files get batch-processed and
sent to the backend where they are processed by the ELK stack.
Then, using [Kibana](https://www.elastic.co/products/kibana)
as a frontend and [Lucene](https://lucene.apache.org/core/2_9_4/queryparsersyntax.html)
as a query language we can make all sorts of analysis.

* Responses to `/v1/books` returned `500` across all users.

  ```lucene
  http_path:"/v1/books" AND http_response_code:500
  ```

* Requests to `/v1/books` made from the main thread.

  ```lucene
  http_path:"/v1/books" AND thread:"main"
  ```

* Requests to `/v1/books` which took from 3 to 5 seconds.

  ```lucene
  http_path:"/v1/books" AND http_request_duration:[3 to 5]
  ```

Those are basic examples, the possibilities are almost endless.
Even better — it is possible to make custom graphs using Kibana
or even create monitoring dashboards with [Grafana](https://grafana.com/).

This kind of approach to the logging process can save a lot of time
spent on investigation and analysis. Not gonna lie — it feels great
to use such powerful instruments.

# Feature Flags, Alerts, Non-Fatals...

There are a lot of practices for managing production environments.
The idea should stay the same — there is no end to testing.
Like it or not — things will go south. It is always better to have tools
to understand why did it happen.
