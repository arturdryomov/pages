---
title: "Do Androids Dream of UI Testing?"
description: "Fear and Loathing in mobile QA"
date: 2018-05-26
slug: do-androids-dream-of-ui-testing
---

Automation is a foundation stone of the software development.
People didn’t like counting numbers themselves, so they invented calculators.
Calculators went to be computers and here we go, waiting for AI to take over,
[watching movies](https://en.wikipedia.org/wiki/Blade_Runner_2049) and
[playing games](https://en.wikipedia.org/wiki/Deus_Ex:_Human_Revolution) about transhumanism
on our way here.

Automation related to UI testing seems te be a Holy Grail from that standpoint.
Sure thing, it can replace manual QA procudures with automated ones! Like, completely!
You just need to have a local backend... And maybe disable animations.
And... you know, somehow wait for backend responses. And don’t forget about the infrastructure.

Let’s just slow down a little and go over all testing layers from
[the testing pyramid](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html) first:
UI, Integration, Unit. Google (as a company, not as a search result) suggests
a 70 (Unit), 20 (Integration), 10 (UI) split. This ratio is justified by rising
maintance cost, flakiness and run speed. Unit tests are as reliable as it gets,
UI tests are a great pain. Let’s go over them.

# Unit Tests

This is a majority of tests you should have (and I hope you have a lot of them already).
Honestly saying, almost everything can be unit-tested. You cannot test
things you shouldn’t test in the first place — like the Android framework code.
The OS is a black box — you give it some instructions and it does its best job
to run them. It might be widgets rendering on a device screen, sending Bluetooth
packages somewhere, you name it. And don’t forget that it was already tested for you.

If you use something from the framework and want to test
the interaction with it, do yourself a favor and introduce some abstractions.
More abstractions you have, easier it gets to write a maintanable testable code.
As a bonus, if you want to have a reactive API for the framework, you can do it yourself.
Want to use a specific thread to do the call — sure, let’s do it!
Just don’t try to cover the whole API — your application most likely doesn’t
use everything anyway.

```kotlin
interface Bluetooth {

    val supportsLe: Single<Boolean>

    class AndroidBluetooth(
        context: AndroidContext,
        ioScheduler: Scheduler
    ) : Bluetooth {

        override val supportsLe = Single
            .fromCallable { context.packageManager.hasSystemFeature(FEATURE_BLUETOOTH_LE) }
            .cache()
            .subscribeOn(ioScheduler)
    }
}

class TestBluetooth : Bluetooth {
    val supportsLeResult = PublishRelay.create<Boolean>

    override val supportsLe = supportsLeResult.take(1).singleOrError()
}
```

You can provide the `Bluetooth` instance using your Inversion of Control
implementation. `AndroidBluetooth` one for the real use and `TestBluetooth` for tests.

Regarding UI-related things — the topic was beaten
to death over and over again. MVP, MVVM, MVI — choose your poison. The `V` part
isolates framework widgets and related interactions, so you can test everything except it.
Create a `TestView`, provide `Test*`
dependencies and here we go, unit tests for the presentation layer!

## Tech Stack

The stability of unit tests comes directly from the environment.
The thing is — unit tests do not need anything extra from you in terms of
control. You don’t need to run an extra OS and change a lot of conditions.

Tests are executed as a regular JVM application on the JVM itself.
Nothing extra is required. Throw a bunch of bytecode at the JVM and you’re done.
And, since the JVM is a pretty much stable product, you have to deal with a single thing —
your code. Actually, the code you supply since most likely you use external libraries.

* Runners: [JUnit 4](https://github.com/junit-team/junit4),
  [JUnit 5](https://github.com/junit-team/junit5),
  [Spek](https://github.com/spekframework/spek),
  [Spectrum](https://github.com/greghaskins/spectrum).
* Assertions: [AssertJ](https://github.com/joel-costigliola/assertj-core),
  [Truth](https://github.com/google/truth).
* Mocks: [Mockito](https://github.com/mockito/mockito).

All of these have one thing in common — they are just a JVM bytecode produced by Java and (or) Kotlin compilers.
Since it is just a regular code pretty similar to the one you write every day,
you can understand it, modify it and even replace it.
In other words, you are fully capable of changing the environment.
This statement might sound obvious but it is extremely precious.

# Integration Tests

This category is an interesting one. Mostly because it is in a limbo between
unit tests and UI tests.

* Compose multiple components and test how do they work together.
* Make a UI test but do not use a real backend (which makes the test non-End-to-End one).

Both of these are actually integration tests.

In other words, a UI test is always an integration test, but a unit test is never an integration test.

# UI Tests

> UI testing differs from unit testing in fundamental ways.
> Unit testing enables you to work within your app's scope and allows you
> to exercise functions and methods with full access to your app's variables and state.
> UI testing exercises your app's UI in the same way that users do without access
> to your app's internal methods, functions, and variables.
> This enables your tests to see the app the same way a user does,
> exposing UI problems that users encounter.

This is actually a direct quote from
[Apple documentation](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html).

Sounds like a dream come true, right? Manual QA processes can be automated!
In theory, it is actually correct.

Test scenarios are getting described
in a programmatic way and the resulting scenario gets executed.
Scenarios generally consist of a number of steps:

* preparation — stub network responses, create files;
* actions — clicks on widgets, scrolls, gestures;
* checks — assertions that UI was changed approprietly.

Seems reasonable enough. Until the reality kicks in.

## Tech Stack

Android basically has a single official way to describe tests —
[Espresso](https://developer.android.com/training/testing/espresso/).
It is kind of meh in terms of declarative description, so generally
I recommend using [Kakao](https://github.com/agoda-com/Kakao) as a thin layer
on top of Espresso.

```kotlin
object CounterScreen : Screen<CounterScreen> {
    val incrementButton = KButton { withId(R.id.button_increment) }
    val decrementButton = KButton { withId(R.id.button_decrement) }
    val numberText = KTextView { withId(R.id.text_number) }
}

class CounterScreenTest {
    @Test fun `it works`() {
        CounterScreen {
            numberText.hasText("0")

            incrementButton.click()
            numberText.hasText("1")

            decrementButton.click()
            numberText.hasText("0")
        }
    }
}
```

This kind of setup works well. It is readable and maintainable.
Unfortunately we live in a connected world, so almost every action we do
leads to network requests and responses, database reads and writes and so on.

### `async` + `await`

Espresso has its own way to deal with async operations and it is called
[`IdlingResource`](https://developer.android.com/training/testing/espresso/idling-resource).
Basically saying it is an advanced `await`. You just need to integrate `IdlingResource`
all over the application. Send a request? Provide a way to `await` for its completion.

This approach sounds tedious so there are tools to help you with that.
If you use RxJava for all async operations you can use
[RxIdler](https://github.com/square/RxIdler).
For OkHttp network requests there is
[OkHttp Idling Resource](https://github.com/JakeWharton/okhttp-idling-resource).
Unfortunately nothing general works for complex applications with
a constant background processing work, like sending log files in background,
listening to a WebSocket — you name it. It is indeed possible to `await`
for the network response on a background thread and then get stuck on another
network request being done somewhere in the application.

The same thing goes to animations. For example, clicking a button should
show a next screen. The application actually does that, but includes a complex
animation for an undefined period of time. It is possible to provide
an `IdlingResource` for the animation or disable animations in the application
altogether, which leads to far less intrusion in the main codebase. Oops!
You’ve just made your tests less honest — they do not check how animations work,
so I guess you fall back to manual QA for that...

### Backend Communication

#### Real Backend

This way you are stepping in
[the danger zone](https://www.youtube.com/watch?v=siwpn14IE7E)
of End-to-End tests.

Using a real environment, not controlled in any way by tests,
brings a couple of painpoints on the table.

* Conflicts between tests. Running two tests in parallel
  using same credentials? Prepare to be kicked out if the backend doesn’t
  support multi-session. Changing data in one test and expecting to see
  a different one in another? Tough luck!
* Conflicts with backend itself. Running a test when
  a backend team wipes a database? Backend is offline? Too bad!

These two seem to be harmless and theoretical but they do exist in practice.
Introducing an environment you don’t control introduces points
of failure as a neat bonus.

Using a real environment, controlled by tests,
is a nice way to do End-to-End testing. Unfortunately you need
cooperation from the backend team.

* Implement an API to mutate the remote environment in tests.
  Like, `POST /v1/end-to-end/users/remove`.
* Provide a way to start and stop the entire backend infrastructure
  per test.

In the era of 100 microservices acting as a single backend system
these two tasks become almost impossible. But you can try!

#### Mocked Backend

Who needs a real backend? We’ll implement our own one!
And we have options.

* Pick [`MockWebServer`](https://github.com/square/okhttp/tree/master/mockwebserver)
  and describe responses necessary for tests.
* Replace network communication code with a mocked one.
  Oops! You’ve just made your tests less honest — they do not check
  how networking works.

Any attempt to have a separate backend implementation brings
a significant downside though — following the contract.
In ideal world a backend team follows a shared documented contract
describing public API calls in detail. Even then you should
stick to it to the letter, updating your own implementation all the time.
And don’t forget — nobody is perfect. Contract was updated but the implementation
doesn’t follow that? Prepare for issues in production. Tests will be fine though.

### Runtime Environment

Since the application is being run as-is JVM is not enough.
You’ll need to run an entire OS!

#### Devices

Nope, forget about that. It was just a dream you had...
All right, all right, I’ll explain the motivation.

The thing is — consumer devices are not ready for the workload
of thousands of tests being run on them constantly.

* Hardware will fail. Displays burn out, CPUs overheat, USB ports stop working.
  It is actually true and not an urban legend.
* Software will fail. Have you ever saw a full-screen firmware update screen
  during a test run? Maybe a dialog of some system application?
  It will be there eventually.

#### Emulators

The good thing about emulators is their dirt cheap resource cost.

* Each test run can use a brand-new emulator instance since the state
  can be wiped without consequences.
* Phone hardware is not required since emulators run on a host desktop OS
  essentially being a virtual machine.

Unfrotunately the tooling around emulators can be... cruel.

I’ve spent a couple of months (yes, you are reading this right)
debugging [emulators crashing on test runs](https://issuetracker.google.com/issues/66884503).
The worst thing with emulators instability is that almost anything
can be an issue. Host hardware CPU started to melt? Host OS kernel updated?
Say hello to emulators crashes and freezes.
The debugging loop is extremely painful. It requires constantly monitoring
emulators, collecting kernel dumps, analyzing OS conditions and hardware state.
Some approaches helped for some time, then everything started all over again.
It takes some effort to maintain the workable state of an emulator because...

The versioning in Android `sdkmanager`
[is seriously messed up](https://issuetracker.google.com/issues/38045649).
All packages have a name, i. e. `emulator`, and a revision, i. e. `4`.
It is possible to install a package, but it is not possible to install a package
of a certain revision. In other words, installing an `emulator` package
will always install the latest revision. Since revisions break things easily
the only way to introduce stability in this mess is to use a Docker image.
Unfortunately using Docker to run emulators is a so-so idea. It actually works,
but instead of host-OS-emulator-OS interaction there is a more complex one —
host-OS-Docker-emulator-OS. This brings even more instability.
As a bonus, there is a weird
[SDK tools archive naming scheme](https://issuetracker.google.com/issues/64292349)
you have to live with.
Oh, have I mentioned that there are
[multiple `emulator` binaries](https://issuetracker.google.com/issues/66886035)?

One can suggest to pick a stable hardware, a stable `emulator` binary,
a stable emulator `system-image` and stick to it using a Docker image.
Well, it doesn’t work this way. If the application you are trying to test
uses Google Play Services package you are forced to update the emulator `system-image`
from time to time since that package is actually bundled into it and
cannot be updated separatly.

## Forgot about ~~Dre~~ Selenium

It is hard to imagine that, but we are falling into the same trap all over again.
Our collegues from the web world struggle with
[UI tests instability](https://sqa.stackexchange.com/questions/32542/how-to-make-selenium-tests-more-stable)
for a long time. Just ask your coworkers for a honest opinion.

# Automation is a Lie?

Why are we doing this to ourselves?

> The bigger the trick and older the trick, the easier it is to pull, based on two principles.
> People think it can’t be that old and it can’t be that big for so many people to have fallen for it.
> The more the person invests, the less chance they will turn back.
> Eventually when one is challenged or questioned, it means its investment
> and thus intelligence is questioned. No one can accept that. Not even to themselves.

There is nothing wrong with the concept of UI testing. In theory it sounds great.
Unfortunately, the practice breaks it easily. Taking a look at a bigger picture
gives a reason for that.

Introducing non-controlled environments does not work well in real life.
UI tests introduce at least two of them:

* remote communication — network-accessible backend API;
* local communication — interaction with the OS.

There are methods to control both of them, but the domain can be an overkill
for small and medium teams. Not everybody is a lite backend developer
and a Linux DevOps engineer. It is a complex work, requiring effort and precision.
Running QEMU emulators in a Docker container on a Linux host machine —
it is not for everyone, believe me. I’ve been there.

# Integration Tests vs. UI Tests

Let’s compare two things.

There is an application with a lot of abstractions over everything imaginable.
Platform-specific code is contained behind a mockable interface (remember `Bluetooth`?).
UI-related components are behind interfaces as well (like in MVP, MVVM, MVI).
It is possible to mock all network interfaces (like Retrofit declarations).
In this case basically everything is a non-platform specific code
with mockable external sources. That means there is a way to launch
the whole application on the JVM, changing only a couple of things.
Invoking actions from the UI? Sure. Receiving mocked data from network?
Of course. Checking UI state? Yep.
In other words, this is a JVM-based integration testing covering
the majority of the application. Fast, reliable and understandable.
It even forces good abstractions as a bonus.

There is a UI tests suite. The backend is mocked locally. UI interactions
are made in an usual manner. There is a fleet of emulators either in the cloud
or as a local infrastructure. Sometimes it works, sometimes it doesn’t.
Runs are slow even with a state of the art sharding. Almost everything is tested,
even the OS framework that was tested via the company which provides it.

Which one would you choose?

