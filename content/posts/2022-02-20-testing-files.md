---
title: "Testing Files without Files"
description: "Overview of VFS on JVM"
date: 2022-02-20
slug: testing-files-without-files
---

File operations become less and less common. As users, we store more and more
data in vendor-provided stores due to its convinience.
I remember the [VCF](https://en.wikipedia.org/wiki/VCard) file format for contacts
but cannot locate one on a local machine since I have Google Contacts.
As developers, we use datastores —
from [S3 buckets](https://aws.amazon.com/s3/)
to [Hive metastores](https://hive.apache.org/).
Such datastores are scalable, fault tolerant and cheap.

However, even if files and file systems are abstracted behind various APIs —
it doesn’t eliminate them. As such, the development workflow involves them
from time to time. In this article I’ll show how to use JVM virtual file systems (VFS)
to test file interactions. It’s a fun approach but with its own pros and cons.

# Overview

Let’s imagine that there is a `Packages` API we want to test.
It’s simple — there is a single method receiving an enumeration of files,
it returns a file of the resulting package.

```kotlin
interface Packages {

    fun pack(files: Iterable<File>): File
}
```

# Options

## Java IO

A classic approach with [`java.io.File`](https://devdocs.io/openjdk~17/java.base/java/io/file).

The (fake) implementation is trivial.

```kotlin
interface Packages {

    fun pack(files: Iterable<File>): File

    class Impl(private val packagesRoot: File) : Packages {

        override fun pack(files: Iterable<File>): File {
            val packageFile = File(packagesRoot, "package")

            return packageFile.apply { mkdirs() }
        }
    }
}
```

The `packagesRoot` seems a bit redundant since a temporary directory
can be resolved via the implementation but it is useful for the test.

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

* familiar — the API is available from Java 1;
* uses the same IO as the implementation.

Cons:

* creates IRL file descriptors,
  polluting [the `inode` space](https://en.wikipedia.org/wiki/Inode);
* IO is slow in general and this kind of IO is not an exception;
* too easy to forget removing files in `tearDown` which results in hanging files.

## Java NIO

A modern approach with [`java.nio.file.Path`](https://devdocs.io/openjdk~17/java.base/java/nio/file/path)
and [`java.nio.file.Files`](https://devdocs.io/openjdk~17/java.base/java/nio/file/files).
It might seem new but the NIO is available from Java 7 which was shipped in 2011.

> :bulb: Hello there, a curious Android developer. Both `Path` and `Files`
> are available since API 26 (8.0, 2017).
> This might make this API unusable due to minimal API requirements.

Both the interface and the implementation need adjustments.
`File` is replaced with `Path` and all actions are done via `Files` static methods.

```kotlin
interface Packages {

    fun pack(files: Iterable<Path>): Path

    class Impl(private val packagesRoot: Path) : Packages {

        override fun pack(files: Iterable<Path>): Path {
            val packageFile = packagesRoot.resolve("package")

            return packageFile.apply { Files.createDirectory(this) }
        }
    }
}
```

For testing purposes there is a wonderful `java.nio.file.FileSystem` implementation —
[JimFS](https://github.com/google/jimfs).
Nope, it was not created by [Jim from The Office](https://theoffice.fandom.com/wiki/Jim_Halpert).
It means Just In Memory File System making it a VFS. It doesn’t use OS storage primitives —
everything is done in memory.

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

* no interaction with IRL IO primitives;
* better performance since in general all actions are RAM actions;
* it’s possible to test different platforms behavior via
  [configurations](https://github.com/google/jimfs/blob/323826d63eade769a606faa9666b9460ccf67795/jimfs/src/main/java/com/google/common/jimfs/Configuration.java#L169-L173).

Cons:

* requires a migration from `java.io` to `java.nio`;
* there is no need to remove files but there is a `close` call
  in the `tearDown` method — it’s possible to avoid this but
  [it’s not recommended](https://github.com/google/jimfs/issues/104#issuecomment-619123056).

## Okio

I call it a portable NIO since the Java NIO feels like an inspiration for a number of APIs there.
Also it’s [a separate artifact](https://github.com/square/okio) and supports Kotlin Multiplatform.

Both the interface and the implementation gonna need changes once again.
There is an in-house `Path` class. Also — in comparison with NIO —
static `Files` calls are moved to the `FileSystem` class.

```kotlin
interface Packages {

    fun pack(files: Iterable<Path>): Path

    class Impl(
        private val packagesFileSystem: FileSystem,
        private val packagesRoot: Path,
    ) : Packages {

        override fun pack(files: Iterable<Path>): Path {
            val packageFile = packagesRoot.resolve("package")

            return packageFile.apply { packagesFileSystem.createDirectory(this) }
        }
    }
}
```

Instead of JimFS there is a built-in `FakeFileSystem` class. It’s also a VFS
without using OS calls. Neat!

```kotlin
class PackagesTests {

    private lateinit var packagesFileSystem: FileSystem
    private lateinit var packages: PackagesOkio

    @BeforeEach
    fun setUp() {
        packagesFileSystem = FakeFileSystem()

        packages = PackagesOkio.Impl(
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
            .onEach { packagesFileSystem.write(it, mustCreate = true) {} }

        assertThat(packagesFileSystem.exists(packages.pack(files))).isTrue()
    }
}
```

Pros:

* all from the Java NIO;
* there is [an additional call](https://square.github.io/okio/3.x/okio-fakefilesystem/okio-fakefilesystem/okio.fakefilesystem/-fake-file-system/check-no-open-files.html)
  for checking non-closed files.

Cons:

* requires a migration from `java.io` to `okio`;
* since there is no static API (`Files` from NIO) the implementation is a bit verbose
  (notice passing `FileSystem` instances around).

## Options Performance

This is not a proper benchmark but I’ve took some measurements.

* CPU: Intel 8257U, RAM: 8 GB LPDDR3, SSD: 250 GB (APFS).
* JVM: 17.0.2.
* Runs: 10. Each run: creating and removing `N` files.

Time in the table reflects the average total duration among runs.

`N`    | Java IO, ms | Java NIO (JimFS), ms | Okio (`FakeFileSystem`), ms
-------|-------------|----------------------|----------------------------
100    | 15          | 3                    | 4
1000   | 100         | 9                    | 20
10000  | 1040        | 30                   | 95
100000 | 15880       | 160                  | 860

Not a surprise that in-memory VFS perform better than the IRL disk IO.

However, these numbers are more or less irrelevant for regular use cases —
it’s unlikely that a test creates thousands of files. I can imagine having
hundreds of tests (each creating dozens of files) though.
