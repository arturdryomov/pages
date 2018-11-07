---
title: "Reactive Pipelines in Action"
description: "The beauty of Functional Reactive Programming."
date: 2018-11-07
slug: reactive-pipelines
---

Human beings are reactive by nature — fortunately or not.
The reason is mostly physiology. The dopamine hormone helps us
to feel comfortable and secure while we do things we are familiar with.
Eating a sandwich sounds and feels far better than gardening, doesn’t it?
Essentially it is a fight between psychology (the mind, proactive actions)
and physiology (the body, reactive actions).

In CS object-oriented programming (OOP) is a king of the hill and
functional programming (FP) is for nerds, right? Well, it is this way because
the OOP is more comfortable for the majority. We, as society, made it this way.
The educational system includes a mandatory OOP course and rarely there
is an FP one. And then there is reactive programming which forms a wild beast
called functional-reactive programming (FRP)...

Taking everything above into the account makes it easy... to give up.
Is it even worth it to maintain a consistent reactive system?
Let’s see how it might look and decide.

# Concepts

Don’t worry, I’m not going to explain FP and FRP all over again. We’ll need only two terms.

* Producer. Produces events, an output. `Observable`, `Flowable`, `Single`, `Maybe`.
* Consumer. Consumes events, an input. `Consumer`, `Action`.

