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
Groovy, Ceylon, Scala, Clojure and Kotlin. It is the foundation and it brings
a lot to the table — error handling is no exception (pun intended).

Exceptions! Developers adore exceptions. It is so easy to `throw` an error
and forget about consequences. Is it a good idea though? Should Kotlin follow
the same path? Fortunately enough there are many good languages around we
can learn from. Let’s dive in!

# Java

There are checked and unchecked exceptions.
Checked ones are not favored among developers since their handling
is forced by the method signature and the compiler.
I think the root of the checked exceptions discontent
is the duality of method calls. The caller is forced to
work with not only the return result of the method but with
the possible exception as well. This creates a lot of friction in practice.
At the same time, checked exceptions are quite useful to enforce
desired behavior. From that perspective, unchecked exceptions are actually
worse than checked ones since they are implicit and easy to miss.

Another option is to return `null` or magic values when something went wrong.
It can be called either a C-style or a documentation-driven error handling —
the caller is expected (but not enforced) to check the return value of a method
for a special case. The case itself is either documented or not — in such situations
the process transforms into a goose chase for implicit errors.
From that perspective checked exceptions are far better.

# Swift

Errors in Swift resemble scope-checked exceptions in Java terms.
Error-throwing functions are required to be annotated with the `throws` keyword.

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
Non-annotated functions are required to handle their exceptions inside
the function itself. Essentially there are no unchecked exceptions in Java terms.

Another neat detail — there are no exceptions in Swift. In fact,
[the documentation](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html)
is very careful to not mention exceptions and use the Error term instead.
`throws` and `throw` keywords are just a syntax sugar for adding another return
value handler. `throw` writes an error to a register and `try` reads it.
Essentially it is like returning a `Pair` or an `Either`.

> :book: Technical details are explained in
> [the excellent article](https://www.mikeash.com/pyblog/friday-qa-2017-08-25-swift-error-handling-implementation.html)
> by Mike Ash.

At the same time,
[there is an accepted proposal](https://github.com/apple/swift-evolution/blob/master/proposals/0235-add-result.md)
to introduce the `Result` type to the standard library as an alternative
to `throw`-driven workflows. It can be viewed as a more explicit, manual
approach to propagating error handling to callers.

```swift
enum Result<Value, Error> {
    case value(Value)
    case error(Error)
}
```

# Go

Fortunately or not Go doesn’t have either Java-like exceptions or
Swift-like syntax sugar. And it is done [by design](https://golang.org/doc/faq#exceptions).
Explicit return values are used instead.

```go
func open(filename: String) (file *File, err error)
```
```go
file, err := open("file.txt")
if err != nil {
    // Process the error.
}
```
Basically, every function which might result in an error returns a pair
of a value itself and an error. That’s it! Reminds a C-style error
handling, but at least it is explicit and type-safe. This style
is verbose, but it works surprisingly good due to the universal application.

> :book: There is [a great article](https://evilmartians.com/chronicles/errors-in-go-from-denial-to-acceptance)
> on coping with Go error handling by Sergey Alexandrovich.

There is a `panic` function though which might look like a Java-like
unchecked exception. Enough hacks and it is even possible to catch them
but it is considered non-idiomatic.
`panic` is the last call for help when things got really, really bad.

# Rust

Rust takes what Go has and takes it to the next level, defining
two categories for errors
[right in the documentation](https://doc.rust-lang.org/book/ch09-00-error-handling.html):

> Rust groups errors into two major categories: recoverable and unrecoverable errors.
> For a recoverable error, such as a file not found error, it’s reasonable to report
> the problem to the user and retry the operation.
> Unrecoverable errors are always symptoms of bugs,
> like trying to access a location beyond the end of an array.

That’s what I like in Rust — the straightforward declaration of principles.

* There are no exceptions — neither via Java-like constructs or Swift-like syntax sugar.
* There is a `panic!` macros — but there are no ways to recover.
* There is a `Result` type with a number of helper functions on top.

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
Well, actually [it does have a way to define them](https://kotlinlang.org/docs/reference/java-to-kotlin-interop.html#checked-exceptions),
mostly for Java-Kotlin interop purposes.

```kotlin
@Throws(IOException::class)
fun open(filename: String): File {
    throw IOException("This is a checked, checked world.")
}
```

Since Kotlin runs on the JVM platform, there are exceptions — no surprises here.
However, Kotlin is not Java and does have a couple of benefits.
Specifically — it is possible to use `sealed class` and pattern matching
to return a union of values and use it. Yes, I’m talking about the `Result` type.

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
a project-specific one. Even better — create `sealed class` for domain-specific
tasks, which might include more than two states.

```kotlin
sealed class Result {
    data class Progress(val percent: Int) : Result()
    data class Success(val file: File): Result()
    sealed class Failure : Result() {
        object Disconnect : Failure()
        data class Undefined(val error: Error) : Failure()
    }
}

fun download(url: HttpUrl): Result
```

Unfortunately, there are no ways to ban the `catch` keyword and
mentally map it to the `panic` invocation. It is still possible
to control this in the scope of a codebase, but it doesn’t scale
with the number of developers.

# Bonus: RxJava

[The Observable Contract](http://reactivex.io/documentation/contract.html)
introduces three basis notifications: `onNext`, `onComplete` and `onError`.
Unfortunately, the `onError` notification gets easily abused by a domain-related
error handling. This behavior introduces the result handling duality.
The solution is obvious if Kotlin is used — use result types instead.

```kotlin
fun download(url: HttpUrl): Observable<Result>
```

This approach simplifies interactions by a huge margin.
`onError` becomes a reactive `panic` — a way to notify the caller
about significant system failures that require developer attention.

> :bulb: Use [`Relay`](https://github.com/JakeWharton/RxRelay)
> instead of `Subject` to stop thinking about `onError` and `onComplete`.

# `Result`s

I see a clear benefit
in using result-driven error handling and a strict Rust-inspired
recoverable-unrecoverable paradigm.

* Implicit exceptions happening in spontaneous places are effectively
  eliminated. It is still possible to `panic` (or `throw`),
  but it is preserved for exceptional conditions (pun intended).
  The API is always explicit and straightforward.
* There is no duality either of exception-result or checked-unchecked.
  A function receives input values as arguments and returns output values
  as results. That’s it. In a way, it helps with avoiding side effects.

> :book: Talking side effects and functional programming —
> [Haskell follows a similar approach](http://book.realworldhaskell.org/read/error-handling.html)
> to avoid exceptions in favor of result types.

Exceptions provide an easy way to deal with errors. Not necessary
[the simple one](https://www.infoq.com/presentations/Simple-Made-Easy).
