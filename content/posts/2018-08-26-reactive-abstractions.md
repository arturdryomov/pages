---
title: "Reactive Abstractions in Android World"
description: "Abstracting and testing platform interactions."
date: 2018-08-26
slug: reactive-abstractions-in-android-world
---

Who knows how many test suites were not created because of a classic parry.

> It cannot be tested — it uses a platform call!

Well, it does not actually true all the time.
For example, unit testing something that only human eye and neural networks
can catch — like animations and transitions — totally doesn’t make a lot of sense.
On other hand, retrying a network request on re-established connection
can and should be tested. And it is possible to gain a couple of perks on the way here.

# Theory

The main advice I can give Android developers regarding testing —
start thinking about the codebase as a platform-agnostic environment.
Not in a ridiculous way but a more pragmatic one — otherwise it is too
easy to slip onto a dark cross-platform path. Associating the codebase
with the JVM platform and not specifically Android is a better idea.
Framework-related interactions can be plugged-in as composable blocks.

Another advice — embrace abstractions available on hand.
Samples in this article will be based on RxJava but it is possible to replace it
with `Future`, `Promise`, Kotlin coroutines or just a barebones code.
This is especially useful with `async` + `await` type of interactions.
Believe me, it is not wise to do everything yourself if there is a good tech
available on hand. Moreover — it is quite easier to maintain consistency
in the codebase if each component speaks using same constructs.
Do not repeat the Tower of Babel fall.

# Practice

Whether we like it or not — platform interactions leak into _the business logic_.
It is understandable — the environment capabilities should be utilized and not ignored.

At the same time it is essential to test the logic of the final product —
otherwise there will be no product at all, only issues and undefined behavior.

Fortunately enough, the mankind deals with such issues for a while.
Let’s use a weight measurement example. How much does a brick weight?
Well, certainly less than a space station and more than an atom.
That characteristic does not really helps when it is necessary to transport
a number of bricks. Will a car break under a million of bricks?
That’s why humanity created _abstractions_, such as grams, kilograms and tons.
It is possible to take this completely (but collectively) made up measurement unit
and apply it everywhere.

Software development provides means to create abstractions easy-as.
It is not necessary to create
an [ISO](https://www.iso.org/) committee to create one — programming language is enough.
Android is not an exception — and it never was.

## Connectivity

It can be useful to retry stalled network requests when OS reconnects
to a network access point. In fact,
[`ConnectivityManager`](https://developer.android.com/reference/android/net/ConnectivityManager)
was there for ages:

> The primary responsibilities of this class are to:
> monitor network connections (Wi-Fi, GPRS, UMTS, etc)...

The most simple usage code of the potential abstractions will look like this.

```kotlin
disposable += connectivity.available.subscribe(refresh)
```

Seems like a single stream will be enough. Let’s do it.

```kotlin
interface Connectivity {

    val available: Observable<Unit>

    class AndroidConnectivity(context: AndroidContext) : Connectivity {

        private val manager = context.systemService<ConnectivityManager>()

        override val available = Observable.create<Unit> { emitter ->
            val listener = OnNetworkActiveListener { emitter.onNext(Unit) }

            manager.addDefaultNetworkActiveListener(listener)
            emitter.setCancellable { manager.removeDefaultNetworkActiveListener(listener) }
        }
    }
}

class TestConnectivity : Connectivity {
    override val available = PublishRelay.create<Unit>()
}
```

Marvelous! A couple of things to notice here.

The `Observable` itself handles proper `Listener` setting on subscription and
unsetting on unsubscription. It uses the
[Dispose pattern](https://en.wikipedia.org/wiki/Dispose_pattern),
i. e. the RxJava `Disposable`. Since all `Observable` behave the same
the end-user of the `Connectivity` will work with it as with any other
`Observable`.

Since there is an `interface` it is extremely easy to provide a `Test*` implementation
in unit tests. Just a single call to simulate real-world behavior and that’s it —
it is possible to test a code which works with the platform framework.

```kotlin
context("connectivity becomes available") {

    beforeEach {
        connectivity.available.accept(Unit)
    }

    it("refreshes") {
        verify(refresh).run()
    }
}
```

## Launch Applications

Usage:

```kotlin
disposable += launchService.launch(Request.ShareText("Ping!"))
    .observeOn(mainThread)
    .subscribe {
        when (result) {
            Result.Success -> view.showSuccess()
            Result.Failure -> view.showSharingNotAvailable()
        }
    }
```

Implementation:

```kotlin
interface LaunchService {

    sealed class Request {
        data class ShareText(val text: String) : Request()
    }

    enum class Result { Success, Failure }

    fun launch(request: Request): Single<Result>

    class Impl(
            private val context: AndroidContext,
            private val application: Application,
            private val mainScheduler: Scheduler
    ) : LaunchService {

        override fun launch(request: Request) = application.currentActivity
                .take(1)
                .singleOrError()
                .map { activity ->
                    try {
                        activity.startActivity(createIntent(request))
                        Result.Success
                    } catch (e: ActivityNotFoundException) {
                        Result.Failure
                    }
                }
                .subscribeOn(mainScheduler)

        override fun createIntent(request: Request) = when (request) {
            is Request.ShareText -> {
                val intent = Intent(Intent.ACTION_SEND).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, request.text)
                }

                Intent.createChooser(intent, request.title)
            }
        }
    }
}
```

## Google Play Services

The concept works well not only with the platform itself,
but with all third-party information sources.

Let’s say it is necessary to show a warning if Google Play Services
are not installed.

Usage:

```kotlin
disposable += googlePlayServices.available
    .filter { it == false }
    .observeOn(mainThread)
    .subscribe(view.showGooglePlayServicesWarning)
```

Implementation:

```kotlin
interface GooglePlayServices {

    val available: Single<Boolean>

    class PackagedGooglePlayServices(
        context: AndroidContext,
        ioScheduler: Scheduler
    ) : GooglePlayServices {

        override val available = Single
            .fromCallable { GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) }
            .map { it == ConnectionResult.SUCCESS }
            .subscribeOn(ioScheduler)
    }
}
```

The useful thing here is that the work is done on IO thread since retrieving
the information can take an undefined amount of time. Since the RxJava is used
all multi-threading mumbo-jumbo is handled automagically.
