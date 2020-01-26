---
title: "Kotlin Code Organization"
description: "Kotlin, Gradle, source sets — together"
date: 2020-01-27
slug: kotlin-code-organization
---

What’s the motivation behind organizing the code? Two points come to mind.

* Help humans. Expectable environments, consistent across the board, are easier
  to understand and adapt. Storing the source code in `src/` instead of `k/`
  makes it easier for people to find.
* Help machines. Build systems need hints. The code in `main/` should be
  assembled all the time, while `test/` is test-specific and shouldn’t make it
  to a production environment.

# SDL

First things first. Maven introduced a concept of [the Standard Directory Layout](https://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html).
Gradle [tends to follow it](https://docs.gradle.org/current/userguide/organizing_gradle_projects.html)
bringing so called [source sets](https://docs.gradle.org/current/userguide/building_java_projects.html#sec:java_source_sets)
along the way. Let’s take a look at the following file system tree.

```
.
├── main
│   ├── java
│   │   └── Code.java
│   ├── kotlin
│   │   └── Kode.kt
│   └── resources
│       └── production.xml
└── test
    ├── java
    │   └── CodeTests.java
    ├── kotlin
    │   └── KodeTests.kt
    └── resources
        └── test.xml
```

* `main`, `test` — source sets. Include everything related to the code scope —
  like the production application (`main`), unit tests (`test`) and more
  (`androidTest`).
* `java`, `kotlin`, `resources` — the code scope implementation details.
  Unit tests can be written in Kotlin and Groovy at the same time,
  the production code might be a Java + Scala mix.

This two-level structure allows us to organize the code based on a target
(`main`, `test`) and on implementation details (`java`, `kotlin`).
Let’s leverage this.

# Tips

## `src/{main|test}/kotlin`

Storing Kotlin files in the Kotlin-specific directory sounds obvious
but a lot of projects are 100% Kotlin and store the source code
as Java. Take a look at
[LeakCanary](https://github.com/square/leakcanary/tree/825ac6242cde0a4c0488547d03e12a8df91a5f31/leakcanary-object-watcher/src),
[Muzei](https://github.com/romannurik/muzei/tree/ba24eb7dcca0490ee8540066c5f8fb51b9a219d9/main/src/main),
[OkHttp](https://github.com/square/okhttp/tree/1b4cc4bb33996c8fdcdb67854a30aea3bec12ae6/okhttp/src/main),
[Scarlet](https://github.com/Tinder/Scarlet/tree/12bac927c6b4109e2b9c50040873b544a84a142c/scarlet-core/src),
[Timber](https://github.com/JakeWharton/timber/tree/10f0adce3921ad2929ddf2f3b7fecda2cf3148a5/timber/src/main),
[ViewPump](https://github.com/InflationX/ViewPump/tree/8dbefccc27dce258b391efa5adfb94ec5ebbbadd/viewpump/src/main),
[Workflow](https://github.com/square/workflow/tree/3cec6d22c4d0ba6ef858e71338d8f68985443ce4/kotlin/workflow-core/src/main)
and more. I see a number of reasons for that.

* The Kotlin compiler supports mixing Java and Kotlin code,
  so there is no punishment from the tooling.
* Projects migrate from Java to Kotlin using the mixing and
  forget to change the source set configuration.
* The Kotlin Android Gradle plugin requires additional configuration
  which might be not trivial.

To be honest, there is nothing outright wrong with mixing Java and Kotlin code.
It’s more accurate and expectable to store them separately.
Also it might help with Java → Kotlin migration efforts — it’s easier to observe
that the Java directory is shrinking and the Kotlin one is growing than
running [`cloc`](https://github.com/AlDanial/cloc) all the time.

## `src/{main|test}/kotlinX`

There is a common issue of organizing Kotlin extensions.
I’ve seen a lot of projects with the `Extensions.kt` garbage fire. When everything is in
a single file — it’s easier to overlook an extension and write a new one placed at...
`extensions/Extensions.kt`. Guess what happens next.

I suggest to follow [the Android KTX](https://developer.android.com/kotlin/ktx)
example and store extensions using the target class package and file names.
As a cherry on top — move them to the `kotlinX/` directory as well,
to separate the project code from additions to the external one. This approach leads
to a better separation of concerns.

For example, the following `io.reactivex.functions.Consumer` extension should be placed at
`src/main/kotlinX/io/reactivex/functions/Consumer.kt`.

```kotlin
package io.reactivex.functions

fun Consumer<Unit>.asAction() = Action { accept(Unit) }
```

Bonus — imports start to make sense.

```diff
- import hello.there.asAction
+ import io.reactivex.functions.asAction
```

## `src/testFixtures/kotlin`

A growing test / specification suite might be not pleasant to look at.
[Using fakes]({{< ref "2019-02-28-superior-testing-fakes-not-mocks.md" >}})
is great but there is a possibility of having a huge file tree with mixed
tests and fakes.

```
.
└── src
    └── test
        └── kotlin
            ├── ApplicationSpec.kt
            ├── FakeApplication.kt
            ├── FakePermissions.kt
            └── PermissionsSpec.kt
```

Since fakes and tests are different things — I suggest to split them
in the digital world as well.

```
.
└── src
    ├── test
    │   └── kotlin
    │       ├── ApplicationSpec.kt
    │       └── PermissionsSpec.kt
    └── testFixtures
        └── kotlin
            ├── FakeApplication.kt
            └── FakePermissions.kt
```

In fact, [Gradle supports this approach for Java code](https://docs.gradle.org/current/userguide/java_testing.html#sec:java_test_fixtures)
and with benefits — it’s possible to share `testFixtures` across modules.
However, it doesn’t work with Gradle [Kotlin](https://youtrack.jetbrains.com/issue/KT-33877)
and [Android](https://issuetracker.google.com/issues/139438142) plugins.

# Gradle API

The code below will use the Gradle Kotlin DSL but it can be adapted to the Groovy DSL as well.
The code was run against Gradle 6.1.1, Gradle Kotlin plugin 1.3.61 and Gradle Android plugin 3.5.3.

## JVM

Gradle uses a couple of classes as an API to configure the source code location:

* `SourceDirectorySet` — a set of source code files;
* `SourceSet` — a group of `SourceDirectorySet`s for Java code and resources;

The Kotlin JVM plugin adds another one.

* `KotlinSourceSet` — like `SourceSet`, but for Kotlin sources.
  Bonus — it configures `src/{main|test}/kotlin` automatically.

The DSL works with those classes.

* Single module (put in the module `build.gradle.kts` file).

    ```kotlin
    import org.jetbrains.kotlin.gradle.plugin.KotlinSourceSet

    // Get a SourceSet collection
    sourceSets {
        // Get a SourceSet by name
        named("SOURCE SET NAME") {
            // Resolve a KotlinSourceSet
            withConvention(KotlinSourceSet::class) {
                // Configure Kotlin SourceDirectorySet
                kotlin.srcDirs("PATH A", "PATH B", "PATH C")
            }
        }
    }
    ```

* Multiple modules (put in the root `build.gradle.kts` file).

    ```kotlin
    import org.jetbrains.kotlin.gradle.plugin.KotlinSourceSet

    subprojects {
        // The sourceSets function is not available at root so we use a different syntax
        configure<SourceSetContainer> {
            named("SOURCE SET NAME") {
                withConvention(KotlinSourceSet::class) {
                    kotlin.srcDirs("PATH A", "PATH B", "PATH C")
                }
            }
        }
    }
    ```

## Android

Android ignores native Gradle source set infrastructure and introduces its own.
To be fair, the Android API tries to mimic the Gradle one, so I suspect
the reinvention was done for a reason.

* `AndroidSourceDirectorySet` (mimics Gradle `SourceDirectorySet`) —
  a set of source code files;
* `AndroidSourceSet` (mimics Gradle `SourceSet`) —
  a group of `AndroidSourceDirectorySet`s for Java code and resources,
  Android resources, assets, AIDL, RenderScript files and more.

The Kotlin Android plugin doesn’t provide a `KotlinAndroidSourceSet`
(like `KotlinSourceSet` for JVM). Fortunately enough we can use the Java `AndroidSourceSet` instead.

The DSL is similar to the Gradle one.

* Single module (put in the module `build.gradle.kts` file).

    ```kotlin
    android {
        // Get an AndroidSourceSet collection
        sourceSets {
            // Get an AndroidSourceSet by name
            named("SOURCE SET NAME") {
                // Configure Java AndroidSourceDirectorySet
                java.srcDirs("PATH A", "PATH B", "PATH C")
            }
        }
    }
    ```

* Multiple modules (put in the root `build.gradle.kts` file).

    ```kotlin
    import com.android.build.gradle.AppPlugin
    import com.android.build.gradle.BaseExtension
    import com.android.build.gradle.LibraryPlugin

    subprojects {
        // Since the API comes from a plugin we have to wait for it
        plugins.matching { it is AppPlugin || it is LibraryPlugin }.whenPluginAdded {
            // The android function is not available at root so we use a different syntax
            configure<BaseExtension> {
                sourceSets {
                    named("SOURCE SET NAME") {
                        java.srcDirs("PATH A", "PATH B", "PATH C")
                    }
                }
            }
        }
    }
    ```

# Gradle Implementation

Finally! We can use the Gradle API to apply our tips!
Snippets below are DSL declarations which can be used in both single and multiple module
configurations described above.

## JVM

```kotlin
named("main") {
    withConvention(KotlinSourceSet::class) {
        kotlin.srcDirs("src/main/kotlinX")
    }
}

named("test") {
    withConvention(KotlinSourceSet::class) {
        kotlin.srcDirs("src/test/kotlinX", "src/testFixtures/kotlin")
    }
}
```

## Android

```kotlin
named("main") {
    java.srcDirs("src/main/kotlin", "src/main/kotlinX")
}

named("test") {
    java.srcDirs("src/test/kotlin", "src/test/kotlinX", "src/testFixtures/kotlin")
}
```

# Next?

Don’t afraid to configure source sets — think more about what can be done better
and adapt. The Gradle API might be not intuitive at the first glance —
especially when Kotlin and Android are brought in the mix but almost everything can be achieved.
