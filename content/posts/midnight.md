---
title: "Midnight in Android Themes"
description: "Dark theme: colors, animations, elevations, HTML, Maps and more."
date: 2019-08-14
slug: midnight-in-android-themes
---

# Colors

This is most likely the most important step.
In ideal scenario it sounds like an easy task — re-declare colors
in `values-night/colors.xml` and that’s it.
Unfortunately it might be more complicated.
Let’s say the primary color across an application is the one
associated with a brand. It is undesirable to change it across themes
but it doesn’t look great all the time. A good example is using
dark colors — such ones look fine in light themes but are blending
into background in dark themes. In such situations it might be
better to use the brand color everywhere except tiny elements —
like `EditText` underlines and links.

To resolve this I’ve found out an approach of opting out of color changes between themes.


```xml
<!-- values/colors.xml -->

<color name="themeless_black">#000000</color>
<color name="themeless_white">#ffffff</color>

<color name="themed_black">@color/themeless_black</color>
<color name="themed_white">@color/themeless_white</color>

<!-- values-night/colors.xml -->

<color name="themed_black">@color/themeless_white</color>
<color name="themed_white">@color/themeless_black</color>
```

The idea is simple — use `themed_*` colors by default.
Such colors are changed across themes and in the majority of situations it is fine.
In exceptional situations when the color should stay the same — use `themeless_*` one.

# Themes

```xml
<!-- values/themes.xml -->

<style name="Base.Theme.Local" parent="Theme.AppCompat.Light.NoActionBar"/>

<style name="Theme.Local" parent="Base.Theme.Local"/>

<!-- values-v23/themes.xml -->

<style name="Base.Theme.Local.v23">
    <item name="android:statusBarColor">@color/themed_white</item>
    <item name="android:windowLightStatusBar">@bool/theme_light</item>
</style>

<style name="Theme.Local" parent="Base.Theme.Local.v23"/>

<!-- values-v27/themes.xml -->

<style name="Base.Theme.Local.v27" parent="Base.Theme.Local.v23">
    <item name="android:navigationBarColor">@color/themed_white</item>
    <item name="android:windowLightNavigationBar">@bool/theme_light</item>
</style>

<style name="Theme.Local" parent="Base.Theme.Local.v27"/>
```

# Icons

## Local

Avoid using bitmap ones like a plague! Well, it makes sense to use bitmaps
for illustrations but icons ideally should be in vector.
Doing so allows to use colors directly in paths and brings automatic theme management.

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24.0"
    android:viewportHeight="24.0">

    <path
        android:fillColor="@color/themed_black"
        android:pathData="drawing-instructions" />

</vector>
```

## Remote

Icons fetched from backend are most likely bitmaps.
It is possible to tint them locally but I would suggest avoid doing so.
Usually resources are placed on remote servers to achieve flexibility.
One day remote icons are monochrome with transparent areas,
the next day they are colorful and photo-realistic.
Tinting will turn latter ones into colored silhouettes.

A better solution is finding a middle-ground — remote icons should fit
light and dark themes at the same time. It is not a universal solution
but most of the time it should work.

# Lottie Animations

Unfortunately Lottie animations do not use Android color resources.
Colors are inlined into the JSON file itself. The good thing is —
it is possible to change colors in runtime using
[dynamic properties](http://airbnb.io/lottie/#/android?id=dynamic-properties).
In fact, I would advise to do this all the time, no matter if there is
a dark theme or not. Colors change all the time but animation files
are not changed with the same frequency.

The implementation is actually a breeze. The awkward part is finding out
correct `KeyPath` combinations — it is better to do that with a design team.

```kotlin
enum AnimationComponent(val path: KeyPath, @ColorRes val colorRes: Int) {
   Circle(KeyPath("circle"), R.color.themed_red),
   Rectangle(KeyPath("rect"), R.color.themed_green),
}

AnimationComponent.values().forEach { component ->
    @ColorInt val componentColor = context.color(component.color)

    animationView.addValueCallback(component.path, LottieProperty.COLOR) { componentColor }
}
```

# Elevation

Elevation looks good in light themes but is essentially invisible in dark ones.
The issue is not new. In fact, it was already resolved and the solution
is described in detail in [the Material Design spec](https://material.io/design/color/dark-theme.html#properties). In short — it is proposed to use overlays in addition to shadows
in dark themes. The overlay changes its transparency depending on the current elevation.
When the overlay is something like white color the elevated surface becomes
lighter. Nice!

Technically speaking the solution is available as well.
[Material Components](https://github.com/material-components/material-components-android)
[implement](https://github.com/material-components/material-components-android/blob/master/docs/theming/Dark.md#elevation-overlays)
elevation overlays in their components like `TabLayout`, `Toolbar`, `NavigationView` and more.

Following attributes declared in the theme will activate overlays and it will be possible
to see the effect immediately on supported components.

```xml
<!-- Translated to black in dark theme. -->
<item name="colorSurface">@color/themed_white</item>
<!-- The boolean value is custom and placed in values and values-night. -->
<item name="elevationOverlayEnabled">@bool/theme_dark</item>
<!-- The color is usually white but might be different. -->
<item name="elevationOverlayColor">@color/elevation_overlay</item>
```

What about custom components? Actually, it is handled by Material Components as well.
There is a `Drawable` subclass called [`MaterialShapeDrawable`](https://github.com/material-components/material-components-android/blob/master/docs/theming/Shape.md).
It is possible to supply it with elevation to achieve the desired effect.
Actually this is what Material Components use under the hood.

```kotlin
class Surface(context: Context, attributes: AttributeSet) : FrameLayout(context, attributes) {

