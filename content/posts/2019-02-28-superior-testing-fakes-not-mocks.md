---
title: "Superior Testing: Make Fakes not Mocks"
description: "To mock, or not to mock, that is the question."
date: 2019-02-28
slug: superior-testing-make-fakes-not-mocks
---

After years of writing and reading tests I’ve discovered that mocking
is either overused or underused. Not sure why exactly it happens
but striking the right balance seems to be a complicated issue.

In this Superior Testing article I’ll show how to replace mocking
in favor of faking and collect benefits.

# Mocking

## Sync

Let’s say we have a books repository allowing us to get a book based on its ID.
The repository depends on the storage. The resulting code is simple enough.

```kotlin
interface BooksStorage {
    fun getBooks(): List<Book>
}

interface BooksRepository {

    fun getBook(id: String): Book?

    class Impl(storage: BooksStorage) : BooksRepository {

        override fun getBook(id: String) = storage.getBooks().find { it.id == id }
    }
}
```

Notice that everything is carefully hidden behind `interface`. This helps
a lot with abstraction which leads to better inversion of control practices
and utility use-cases (like mocking). Rephrasing
[a modern classic Beyoncé](https://en.wikipedia.org/wiki/Single_Ladies_(Put_a_Ring_on_It)):

> If you like it, then you shoulda put an `interface` on it.

We’ll make a single test for now — to check that the repository returns `null`
when the storage is blank.

```kotlin
@Test fun testBlankStorage() {
    val storage = mock<BooksStorage> {
        `when`(getBooks()).thenReturn(emptyList())
    }
    val repository = BooksRepository.Impl(storage)

    assertThat(repository.getBook("ID")).isNull()
}
```

## Reactive

Soon enough we notice that book-related operations block the main thread.
Also, RxJava is [so hot right now](https://www.reddit.com/r/OutOfTheLoop/comments/2ho0gy/where_di_the_so_hot_right_now_meme_come_from/)
(or was, I have no idea). The code evolves.

```kotlin
interface BooksStorage {
    fun getBooks(): Observable<List<Book>>
}

interface BooksRepository {

    fun getBook(id: String): Observable<Optional<Book>>

    class Impl(storage: BooksStorage) : BooksRepository {

        override fun getBook(id: String) = storage.getBooks()
            .map { books -> books.find { it.id == id }.toOptional() }
    }
}
```

The relevant test needs to be modified as well.

```kotlin
@Test fun testBlankStorage() {
    val storageBooks = PublishSubject.create<List<Book>>()
    val storage = mock<BooksStorage> {
        `when`(getBooks()).thenReturn(storageBooks)
    }
    val repository = BooksRepository.Impl(storage)

    storageBooks.onNext(emptyList())
    repository.getBook("ID").assertValuesOnly(None)
}
```

## Lessons Learned

### Good

* Mocking works and works well.

### Meh

* More complicated the code becomes — the bulkier mocking feels.
  This scales linearly.
* Reusability is minor at best.
  Producing another test will require the same mocking all over again.
* The implicit dependency on the mocking framework actually exists but is carefully forgotten.
  This might not seem like an issue but maintaining mocking tools is a dangerous
  idea — magic is not cheap and certainly is not trivial.

# Faking

Instead of mocking let’s produce reusable fakes using language instruments and nothing else.

> :book: Fakes might be called stubs or dummies —
> [depends on the material](http://xunitpatterns.com/Mocks,%20Fakes,%20Stubs%20and%20Dummies.html).
> I suggest calling them _test implementations_.

## Sync

The implementation is not complicated at all.

```kotlin
class TestBooksStorage : BooksStorage {
    var getBookResult: String? = null

    override fun getBook(id: String) = getBookResult
}
```

The relevant test changes, but not by a huge margin.

```kotlin
@Test fun testBlankStorage() {
    val storage = TestBooksStorage().apply {
        getBookResult = null
    }
    val repository = BooksRepository.Impl(storage)

    assertThat(repository.getBook("ID")).isNull()
}
```

## Reactive

Basically the same thing as the sync variant.

```kotlin
class TestBooksStorage : BooksStorage {
    val books = PublishSubject.create<List<Book>>()

    override fun getBooks() = books
}
```

```kotlin
@Test fun testBlankStorage() {
    val storage = TestBooksStorage()
    val repository = BooksRepository.Impl(storage)

    storage.books.onNext(emptyList())
    repository.getBook("ID").assertValuesOnly(None)
}
```

There is an interesting note though. If we transform `BooksStorage` to use
`val` instead of `fun` we’ll be able to use a more compact notation.

```kotlin
interface BooksStorage {
    val books: Observable<List<Book>>
}

class TestBooksStorage {
    override val books = PublishSubject.create<List<Book>>()
}
```

```kotlin
@Test fun testBlankStorage() {
    val storage = TestBooksStorage()
    val repository = BooksRepository.Impl(storage)

    storage.books.onNext(emptyList())
    repository.getBook("ID").assertValuesOnly(None)
}
```

This is possible because in Kotlin referencing an `interface` implementation
gives access to underlying types. In this particular case `books`
is an `Observable` but we reference it as `PublishSubject` because we have access
to the actual implementation. Use it as an advantage in tests but avoid
in inversion of control containers since essentially it might lead
to leaking implementation details.

## Lessons Learned

### Good

* Test implementations are implemented as dedicated reusable components.
* In particular cases faking is less verbose than mocking.
* It is possible to sugar-coat fakes with DSL-ish operators like `BooksStorage.emitBooks()`.
* There is no external dependency on the mocking provider.

### Meh

* Faking requires manual implementation.
  Might be resolved with code-generation though.

# Lessons Learned (Again!)

I think mocking vs. faking is a classic easy vs. simple scenario.
It is relatively easy to mock things left and right but is it simple
on the scale of the entire codebase? Is it understandable and maintainable?
Does it help to make universal and effective tests?
It depends on the exact use-case of course. But please, avoid using a microscope
as a hammer.

