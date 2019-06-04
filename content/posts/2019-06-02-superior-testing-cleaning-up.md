---
title: "Superior Testing: Cleaning Up"
description: "Making the world a better place, one byte at a time."
date: 2019-06-02
slug: superior-testing-cleaning-up
---

There is an intersting game called [Viscera Cleanup Detail](https://en.wikipedia.org/wiki/Viscera_Cleanup_Detail).
The task in this game is to... clean things up.
Well, it is a bit more exciting since it involves alien invasions,
but in the end of the day players become space janitors.
It is surprisingly addictive.

The source code of things we do is like a kitchen.
There are useful tools there and there, appliances and dishware.
When things are in order it is so pleasant to make a sandwich but
when they are messed up — it is easier to order a pizza.
Developers understand that, but there is an additional motivation to keep things clean — users.
Nobody wants an IT product that breaks all the time.

The picture is very different with tests.
A lot of time tests become a second class citizen which is unfortunate.
Tests are an important tool and need to be kept in order.

# RAM

It it interesting that not a lot of people bother with memory management
in tests until it bites real hard. Tests run so fast and have such
short lifecycle that memory consumption seems like not an issue.
At the same time this short time-to-live cycle hits garbage collector hard.
And guess what works worse when there are memory leaks but
the execution demands more and more memory? That’s right — GC.
In practice it means that memory leaks and high memory consumption in general
slow down test runs, eventually leading to out-of-memory errors.

## Mockito

### Inline Mocking

Mockito 2.1.0 provides [inline mocking](https://github.com/mockito/mockito/wiki/What%27s-new-in-Mockito-2#mock-the-unmockable-opt-in-mocking-of-final-classesmethods).
Basically it allows to mock and spy `final` Java classes.
This might be useful in combination with Kotlin, where classes are `final` by default.
Unfortunately this mechanism [hits really hard with cyclic references](https://github.com/mockito/mockito/issues/1614).
At the same time the issue is so tricky [a new API](https://static.javadoc.io/org.mockito/mockito-core/2.27.0/org/mockito/MockitoFramework.html#clearInlineMocks--)
was introduced to mitigate this. Use it to avoid memory leaks.

```kotlin
fun afterEachTest() {
    Mockito.framework().clearInlineMocks()
}
```

### Stubs

It might be surprising to find out how much Mockito does under the hood.
There is basically a mini-GC tracking all invocations and more.
This is not cheap from computing standpoint.

Fortunately we can save a bit of memory using
[a not very popular method of creating stubs](https://static.javadoc.io/org.mockito/mockito-core/2.27.0/org/mockito/MockSettings.html#stubOnly--)
which do not track invocations.
Use it to make dumb objects which will not be verified.
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

Not following these rules might result in miriads of files
scattered around in the project directory.
Especially if there are hundreds of them created and removed on each run.

Even better — do not repeat all necessary steps in all tests and
use [JUnit rule](https://junit.org/junit4/javadoc/latest/org/junit/rules/TemporaryFolder.html)
instead. It is not even necessary to use JUnit 4 to use it.

```kotlin
val fileSystem by memoized { TemporaryFolder() }

beforeEach {
    fileSystem.create()
}

it("creates files") {
    assertThat(File(fileSystem.root, "file")).exists()
}

afterEach {
    fileSystem.delete()
}
```

# Cleaning Up

Think about test runs this way — they should not leave anything behind.
Tests are ghosts. Or ninjas.
And seriously — [play the game](https://en.wikipedia.org/wiki/Viscera_Cleanup_Detail).