The success of our enterprise
(not be confused with [the USS one](https://en.wikipedia.org/wiki/Starship_Enterprise))
depends on providing enough abstractions to connect producers and consumers,
forming Pipelines.

> :book: Advices about abstractions are available in
> [Reactive Abstractions in Android World]({{< ref "2018-08-26-reactive-abstractions.md" >}}).

Honestly saying, I find reactive pipelines beautiful. There is something deeply
satisfying in understanding that a complete flow can be tracked via a single
stream from a producer to a consumer.

* A connectivity change restarts a stalled network request,
  which mutates a current data state, which triggers a UI redraw.
* Clicking a refresh button triggers a data refresh,
  which starts a network request, which again mutates a current data state,
  which triggers a UI redraw.

And all these actions are done without ad-hoc solutions and concepts.
The flow is declarative, consistent and elegant.

> The formula has infinite depth in its efficacy and application
> but it’s staggeringly simple and completely consistent.
>
> – [_Revolver (2005)_](https://en.wikipedia.org/wiki/Revolver_(2005_film))

# Structure

> :book: We’ll use Data-Domain-Presentation
> [multitier architecture](https://en.wikipedia.org/wiki/Multitier_architecture).
> Please refer to Martin Fowler
> [for details](https://martinfowler.com/bliki/PresentationDomainDataLayering.html).

## Data

Network-related data sources (especially on Android) most likely use
[Retrofit](https://github.com/square/retrofit) or something similar.
However, I don’t associate raw API interfaces with data providers since
in most cases there is an in-house handling for common tasks.

* Connectivity. Restart requests on re-established network connections.
* Retries. Restart requests `N` times or (and) transform error responses
  to manually-retryable actions.
* Authentication, validation, processing, [SSE](https://en.wikipedia.org/wiki/Server-sent_events), etc.

```kotlin
sealed class BookResponse {
    data class Success(val books: List<Book>) : BookResponse()
    object Failure : BookResponse()
}

interface BooksNetworkSource {
    fun getBooks(pageSize: Int): Observable<BooksResponse>
    fun getBookReviews(): Flowable<BookReview>

    class Impl(
        private val api: BooksApi,
        private val ioScheduler: Scheduler
    ) { /* ... */ }
}
```

* `getBooks` method returns `Observable` and not `Single` since the request
  is automatically resubmitted on available network if it wasn’t available
  initially.
* `getBookReviews` method returns `Flowable` since it is a continuous
  stream of server-sent events which can be a source of issues with backpressure.

Storate-related data sources are easier.

```kotlin
interface BooksStorageSource {
    fun getBooksPageSize: Single<Int>
    fun setBooksPageSize: Single<Unit>

    class Impl(
        private val context: AndroidContext,
        private val ioScheduler: Scheduler
    ) { /* ... */ }
}
```

Notice that `setBooksPageSize` is `Single` and not `Consumer`.
`Consumer` makes more sense as an interaction — it is an input after all.
In real life it needs to be async to not block user interactions.
There are use cases when it is necessary to ensure that changes were applied
before proceeding with another action. A classic example is a sign out procedure —
everything needs to be cleaned up before a different account is being signed in.
There are no such guarantees with `Consumer`.

Both sources receive a worker `Scheduler` as a constructor argument.
It is done this way for two reasons.

* Only producer-level components should control producer-related threading.
  Having IO `Scheduler` on the consumer level means taking unnecessary responsibility
  without proper knowledge about the producer implementation. I. e. better forget
  about `subscribeOn` on the presentation level.
* Inversion of control and simplified testing — just provide `Schedulers.trampoline()`
  to make all the work sync or `TestScheduler` to control time-related operations.

## Domain

We’ll use stateful example, but essentially this level is a mediator
between the data and the presentation. Business-related decisions are done here.

> :book: Advices about state mutations are available in
> [Reactive State Mutations via CQRS]({{< ref "2018-10-21-reactive-state.md" >}}).

```kotlin
interface BooksService {

    sealed class State {
        object Progress : State()
        data class Content(val books: List<Book>) : State()
        object Error : State()
    }

    enum class Command {
        Refresh
    }

    val state: Observable<State>
    val command: Consumer<Command>

    class Impl(
        private val networkSource: BooksNetworkSource,
        private val storageSource: BooksStorageSource
    ): BooksService { /* ... */ }
}
```

Notice that the service does not receive a `Scheduler`.

* Producer-level components (data) know which thread is necessary for producing.
* Cnsumer-level components (presentation) know which thread is necessary for consuming.

## Presentation

MVWhatever will do the trick, but I highly sugggest giving MVI a shot.

Personally I see presentation components as consumers, but it will be ignorant
to forget that user actions are actually producers. This is not a bad thing
because embracing the reactive approach makes this a benefit.

```kotlin
interface BooksScreen {

    interface View {
        enum class State { Progress, Content, Error }

        val stateSwitcher: ViewAnimator<State>
        val refreshButton: Button
        val errorRefreshButton: Button

        val books: Consumer<Book>
    }

    class ViewModel(
        private val booksService: BooksService,
        private val mainScheduler: Scheduler
    ) {
        private val disposable = CompositeDisposable()

        fun bind(view: View) {
            disposable += Observable
                .merge(
                    view.refreshButton.clicks,
                    view.errorRefreshButton.clicks
                )
                .map { BooksService.Command.Refresh }
                .subscribe(booksService.command)

            disposable += booksService.state
                .map {
                    when (it) {
                        is BooksService.State.Progress -> View.State.Progress
                        is BooksService.State.Content -> View.State.Content
                        is BooksService.State.Error -> View.State.Error
                    }
                }
                .observeOn(mainScheduler)
                .subscribe(view.stateSwitcher.state)

            disposable += booksService.state
                .ofType<BooksService.State.Content>
                .map { it.books }
                .observeOn(mainScheduler)
                .subscribe(view.books)
        }

        fun unbind() = disposable.clear()
    }

    class ViewImpl(view: AndroidView) : View { /* ... */ }
}
```

* The `Scheduler` is being passed as an argument for inversion of control purposes.
  Also, the presentation components knows best what should be executed on the UI thread.
  This is where `observeOn` should be used and probably nowhere else.
* `view.refreshButton.clicks` and `view.errorRefreshButton.clicks` serve as producers.
  The reactive feedback from `BooksService` redraws the UI, which is awesome
  since the state is managed by a component with a broader scope.
  It makes the presentation component do the presenting job and nothing else.

# Is It Worth It?

I cannot say for everyone, but my answer is definitive Yes.

Thinking about reproducing same interactions as above on callbacks and listeners
cause a headache. Replicating a reactive feedback without reactive approach
most likely will lead to unscalable mess. Nobody on the team will eventually know
what the hell is happening.

There is a number of concepts FRP brings on a table which are hard to beat or even replace.

* Declarative scalable API. Operators mutate the state from the input and provide
  the output. No side-effects, no unpredictable behavior. The process is streamlined,
  easily readable and stable.
* Ridiculously easy multi-threading. Since there are no side-effects each operator
  can perform on a particular thread. Even better — since switching a thread
  is an operator it is a part of the same awesome declarative API.
* Unified disposing policies. Each operation can be disposed via `Disposable`.
  No need to assign callbacks to `null` at the right moment or interrupt threads.
  `Disposable.dispose` or `CompositeDisposable.clear` and that’s it.
* Unified terms across implemenations. RxJava people understand RxSwift people really well.
  The same cannot be said even about Go and goroutines and Kotlin and coroutines.

It is a no-brainer. Embracing the concept and unifying the codebase behind it
brings benefits on a conceptual level in a long run. Isn’t that what we want
as developers and human beings?

Be proactive about being reactive!