    init {
        background = MaterialShapeDrawable.createWithElevationOverlay(context, elevation)
    }

    override fun setElevation(elevation: Float) {
        super.setElevation(elevation)

        MaterialShapeUtils.setElevation(this, elevation)
    }
}
```

> :book: Take a look at `ShapeAppearanceModel` to make cards with rounded corners,
> triangle edges and more via custom `EdgeTreatment` and `CornerTreatment` implementations.

What about gradients and color transitions on elevated surfaces?
`ElevationOverlayProvider` helps with that. This class is used under the hood
of `MaterialShapeDrawable`. The following extension is a helpful shortcut.

```kotlin
@ColorInt
fun Context.surfaceColor(elevation: Float): Int {
    return ElevationOverlayProvider(this).compositeOverlayWithThemeSurfaceColorIfNeeded(elevation)
}
```

Talking about surface colors — let’s backtrack a bit.
Which color should be used for `elevationOverlayColor` attribute?
`#ffffff` comes to mind. Unfortunately that is not always what
a design team wants to see. Most likely there will be a defined
color `S` for surfaces and a color `ES` for elevated surfaces.
At the same time, the math behind `ElevationOverlayProvider` is a bit tricky,
especially when it comes to ARGB colors with defined alpha channel.

The solution here is color subtraction. Yep. To get a color for `elevationOverlayColor`
subtract S from ES. For example, using the surface color
`#000000` <span style="color: #000000">■</span>
and the elevated surface color
`#5b5f65` <span style="color: #5b5f65">■</span>
we’ll get
`#e6f0ff` <span style="color: #e6f0ff">■</span>.
Using the resulting color is usually close enough to design vision without losing
the ability to automatically change surface color depending on the current elevation.
Oh, please don’t subtract colors manually,
use [the special calculator](https://www.colorhexa.com).

> :book: Since I’m horrible at explaining color math — refer to wonderful
> [Alpha Compositing](https://ciechanow.ski/alpha-compositing/) and
> [Color Spaces](https://ciechanow.ski/color-spaces/) articles for details about color subtraction.

# HTML

## Remote

Since Chrome 76 it is possible to use the
[`prefers-color-scheme`](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-color-scheme)
CSS media feature. It allows to switch website theme using OS-level settings.
This blog supports it!

* On macOS open System Preferences → General → Switch Appearance to Dark.
* On Android Q+ switch to Dark theme using Settings Panel on top of system notifications.
* On Windows, KDE, GNOME and friends — sorry folks, I have no idea what to do.

Technically it is implemented like this:

```css
:root {
    --color-background: #ffffff;
}

@media (prefers-color-scheme: dark) {
    :root {
        --color-background: #1d1f21;
    }
}

body {
    background-color: var(--color-background);
}
```

Since Android 5.0 the `WebView`
[is updated separately](https://developer.chrome.com/multidevice/webview/overview)
so there is a good chance that it will support this feature as well.
[Chrome Custom Tabs](https://developer.chrome.com/multidevice/android/customtabs)
might work a bit better.

Of course, this kind of approach will require implementation from a frontend team
behind web pages shown in the application but it is something.

## Local

There is a good chance that some web pages are rendered locally on a device.
Good examples are OSS license screens and HTML-formatted content from a backend.

Of course it is possible to use the approach described above for Remote pages
but until the `WebView` is updated everywhere to Chrome 76-backed version
it is possible to use templating like this.

```mustache
body {
    background-color: {{color_background}};
}
```

This is [a Mustache-like template](https://mustache.github.io).
`{{color_background}}` is gonna be replaced in runtime with local colors.

```kotlin
enum class HtmlColor(val mask: String, @ColorRes res: Int) {
    Background("color_background", R.color.themed_white),
}

val html = HtmlColor.values().fold(htmlTemplate) { html, htmlColor ->
    html.replace("{{${htmlColor.mask}}}", "#${context.color(htmlColor.res).colorHexRgba()}")
}

fun Int.colorHexRgba() = String.format("%08x", shl(8) + ushr(24))
```

Notice the `colorHexRgba` extension. It is not possible to use Android colors as-is
since HTML uses RGBA notation while Android uses ARGB
(I hope there was a good reason for this).

# Maps

Both regular and [lite](https://developers.google.com/maps/documentation/android-sdk/lite)
[`MapView`](https://developers.google.com/android/reference/com/google/android/gms/maps/MapView)
support styling via
[`MapStyleOptions`](https://developers.google.com/android/reference/com/google/android/gms/maps/model/MapStyleOptions).
In fact, it is possible to place the light style in `raw/map_style.json` and
the dark one in `raw-night/map_style.json`. This approach gives automatic
map style switching via referencing `R.raw.map_style`.

Using [static maps](https://developers.google.com/maps/documentation/maps-static/intro)
is a bit more awkward.
[The styling is still available](https://developers.google.com/maps/documentation/maps-static/styling)
but since the style is sent via HTTP request it means that domain-level entities of the application
will know about the presentation-level characteristic. This is an unpleasant
coupling. I suggest to migrate to the lite `MapView` — it covers basically everything
the static map provides and renders maps on a device instead of making network calls.
Also — it is free! The static maps API is billed.
