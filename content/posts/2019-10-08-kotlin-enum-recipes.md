---
title: "Kotlin Enum Recipes"
description: "Is this... a sealed class?"
date: 2019-10-08
slug: kotlin-enum-recipes
---

Enumerations, in a form of `enum class` declarations, got a bad rep on Android.
In fact, the official documentation straight out
[recommends to avoid them](https://developer.android.com/topic/performance/reduce-apk-size#remove-enums).
How rude is that?
At the same time, [Effective Java](https://www.amazon.com//dp/0134685997)
has a full chapter about `enum`.
The situation reminds me of [the trolley problem](https://en.wikipedia.org/wiki/Trolley_problem).
Kind of.

In this article, I’ll distance myself from Android specifics and show
useful `enum`-related snippets.

# Declaration

## Naming

Use `CamelCase`, don’t be ashamed. I doubt that anyone names
`sealed class` using the `UPPERCASE` notation.

```kotlin
sealed class Level {
    data class HIGH(val value: Long) : Level()
    data class LOW(val value: Short) : Level()
}
```

Enumerations are not so different. Don’t scream in code!
We don’t have [BASIC](https://en.wikipedia.org/wiki/BASIC) syntax constraints.

```kotlin
enum class Fruit {
    Apple, Orange
}
```

## Commas

Let’s say we have a `Screen` enumeration.

```kotlin
enum class Screen(val analyticsName: String) {
    SignIn("Sign In")
}
```

At some point we need to add another case to the `Screen` — `SignUp`.

```kotlin
enum class Screen(val analyticsName: String) {
    SignIn("Sign In"),
    SignUp("Sign Up")
}
```

Looks fine, but the change from a VCS perspective will be like this:

```diff
- SignIn("Sign In")
+ SignIn("Sign Up"),
+ SignUp("Sign Up")
```

This approach makes it difficult to see through `SignIn` changes.
The last `SignIn` change is now tied to the `SignUp` one which doesn’t make sense.
We can solve this by putting commas after each enumeration case.

```kotlin
enum class Screen(val analyticsName: String) {
    SignIn("Sign In"),
    SignUp("Sign Up"),
}
```

This way the VCS change becomes minimal.

```diff
+ SignUp("Sign Up"),
```

# Usage

## Constants Namespacing

The barbarian approach to create namespaces is using prefixes.

```kotlin
companion object {
    const val SHARED_PREFERENCE_KEY_TOKEN = "token"
    const val SHARED_PREFERENCE_KEY_SESSIONS_COUNT = "sessions-count"
}
```

The next step — named `companion object`.

```kotlin
companion object SharedPreferenceKeys {
    const val TOKEN = "token"
    const val SESSIONS_COUNT = "sessions-count"
}
```

There is catch though — a class can have a single `companion object`, named or not.
`enum` doesn’t have such limitations.

```kotlin
enum class SharedPreferenceKey(val value: String) {
    Token("token"),
    SessionsCount("sessions-count"),
}
```

## Abstraction

### API

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

> :warning: Gson will write unknown `enum` values as `null` —
> ignoring the Kotlin nullability — since the Java reflection doesn’t know about Kotlin.
> Make such values nullable and handle them as deserialization errors or use
> Moshi which will do it automatically.

### Android Resources

It is possible to define `enum` in XML which is helpful with custom `View` implementations.

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

Instead of `Int`-matching in `NavigationBar.kt` it is better
to declare an `enum` as a direct XML mirror.

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

### Even More

Map markers:

```kotlin
enum class Marker(@DrawableRes val icon: Int, val elevation: Int) {
    Airport(R.drawable.ic_map_airport, elevation = 4),
    Underground(R.drawable.ic_map_underground, elevation = 0),
}

data class ViewState(val marker: Marker, val location: LatLng)
```

List sections:

```kotlin
enum class Section(@StringRes val title: Int, val from: Int, val to: Int) {
    Dozen(R.string.Section_Dozen, from = 0, to = 10),
    Dozens(R.string.Section_Dozens, from = 11, to = Int.MAX_VALUE),
}

listOf(1, 2, 3, 42).groupBy { number ->
    Section.values().find { it.from <= number && number <= it.to }
}
```

The idea remains the same — use the declarative `enum` nature when it fits.

## Iterating

### Templates

Let’s say we need to render an HTML page. Since we want to keep application colors
and HTML colors in sync, we need to translate resources to RGBA hex values.

This is where the `enum` `values()` method becomes helpful. We can declare
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

### Tests

This is not as useful for JUnit-based approaches but enumerations shine with
anything specification-related.

```kotlin
ErrorCode.values().forEach { errorCode ->

    it("creates error response from error code [${errorCode.name}]") {
        assertThat(api.response(errorCode)).isEqualTo(ErrorResponse(errorCode))
    }
}
```

This is a rough equivalent of this JUnit test:

```kotlin
@Test fun `it creates error response`() {
    ErrorCode.values().forEach { errorCode ->
        assertThat(api.response(errorCode)).isEqualTo(ErrorResponse(errorCode))
    }
}
```

However, instead of a single test with a number of assertions the specification above
will produce a number of tests with a single assertion in each one.

```
.
├── it creates error response from error code [BadRequest]
├── it creates error response from error code [NotFound]
└── it creates error response from error code [Unauthorized]
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

## Anti-Abusing `sealed class`

I see the following `sealed class` usage from time to time and it kind of hurts.

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

# Refactoring IRL

I was lucky to see
[a convenient piece of the Mozilla Fenix code](https://github.com/mozilla-mobile/fenix/blob/e6d29df5de88684be18778c155ba694f794423ca/app/src/main/java/org/mozilla/fenix/AppRequestInterceptor.kt#L61-L117)
which I’m gonna refactor step-by-step.

## `sealed class` → `enum class`

There is no need to have a `sealed class` with `object` cases. Replacing it with `enum`.

```kotlin
sealed class RiskLevel {
    object Low : RiskLevel()
    object Medium : RiskLevel()
    object High : RiskLevel()
}
```

:arrow_down:

```kotlin
enum class RiskLevel { Low, Medium, High }
```

## Methods → Fields

We can inline method result values into `enum` since both are matching operations and nothing else.

```kotlin
private fun getPageForRiskLevel(riskLevel: RiskLevel): Int {
    return when (riskLevel) {
        RiskLevel.Low -> R.raw.low_risk_error_pages
        RiskLevel.Medium -> R.raw.medium_and_high_risk_error_pages
        RiskLevel.High -> R.raw.medium_and_high_risk_error_pages
    }
}

private fun getStyleForRiskLevel(riskLevel: RiskLevel): Int {
    return when (riskLevel) {
        RiskLevel.Low -> R.raw.low_and_medium_risk_error_style
        RiskLevel.Medium -> R.raw.low_and_medium_risk_error_style
        RiskLevel.High -> R.raw.high_risk_error_style
    }
}
```

:arrow_down:

```kotlin
enum class RiskLevel(@RawRes val html: Int, @RawRes val css: Int) {
    Low(R.raw.low_risk_error_pages, R.raw.low_and_medium_risk_error_style),
    Medium(R.raw.medium_and_high_risk_error_pages, R.raw.low_and_medium_risk_error_style),
    High(R.raw.medium_and_high_risk_error_pages, R.raw.high_risk_error_style),
}
```

## Usage

Since we don’t have methods anymore we can reference `enum` fields directly.

```kotlin
val htmlResource = getPageForRiskLevel(riskLevel)
val cssResource = getStyleForRiskLevel(riskLevel)

ErrorPages.createErrorPage(htmlResource, cssResource)
```

:arrow_down:

```kotlin
ErrorPages.createErrorPage(riskLevel.html, cssResource.css)
```

## Voilà!

Seems like we managed to eliminate about 20 LOC without loss.
In fact, the code became more declarative!

I think this example shows that there are good enumeration use cases.
Don’t be afraid to use them. Not everything needs a `sealed class`.
