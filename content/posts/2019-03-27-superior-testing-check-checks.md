---
title: "Superior Testing: Check Your Checks"
description: "Testing tests is useless for sure but correct checks are important!"
date: 2019-03-27
slug: superior-testing-check-checks
---

[False positives](https://en.wikipedia.org/wiki/False_positives_and_false_negatives#False_positive_error).
Such an interesting combination of words, isn’t it?
The nature of false positives is mostly human.
We misinterpret conditions, define them wrong, forget about effects —
but the machine obeys. We get what we want but not what we need.
This is dangerous. The civilization downfall in various
science fiction books is a false positive result. The AI gets instructions
to eliminate all threats, humanity becomes the threat, roll the action scene.
This is so not new that we got used to it.

Another thing easy to ignore is how we check condition results.
In a world where more and more code becomes async those conditions become
increasingly complex. The complexity means errors, errors mean bugs and
bugs — as we know — mean [war](https://en.wikipedia.org/wiki/Starship_Troopers_(film)).

# Assertions

A lot of time had passed since [`assert.h`](https://en.wikipedia.org/wiki/Assert.h) till
[AssertJ](http://joel-costigliola.github.io/assertj/) but the concept remains the same.
Assertions are perfect for testing.
Check the condition, if it succeeds — proceed with the execution,
if it fails — raise an error and fail the test.

It does not matter what to use on the JVM platform. There are AssertJ,
[Truth](https://google.github.io/truth/) and [Hamcrest](http://hamcrest.org/).
I’m stuck with AssertJ because it feels good to use. I even remember
[AssertJ Android extensions](https://github.com/square/assertj-android)!
Good times. Don’t listen to me, better read
the [thorough comparison](https://google.github.io/truth/comparison).

Assertions fail short with side effects though. For example, we need to check
not only the result of the function but the analytics call underneath.

```kotlin
fun calculate(): Result {
    analytics.trackEvent("Calc")

    return businessResult()
}
```

Yes, it is a meh peace of code, functional programming is superior, yada-yada-yada.
The thing is — `analytics.trackEvent` does not have a result. Most likely
it calls weird SDK and we are not interested in workings behind it.

```kotlin
interface Analytics {
    fun trackEvent(event: String)
}
```

This is where we remember about...

# Verifications

It is a no-brainer — [Mockito](http://mockito.org/) is the right choice.

```kotlin
val analytics = mock<Analytics>()

calculate()

verify(analytics).trackEvent("Calc")
```

Looks like magic, right? Well, it kinda is — a lot of reflection is involved,
intercepting invocations and a bit of salt. It works though and works well.

Let’s take a look at another example.

```kotlin
interface Calculator {

    val plus: Consumer<Int>

    class Impl(onPlus: Consumer<Int>) : Calculator {

        override val plus = Consumer<Int> {
            onPlus.accept(2)
            onPlus.accept(4)
        }
    }
}
```
```kotlin
@Test fun testPlus() {
    val onPlus = mock<Consumer<Int>>()
    val calculator = Calculator.Impl(onPlus)

    calculator.plus.accept(2)

    verify(onPlus).accept(2)
}
```
```
TEST PASSED
```

Not exactly an expected result. `Calculator.Impl.plus` invokes `onPlus` two times.
The first call passes `2`, the second one passes `4`. We are checking that
`2` was passed and... it is actually completely correct. `2` was passed, right?
We haven’t specified the window when was it passed and what happened after it did.

This behavior is dangerous when we check side effects of various nature.
For example, we might change a text message on UI. We do that, write a test
that verifies text changing action and it passes. Unfortunately, it is possible
to find out that the message was changed again, to another text we don’t want to see.

The good news is — Mockito has [a verification mode](https://static.javadoc.io/org.mockito/mockito-core/2.25.1/org/mockito/Mockito.html#only--)
which checks exactly what we need.

```diff
- verify(onPlus).accept(2)
+ verify(onPlus, only()).accept(2)
```
```
TEST FAILED

org.mockito.exceptions.verification.NoInteractionsWanted:
No interactions wanted here:
-> at Test.kt
But found this interaction on mock 'consumer':
-> at Calculator$Impl$plus$1.accept(Calculator.kt)
***
For your reference, here is the list of all invocations ([?] - means unverified).
1. [?]-> at Calculator$Impl$plus$1.accept(Calculator.kt:8)
2. [?]-> at Calculator$Impl$plus$1.accept(Calculator.kt:9)
```

Nice! What can we do with this though? How do we make verifications correct?

* Forget about `verify`. Use this Kotlin extension instead.

    ```kotlin
    inline fun <T> verifyOnly(mock: T): T = Mockito.verify(mock, Mockito.only())
    ```

* Learn about [`clearInvocations`](https://static.javadoc.io/org.mockito/mockito-core/2.25.1/org/mockito/Mockito.html#clearInvocations-T...-).
  It is useful for tests where there is an interest in checking behavior
  after a particular state and all interactions before this state are irrelevant.

    ```kotlin
    @Test fun testCalculate() {
        repeat(42) { calculator.plus(it) }
        clearInvocations(onPlus)

        calculator.plus(1)
        verifyOnly(onPlus).accept(1)
    }
    ```

# RxJava Assertions

Don’t be so sure that these assertions are the same faithful assertions described above.
Observe!

```kotlin
interface Calculator {

    val value: Observable<Int>
    val plus: Consumer<Int>

    class Impl : Calculator {

        override val value = BehaviorSubject.create<Int>().toSerialized()

        override val plus = Consumer<Int> {
            value.onNext(2)
            value.onError(RuntimeException())
        }
    }
}
```
```kotlin
@Test fun testPlus() {
    val valueObserver = TestObserver<Int>()
    val calculator = Calculator.Impl().apply {
        value.subscribe(valueObserver)
    }

    calculator.plus.accept(2)

    valueObserver.assertValue(2)
}
```
```
TEST PASSED
```

Not expected, right? `Calculator.Impl.plus` emits the value event and the terminal error event.
Is it what we want? Most likely not — the test passes but in real-life
we’ll see either an error message or an application crash. Not a good thing.

[`assertValue`](http://reactivex.io/RxJava/javadoc/io/reactivex/observers/BaseTestConsumer.html#assertValue-io.reactivex.functions.Predicate-)
checks only value events — nothing more, nothing less.
At the same time, `Observable` can be terminated either via completion or an error.

Thankfully there are more suitable checks.

* [`assertValuesOnly`](http://reactivex.io/RxJava/javadoc/io/reactivex/observers/BaseTestConsumer.html#assertValuesOnly-T...-) —
  will check for values and for no terminal events.
* [`assertResult`](http://reactivex.io/RxJava/javadoc/io/reactivex/observers/BaseTestConsumer.html#assertResult-T...-) —
  will check for the value and for completion event. Useful for testing `Single`.

```diff
- valueObserver.assertValue(2)
+ valueObserver.assertValuesOnly(2)
```
```
TEST FAILED

Error(s) present: (latch = 0, values = 1, errors = 1, completions = 0)
```

# The Cruel, Cruel World

Let’s take a step back and take a look at the bigger picture.
False positives described above are caused by fundamentally dangerous practices.

* Verifications are side effect checks. Side effects are gross.
* RxJava assertions are multi-result checks. Multiple results mean more complexity.

Of course, both of these should be resolved via a simpler approach — pure functions.
Passing inputs, receiving outputs — that’s it. Asserts are enough for such flows.
Unfortunately, the state of tech is not mature enough to implement this utopia.
In the meanwhile, be careful on the way to the
[Valley Beyond](https://westworld.fandom.com/wiki/Valley_Beyond).
