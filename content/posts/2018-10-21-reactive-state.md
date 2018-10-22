---
title: "Reactive State Mutations via CQRS"
description: "Managing state, the safe way. Without event sourcing (for now)."
date: 2018-10-21
slug: reactive-state-mutations
---

# Real Life

There is a brand new project which will provide book recommendations.
The very first step is getting a list of books from a backend.
This is enough _forever and ever_. Sounds good.


```kotlin
interface BookService {
    fun getBooks(): Single<List<Book>>
}
```

Suddenly — _because Agile_ — we need to save books on the backend.
All right.

```kotlin
interface BookService {
    enum class BookCreateResult { Success, Failure }

    fun getBooks(): Single<List<Book>>
    fun createBook(): Single<BookCreateResult>
}
```

New features, new screens! Unfortunately for us it means that
the books fetching progress should be preserved across screens.
I guess a public property should do the trick...

```kotlin
interface BookService {
    enum class BookCreateResult { Success, Failure }

    fun getBooks(): Single<List<Book>>
    val getBooksProgress: Observable<Boolean>

    fun createBook(): Single<BookCreateResult>
}
```

Damn, the QA team brought up an issue at the very last minute before the release.
Fetching books might fail and we need to show it on all screens
to give the ability to re-fetch them. Just a sec, another property
and here we go.

```kotlin
interface BookService {
    enum class BookCreateResult { Success, Failure }

    fun getBooks(): Single<List<Book>>
    val getBooksProgress: Observable<Boolean>
    val getBooksFailure: Observable<Boolean>

    fun createBook(): Single<BookCreateResult>
}
```

The project hit the production! It works all right, but
the very first customer had a complaint that the book was created wrong
and there is no way to delete it. Sounds like creating a book,
but [some would say it is the reverse](https://www.youtube.com/watch?v=2YTLtG4LMsM)...

```kotlin
interface BookService {
    enum class BookCreateResult { Success, Failure }
    enum class BookDeleteResult { Success, Failure }

    fun getBooks(): Single<List<Book>>
    val getBooksProgress: Observable<Boolean>
    val getBooksFailure: Observable<Boolean>

    fun createBook(): Single<BookCreateResult>
    fun deleteBook(): Single<BookDeleteResult>
}
```

This is how it’s done folks! When asked on an interview to show the finest
piece of code I’ll show this one.

And then someone brings up that the `BookService` should work offline...

# This is Bad

The `BookService` is far from perfect.

`BookService` clients gradually became more and more complicated.
Instead of a comfy stateless life they are forced to remember
that creating a book should trigger re-fetching books from a backend.
At the same time, this refresh operation should be done only
on `BookCreateResult.Success` and not on `BookCreateResult.Failure`.
The same goes to the delete operation.
Most likely this logic will be distributed and copy-pasted across the client code.

Another distinct feature is how easily `BookService` transformed from being
stateless to being stateful. Essentially a pure `getBooks` produced
`getBooksProgress` and `getBooksFailure` side-effects. It is understandable —
requirements have been changed, but the mistake is still there.
The change in nature hadn’t been followed by the change in design.
The burden of complications was transitioned to clients.

I’ve spared the details of the implementation since the resulting API
is bad enough. Under the hood the `BookService` probably is juggling
multiple `Subject` or `Relay` in combination with `onNext`.
Forget about proper thread-safety — at this point it is on clients shoulders as well.
The requirement to cache data (at least in memory) will complicate things even more.

Do not forget that the evolution above seems to be rapid but in reality these
changes are applied gradually. Since no one has time to do a proper refactoring
the `BookService` has a pretty good chance to stay this way forever.
Just like dinosaurs. Until the meteorit nuked tham. You know how it goes.

# CQRS

Every time I think there is something smart and fresh, a careful research
reveals that the concept was there for years. CQRS is one of them.

CQRS stands for Command Query Responsibility Segregation.
It is a variety of CQS — Command-Query Separation.
Usually it is connected to Event Sourcing, but it is a different story.

> :book: This article will narrow down the concept.
> For further explanation I suggest to read [the Martin Fowler peace](https://martinfowler.com/bliki/CQRS.html)
> and [the Microsoft documentation](https://docs.microsoft.com/en-us/azure/architecture/patterns/cqrs).
