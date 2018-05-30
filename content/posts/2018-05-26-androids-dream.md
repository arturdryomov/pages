---
title: "Do Androids Dream of UI Testing?"
description: "Fear and Loathing in mobile QA"
date: 2018-05-26
slug: do-androids-dream-of-ui-testing
---

Automation is a foundation stone of the software development.
People didn’t like counting numbers themselves, so they invented calculators.
Calculators went to be computers and here we go, waiting for AI to take over,
[watching movies](https://en.wikipedia.org/wiki/Blade_Runner_2049)
about transhumanism on our way here.

Automation related to UI testing seems te be a Holy Grail from that standpoint.
Sure thing, it can replace manual QA procedures with automated ones! Like, completely!
You just need to have a local backend... And maybe disable animations.
And... you know, somehow wait for backend responses. And don’t forget about the infrastructure.

Let’s slow down a little and go over all testing layers from
[the testing pyramid](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html) first:
Unit, Integration, UI. The general suggested split is
70% (Unit), 20% (Integration) and 10% (UI). This ratio is justified by rising
maintenance cost, flakiness and run speed. Unit tests are as reliable as it gets,
UI tests are a great pain. Let’s go over all of them.

# Unit Tests

This is a majority of tests a project should have.
Honestly saying, almost everything can be unit-tested.
Things impossible to unit-test most likely shouldn’t be tested in the first place —
like the Android framework code.

The OS is a black box — it consumes instructions and does its best job
to run them. It might be widgets rendering on a device screen, sending Bluetooth
packets or reading [`sysfs`](https://en.wikipedia.org/wiki/Sysfs).
The whole point of the framework API is to
shield application developers from the OS. Use this advantage.

The easy thing to forget is that the framework was already tested
by Google internally. There is no need to test an external contract.
If there is a need to do so it is an indicator that the contract provider
breaks it. These things should be reported to the provider, otherwise,
there will be a constant battle with the environment.

If the application code references the framework, there is still a way to test
the interaction with it using abstractions.
More abstractions available, easier it gets to write a maintainable testable code.
As a bonus, it is possible to provide reactive API for the framework
or the one compatible with [coroutines](https://kotlinlang.org/docs/reference/coroutines.html).
There is no need to cover the whole API — the application most likely doesn’t
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
```
```kotlin
class TestBluetooth : Bluetooth {
    val supportsLeResult = PublishRelay.create<Boolean>

    override val supportsLe = supportsLeResult.take(1).singleOrError()
}
```

The `Bluetooth` instance should be provided via the Inversion of Control
implementation. `AndroidBluetooth` is for the real use and `TestBluetooth` is for tests.

About UI-related things — the topic was beaten
to death over and over again. MVP, MVVM, MVI — everything works. The `V` part
isolates framework widgets and related interactions, so it is possible to test
everything except it. Create a `TestView`, provide `Test*`
dependencies and here we go, unit tests for the presentation!

## Tech Stack

The stability of unit tests comes directly from the environment.
The thing is — unit tests do not need anything extra in terms of
control. There is no need to run an extra OS and change a lot of conditions.

Tests are executed as a regular JVM application on the JVM itself.
Nothing extra is required. Throw a bunch of bytecode at the JVM and it’s done.
And, since the JVM is a pretty much stable product, there is only a single thing to care about —
the project codebase. Actually, the supplied code since most likely external libraries would be used.

* Runners: [JUnit 4](https://github.com/junit-team/junit4),
  [JUnit 5](https://github.com/junit-team/junit5),
  [Spek](https://github.com/spekframework/spek),
  [Spectrum](https://github.com/greghaskins/spectrum).
* Assertions: [AssertJ](https://github.com/joel-costigliola/assertj-core),
  [Truth](https://github.com/google/truth).
* Mocks: [Mockito](https://github.com/mockito/mockito).

All these have one thing in common — they are a JVM bytecode produced by Java and (or) Kotlin compilers.
Since it is a regular code pretty similar to the one from the project codebase,
it is easy to understand it, modify it and even replace it.
In other words, there is a total control of the environment.
This statement might sound obvious but it is precious.

# Integration Tests

This category is an interesting one. Mostly because it is in a limbo between
unit tests and UI tests.

* Compose multiple components and make a test about
  how do they work together using the same
  JVM-based approach as for unit tests.
* Make a UI test but do not use a real backend
  (which makes the test a non-End-to-End one).

Both of these are actually integration tests since they test integration between components.
The UI test will test a much more sophisticated combination though.

In other words, a UI test is always an integration test, but a unit test is never an integration test.

# UI Tests

> UI testing differs from unit testing in fundamental ways.
> Unit testing enables you to work within your app's scope and allows you
> to exercise functions and methods with full access to your app's variables and state.
> UI testing exercises your app's UI in the same way that users do without access
> to your app's internal methods, functions, and variables.
> This enables your tests to see the app the same way a user does,
> exposing UI problems that users encounter.
>
> -- [*Apple documentation*](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)

Sounds like a dream come true, right? Manual QA processes can be completely automated!

The difference from manual procedures is in a programmatic-ish approach.
Test scenarios are getting described as a regular test suite.
The resulting suite gets executed.
Scenarios generally consist of a number of steps:

* preparation — stub network responses, create files;
* actions — clicks on widgets, scrolls, gestures;
* checks — assertions that UI was changed appropriately.

## Tech Stack

Android has a single official way to describe tests —
[Espresso](https://developer.android.com/training/testing/espresso/).
It is kind of meh in terms of declarative description, so generally
I recommend using [Kakao](https://github.com/agoda-com/Kakao) as a thin layer
on top of Espresso. The result looks something like that.

```kotlin
object CounterScreen : Screen<CounterScreen> {
    val incrementButton = KButton { withId(R.id.button_increment) }
    val decrementButton = KButton { withId(R.id.button_decrement) }
    val numberText = KTextView { withId(R.id.text_number) }
}
```
```kotlin
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
Unfortunately, the world around us is highly connected, so almost every action we do
leads to network requests and responses, database reads and writes and so on.

### `async` + `await`

Espresso has its own way to deal with async operations and it is called
[`IdlingResource`](https://developer.android.com/training/testing/espresso/idling-resource).
Basically saying it is an advanced `await`. Developers just need to integrate `IdlingResource`
all over the application. Send a request? Provide a way to `await` for its completion.

Honestly saying it is a fair solution. There is no silver bullet to magically
`await` for an `async` operation without accessing some entry points.

This approach sounds tedious though so there are tools to help with that.
For RxJava operations it is possible to use
[RxIdler](https://github.com/square/RxIdler).
For OkHttp network requests there is
[OkHttp Idling Resource](https://github.com/JakeWharton/okhttp-idling-resource).
Unfortunately, nothing general works for complex applications with
a constant background processing work, like sending files in background periodically,
listening to a WebSocket and so on. Using general approaches can lead to a successful `await`
for the network response on a background thread and then getting stuck on another
network request being done somewhere in the application since there is an `await`
for all background processes and all network responses.

The same thing goes for animations. For example, clicking a button invokes
showing a next screen. The application actually does that but includes a complex
animation for an undefined time interval. It is possible to provide
an `IdlingResource` for the animation or disable animations in the application
altogether, which leads to far less intrusion in the main codebase.

> :warning: Disabling animations makes tests more stable but less honest —
> they do not check how animations work and to which events they might lead.

### Backend Communication

#### Real Backend

This is [the danger zone](https://www.youtube.com/watch?v=siwpn14IE7E) of End-to-End tests.

##### Regular Shared Instance

Using a real environment, not controlled in any way by tests,
brings a couple of painpoints on the table.

* Conflicts between tests. Running two tests in parallel
  using same credentials? Prepare to be kicked out if the backend doesn’t
  support multi-session. Changing data in one test and expecting to see
  a different one in another? Tough luck!
* Conflicts with backend itself. Running a test when
  a backend team wipes a database? Backend is offline? Too bad!

These two seem to be harmless and theoretical but they do exist in practice.
The lack of control brings points of failure as a neat bonus.

##### Test-Controlled Isolated Instances

Using a real environment, controlled by tests, is a good idea.
Unfortunately, it requires cooperation from the backend team.

* Implement an API to mutate the remote environment in tests.
  Like, `POST /end-to-end/users/remove`.
* Provide a way to start and stop the entire backend infrastructure
  per test.

In the era of 100 microservices acting as a single backend system
these tasks become almost impossible. Personally, I’ve observed
a progression from _can be run on a single machine_ to _no way it runs on a single machine_.
This kind of resource consumption can be an unachievable luxury —
starting a whole backend cluster per test is too much.

#### Mocked Backend

Who needs a real backend? We’ll implement our own one!
And we have options.

* Pick [`MockWebServer`](https://github.com/square/okhttp/tree/master/mockwebserver)
  and describe responses necessary for tests.
  The same can be achieved with a clever blocking OkHttp `Interceptor`.
* Replace network communication code with a mocked one.

> :warning: Replacing network-related code makes tests less honest
> from the integration standpoint.

Any attempt to have a separate backend implementation brings
a significant downside though — following the contract.

In ideal world, the backend team follows a shared documented contract
describing public API calls in detail. Even then the mobile team should
stick to it to the letter, updating the implementation all the time.
Fortunately, it can be semi-automated using tools like
[Apache Thrift](https://thrift.apache.org/).

Since nobody is perfect and people communication remains one of the toughest issues in CS
there might be issues. The contract was updated but the implementation
doesn’t follow that? Prepare for issues in production. Tests will be fine though.

### Infrastructure

Since the application is being run as-is, just like a regular one on a consumer device,
JVM is not enough. Prepare to run an entire OS!

#### Devices

It doesn’t work. Moving on...
All right, all right, there is actually a motivation.

The thing is — consumer devices are not ready for the workload
of thousands of tests being run on them constantly.

* Hardware will fail. Displays burn out, CPUs overheat, USB ports stop working.
  It is actually true and not an urban legend.
* Software will interrupt. Full-screen firmware update notification
  during a test run? Maybe a dialog of some system application?
  It will be there eventually.

#### Emulators

The good thing about emulators is their dirt cheap resource cost.

* Each test run can use a brand-new emulator instance since the state
  can be wiped without consequences.
* Phone hardware is not required since emulators run on a host desktop OS
  essentially being a virtual machine.

Unfortunately, the tooling around emulators can be... cruel.

I’ve spent a couple of months (yes, you are reading this right)
debugging [emulators crashing on test runs](https://issuetracker.google.com/issues/66884503).
The worst thing with emulators instability is that almost anything
can be an issue. Host hardware CPU started to melt? Host OS kernel updated?
Say hello to emulators crashes and freezes.
The debugging loop is extremely painful. It requires constantly monitoring
emulators, collecting kernel dumps, analyzing OS conditions and hardware state.
Some approaches helped for some time, then everything started all over again.
It takes quite an effort to maintain the workable state of emulators because...

The versioning in Android `sdkmanager`
[is seriously messed up](https://issuetracker.google.com/issues/38045649).
All packages have a name, i.e. `emulator`, and a revision, i.e. `4`.
It is possible to install a package, but it is not possible to install a package
of a certain revision. In other words, installing the `emulator` package
will always install the latest revision. Since revisions break things easily,
the only way to introduce stability in this mess is to use a Docker image.
Unfortunately, using Docker to run emulators is a so-so idea. It actually works,
but instead of Host OS ↔ Emulator OS interaction there is a more complex one —
Host OS ↔ Docker ↔ Emulator OS. This brings even more instability.
As a bonus, there is a weird
[SDK tools archive naming scheme](https://issuetracker.google.com/issues/64292349)
we have to live with.
Oh, have I mentioned that there are
[multiple `emulator` binaries](https://issuetracker.google.com/issues/66886035)?

One can suggest picking a stable hardware, a stable `emulator` binary,
a stable emulator `system-image` and stick to it using a Docker image.
Well, it doesn’t work this way. If the application
uses Google Play Services package there is a need to update the emulator `system-image`
from time to time since that package is actually bundled into it and
cannot be updated separately.

## Forgot about ~~Dre~~ Selenium

It is hard to imagine that, but we are falling into the same trap all over again.
Our colleges from the web world struggle with
[UI tests instability](https://sqa.stackexchange.com/questions/32542/how-to-make-selenium-tests-more-stable)
for a long time. Just ask your coworkers for an honest opinion.

OK, don’t trust random people from the internet? Do you trust a huge company
with millions of tests and the statistical data about flakiness?
[Here we go](https://testing.googleblog.com/2017/04/where-do-our-flaky-tests-come-from.html).

Why are we still doing this to ourselves?

> The bigger the trick and older the trick, the easier it is to pull.
> People think it can’t be that old and it can’t be that big for so many people to have fallen for it.
>
> The more the person invests, the less chance they will turn back.
> Eventually, when one is challenged or questioned, it means its investment
> and thus intelligence is questioned. No one can accept that. Not even to themselves.
>
> -- [*Revolver (2005)*](https://en.wikipedia.org/wiki/Revolver_(2005_film))

# Automation is a Lie?

There is nothing wrong with the concept of UI testing. In theory, it sounds great.
Unfortunately, the practice breaks it easily. Taking a look at a bigger picture
gives a reason for that.

Introducing non-controlled environments does not work well in real life.
UI tests introduce at least two of them:

* remote communication — network-accessible backend API;
* local communication — interaction with the OS.

There are methods to control both of them, but the domain can be an overkill
for small and medium-sized teams. Not everybody is a backend developer
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
Invoking actions from the UI? Sure. Receiving mocked data from the network?
Of course. Checking UI state? Yep.
In other words, this is a JVM-based integration testing covering
the majority of the application. Fast, reliable and understandable.
It even forces good abstractions as a bonus.

There is a UI tests suite. The backend is mocked locally. UI interactions
are made in a usual manner. There is a fleet of emulators either in the cloud
or as a local infrastructure. Sometimes it works, sometimes it doesn’t.
Runs are slow even with a state of the art sharding. Almost everything is tested,
even the OS framework that was tested via the company which provides it.

*Which one would you choose?*

Personally, I would pick a good integration test covering 70% of possible
scenarios over any UI test covering 90%. The difference is just not worth it.

* Development resources spent trying to stabilize non-controlled environments
  is a waste.
* Anything even remotely flaky brings the opposite of confidence to developers.
  People just press the Restart button all over again, because at this point
  they are sure that the issue is with the environment and not the test itself.

Besides, there is a technique called _Testing in Production_. This is not a joke.
Monitoring, feature flags, A/B experiments and more — all of these are actually
related to the in-production testing.
There is [a great article](https://medium.com/@copyconstruct/testing-in-production-the-safe-way-18ca102d0ef1)
about it.

Recently I’ve done a technical exit interview with a former co-worker of mine.
One of the questions I’ve asked was about the best thing in the project
and the worst one from the technical perspective.

* The best thing — BDD-style [Spek](https://github.com/spekframework/spek)
  unit tests. It was a pure joy to write and read them.
* The worst thing — UI tests. Their flakiness and constant battles
  with environments wore the person down. _It was a useless waste of time._

Fun fact. I’ve monitored UI tests for a couple of months with a goal to note
all bugs caught by them. The number was zero in the end. The majority
of risky code was caught by an extensive unit tests suite.

# The Fall

> I’ve seen things you people wouldn’t believe.
> Attack ships on fire off the shoulder of Orion.
> I watched C-beams glitter in the dark near the Tannhäuser Gate.
> All those moments will be lost in time, like tears in rain.
>
> -- [*Roy Batty*](https://en.wikipedia.org/wiki/Tears_in_rain_monologue)

It is always hard to let go. A lot of effort was put into writing
[a custom test runner](https://github.com/gojuno/composer),
[a custom emulators manager](https://github.com/gojuno/swarmer),
a mock HTTP server with SSE streaming support. A lot of time was spent
on maintaining emulator-running nodes based on Linux and Docker.
A lot of knowledge was put into creating a number of Espresso tests.
Disabling UI tests from a CI pipeline was a painful experience.
Like waving goodbye to a good friend.

*Do Androids Dream of Integration Testing?*

---

Title is the reference to the [Blade Runner](https://en.wikipedia.org/wiki/Blade_Runner)
movie and to [the original novel](https://en.wikipedia.org/wiki/Do_Androids_Dream_of_Electric_Sheep%3F).

---

Thanks to [Artem Zinnatullin](https://twitter.com/artem_zin) and
[Igor Gomonov](https://www.linkedin.com/in/igor-gomonov-a66903b7/) for the review!
