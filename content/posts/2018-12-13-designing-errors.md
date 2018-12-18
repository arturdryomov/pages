---
title: "Designing Errors with Kotlin"
description: "Checked and unchecked, recoverable and unrecoverable — what to pick?"
date: 2018-12-13
slug: designing-errors-with-kotlin
---

Fun fact — the area of
[the Java island](https://en.wikipedia.org/wiki/Java) is 138 793 km²,
[the Kotlin island](https://en.wikipedia.org/wiki/Kotlin_Island) occupies 15 km².
Of course, it is blatantly incorrect to compare languages based on same-named island areas.
At the same time, it brings things in perspective. Java is the cornerstone
of the JVM platform. The platform itself overshadows everything it hosts:
Groovy, Ceylon, Scala, Clojure and Kotlin. It brings
a lot to the table — error handling is no exception (pun intended).

Exceptions! Developers adore exceptions. It is so easy to `throw` an error
and forget about consequences. Is it a good idea though? Should Kotlin follow
the same path? Fortunately enough there are many good languages we can learn from.
Let’s dive in!

# Java

There are checked and unchecked exceptions.
Checked ones are not favored among developers since their handling
is forced by the function signature.
I think the root of the checked exceptions discontent
is the duality it introduces. The caller is forced to
work not only with the function result but with
the possible exception. This creates a lot of friction.
At the same time, checked exceptions are useful to enforce
a desired behavior. From that perspective, unchecked exceptions are actually
worse — unchecked ones are implicit and easy to miss, checked ones
are explicit and defined in the declaration.

```java
File open(String filename) throws IOException
```

Another option is to return `null` or magic values when something went wrong.
It can be called either a C-style or a documentation-driven error handling —
the caller is expected (but not enforced) to check the function result
for a special case. The case itself is either documented or not — in such situations
the process transforms into a goose chase for implicit errors.

# Swift

Errors in Swift resemble Java checked exceptions.
Error-producing functions are required to be annotated with the `throws` keyword.

```swift
func open(filename: String) throws -> File
```
```swift
do {
    try open("file.txt")
} catch {
    print("Gotta catch them all!")
}
```

The neat part is that only throwing functions are allowed to `throw`.
Non-annotated functions are required to handle their exceptions themselves.
There are no unchecked exceptions.

Another neat detail — there are no exceptions in Swift. Yep. In fact,
[the documentation](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html)
is very careful to not even mention exceptions and uses the Error term instead.
`throws` and `throw` keywords are just a syntax sugar for working with additional return
value. `throw` writes an error to a register and `try` reads it.
Essentially it is like returning a `Pair` or an `Either`.

> :book: Technical details are explained in
> [the excellent article](https://www.mikeash.com/pyblog/friday-qa-2017-08-25-swift-error-handling-implementation.html)
> by Mike Ash.

At the same time,
[there is an accepted proposal](https://github.com/apple/swift-evolution/blob/master/proposals/0235-add-result.md)
to introduce the `Result` type to the standard library as an alternative
to `throw`-driven workflows. It can be seen as a more explicit, manual
approach to propagating errors to callers. `Result` eliminates
the function result vs. error duality via combining both of them.

```swift
enum Result<Value, Error> {
    case value(Value)
    case error(Error)
}
```

# Go

Fortunately or not Go doesn’t have either Java-like exceptions or
Swift-like syntax sugar. And it is this way [by design](https://golang.org/doc/faq#exceptions).
Explicit return values are used instead.

```go
func open(filename: String) (*File, error)
```
```go
file, err := open("file.txt")

if err != nil {
    println("YARRR!")
}
```
Basically, each function which might result in an error returns a pair
of a value and an error. That’s it! Looks like a C-style error
handling, but at least it is explicit and type-safe. The style
is verbose, but it works surprisingly good due to the universal application.

> :book: There is [a great article](https://evilmartians.com/chronicles/errors-in-go-from-denial-to-acceptance)
> on coping with Go error handling by Sergey Alexandrovich.

There is a `panic` function which might look like a Java
unchecked exception. Using enough hacks makes it possible to catch `panic` errors
but it is considered non-idiomatic.
`panic` is the last call for help when things got really, really bad.

```go
panic("on the streets of London")
```

# Rust

Rust takes what Go has and moves it to the next level, defining
two error categories
[right in the documentation](https://doc.rust-lang.org/book/ch09-00-error-handling.html):

> Rust groups errors into two major categories: recoverable and unrecoverable errors.
> For a recoverable error, such as a file not found error, it’s reasonable to report
> the problem to the user and retry the operation.
> Unrecoverable errors are always symptoms of bugs,
> like trying to access a location beyond the end of an array.

That’s what I like about Rust — the straightforward declaration of principles.

* There are no exceptions — neither Java-like or Swift-like.
* There is a `panic!` macros — but there are no ways to recover.
* There is a `Result` type with a number of helper functions on top.

```rust
panic!("at the Disco")
```

```rust
enum Result<Value, Error> {
    Ok(Value),
    Err(Error),
}
```

# Kotlin

Welcome back to the JVM world!

Kotlin
[does not have checked exceptions](https://kotlinlang.org/docs/reference/exceptions.html#checked-exceptions).
Well, actually [it does](https://kotlinlang.org/docs/reference/java-to-kotlin-interop.html#checked-exceptions),
mostly for Java interop purposes.

```kotlin
@Throws(IOException::class)
fun open(filename: String): File {
    throw IOException("This is a checked, checked world.")
}
```

Since Kotlin runs on the JVM platform, there are unchecked exceptions.
However, Kotlin is not Java — it has a couple of benefits.
Specifically — it is possible to use `sealed class` and pattern matching
to return a union of values and use it. Yep, just like the `Result` type.

```kotlin
sealed class Result<Value, Error> {
    data class Success(val value: Value) : Result()
    data class Failure(val error: Error) : Result()
}
```
```kotlin
fun open(filename: String): Result<File, String>
```
```kotlin
val result = open("file.txt")

when (result) {
    is Success -> println(result.value.path)
    is Failure -> println(result.error)
}
```

In fact, there is [an accepted proposal](https://github.com/Kotlin/KEEP/blob/master/proposals/stdlib/result.md)
to include a similar type in the standard library, but it is a bit weird
since it is scoped to coroutines. Not to worry! It is still possible to introduce
a project-specific one. Even better — create various `sealed class` for domain-specific
tasks, which might include more than two states.

```kotlin
sealed class Result {
    data class Progress(val percent: Int) : Result()
    data class Success(val file: File): Result()
    sealed class Failure : Result() {
        object Disconnect : Failure()
        data class Undefined(val code: Int) : Failure()
    }
}

fun download(url: HttpUrl): Result
```

Unfortunately, there are no ways to ban the `catch` keyword and
mentally map it to the `panic` invocation. It is still possible
to control this in the scope of a codebase, but it doesn’t scale
well with the growing number of developers.

# Bonus: RxJava

[The Observable Contract](http://reactivex.io/documentation/contract.html)
introduces three basis notifications: `onNext`, `onComplete` and `onError`.
Unfortunately, the `onError` notification is often abused by a domain-related
error handling. This behavior introduces the result handling duality we’ve talked before.
The solution is obvious if Kotlin is available — use result types as `onNext`
and do not use errors.

```kotlin
fun download(url: HttpUrl): Observable<Result>
```

This approach simplifies interactions by a huge margin.
`onError` becomes a reactive `panic` — a way to notify the caller
about significant system failures that require developer attention.
[Fail-fast](https://en.wikipedia.org/wiki/Fail-fast), right?

> :bulb: Use [`Relay`](https://github.com/JakeWharton/RxRelay)
> instead of `Subject` to stop thinking about `onError` and `onComplete`.

# `Result`s

I see a clear benefit in using result-driven error handling and a strict
recoverable-unrecoverable paradigm.

* Implicit exceptions happening in spontaneous places are effectively
  eliminated. It is still possible to `panic` (or `throw`),
  but it is preserved for exceptional conditions (pun intended).
  Function signatures become explicit and straightforward.
* There is no duality either of result vs. error or checked vs. unchecked.
  A function receives input as arguments and returns output
  as results. That’s it. In a way, it helps to avoid side effects.

> :book: Talking side effects and functional programming —
> [Haskell follows a similar approach](http://book.realworldhaskell.org/read/error-handling.html)
> to avoid exceptions in favor of result types.

Exceptions provide an easy way to deal with errors. Not necessary
[the simple one](https://www.infoq.com/presentations/Simple-Made-Easy).

