---
title: "Superior Testing: Make Fakes not Mocks"
description: "To mock, or not to mock, that is the question."
date: 2019-02-27
slug: superior-testing-make-fakes-not-mocks
---

http://xunitpatterns.com/Mocks,%20Fakes,%20Stubs%20and%20Dummies.html

## Mocking

### Sync

Let’s say we have a books repository. The repository depends on the storage.
Regarding available operations — we need to get a book based on the book ID.
The resulting code is simple enough:

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

### Reactive

Soon enough we notice that book-related operations block the main thread.
Also, RxJava is so hot right now (or was, I have no idea). The code evolves.

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

The relevant test needs to be modified as well.

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

### Lessons Learned

#### Good

* Mocking works and works well.

#### Meh

* More complicated the code becomes — the bulkier mocking feels.
  This scales linearly with the number of ad-hoc methods we should replace.
* Reusability is minor at best. Producing another test will make the same mocking.

## Faking

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
