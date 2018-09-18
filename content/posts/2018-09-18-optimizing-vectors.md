---
title: "Optimizing Android Vector Images. Or Not?"
description: "Measuring VectorDrawable drawing times with various tools applied."
date: 2018-09-18
slug: optimizing-android-vector-images
---

An average working day of an Android developer involves doing something with UI.
Pushing widgets around, changing text and images...

The colleges of mine convert SVG images to `VectorDrawable` via
a specific converter and I use Android Studio.
Which tool does the job better? Let’s find out!

# Tools

Converters (do optimizations under the hood):

* Android Studio (3.1.4) — IDE.
* [`svg2android`](http://inloop.github.io/svg2android/) — website,
  [deprecated](https://github.com/inloop/svg2android/commit/4c2312ad376e6c81f0673121b7978768cd94c595)
  in favor of Android Studio.
* [`svg2vector`](http://a-student.github.io/SvgToVectorDrawableConverter.Web/) — website.

Optimizers:

* [Avocado](https://github.com/alexjlockwood/avocado/) (1.0.0) — command line tool, optimizes `VectorDrawable` XML files.
* [SVGO](https://github.com/svg/svgo) (1.0.5) — command line tool, optimizes SVG files.

> :bulb: Zeplin exports SVG assets
> [using SVGO under the hood](https://support.zeplin.io/zeplin-101/developing-web-projects-using-zeplin).

# Images

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

It is not surprising, but files produced by different tools are different.
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
is the same as `L4,4 v2` from Android Studio.

* `L` draws a line to the point `(x = 4, y = 4)` and another one to `(x = 4, y = 6)`.
* `v` draws a vertical line using the shift, which is `6 - 4 = 2` in our case.

Operations squashing helps with optimizing drawing performance since the renderer can make
more efficient decisions based on the instruction. At the same time, fewer commands
mean more efficient execution. Actually, Android Lint
[has a `VectorPath` check](http://tools.android.com/tips/lint-checks)
for such cases.

> :book: The maximum instructions count for Lint is `800`.
> See [the source code](https://android.googlesource.com/platform/tools/base/+/studio-master-dev/lint/libs/lint-checks/src/main/java/com/android/tools/lint/checks/VectorPathDetector.java)
> for details.

Do not forget that `#apksizematters`! Less instructions → less text → less file size.

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
  <summary>_Click to expand the benchmark code._</summary>

```kotlin
companion object {
    private const val ITERATIONS_COUNT = 10_000
}

private val random = Random()

private fun measure() {
    listOf(
            R.drawable.android_studio,
            R.drawable.svg2android,
            R.drawable.svg2vector,
            R.drawable.android_studio_and_avocado,
            R.drawable.svgo_and_android_studio
    ).forEach { drawableRes ->

        val drawableName = resources.getResourceEntryName(drawableRes)

        val measurements = (0 until ITERATIONS_COUNT)
            .map { measure(drawableRes) }

        val averageParseMillis = measurements
            .map { it.parseTimeMillis }
            .average()
        val averageRenderMillis = measurements
            .map { it.renderTimeMillis }
            .average()

        println(":: [$drawableName]. Parse: $averageParseMillis ms. Render: $averageRenderMillis ms.")
    }
}

private data class Measurement(val parseTimeMillis: Long, val renderTimeMillis: Long)

private fun measure(@DrawableRes drawableRes: Int): Measurement {
    lateinit var drawable: Drawable

    val parseTime = measureTimeMillis {
        // Unfortunately it seems to be impossible to disable internal caching.
        drawable = getDrawable(drawableRes)
    }

    if (drawable !is VectorDrawable) {
        throw IllegalArgumentException("Drawable is supposed to be VectorDrawable.")
    }

    // Change tint to prevent internal render internal caching.
    drawable.setTint(random.nextInt())

    val bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    drawable.setBounds(0, 0, canvas.width, canvas.height)

    val renderTime = measureTimeMillis {
        drawable.draw(canvas)
    }

    return Measurement(parseTime, renderTime)
}
```
</details>

### Environment

* MacBook Pro: Intel Core i5 @ 2.7 GHz, 8 GB 1867 MHz DDR3.
* Emulator: 27.3.10.
* Emulator system image: Nexus 4, Android 8.0.
* Iterations count: 10 000.

> :book: Seems like in Android 7.0 `VectorDrawable`
> [was re-implemented to use native rendering](https://android.googlesource.com/platform/frameworks/base/+/804618d0863a5d8ad1b08a846bd5319be864a1cb).
> Relative numbers remain the same, but be advised that absolute performance
> might differ between API versions.

### Results

#### `octicon-octoface`

Tool                     | Average Render Duration, ms | Average Parse Duration, ms
-------------------------|-----------------------------|----------------------------
Android Studio           | 24.5128                     | 0.0594
`svg2android`            | 20.1871                     | 0.0570
`svg2vector`             | 24.5424                     | 0.0581
Android Studio + Avocado | 24.5393                     | 0.0596
SVGO + Android Studio    | 24.5721                     | 0.0619

`svg2android` looks like the fastest one but it imported SVG incorrectly.
Resulting `VectorDrawable` produced an invisible image.

#### `octicon-repo`

Tool                     | Average Render Duration, ms | Average Parse Duration, ms
-------------------------|-----------------------------|----------------------------
Android Studio           | 18.1411                     | 0.0575
`svg2android`            | 18.1608                     | 0.0604
`svg2vector`             | 18.3110                     | 0.0562
Android Studio + Avocado | 18.1604                     | 0.0554
SVGO + Android Studio    | 18.1699                     | 0.0588

#### `material-android`

Tool                     | Average Render Duration, ms | Average Parse Duration, ms
-------------------------|-----------------------------|----------------------------
Android Studio           | 0.0848                      | 0.0241
`svg2android`            | 0.1197                      | 0.0395
`svg2vector`             | 0.1275                      | 0.0420
Android Studio + Avocado | 0.1189                      | 0.0348
SVGO + Android Studio    | 0.1287                      | 0.0399

#### `material-store`

Tool                     | Average Render Duration, ms | Average Parse Duration, ms
-------------------------|-----------------------------|----------------------------
Android Studio           | 0.0936                      | 0.0408
`svg2android`            | 0.0892                      | 0.0390
`svg2vector`             | 0.0915                      | 0.0366
Android Studio + Avocado | 0.0898                      | 0.0405
SVGO + Android Studio    | 0.0944                      | 0.0405

# Conclusion

It is hard to declare a winner with XML. I like that Android Studio
removes useless instructions and attributes. It doesn’t matter
how `android:pathData` looks though since it is not getting modified by hand
on a regular basis. At the same time, it helps if it is more compact, which
Studio does relatively better than others.

About performance — there is no clear winner as well.
Android Studio shows good results with small icons and SVGO helps with
huge web images. It is understandable — SVG is a mature standard
with known optimization techniques. Knowing that `android:pathData` is
SVG `path.d` it is obvious that relying on a more mature optimizer makes more sense.

In other words, Android Studio is _good enough_, at least from my point of view.
Besides, it makes the SVG import easy-as — open it in IDE and that’s it.
If there is a need to optimize an image — SVGO is a good choice.

---

Thanks to [Artem Zinnatullin](https://twitter.com/artem_zin) and
[Alex Lockwood](https://twitter.com/alexjlockwood) for the review!
