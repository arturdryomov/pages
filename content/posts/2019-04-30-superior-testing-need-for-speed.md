---
title: "Superior Testing: Need for Speed"
description: "I feel the need — the need for speed!"
date: 2019-04-30
slug: superior-testing-need-for-speed
---

Everybody wants to have a faster development cycle.
Everything should be flawless and straightforward.
Nobody wants to have hour-long builds and stuck CI queues.
We need results! Now! Or maybe even in the past, preemptively.
[Guard](https://github.com/guard/guard) from the Ruby ecosystem comes to mind,
starting tests on file changes, without doing it manually.

Talking about tests — they are a part of the cycle, right?
We run them both locally and remotely (as part of a CI pipeline).
It takes time and I think [we can do better](https://www.youtube.com/watch?v=SLILjDx0SO0)!

# Execute in Parallel

A lot of people are familiar with [the `--parallel` flag](https://docs.gradle.org/current/userguide/multi_project_builds.html#sec:parallel_execution).
It will execute Gradle tasks in parallel, not much else.
[We can do the same with tests](https://docs.gradle.org/current/dsl/org.gradle.api.tasks.testing.Test.html#org.gradle.api.tasks.testing.Test:maxParallelForks).

```kotlin
tasks.withType<Test> {
    maxParallelForks = Runtime.getRuntime().availableProcessors() / 2
}
```

The `maxParallelForks` default value is `1`. Give it a bigger number and Gradle
will execute test classes (not methods) in parallel. The snippet above
uses a half of available CPU cores. Results:

`maxParallelForks` | `testDebugUnitTest` time, seconds
-------------------|----------------------------------
1                  | 53
4                  | 41

# Kill Reports

Gradle test execution ends in generating at least two sets of reports —
JUnit XML and HTML. There is a chance that a CI system of choice uses
at least one of them to render results on UI.
But a lot of systems do not use it at all. Moreover, there is
a good chance that developers do not use these reports at all.
[Let’s nuke them](https://docs.gradle.org/current/javadoc/org/gradle/api/reporting/Report.html#setEnabled-boolean-)!

```kotlin
tasks.withType<Test> {
    reports.forEach { report -> report.isEnabled = false }
}
```

`report.isEnabled` | `testDebugUnitTest` time, seconds
-------------------|----------------------------------
`true`             | 41
`false`            | 40

Well, this is kind of disappointing... However, there is an interesting
side effect.

```
$ find build/reports/tests/testDebugUnitTest -name "*.html" | wc -l
```

The result will be a number of test classes or similar. This number is
the number of files created by the HTML report. Tools like
[Mainframer](https://github.com/buildfoundation/mainframer) transfer files
and fewer files — the better. Most likely the same thing can be applied
to packaging build artifacts during the CI pipeline.

`report.isEnabled` | Mainframer sync time, seconds
-------------------|----------------------------------
`true`             | 6
`false`            | 2

# Kill Android Variants

Results above reflect the `testDebugUnitTest` execution.
At the same time there is a good chance that the CI pipeline
executes either `test` or `build` (`assemble` + `test`) task.
The issue with the `test` task is that it runs both
`testDebugUnitTest` and `testReleaseUnitTest`.
This effectively doubles the execution time.

Gradle Task           | Execution time, seconds
----------------------|------------------------
`testDebugUnitTest`   | 40
`testReleaseUnitTest` | 40
`test`                | 80

But do we even care about the debug variant? We are shipping the release code, right?
I’m not gonna suggest excluding the `testDebugUnitTest` as universal advice
since it is a matter of choice. There is the command though:

```
$ ./gradlew build --exclude-task testDebugUnitTest
```

BTW Tor Norbye from the Android Studio team
[suggests](https://groups.google.com/forum/#!msg/lint-dev/RGTvK_uHQGQ/FjJA12aGBAAJ)
excluding the `lintDebug` with similar motivation.

> You’re probably only shipping your release variant,
> so you could limit yourself to just running `lintRelease` and you’re not going to miss much.

# Math

Let’s iterate over what can be done to make tests execution faster, without changing the source code.

* Parallel execution: reduce from 53 to 41 seconds.
* Killing reports: reduce from 41 to 40 seconds, plus reduced Mainframer sync time.
* Killing debug Android variant: not letting the number be multiplied by the factor of two.

Looks good! Believe me — it feels even better to do this IRL :wink:
