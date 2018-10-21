---
title: "Reactive State Mutations via CQRS"
description: "Managing state, the safe way. Without event sourcing (for now)."
date: 2018-10-21
slug: reactive-state-mutations
---

```kotlin
interface BooksService {
    fun getBooks(): Single<List<Book>>
}
```

```kotlin
interface BooksService {
    fun getBooks(): Single<List<Book>>
    fun createBook(): Single<Book>
}
```

```kotlin
interface BooksService {
    fun getBooks(): Single<List<Book>>
    fun createBook(): Single<Book>

    val booksProgress: Observable<Boolean>
}
```

```kotlin
interface BooksService {
    fun getBooks(): Single<List<Book>>
    fun createBook(): Single<Book>

    val booksProgress: Observable<Boolean>
    val booksFailure: Observable<Boolean>
}
```

```kotlin
interface BooksService {

    sealed class State {
        data class Content(val books: List<Book>): State()
        object Progress: State()
        object Failure: State()
    }

    val refresh: Action

    val create: Single<BookCreateResult>
}
```
