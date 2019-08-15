---
title: "Midnight in Android Themes"
description: "The dark theme: colors, animations, elevations, HTML, Maps and moar."
date: 2019-08-15
slug: midnight-in-android-themes
---

Android Q introduces [dark themes](https://developer.android.com/preview/features/darktheme).
Or [night mode](https://developer.android.com/reference/androidx/appcompat/app/AppCompatDelegate.html#MODE_NIGHT_YES)?
No idea. Anyways, it is here and can be helpful with using applications in
dark environments or with bringing back that sweet Winamp skins vibe.

Implementing dark themes is surprisingly deep and affects the whole application.
At times it feels like a redesign. I’ve tried to collect steps we’ve made to
introduce the dark theme in the [Juno rider application](https://play.google.com/store/apps/details?id=com.gojuno.rider)
and make a (kind of) comprehensive guide. Let’s jump in!

# Switching

It is important to start with this step to actually take a look at the dark theme.

`AppCompatDelegate.setDefaultNightMode` is our friend here. Use AppCompat 1.1.0+ —
earlier versions do not work well with theme switching (activities don’t restart,
themes are not applied to the navigation bar).

* Android < Q
  * Show the in-application switch. Save theme on each switch.
  * Use `AppCompatDelegate.MODE_NIGHT_NO` and `AppCompatDelegate.MODE_NIGHT_YES`.
  * In `Application.attachBaseContext` read saved theme and switch to it.
* Android ≥ Q
  * Do not show in-application switch. The system one is enough.
  * In `Application.attachBaseContext` switch to `AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM`.

That’s it! From now on it is possible to use resources with the `night` modifier
(`values-night`, `drawable-night`, etc). Unfortunately switching recreates
activities, like a regular configuration change.

> :warning: I ignore `AppCompatDelegate.MODE_NIGHT_AUTO_BATTERY`
> and go against [Google suggestions](https://developer.android.com/preview/features/darktheme#changing_themes_in-app)
> of showing a gazillion of switches.
> At least macOS and Windows work without ad-hoc switches.

# Colors

In the ideal scenario it is enough to re-declare colors in `values-night/colors.xml`.
Unfortunately it is not always so simple. It might be important
to maintain brand colors but replace them with vibrant variants
for small elements like underlines and links. Or keep colors across themes for particular icons.

To resolve this I’ve found an approach of opting out from color changes between themes.
We’ll declare two sets of colors — themed and themeless. Themed ones should be
used by default but can be replaced with themeless variants to opt-out from
theming. The colors naming gives mnemonics as a bonus — before using a color
a developer should explicitly choose whether it should be themed or not.

```xml
<!-- values/colors.xml -->

<color name="themeless_black">#000000</color>
<color name="themeless_white">#ffffff</color>

<color name="themed_black">@color/themeless_black</color>
<color name="themed_white">@color/themeless_white</color>
```

```xml
<!-- values-night/colors.xml -->

<color name="themed_black">@color/themeless_white</color>
<color name="themed_white">@color/themeless_black</color>
```

# Themes

There is a good chance that system status and navigation bars should have
different colors between themes. `*BarColor` and `windowLight*Bar` do the trick.
Unfortunately these attributes are available from different API versions
so we’ll use a known trick with `Base.*` themes.

```xml
<!-- values/bools.xml -->

<bool name="theme_light">true</bool>
```

```xml
<!-- values-night/bools.xml -->

<bool name="theme_light">false</bool>
```

```xml
<!-- values/themes.xml -->

<style name="Base.Theme.Local" parent="Theme.AppCompat.Light.NoActionBar"/>
<style name="Theme.Local" parent="Base.Theme.Local"/>
```

> :bulb: Notice that I’m not using `Theme.AppCompat.DayNight`.
> `DayNight` switches `Theme.AppCompat` attributes between themes but it might be
> useless if attributes are already re-declared in the application-level theme.

```xml
<!-- values-v23/themes.xml -->

<style name="Base.Theme.Local.v23">
    <item name="android:statusBarColor">@color/themed_white</item>
    <item name="android:windowLightStatusBar">@bool/theme_light</item>
</style>

<style name="Theme.Local" parent="Base.Theme.Local.v23"/>
```

```xml
<!-- values-v27/themes.xml -->

<style name="Base.Theme.Local.v27" parent="Base.Theme.Local.v23">
    <item name="android:navigationBarColor">@color/themed_white</item>
    <item name="android:windowLightNavigationBar">@bool/theme_light</item>
</style>

<style name="Theme.Local" parent="Base.Theme.Local.v27"/>
```

# Icons

## Local

Avoid using bitmaps like a plague! Well, it makes sense to use bitmaps
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
        android:pathData="drawing-instructions"
        />

</vector>
```

## Remote

Icons fetched from a backend are most likely bitmaps.
It is possible to tint them locally but I would suggest avoiding doing so.
Usually resources are placed on remote servers to achieve flexibility.
One day remote icons are monochrome with transparent areas,
the next day they are colorful and photo-realistic.
Tinting will turn the latter ones into colored silhouettes.

A better solution is finding a middle-ground — remote icons should fit
both light and dark themes.

# Lottie Animations

Unfortunately Lottie animations do not use Android color resources.
Colors are inlined in JSON files. The good thing is —
it is possible to change colors in runtime using
[dynamic properties](http://airbnb.io/lottie/#/android?id=dynamic-properties).
In fact, I would advise to do so all the time, no matter if there is
a dark theme or not. Colors change all the time but animation files
are not changed with the same frequency.

The implementation is actually a breeze. The awkward part is finding
correct `KeyPath` combinations — it is better to do that with a design team.

```kotlin
enum AnimationComponent(val path: KeyPath, @ColorRes val colorRes: Int) {
   Circle(KeyPath("circle-group-42"), R.color.themed_black),
}

AnimationComponent.values().forEach { component ->
    @ColorInt val componentColor = context.color(component.color)

    animationView.addValueCallback(component.path, LottieProperty.COLOR) { componentColor }
}
```

# Elevation

Elevations look good in light themes but are essentially invisible in dark ones.
The workaround is described in [the Material Design spec](https://material.io/design/color/dark-theme.html#properties).
In short — it is proposed to use overlays in addition to shadows
for dark themes. The overlay changes its transparency depending on the current elevation.
When the overlay is the white color the elevated surface becomes
lighter. Neat!

The technical solution is available as well.
[Material Components](https://github.com/material-components/material-components-android)
[implement](https://github.com/material-components/material-components-android/blob/master/docs/theming/Dark.md#elevation-overlays)
elevation overlays in components like `NavigationView`, `TabLayout`, `Toolbar` and more.

Following attributes declared in the theme will activate overlays.

```xml
<!-- values/bools.xml -->

<bool name="theme_dark">false</bool>
```

```xml
<!-- values-night/bools.xml -->

<bool name="theme_dark">true</bool>
```

```xml
<!-- values/themes.xml -->

<item name="colorSurface">@color/themed_white</item>
<item name="elevationOverlayEnabled">@bool/theme_dark</item>
<item name="elevationOverlayColor">@color/themed_black</item>
```

What about custom components? Actually, it is handled by Material Components as well.
There is a `Drawable` subclass called [`MaterialShapeDrawable`](https://github.com/material-components/material-components-android/blob/master/docs/theming/Shape.md).
It is possible to supply it with the elevation to achieve the desired effect.
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

> :book: Take a look at the `ShapeAppearanceModel` to make cards with rounded corners,
> triangle edges and more via custom `EdgeTreatment` and `CornerTreatment` implementations.

What about gradients and color transitions on elevated surfaces?
`ElevationOverlayProvider` helps with that. This class is used under the hood
of `MaterialShapeDrawable`. The following extension is a shortcut.

```kotlin
@ColorInt
fun Context.surfaceColor(elevation: Float): Int {
    return ElevationOverlayProvider(this).compositeOverlayWithThemeSurfaceColorIfNeeded(elevation)
}
```

Talking about surface colors — let’s backtrack a bit.
Which color should be used for the `elevationOverlayColor` attribute?
`#ffffff` comes to mind. Unfortunately this is not always what
a design team wants. Most likely there will be a defined
color `S` for surfaces and a color `ES` for elevated surfaces.
The math behind `ElevationOverlayProvider` is a bit tricky,
especially when it comes to ARGB colors with defined alpha channel.

The solution here is the color subtraction. To get a color for `elevationOverlayColor`
subtract `S` from `ES`. For example, using the surface color
`#000000` <span style="color: #000000">■</span>
and the elevated surface color
`#5b5f65` <span style="color: #5b5f65">■</span>
we’ll get
`#e6f0ff` <span style="color: #e6f0ff">■</span>.
Using the resulting color is usually close enough to the design vision without compromising
the ability to automatically change surface color depending on the current elevation.
Oh, please don’t subtract colors manually,
use [the special calculator](https://www.colorhexa.com).

> :book: Since I’m horrible at explaining color math — refer to wonderful
> [Alpha Compositing](https://ciechanow.ski/alpha-compositing/) and
> [Color Spaces](https://ciechanow.ski/color-spaces/) articles for details.

# HTML

## Remote

From Chrome 76 it is possible to use the
[`prefers-color-scheme`](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-color-scheme)
CSS media feature. It allows switching website themes using OS-level settings.
This blog supports it!

Technically it is implemented like this:

```css
:root {
    --color-background: #ffffff;
}

@media (prefers-color-scheme: dark) {
    :root {
        --color-background: #000000;
    }
}

body {
    background-color: var(--color-background);
}
```

From Android 5.0 the `WebView`
[is regularly updated](https://developer.chrome.com/multidevice/webview/overview)
so there is a good chance that it will support this feature.
[Chrome Custom Tabs](https://developer.chrome.com/multidevice/android/customtabs)
might work a bit better.

Of course, this kind of approach will require implementation from a frontend team
behind web pages.

## Local

There is a good chance that some web pages are rendered locally on a device.
Good examples are the OSS license screen and the HTML-formatted content from a backend.

Of course it is possible to use the approach described above for remote pages
but until the `WebView` is updated everywhere to the Chrome 76-backed version
it is possible to use templates.

```mustache
body {
    background-color: {{color_background}};
}
```

This is [a Mustache-like template](https://mustache.github.io).
`{{color_background}}` is replaced in runtime with a local color.

```kotlin
enum class CssColor(val mask: String, @ColorRes res: Int) {
    Background("color_background", R.color.themed_white),
}

val css = CssColor.values().fold(cssTemplate) { css, cssColor ->
    css.replace("{{${cssColor.mask}}}", "#${context.color(cssColor.res).colorHexRgba()}")
}

fun Int.colorHexRgba() = String.format("%08x", shl(8) + ushr(24))
```

> :bulb: Notice the `colorHexRgba` extension. It is not possible to use Android colors as-is
> since HTML uses the RGBA notation while Android uses the ARGB one.

# Maps

Both regular and [lite](https://developers.google.com/maps/documentation/android-sdk/lite)
[`MapView`](https://developers.google.com/android/reference/com/google/android/gms/maps/MapView)
support styling via
[`MapStyleOptions`](https://developers.google.com/android/reference/com/google/android/gms/maps/model/MapStyleOptions).
In fact, it is possible to place the light style in `raw/map_style.json` and
the dark one in `raw-night/map_style.json`. This approach gives automatic
map style switching via referencing `R.raw.map_style`.

Using [static maps](https://developers.google.com/maps/documentation/maps-static/intro)
is more awkward.
[The styling is still available](https://developers.google.com/maps/documentation/maps-static/styling)
but since the style is sent via an HTTP request it means that domain-level entities of the application
will know about the presentation-level characteristic. This is an unpleasant
coupling. I suggest to migrate to the lite `MapView` — it covers basically everything
the static map provides and renders it on a device instead of making network calls.
Also — it is [free](https://developers.google.com/maps/billing/gmp-billing#mobile-static)!

# MOAR

Fullscreen views, color change animations, dealing with transparency and
a lot of fine-tuning. The dark theme integration becomes a marathon, not a sprint.
Having something like a design system definitely helps.

Is it worth it? I think so. It sheds a light on hacks and forces
to make universal decisions. This is a good thing. Ah, yes, it looks nice!

---

The title is a reference to the [Midnight in a Perfect World](https://open.spotify.com/track/1z6zJqayfsAiiYtQ3minb7) track.

