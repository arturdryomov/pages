---
title: "Optimizing Android Vector Images. Or Not?"
description: "Measuring VectorDrawable drawing times with various tools applied."
date: 2018-09-09
slug: optimizing-android-vector-images
---

Developers like tools. A good tool can save hours of work or improve the workflow experience.
For example, it is possible to use `git log`, but why do that when [`tig`](https://jonas.github.io/tig/)
is around?

An average working day of an Android developer involves doing something with UI.
Pushing widgets around, changing text and images.
Turns out, the colleges of mine convert SVG images to `VectorDrawable` via
a specific converter and I use Android Studio.
Which tool does the job better? Let’s find out!

# Tools

Converters (do optimizations under the hood):

* Android Studio.
* [`svg2android`](http://inloop.github.io/svg2android/) — website,
  [`@Deprecated`](https://github.com/inloop/svg2android/commit/4c2312ad376e6c81f0673121b7978768cd94c595)
  in favor of Android Studio.
* [`svg2vector`](http://a-student.github.io/SvgToVectorDrawableConverter.Web/) — website.

Optimizers:

* [Avocado](https://github.com/alexjlockwood/avocado/) — command line tool, optimizes `VectorDrawable` XML files.
* [SVGO](https://github.com/svg/svgo) — command line tool, optimizes SVG files.

> :bulb: Zeplin exports SVG assets
> [using SVGO under the hood](https://support.zeplin.io/zeplin-101/developing-web-projects-using-zeplin).

# Sample Images

## [Octicons](https://octicons.github.com/)

These are examples of semi-complicated web icons.
Image sizes are unconventional — more than `1024` `dp`.
[It is not advisable to use vector images of such size](https://developer.android.com/studio/write/vector-asset-studio#when),
but let’s look at it as a push-to-the-limit approach.

* [`octicon-octoface`](https://octicons.github.com/icon/octoface/)
* [`octicon-repo`](https://octicons.github.com/icon/repo/)

## [Material](https://material.io/tools/icons/)

I suspect that these icons were designed with mobile in mind
and were pre-optimized for mobile rendering, but that might be completely false.
Both of them are conventionally sized to `24` `dp`.

* [`material-android`](https://material.io/tools/icons/?icon=android)
* [`material-store`](https://material.io/tools/icons/?icon=store)

# Comparison

## XML

It is not surprising, but files made by different tools are different.
Especially when it comes to the most important thing — `android:pathData`.
This `<path>` attribute serves as an instructions set in terms
of _go there, paint this_.

It reminds me of the very first programming language
I’ve used — [Logo](https://en.wikipedia.org/wiki/Logo_(programming_language)).
It can be used to teach basic programming concepts
using so-called [turtle graphics](https://en.wikipedia.org/wiki/Turtle_graphics).

> :book: `android:pathData` uses the exact same format as `d` attribute in SVG files.
Mozilla provides [great documentation](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d)
for it with neat samples.

Let’s see how it looks in action.

* Android Studio:

    ```text
    M20,4L4,4v2h16L20,4zM21,14v-2l-1,-5L4,7l-1,5v2h1v6h10v-6h4v6h2v-6h1zM12,18L6,18v-4h6v4z
    ```
* `svg2android`:

    ```text
    M20,4 L4,4 L4,6 L20,6 L20,4 Z M21,14 L21,12 L20,7 L4,7 L3,12 L3,14 L4,14 L4,20 L14,20 L14,14 L18,14 L18,20 L20,20 L20,14 L21,14 Z M12,18 L6,18 L6,14 L12,14 L12,18 Z
    ```
* `svg2vector`:

    ```text
    M20 4L4 4 4 6 20 6 20 4Zm1 10l0 -2 -1 -5 -16 0 -1 5 0 2 1 0 0 6 10 0 0 -6 4 0 0 6 2 0 0 -6 1 0zm-9 4l-6 0 0 -4 6 0 0 4z
    ```
* Android Studio + Avocado:

    ```text
    M20 4H4v2h16V4zm1 10v-2l-1-5H4l-1 5v2h1v6h10v-6h4v6h2v-6h1zm-9 4H6v-4h6v4z
    ```
* SVGO + Android Studio:

    ```text
    M20,4L4,4v2h16L20,4zM21,14v-2l-1,-5L4,7l-1,5v2h1v6h10v-6h4v6h2v-6h1zM12,18L6,18v-4h6v4z
    ```

    Not the best example since SVGO hadn’t optimized anything
    and looks identical to Android Studio. It doesn’t hold true with other icons.

[The SVG specification does not care about separators](https://www.w3.org/TR/SVG/paths.html#PathDataGeneralInformation),
so commas can be replaced with spaces and vice-versa.
In other words, `M20,4L4,4` from Android Studio is exactly the same as `M20 4L4 4` from `svg2vector`.

Taking separators out of the picture, further changes go to squashing
and replacing operations. For example, `L4,4 4,6` from `svg2android`
is the same as `L4,4 v2` from Android Studio — it draws a line to `4, 4` and another one to `4, 6`.
`L` draws a line to point and `v` draws a vertical line using the shift, which is `6 - 4 = 2` in our case.

Operations squashing helps with optimizing drawing performance. Fewer commands
mean more efficient execution. Actually, Android Lint
[has a `VectorPath` check](http://tools.android.com/tips/lint-checks)
for such cases.

> :book: The maximum instructions count for Lint is `800`.
> See [the source code](https://android.googlesource.com/platform/tools/base/+/studio-master-dev/lint/libs/lint-checks/src/main/java/com/android/tools/lint/checks/VectorPathDetector.java)
> for details.

Besides `pathData` differences, there are some minor deviations as well.

* `svg2android` tends to keep useless `<path>` — ones that draw nothing, i. e. transparent lines.
  Other tools remove them.
* `svg2vector` tends to keep `<group>` containers.
  Other tools merge it with inner `<path>` when possible.

## Performance

### Method

Most of the time `VectorDrawable` goes straight into `ImageView`.
Restarting application over and over to get necessary numbers
is kind of tedious, especially if there are going to be thousands of passes.
The benchmark code measures `VectorDrawable#draw` calls instead.

<details>
  <summary>_Click to expand benchmark code._</summary>

```kotlin
companion object {
    private const val ITERATIONS_COUNT = 30_000
}

private val random = Random()

private fun measureRenderMillis() {
    listOf(
            R.drawable.android_studio,
            R.drawable.svg2android,
            R.drawable.svg2vector,
            R.drawable.android_studio_and_avocado,
            R.drawable.svgo_and_android_studio
    ).forEach { res ->

        val name = resources.getResourceEntryName(res)

        val averageRenderMillis = (0..ITERATIONS_COUNT)
            .map { measureRenderMillis(res) }
            .average()

        println(":: [$name]: $averageRenderMillis ms")
    }
}

private fun measureRenderMillis(@DrawableRes drawableRes: Int): Long {
    val drawable = getDrawable(drawableRes).apply {
        if (this !is VectorDrawable) {
            throw IllegalArgumentException("Drawable supposed to be VectorDrawable.")
        }

        // Tint to prevent internal caching, i. e. draw from scratch all the time.
        setTint(random.nextInt())
    }

    val bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    drawable.setBounds(0, 0, canvas.width, canvas.height)

    return measureTimeMillis { drawable.draw(canvas) }
}
```

</details>

### Environment

* MacBook Pro: Intel Core i5 @ 2.7 GHz, 8 GB 1867 MHz DDR3.
* Emulator: Nexus 4, API 26.
* Iterations count: 30 000.

### Results

#### `octicon-octoface`

Tool                     | Average Duration, ms
-------------------------|---------------------
Android Studio           | 24.41
`svg2android`            | 19.98
`svg2vector`             | 24.10
Android Studio + Avocado | 24.20
SVGO + Android Studio    | 24.02

`svg2android` looks like the fastest one but it imported SVG incorrectly.
Resulting `VectorDrawable` produced an invisible image.

#### `octicon-repo`

Tool                     | Average Duration, ms
-------------------------|---------------------
Android Studio           | 18.35
`svg2android`            | 18.01
`svg2vector`             | 18.08
Android Studio + Avocado | 18.00
SVGO + Android Studio    | 17.90

#### `material-android`

Tool                     | Average Duration, ms
-------------------------|---------------------
Android Studio           | 0.095
`svg2android`            | 0.111
`svg2vector`             | 0.115
Android Studio + Avocado | 0.114
SVGO + Android Studio    | 0.114

#### `material-store`

Tool                     | Average Duration, ms
-------------------------|---------------------
Android Studio           | 0.076
`svg2android`            | 0.086
`svg2vector`             | 0.085
Android Studio + Avocado | 0.091
SVGO + Android Studio    | 0.095

# Conclusions

It is hard to declare a winner with XML. I like that Android Studio
removes useless instructions and attributes. It doesn’t matter
how `android:pathData` looks though since it is not getting modified by hand
on a regular basis.

About performance — there is no clear winner as well.
Android Studio shows good results with small icons and SVGO helps with
huge web images. It is understandable — SVG is a mature standard
with known optimization techniques. Knowing that `android:pathData` is
SVG `path.d` it is obvious that relying on a more mature optimizer makes more sense.

In other words, Android Studio is _good enough_, at least from my point of view.
Besides, it makes the SVG import easy-as — open it in IDE and that’s it.
If there is a need to optimize an image — SVGO is a good choice.

