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

## Namespacing

The barbarian approach to create namespacing is (of course) prefixes.

```kotlin
companion object {
    const val SHARED_PREFERENCE_KEY_TOKEN = "token"
    const val SHARED_PREFERENCE_KEY_SESSIONS_COUNT = "sessions-count"
}
```

The next level is named `companion object` declarations.

```kotlin
companion object SharedPreferenceKeys {
    const val TOKEN = "token"
    const val SESSIONS_COUNT = "sessions-count"
}
```

There is catch though — a class can have a single `companion object`,
no matter named or not.

It is possible to use `enum` to create an infinite number of namespaces.

```kotlin
enum class SharedPreferenceKey(val value: String) {
    Token("token"),
    SessionsCount("sessions-count"),
}
```

An additional bonus — type-safety!

```kotlin
// Possible to pass non-existent keys.
fun sharedPreferenceValue(key: String): String

// Impossible to pass garbage since the type provides the scoping.
fun sharedPreferenceValue(key: SharedPreferenceKey): String
```

## Abstraction

The idea is simple. When we have an enumeration set that we need to translate
in source code — it might be useful to have an `enum`. First, it brings
the declarative description of available enumeration cases. Second, it provides
type-safety over alternative methods (like constants).

### HTTP API

Let’s imagine that a backend returns codes in error responses.

```kotlin
data class ErrorResponse(@SerializedName("code") val code: String)
```

This is a fine declaration but the usage becomes repetitive and error-prone to typos.

```kotlin
if (error.code == "not_found") {
    throw RuntimeException()
}

// ... 1_000_000 LOC ...

// Oops!
if (error.code == "not__found") {
    throw RuntimeException()
}
```

Enumerations are perfect for this.

```kotlin
enum class ErrorCode(val value: String) {
    @SerializedName("not_found") NotFound,
    @SerializedName("unauthorized") Unauthorized,
}

data class ErrorResponse(@SerializedName("code") val code: ErrorCode?)
```

> :warning: Gson will write unknown `enum` values as `null`,
> no matter the Kotlin nullability since the Java reflection doesn’t know about it.
> Make such values nullable and handle them as deserialization errors or use
> Moshi which will handle it automatically.

### Android Resources

It is possible to define `enum` in XML which is helpful for custom `View` implementations.

```xml
<declare-styleable name="NavigationBar">
    <attr name="navigationIcon">
        <enum name="back" value="0"/>
        <enum name="close" value="1"/>
        <enum name="menu" value="2"/>
    </attr>
</declare-styleable>
```
```xml
<NavigationBar
    android:layout_height="wrap_content"
    android:layout_width="match_parent"
    application:navigationIcon="close"/>
```

Instead of matching to constants in `NavigationBar.kt` it is better
to declare `enum` as an XML mirror.

```kotlin
enum class NavigationIcon(val attrValue: Int) {
    Back(0),
    Close(1),
    Menu(2),
}
```
```kotlin
val defaultIcon = NavigationIcon.Back

val icon = attrs.getInt(R.styleable.NavigationBar_navigationIcon, defaultIcon.attrValue).let { attrValue ->
    NavigationIcon.values().find { it.attrValue == attrValue } ?: defaultIcon
}
```

### Platform-Specific Values

It is useful to hide platform values inside `enum` cases to provide
both abstraction from a platform and DSL-like storage of possibilities.

For example, here is an enumeration of supported vibration patterns:

```kotlin
enum class VibrationPattern(private vararg timings: Long) {
    Ping(0, 100),
    Pong(50, 150),
    ;

    fun asAndroidEffect() = android.os.VibrationEffect.createWaveform(timings)
}
```

Map markers:

```kotlin
enum class Marker(@DrawableRes val icon: Int, val elevation: Int) {
    Airport(R.drawable.ic_map_airport, 4),
    Underground(R.drawable.ic_map_underground, 0),
}

data class ViewState(val marker: Marker, val location: LatLng)
```

List sections:

```kotlin
enum class Section(@StringRes val title: Int, val from: Int, val to: Int) {
    Dozen(R.string.Section_Dozen, 0, 10),
    Dozens(R.string.Section_Dozens, 11, Int.MAX_VALUE),
}

data class ViewState(val values: Map<Section, List<Item>>)
```

The idea remains the same — keep the declarative description of enumeration sets.

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

## Batch Operations

Let’s say we need to render an HTML page. Since we want to keep native colors
and HTML colors in sync — we need to translate native ones to HTML.

This is where the `values()` `enum` method becomes helpful. We can declare
color associations, go over all of them and get processed CSS.

```kotlin
enum class CssTemplateColor(val mask: String, @ColorRes val res: Int) {
    Background("color_background", R.color.white),
    Text("color_text", R.color.black),
}
```
```kotlin
val cssTemplate =
    """
    body {
        background-color: {{color_background}};
        color: {{color_text}};
    }
    """

val css = CssTemplateColor.values().fold(cssTemplate) { css, color ->
    css.replace("{{${color.mask}}}", "#${color.res.hexRgba()}")
}
```

Another example — LeakCanary and its [`AndroidReferenceMatchers`](https://github.com/square/leakcanary/blob/bd9d9836813d06df41335ed8916ce756628a3130/shark-android/src/main/java/shark/AndroidReferenceMatchers.kt).
Since it is declared as `enum` with a common method declaration —
it is possible to [go over all cases and call the method](https://github.com/square/leakcanary/blob/bd9d9836813d06df41335ed8916ce756628a3130/shark-android/src/main/java/shark/AndroidReferenceMatchers.kt#L1217-L1233). Think about it as iterating over all `interface` implementations
without reflection calls.

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

# Case Study Refactoring

We are gonna take a piece of the Mozilla Fenix code and refactor it.

```kotlin
enum class RiskLevel(@RawRes val pageRes: Int, @RawRes val styleRes: Int) {
    Low(R.raw.low_risk_error_pages, R.raw.low_and_medium_risk_error_style),
    Medium(R.raw.medium_and_high_risk_error_pages, R.raw.low_and_medium_risk_error_style),
    High(R.raw.medium_and_high_risk_error_pages, R.raw.high_risk_error_style),
}

val ErrorType.riskLevel: RiskLevel = when (this) {
    ErrorType.UNKNOWN,
    ErrorType.ERROR_UNKNOWN_PROTOCOL,
    ErrorType.ERROR_UNKNOWN_PROXY_HOST -> RiskLevel.Low

    ErrorType.ERROR_SECURITY_BAD_CERT,
    ErrorType.ERROR_SECURITY_SSL -> RiskLevel.Medium

    ErrorType.ERROR_SAFEBROWSING_MALWARE_URI -> RiskLevel.High
}
```
