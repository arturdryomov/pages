---
title: "Testing Files without Files"
description: "Overview of fake VFS on JVM"
date: 2022-02-21
slug: testing-files-without-files
---

File operations become less and less common. As users, we store more and more
data in a vendor storage due to its convenience.
I remember [the contacts file format](https://en.wikipedia.org/wiki/VCard)
but cannot locate one on a local machine — I have Google Contacts instead.
As developers, we use datastores —
from [S3](https://aws.amazon.com/s3/)
to [Hive Metastore](https://hive.apache.org/).
Such datastores are scalable, fault tolerant and cheap.

However, even if files and file systems are hidden behind various APIs —
it doesn’t eliminate them. In this article I’ll show how to use Java fake file systems
to test file interactions. It’s a fun approach but with its own pros and cons.

# Overview

Let’s imagine that there is a `Packages` class we want to test.

```kotlin
interface Packages {

    fun pack(files: Iterable<File>): File
}
```

The `pack` method receives an enumeration of files and returns a file of the resulting package.

# Options

## Java IO

A classic approach using [`java.io.File`](https://devdocs.io/openjdk~17/java.base/java/io/file).

The (fake) implementation:

* receives a `packagesRoot` argument, making it possible to switch it in tests;
* creates a blank file at `packagesRoot`.

```kotlin
interface Packages {

    fun pack(files: Iterable<File>): File

    class Impl(private val packagesRoot: File) : Packages {

        override fun pack(files: Iterable<File>): File {
            val packageFile = File(packagesRoot, "package.tar")

            return packageFile.apply { createNewFile() }
        }
    }
}
```

The corresponding test suite:

* creates a random directory serving as `packagesRoot` before each test;
* deletes `packagesRoot` after each test.

```kotlin
class PackagesTests {

    private lateinit var packagesRoot: File
    private lateinit var packages: Packages

    @BeforeEach
    private fun setUp() {
        packagesRoot = createTempDir()
        packages = Packages.Impl(packagesRoot)
    }

    @AfterEach
    private fun tearDown() {
        packagesRoot.deleteRecursively()
    }

    @Test
    fun pack() {
        val files = (0..10)
            .map { File(packagesRoot, "$it.txt") }
            .onEach { it.createNewFile() }

        assertThat(packages.pack(files)).exists()
    }
}
```

Pros:

* `java.io.File` is available from Java 1;
* uses the same API as the implementation (no potential surprises).

Cons:

* creates disk file descriptors,
  polluting [the `inode` space](https://en.wikipedia.org/wiki/Inode);
* disk operations are blocking and are not that fast even with SSD;
* easy to forget removing files after each test.

## Java NIO

A modern approach with [`java.nio.file.Path`](https://devdocs.io/openjdk~17/java.base/java/nio/file/path).
It might feel new but the NIO is available from Java 7 (2011).

> :bulb: Hello there, a curious Android developer.
> `java.nio.file.*` is available from API 26 (8.0).

Both the interface and the implementation need changes:

* `java.io.File` becomes `java.nio.file.Path`;
* `java.io.File` mutation calls are done via `java.nio.file.Files`;
* `java.nio.file.Path` uses `java.nio.file.FileSystem` under the hood.

```kotlin
interface Packages {

    fun pack(files: Iterable<Path>): Path

    class Impl(private val packagesRoot: Path) : Packages {

        override fun pack(files: Iterable<Path>): Path {
            val packageFile = packagesRoot.resolve("package.tar")

            return packageFile.apply { Files.createFile(this) }
        }
    }
}
```

The corresponding test suite:

* creates a fake file system using JimFS before each test;
* provides `packagesRoot` via the fake file system;
* closes the fake file system after each test.

[JimFS](https://github.com/google/jimfs) is
an in-memory `java.nio.file.FileSystem` implementation.
Nope, it wasn’t created by [Jim from The Office](https://theoffice.fandom.com/wiki/Jim_Halpert).
It means Just In Memory File System. It doesn’t use disk at all.

```kotlin
class PackagesTests {

    private lateinit var packagesFileSystem: FileSystem
    private lateinit var packages: Packages

    @BeforeEach
    fun setUp() {
        packagesFileSystem = Jimfs.newFileSystem()

        packages = Packages.Impl(
            packagesRoot = packagesFileSystem.getPath("packages").apply {
                Files.createDirectory(this)
            },
        )
    }

    @AfterEach
    fun tearDown() {
        packagesFileSystem.close()
    }

    @Test
    fun pack() {
        val files = (0..10)
            .map { packagesFileSystem.getPath("$it.txt") }
            .onEach { Files.createFile(it) }

        assertThat(packages.pack(files)).exists()
    }
}
```

Pros:

* no disk interaction meaning better performance;
* it’s possible to test different platforms behavior via
  [configurations](https://github.com/google/jimfs/blob/323826d63eade769a606faa9666b9460ccf67795/jimfs/src/main/java/com/google/common/jimfs/Configuration.java#L169-L173).

Cons:

* requires a migration from `java.io.File` to `java.nio.file.*`;
* while there is no need to remove files —
  there is [a recommendation](https://github.com/google/jimfs/issues/104#issuecomment-619123056)
  to close JimFS instances.

## Okio

I call it a portable NIO since the Java NIO feels like an inspiration for the Okio FS API.
Also it’s [a separate artifact](https://github.com/square/okio) and supports Kotlin Multiplatform.

Both the interface and the implementation need changes:

* `java.io.File` becomes `okio.Path`;
* `java.io.File` mutation calls are done via `okio.FileSystem`.

```kotlin
interface Packages {

    fun pack(files: Iterable<Path>): Path

    class Impl(
        private val packagesFileSystem: FileSystem,
        private val packagesRoot: Path,
    ) : Packages {

        override fun pack(files: Iterable<Path>): Path {
            val packageFile = packagesRoot.resolve("package.tar")

            return packageFile.apply { packagesFileSystem.write(this) {} }
        }
    }
}
```

The corresponding test suite:

* creates a fake file system using `FakeFileSystem` before each test;
* provides `packagesRoot` via the fake file system.

JimFS is not relevant here but there is a neat `okio.fakefilesystem.FakeFileSystem` doing the same thing.

```kotlin
class PackagesTests {

    private lateinit var packagesFileSystem: FileSystem
    private lateinit var packages: Packages

    @BeforeEach
    fun setUp() {
        packagesFileSystem = FakeFileSystem()

        packages = Packages.Impl(
            packagesFileSystem = packagesFileSystem,
            packagesRoot = "packages".toPath().apply {
                packagesFileSystem.createDirectory(this)
            },
        )
    }

    @Test
    fun pack() {
        val files = (0..10)
            .map { "$it.txt".toPath() }
            .onEach { packagesFileSystem.write(it) {} }

        assertThat(packagesFileSystem.exists(packages.pack(files))).isTrue()
    }
}
```

Pros:

* no disk interaction meaning better performance;
* it’s possible to test different platforms behavior via
  [configuration calls](https://square.github.io/okio/3.x/okio-fakefilesystem/okio-fakefilesystem/okio.fakefilesystem/-fake-file-system/emulate-windows.html);
* it’s possible to [test for hanging open files](https://square.github.io/okio/3.x/okio-fakefilesystem/okio-fakefilesystem/okio.fakefilesystem/-fake-file-system/check-no-open-files.html).

Cons:

* requires a migration from `java.io.File` to `okio.*`;
* the implementation is a bit verbose (notice passing `FileSystem` instances around).

# Options Performance

I’ve took execution measurements but please note that this is not a benchmark.

* CPU: Intel 8257U, RAM: 8 GB LPDDR3, SSD: 250 GB (APFS).
* JVM: 17.0.2.
* Runs: 10. Each run: create and delete `N` files.

Time in the table is the average run duration.

`N`    | Java IO, ms | Java NIO (JimFS), ms | Okio (`FakeFileSystem`), ms
-------|-------------|----------------------|----------------------------
100    | 15          | 3                    | 4
1000   | 100         | 9                    | 20
10000  | 1040        | 30                   | 95
100000 | 15880       | 160                  | 860

No surprises here — RAM performs better than SSD.

However, tests creating thousands of files are uncommon. I can imagine having
hundreds of tests (each creating dozens of files) though. Still — ergonomics
might be a better choosing criteria here.

# Decisions

The choice depends on circumstances. As for me — I think NIO is a great choice
for JVM services, Okio — for Android applications.
Also — more than zero tests is awesome, that’s all that matters.
