---
title: "Reactive Abstractions in Android World"
description: "Abstracting and testing platform interactions."
date: 2018-08-26
slug: reactive-abstractions-in-android-world
---

Who knows how many test suites were not created because of a classic parry.

> It cannot be tested — it uses a platform call!

Well, it is not actually true all the time.
Unit testing something that only a human eye and neural networks
can catch — like animations — doesn’t make sense.
On the other hand, retrying a network request on a re-established connection
can and should be tested. As a bonus, it is possible to gain a couple of perks.

# Theory

The main advice I can give Android developers about testing —
start thinking about the codebase as a platform-agnostic environment.
Not in a ridiculous way but in a more pragmatic one — otherwise, it is too
easy to slip on a dark cross-platform path. Associating the codebase
with the JVM platform and not specifically Android is a better idea.
Framework-related interactions can be plugged-in as composable blocks.

Another advice — embrace abstractions available on hand.
Samples in this article are based on RxJava but it is possible to replace it
with `Future`, `Promise` or Kotlin coroutines.
This is especially useful with `async` + `await` type of interactions.
Believe me, it is not wise to do everything from scratch if there is a good tech
available. Moreover, it is easier to maintain consistency
in the codebase if each component speaks using the same constructs.
Do not repeat the [Tower of Babel](https://en.wikipedia.org/wiki/Tower_of_Babel) fall.

# Practice

Lke it or not — platform interactions leak into the business logic.
It is understandable — the environment capabilities should be utilized and not ignored.

At the same time it is essential to test the logic of the final product —
otherwise, there will be no product at all, only issues and undefined behavior.

Fortunately enough, the mankind deals with such issues for a while.
Let’s use a weight measurement example. How much does a brick weight?
Well, certainly less than a space station and more than an atom.
That characteristic does not really help when it is necessary to transport
a number of bricks. Will a car break under a million bricks?
That’s why humanity created _abstractions_, such as grams, kilograms and tons.
It is possible to take this completely (but collectively) made up measurement unit
and apply it everywhere.

Software development provides means to create abstractions easy-as.
It is not necessary to create
an [ISO](https://www.iso.org/) committee to create one — a programming language is enough.
Android is not an exception — and it never was.

## Connectivity

It can be useful to retry stalled network requests when OS reconnects
to a network access point. In fact,
[`ConnectivityManager`](https://developer.android.com/reference/android/net/ConnectivityManager)
was there for centuries and can help with this issue:

> The primary responsibilities of this class are to:
> monitor network connections (Wi-Fi, GPRS, UMTS, etc)...

The usage of the potential abstraction looks like this.

```kotlin
disposable += connectivity.available.subscribe(refresh)
```

Seems like a single stream will be enough. Let’s do it!

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
```

Marvelous! A couple of things to notice here.

The `Observable` itself handles proper `Listener` setting on subscription and
unsetting on unsubscription. It uses the
[Dispose pattern](https://en.wikipedia.org/wiki/Dispose_pattern),
i. e. the RxJava `Disposable`. Since all `Observable` behave the same
the end-user of the `Connectivity` will work with it as with any other
`Observable`.

Since there is an `interface` it is easy to provide a `Test*` implementation
for unit tests. Just a single call to simulate the real-world behavior and that’s it —
it is possible to test a code which works with the platform framework.

```kotlin
class TestConnectivity : Connectivity {
    override val available = PublishSubject.create<Unit>()
}
```

```kotlin
context("connectivity becomes available") {

    beforeEach {
        connectivity.available.onNext(Unit)
    }

    it("refreshes") {
        verify(refresh).run()
    }
}
```

## Launching

What about starting something via `Intent`? The operation itself is trivial,
but it is necessary to keep in mind that there might be an `ActivityNotFoundException`.
This exception is being thrown when nobody can handle our intention.

```kotlin
disposable += launcher.launch(Request.ShareText("Ping!"))
    .observeOn(mainThread)
    .subscribe {
        when (result) {
            Result.Success -> view.showSuccessAlert()
            Result.Failure -> view.showFailureAlert()
        }
    }
```

To achieve this we are going to create our own abstraction over `Intent`.
Doing so will hide the complexity and will help to avoid a copy-paste
of the same `Intent` building over and over again.

```kotlin
interface Launcher {

    sealed class Request {
        data class ShareText(val text: String) : Request()
    }

    enum class Result { Success, Failure }

    fun launch(request: Request): Single<Result>

    class AndroidLauncher(
            private val application: Application,
            private val mainScheduler: Scheduler
    ) : Launcher {

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

        private inline fun createIntent(request: Request) = when (request) {
            is Request.ShareText -> {
                val intent = Intent(Intent.ACTION_SEND).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, request.text)
                }

                Intent.createChooser(intent, /* chooser title */ null)
            }
        }
    }
}
```

We are controlling the thread under the hood so the consumer does not need to know
implementation details.

An attentive reader might notice that we are using
another abstraction — `Application#currentActivity`. It is trivial to implement using
[`ActivityLifecycleCallbacks`](https://developer.android.com/reference/android/app/Application.ActivityLifecycleCallbacks) and
`Connectivity`-like approach to listeners and callbacks.

Of course, we can test the behavior.

```kotlin
class TestLauncher: Launcher {
    val result = SingleSubject.create<Result>()

    override fun launch(request: Request) = result
}
```

```kotlin
context("launch result is success") {

    beforeEach {
        launcher.result.onSuccess(Result.Success)
    }

    it("shows success alert") {
        verify(view).showSuccessAlert()
    }
}

context("launch result is failure") {

    beforeEach {
        launcher.result.onSuccess(Result.Failure)
    }

    it("shows failure alert") {
        verify(view).showFailureAlert()
    }
}
```

## Google Play Services

The concept works well not only with the platform
but with all third-party information sources — such as various SDK.
In such cases, it is possible to improve the external API — for example,
provide proper nullability handling if the SDK is not annotated with `@Nullable` and `@NonNull`.

Let’s say it is necessary to show a warning if Google Play Services
is not installed.

```kotlin
disposable += googlePlayServices.available
    .filter { it == false }
    .observeOn(mainThread)
    .subscribe(view::showGooglePlayServicesWarningAlert)
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

The work is done on IO thread since retrieving the information can take an undefined amount of time.
Since the RxJava is used all multi-threading mumbo-jumbo is handled automagically.

And of course, it is possible to test the behavior without mocking static
`GoogleApiAvailability` `getInstance()` method.

# Retrospective

The beautiful thing about abstractions is that they are universal and can be applied everywhere.

* Runtime permissions.
* Requesting data from other applications via `startActivityForResult`.
* Notifications and push messages processing.
* Location updates, accessibility, battery checks and more.

At the same time, using a high-level abstraction — like a reactive approach and
RxJava in particular — brings a couple of benefits.

* Proper multi-threading maintained via producers.
* Ease of testing via producer-consumer components such as `Subject`.

The ironic thing about abstractions is that developers create them all the time
for their own domain but tend to avoid creating them for external sources.
Do not make this mistake.
