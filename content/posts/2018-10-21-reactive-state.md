---
title: "Reactive State Mutations via CQRS"
description: "Managing state, the safe way. Without event sourcing (for now)."
date: 2018-10-21
slug: reactive-state-mutations
---

State-state-state. It surrounds us. Think hard enough and everything around
will become either a state or a state mutation.
The current time is a state and each passing second is a state mutation,
which increments the current value.
A tree can be represented by a state and each drop of rain mutates it,
increasing the water supply level and applying the pressure on leafs.

The concept is not new, but sometimes it becomes so hard to manage it.
Even in software development, which was basically created to represent
the world around us in strict terms.

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
    fun createBook(book: Book): Single<BookCreateResult>
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

    fun createBook(book: Book): Single<BookCreateResult>
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

    fun createBook(book: Book): Single<BookCreateResult>
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

    fun createBook(book: Book): Single<BookCreateResult>
    fun deleteBook(book: Book): Single<BookDeleteResult>
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
Just like dinosaurs. Until the meteorit nuked them. You know how it goes.

# CQRS

Every time I think there is something smart and fresh, a careful research
reveals that the concept was there for years. CQRS is one of them.

CQRS stands for Command Query Responsibility Segregation.
It is a variety of CQS — Command-Query Separation.
Usually it is connected to Event Sourcing, but it is a different story.

> :book: This article will narrow down the concept.
> For further explanation I suggest to read [the Martin Fowler peace](https://martinfowler.com/bliki/CQRS.html)
> and [the Microsoft documentation](https://docs.microsoft.com/en-us/azure/architecture/patterns/cqrs).

Basically saying, CQRS replaces [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete)-like
interactions with two separate entities.

* Commands. Represent requests for changes of a particular resource. Serve as inputs.
* Queries. Represent the resource. Serve as outputs.

This brings a couple of benefits on the table.

* Performance. It becomes possible to scale resource reads and writes independently.
  The most popular resource in such cases is a database.
* Domain organization. Sometimes, but not always, multiple clearly defined
  queries and commands work better than a number of various class methods.

# The Grand Refactoring

Let’s take CQRS, mix it with the reactive approach and apply it to the `BookService`.

First of all, we now know that the `BookService` is not stateless but stateful.
The clear state representation will make the API much more explicit.

```kotlin
sealed class State {
    object Progress : State()
    data class Content(val books: List<Book>) : State()
    object Error : State()
}

val state: Observable<State>
```

This is a major step on the right course.

* The `getBooks` method was removed — good riddance! It looked like a stateless one
  but actually modified state under the hood and provided side effects.
* `getBooksProgress` and `getBooksFailure` properties were removed as well since they were
  actually a side effect representation.
* There is a clear `state` property which declares that it is always there
  and can be updated thanks to the signature — it is a property and the `Observable`.

It is clear that the `State` class represents a CQRS Query. What about Commands?

```kotlin
sealed class Command {
    object Refresh : Command()
    data class Create(val book: Book) : Command()
    data class Delete(val book: Book) : Command()
}

val command: Consumer<Command>
```

This is a bit idealistic API though. In the future we might want
to receive a command result outside of the `State` —
which will become handy for error handling.
It can be solved with a syntax sugar.

```kotlin
interface BookService {

    val refresh: Action

    fun create(book: Book): Single<Unit>
    fun delete(book: Book): Single<Unit>

    class Impl : BookService {

        private sealed class Command {
            object Refresh : Command()
            data class Create(val book: Book) : Command()
            data class Delete(val book: Book) : Command()
        }
    }
}
```

The API is pretty much done. What about the implementation?

First of all, we’ll need stateless commands stream and stateful state one.

* Commands come and go, the `BookService` reacts to them and moves on.
* The State is being preserved during the runtime.

```kotlin
class Impl(api: BooksApi) : BookService {
    override val state = BehaviorRelay.create<State>().toSerialized()
    override val command = PublishRelay.create<Command>().toSerialized()
}
```

Next, we are going to react to commands and produce states based on results.
The refresh command is pretty straightforward.

```kotlin
val refreshState = command
    .ofType<Command.Refresh>()
    .map { State.Progress }

val refreshResultState = command
    .ofType<Command.Refresh>()
    .switchMap { api.getBooks() }
    .map {
        when (it) {
            is BooksResponse.Success -> State.Content(it.books)
            is BooksResponse.Failure -> State.Error
        }
    }
```

Create and delete commands are a bit more tricky since the implementation depends
on our needs.

* If we want to refresh books from the backend we can produce `Command.Refresh` internally.
* If we want to combine books locally we can do that by mutating the current state by hand.

In this implementation I’m gonna go with the first one.


```kotlin
val createResultCommand = command
    .ofType<Command.Create>()
    .switchMap { api.createBook(it.book) }
    .switchMapSingle {
        when (it) {
            is BookCreateResponse.Success -> Single.just(Command.Refresh)
            is BookCreateResponse.Failure -> Single.never()
        }
    }

val deleteResultCommand = TODO("Basically the same as the create one.")
```

And now it is time to combine commands and states.

```kotlin
disposable += Observable
    .merge(refreshState, refreshResultState)
    .subscribe(state)

disposable += Observable
    .merge(createResultCommand, deleteResultCommand)
    .subscribe(command)
```

Done!

<details>
  <summary>_Click to expand the complete code._</summary>

```kotlin
interface BookService {

    sealed class State {
        object Progress : State()
        data class Content(val books: List<Book>) : State()
        object Error : State()
    }

    sealed class Command {
        object Refresh : Command()
        data class Create(val book: Book) : Command()
        data class Delete(val book: Book) : Command()
    }

    val state: Observable<State>
    val command: Consumer<Command>

    class Impl(disposable: CompositeDisposable, api: BooksApi) : BookService {

        override val state = BehaviorRelay.create<State>().toSerialized()
        override val command = PublishRelay.create<Command>().toSerialized()

        init {
            val refreshState = command
                .ofType<Command.Refresh>()
                .map { State.Progress }

            val refreshResultState = command
                .ofType<Command.Refresh>()
                .switchMap { api.getBooks() }
                .map {
                    when (it) {
                        is BooksResponse.Success -> State.Content(it.books)
                        is BooksResponse.Failure -> State.Error
                    }
                }

            val createResultCommand = command
                .ofType<Command.Create>()
                .switchMap { api.createBook(it.book) }
                .switchMapSingle {
                    when (it) {
                        is BookCreateResponse.Success -> Single.just(Command.Refresh)
                        is BookCreateResponse.Failure -> Single.never()
                    }
                }

            val deleteResultCommand = TODO("Basically the same as the create one.")

            disposable += Observable
                .merge(refreshState, refreshResultState)
                .subscribe(state)

            disposable += Observable
                .merge(createResultCommand, deleteResultCommand)
                .subscribe(command)
        }
    }
}
```
</details>

# Lessons Learned

CQRS-like reactive APIs for state mutations can be very useful.

* The API is clear and declarative.
* The API forces right concepts (states and state mutations) both on the outside and on the inside.
* The API is reactive, directly representing the producer-consumer pair.
* The implementation is error-prone-less since the design enforces single state of truth for both states and state mutations.
* The implementation is thread-safe since commands are handled consequentially, one-by-one.

It isn’t a silver bullet, but I can definetly suggest it when dealing with state.

