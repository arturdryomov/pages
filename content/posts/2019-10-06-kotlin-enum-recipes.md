---
title: "Kotlin Enum Recipes"
description: "Is this... a sealed class?"
date: 2019-10-06
slug: kotlin-enum-recipes
---

# Declaration

## Naming

Use `CamelCase`, don’t be ashamed. I doubt that anyone names
sealed classes using the `UPPERCASE` notation.

```kotlin
sealed class Level {
    data class HIGH(val value: Long) : Level()
    data class LOW(val value: Short) : Level()
}
```

Enumerations are not so different. Don’t scream at developers!
We don’t have [BASIC](https://en.wikipedia.org/wiki/BASIC) constraints.

```kotlin
enum class Fruit {
    Apple, Orange
}
```

## Multiline Commas

There is a useful trick for minimizing VCS changes while adding an `enum` case.

```kotlin
enum class Screen(val analyticsName: String) {
    SignIn("Sign In")
}
```

Let’s imagine we need to add an another case to the `Screen` `enum` — `SignUp`.

```kotlin
enum class Screen(val analyticsName: String) {
    SignIn("Sign In"),
    SignUp("Sign Up")
}
```

Looks fine, but the VCS change will look like this:

```diff
- SignIn("Sign In")
+ SignIn("Sign Up"),
+ SignUp("Sign Up")
```

This approach makes it difficult to determine when the `SignIn` case was introduced
since the last `SignIn` change is now tied to the `SignUp` one which doesn’t make sense.

We can solve this via putting commas after each enumeration case.

```kotlin
enum class Screen(val analyticsName: String) {
    SignIn("Sign In"),
}
```

This way the VCS change becomes minimal:

```diff
+ SignUp("Sign Up"),
```

# Usage

## Anti-Abusing `sealed class`

I see the following sealed classes usage from time to time and it kind of hurts.

```kotlin
sealed class Color {
    object Red : Color()
    object Green : Color()
    object Blue : Color()
}
```

There is no reason for this not to be an `enum`.

```kotlin
enum class Color {
    Red, Green, Blue
}
```

Putting semantics aside I want to remind everyone that the Kotlin `object`
creates a singleton. I doubt that it is desirable to have a lot of static objects.

For example, the `sealed class Color` above will be translated into something like this (in Java notation):

```java
public abstract class Color {

    private Color() {
    }

    public static final class Red extends Color {
        public static final Color.Red INSTANCE = new Color.Red();
    }

    public static final class Green extends Color {
        public static final Color.Green INSTANCE = new Color.Green();
    }

    public static final class Blue extends Color {
        public static final Color.Blue INSTANCE = new Color.Blue();
    }
}
```

## [`EnumSet`](https://developer.android.com/reference/java/util/EnumSet)

Use it when there is a need to define a subset of enumeration values.
It is much more efficient than regular `Set` implementations
since values are stored as bit vectors internally.

```kotlin
val onboardingScreens = EnumSet.of(Screen.SignIn, Screen.SignUp)
```

This is a `java.util` class and unfortunately there nothing
like this in Kotlin for cases when the endgame is multiplatform.
Most likely it is possible to solve this using platform-specific declarations.

```kotlin
expect fun <T> enumSetOf(vararg elements: T): Set<T>
```
```kotlin
// JVM
actual fun <T> enumSetOf(vararg elements: T): Set<T> = EnumSet.of(elements)

// Not JVM
actual fun <T> enumSetOf(vararg elements: T): Set<T> = setOf(elements)
```
