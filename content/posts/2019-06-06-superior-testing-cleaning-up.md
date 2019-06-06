---
title: "Superior Testing: Cleaning Up"
description: "Making the world a better place, one byte at a time."
date: 2019-06-06
slug: superior-testing-cleaning-up
---

There is a game called [Viscera Cleanup Detail](https://en.wikipedia.org/wiki/Viscera_Cleanup_Detail).
The task in this game is to... clean things up.
Well, it is a bit more exciting since it involves alien invasions,
but at the end of the day players become space janitors.
It is surprisingly addictive.

Cleaning things is useful and helpful in a lot of ways.
Developers understand that, but usually there is an additional motivation
to keep things in order — users.
Nobody wants a product that breaks because there is not enough memory
or wrecks havoc across the file system.
The picture is very different with tests — often they become
a second class citizen. It shouldn’t be this way.

# RAM

It is interesting that not a lot of people bother with memory management
in tests. Tests run so fast and have such
short lifecycle that memory consumption doesn’t seem like an issue.
At the same time this short time-to-live cycle hits garbage collector hard.
And guess what works worse when there are memory leaks but
the execution demands more and more memory? That’s right — GC.
In practice it means that memory leaks and high memory consumption in general
slow down test runs, eventually leading to out-of-memory errors.

## Mockito

### Inline Mocking

Mockito 2.1.0 introduced [inline mocking](https://github.com/mockito/mockito/wiki/What%27s-new-in-Mockito-2#mock-the-unmockable-opt-in-mocking-of-final-classesmethods).
It allows to mock and spy `final` Java classes.
This might be useful in combination with Kotlin, where classes are `final` by default.
Unfortunately this mechanism [doesn’t work well with cyclic references](https://github.com/mockito/mockito/issues/1614).
At the same time the issue is so tricky [a new API](https://static.javadoc.io/org.mockito/mockito-core/2.27.0/org/mockito/MockitoFramework.html#clearInlineMocks--)
was introduced to mitigate this since it was not possible to resolve it automatically.
Use it!

```kotlin
@After fun clearMockito() {
    Mockito.framework().clearInlineMocks()
}
```

### Stubs

It might be surprising to find out how much Mockito does under the hood.
There is basically a mini-GC tracking all invocations.
Fortunately we can save a bit of memory using
[a not very popular method to create stubs](https://static.javadoc.io/org.mockito/mockito-core/2.27.0/org/mockito/MockSettings.html#stubOnly--)
which do not track invocations.
Use it to make dumb objects which will not be verified in the future.
Or not use Mockito at all for this, just create objects by hand.

We can make a handy Kotlin function which will reduce the boilerplate.

```kotlin
inline fun <reified T : Any> stub() = Mockito.mock(T::class.java, Mockito.withSettings().stubOnly()) as T
```
```kotlin
val actionStub = stub<Action>()
```

# Files

Dealing with files in tests is straightforward.

* Create files only in [temporary directories](https://en.wikipedia.org/wiki/Temporary_folder).
* Delete files after each run.

Not following these rules might result in myriads of files
scattered around in the project directory.
Especially if there are hundreds of them created and removed on each run.

Even better — do not repeat all necessary steps in all tests and
use [a JUnit rule](https://junit.org/junit4/javadoc/latest/org/junit/rules/TemporaryFolder.html)
instead. It is not even necessary to use JUnit 4 to use it.

```kotlin
val fileSystem by memoized { TemporaryFolder() }

beforeEach {
    fileSystem.create()
}

it("creates file system") {
    assertThat(fileSystem.root).exists()
}

afterEach {
    fileSystem.delete()
}
```

# Cleaning Up

Think about test runs this way — they should not leave anything behind.
Tests are ghosts. Or ninjas.
And seriously — [play the game](https://en.wikipedia.org/wiki/Viscera_Cleanup_Detail).
