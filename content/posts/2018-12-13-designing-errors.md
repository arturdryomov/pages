---
title: "Designing Errors with Kotlin"
description: "Checked and unchecked, recoverable and unrecoverable — what to pick?"
date: 2018-12-13
slug: designing-errors-with-kotlin
---

Fun fact — the area of
[the Java island](https://en.wikipedia.org/wiki/Java) is 138 793 km²,
[the Kotlin island](https://en.wikipedia.org/wiki/Kotlin_Island) occupies 15 km².
Of course it is blanatly incorrect to compare languages based on same-named island areas.
At the same time it brings things in perspective. Java is the cornerstone
of the JVM platform. The platform itself overshadows everything it hosts:
Groovy, Ceylon, Scala, Clojure and Kotlin. It is the foundation and it brings
a lot to the table — error handling is no exception (pun intended).

Exceptions! Developers adore exceptions. It is so easy to `throw` an error
and forget about consequences. Is it a good idea though? Should Kotlin follow
the same path? Fortunately enough there are many good languages around we
can learn from. Let’s dive in!
