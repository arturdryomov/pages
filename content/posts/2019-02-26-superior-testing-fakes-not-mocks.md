---
title: "Superior Testing: Make Fakes not Mocks"
description: "To mock, or not to mock, that is the question."
date: 2019-02-27
slug: superior-testing-make-fakes-not-mocks
---

http://xunitpatterns.com/Mocks,%20Fakes,%20Stubs%20and%20Dummies.html

```kotlin
interface BooksStorage {
    fun getBooks(): List<Book>
}

interface BooksRepository {

    fun getBook(id: String): Book?

    class Impl(storage: BooksStorage) : BooksRepository {

        override fun getBook(id: String) = storage.getBooks()
            .find { it.id == id }
    }
}
```

```kotlin
@Test fun testBlankStorage() {
    val storage = mock<BooksStorage> {
        `when`(getBooks()).thenReturn(emptyList())
    }
    val repository = BooksRepository.Impl(storage)

    assertThat(repository.getBook("ID")).isNull()
}
```

```kotlin
interface BooksStorage {
    fun getBooks(): Observable<List<Book>>
}

interface BooksRepository {

    fun getBook(id: String): Observable<Optional<Book>>

    class Impl(storage: BooksStorage) : BooksRepository {

        override fun getBook(id: String) = storage.getBooks()
            .map { books -> books.find { it.id == id } }
    }
}
```

```kotlin
@Test fun testBlankStorage() {
    val storageBooks = PublishSubject.create<List<Book>>()
    val storage = mock<BooksStorage> {
        `when`(getBooks()).thenReturn(storageBooks)
    }
    val repository = BooksRepository.Impl(storage)

    storageBooks.onNext(emptyList())
    repository.getBook("ID").assertResult(None)
}
```

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
    repository.getBook("ID").assertResult(None)
}
```

```kotlin
interface BooksStorage {
    val books: Observable<List<Book>>
}
```

```kotlin
class TestBooksStorage : BooksStorage {
    override val books = PublishSubject.create<List<Book>>()
}
```

```kotlin
@Test fun testBlankStorage() {
    val storage = TestBooksStorage()
    val repository = BooksRepository.Impl(storage)

    storage.books.onNext(emptyList())
    repository.getBook("ID").assertResult(None)
}
```
