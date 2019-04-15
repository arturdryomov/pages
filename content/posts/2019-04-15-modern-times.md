---
title: "Modern DateTimes on Android"
description: "Are we... out of time?"
date: 2019-04-15
slug: modern-times
---

Java 8 gave us a great gift — the `java.time` package, known as
[JSR 310](https://jcp.org/en/jsr/detail?id=310) and
[ThreeTen](https://www.threeten.org/).
The story behind `java.time` is unique. It was introduced as
[JEP 150](https://openjdk.java.net/jeps/150) by an independent developer —
Stephen Colebourne ([`@jodastephen`](https://github.com/jodastephen)).
Yep, the same person who designed and developed
[Joda-Time](https://github.com/JodaOrg/joda-time).
It was even endorsed by Brian Goetz, the
[Java Concurrency in Practice](http://jcip.net/) author!
The result was a great API — explicit and direct,
based on years of Joda-Time experience.


> The existing Java date and time classes are poor, mutable,
> and have unpredictable performance. There has been a long-standing desire
> for a better date and time API based on the Joda-Time project.
> The new API will have a more intuitive design allowing code
> to better express its intent. The classes will also be immutable
> which aligns with the multi-core direction of the industry.
>
> — [_JEP 150: Motivation_](https://openjdk.java.net/jeps/150)

The message is clear — the replacement was needed.
The good news — we got it. The bad news — we have...

# Android

Java 8 was released in 2014, now is 2019 and we still cannot use it on Android
without asteriscs.

## `minSdkVersion <= 25`

Use [ThreeTenBP](https://github.com/ThreeTen/threetenbp) (ThreeTen backport) and
[ThreeTenABP](https://github.com/JakeWharton/ThreeTenABP/) (ThreeTen Android backport).

The ABP one is not actually a full-blown ThreeTen implementation.
It is a special time zones data initializer which fetches time zone data
not from Java resources but from Android assets since it is more efficient.

### Dependencies

#### Application

* `com.jakewharton.threetenabp:threetenabp:{ABP_VERSION}` —
  efficient time zones initializer.
* `org.threeten:threetenbp:{BP_VERSION}:no-tzdb` —
  ThreeTenBP, but [without time zones data](https://github.com/ThreeTen/threetenbp/blob/31b133c35cbc45b767e0c9392818438f20b80059/pom.xml#L218-L237).
    * ThreeTenABP provides the same transitive dependency under the hood
      but it is useful to have the same ThreeTenBP version for...

#### Unit Tests

* `org.threeten:threetenbp:{BP_VERSION}` — regular ThreeTenBP.
    * Unit tests are being run on JVM so there is no need for the Android-specific
      time zones initializer.

### Joda-Time?

Abandon Joda-Time! Don’t be hisitant to [migrate from it](https://blog.joda.org/2014/11/converting-from-joda-time-to-javatime.html)
to ThreeTenBP ASAP.

* ThreeTen is the next evolutionary step, created by the same developer.
* Since ThreeTenBP is a ThreeTen backport, migrating to the native JVM API becomes
  a bulk `org.threeten.bp` package replacement with `java.time`.
    * The migration itself is a fact — `java.time` is already
      available on Android and it is a matter of time before we can use it everywhere.
* JVM ecosystem already uses `java.time`.
  It is better to use same API to speak the same language.
    * [Project Reactor is a good example](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html#interval-java.time.Duration-).
* ThreeTen is better for APK size than Joda-Time.
    * Joda-Time without time zones + Joda-Time Android is `735 KiB`.
    * ThreeTenBP without time zones + ThreeTenABP is `485 KiB`.

## `minSdkVersion >= 26`

Use [`java.time`](https://developer.android.com/reference/java/time/package-summary),
forget about Joda-Time and ThreeTenBP.

> :book: Android [uses ICU](https://android.googlesource.com/platform/libcore/+/master/ojluni/src/main/java/java/time/zone/IcuZoneRulesProvider.java)
> to provide time zones data.

The downside of using native `java.time` is updating time zones data.
Since standalone distributions (such as Joda-Time and ThreeTenBP) carry their
own time zones data it is possible to update it separately.
Unfortunately on Android system time zones data updates [depend on OEM](https://source.android.com/devices/tech/config/timezone-rules).
It is an open question which OEMs actually do this in real world.

# Usage

## Access

Since ThreeTenBP without time zones data will not initialize time zones by itself,
we’ll need to do it ourselves. Executing time zone-related
operations without initialization will lead to runtime exceptions. It is a good idea to have
a time abstraction in place which will be an entry point for time-related data.
It is a good practice to have it for testing purposes anyway.

> :book: `Duration` is safe to use everywhere since it is basically
> [a pair of seconds and nanoseconds](https://github.com/ThreeTen/threetenbp/blob/31b133c35cbc45b767e0c9392818438f20b80059/src/main/java/org/threeten/bp/Duration.java#L486-L490)
> with syntax sugar on top.

```kotlin
interface Time {

    fun now(): ZonedDateTime

    class Impl(private val context: AndroidContext) : Time {

        private val initialized = AtomicBoolean()

        override fun now(): ZonedDateTime {
            if (initialized.get() == false) {
                AndroidThreeTen.init(context)
                initialized.set(true)
            }

            return ZonedDateTime.now()
        }
    }
}
```

It is not the best implementation, especially thread-safe wise, but it delivers the idea.

Don’t forget that despite ThreeTenABP features efficient time zone data initializer
it still takes more than 100 milliseconds to do so. To avoid blocking
the main thread use background threads on the application startup to pre-initialize time zones.

Please notice that this optimization does not eliminate the `Time` abstraction.
Since the background initialization is an async process it is possible to use
`ZonedDateTime` before time zones were actually initialized.

```kotlin
class Application : android.app.Application {

    override fun onCreate() {
        super.onCreate()

        // Provide time variable via IoC container of choise.

        Schedulers.io().scheduleDirect { time.now() }
    }
}
```

## Constants

There is a common struggle in the industry with naming variables.

```kotlin
companion object {
    private const val DELAY = 10
}
```

What does it even mean? Are we talking about seconds or hours? We can make it a bit better.

```kotlin
companion object {
    private const val DELAY_SECONDS = 10
}
```

It does not save us though. Since naming is a semantic rule,
it depends on human nature and behavior. Fortunately enough we have `Duration`.

```kotlin
companion object {
    private val DELAY = Duration.ofSeconds(10)
}
```

Being honest — it is not a silver bullet but it reduces the confusion significantly.

# Time Out

Think about what to do with time before you run out of... time.

---

The title is a reference to the [Charlie Chaplin movie](https://en.wikipedia.org/wiki/Modern_Times_(film)).
