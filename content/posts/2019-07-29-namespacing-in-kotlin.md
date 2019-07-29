---
title: "Namespacing in Kotlin"
description: "Well, the lack of."
date: 2019-07-29
slug: namespacing-in-kotlin
---

The development process is a research. Find the state machine,
organize mutations, wire it for consumers. The process
repeats and leads to the meta-research. We investigate scenarios and
search for reusable parts. Patterns arise, implementations follow.
Ideally, the code resembles a fractal structure.

> An architecture is said to be fractal if subcomponents are structured
> in the same way as the whole is.
>
> — [*André Staltz*](https://staltz.com/unidirectional-user-interface-architectures.html)

# The Problem

Let’s say we have a fractal components structure. Each one has a `View` and a `ViewModel`.

There is a `Movie` component which delegates to sub-components
of the same structure — `MovieCast` and `MovieRating`. The movie view
contains the cast view and the rating view, the same applies to the view model.

```kotlin
interface MovieView {
    val cast: MovieCastView
    val rating: MovieRatingView
}

interface MovieViewModel {
    val cast: MovieCastViewModel
    val rating: MovieRatingViewModel
}
```

This is a fine structure but IRL classes are separate.

```kotlin
interface MovieView
interface MovieViewModel

interface MovieCastView
interface MovieCastViewModel

interface MovieRatingView
interface MovieRatingViewModel
```

The reliance on the naming is apparent. It is repeating, verbose and does not show
that components follow the same structure. What if...

```kotlin
namespace Movie {
    interface View
    interface ViewModel
}

namespace MovieCast {
    interface View
    interface ViewModel
}

namespace MovieRating {
    interface View
    interface ViewModel
}
```

Much better. It is clear that components are using the same pattern.
It scales!

```kotlin
interface MovieView
interface MovieViewModel
class MovieActivity
```

vs.

```kotlin

namespace Movie {
    interface View
    interface ViewModel
    class Activity
}
```

The `namespace` keyword is obviously made up, Kotlin does not have it.
How do we achieve the same effect?

# The Solution

## `package`

[This is Java](https://www.youtube.com/watch?v=VYOjWnS4cMY).

```kotlin
package component

interface View
interface ViewModel
```

It works but it is awkward to use:

```kotlin
package movie.cast

interface View
```
```kotlin
package movie

interface View {
    val cast: movie.cast.View
}
```

We are forced to use [the FQN](https://en.wikipedia.org/wiki/Fully_qualified_name)
since the compiler is not able to distinguish between `View` classes.
Not good.

## `enum`

I’m not actually joking.

```kotlin
enum class Component {
    ;

    interface View
    interface ViewModel
}
```

:heavy_plus_sign: It is impossible to create the `Component` instance.

:heavy_minus_sign: It is awkward to have a semicolon at the beginning of each component.

:heavy_minus_sign: Semantics are messed up.
In Java and Kotlin `enum` represent variations of the enumeration
(unlike Swift where `enum` cases might have completely different structure).
While nested classes are not `enum` cases it feels wrong.

## `object`

```kotlin
object Component {
    interface View
    interface ViewModel
}
```

It works! The Java representation is not fun though.

```java
public final class Component {

    public static final Component INSTANCE;

    private Component() {
    }

    static {
        Component var0 = new Component();
        INSTANCE = var0;
    }
```

Yikes! We create a completely useless singleton for no reason.
Moving on.

## `class`

```kotlin
class Component {
    interface View
    interface ViewModel
}
```

What a `class`y way to do things. Looks fine in the Java representation.

```java
public final class Component {
```

Let’s take a deeper look using the disassembler.

```
$ javap -C Component.java && javap -c -verbose Component.class
```
```
  Size 194 bytes
  MD5 checksum 3a2a9141881597581908528a19f7d993
  Compiled from "Component.java"
public final class Component
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_FINAL, ACC_SUPER
Constant pool:
   #1 = Methodref          #3.#10         // java/lang/Object."<init>":()V
   #2 = Class              #11            // Component
   #3 = Class              #12            // java/lang/Object
   #4 = Utf8               <init>
   #5 = Utf8               ()V
   #6 = Utf8               Code
   #7 = Utf8               LineNumberTable
   #8 = Utf8               SourceFile
   #9 = Utf8               Component.java
  #10 = NameAndType        #4:#5          // "<init>":()V
  #11 = Utf8               Component
  #12 = Utf8               java/lang/Object
{
  public Component();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0
}
```

:heavy_plus_sign: Looks innocent compared to the `object`.

:heavy_plus_sign: Impossible to inherit from since Kotlin classes are `final` by default.

:heavy_minus_sign: Possible to create an object.

## `interface`

```kotlin
interface Component {
    interface View
    interface ViewModel
}
```

Almost the same as the `class` approach. The Java representation does not bring surprises.

```java
interface Component {
```

The disassembler shows that it is much lighter than the `class`.

```
$ javap -C Component.java && javap -c -verbose Component.class
```
```
  Size 101 bytes
  MD5 checksum 574e4f61d4b3e17ccd964289678c7ae2
  Compiled from "Component.java"
interface Component
  minor version: 0
  major version: 52
  flags: ACC_INTERFACE, ACC_ABSTRACT
Constant pool:
  #1 = Class              #5              // Component
  #2 = Class              #6              // java/lang/Object
  #3 = Utf8               SourceFile
  #4 = Utf8               Component.java
  #5 = Utf8               Component
  #6 = Utf8               java/lang/Object
{
}
```

:heavy_plus_sign: Impossible to create an object.

:heavy_plus_sign: Lighter than the `class` — 6 constants in the pool vs. 12, 101 bytes on disk vs. 194.

:heavy_minus_sign: Possible to inherit from.

## `namespace`?

```csharp
namespace Component {
    interface IView
    interface IViewModel
}
```

The `I` prefix means that we are in [the C# world](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/namespaces/).
It might be surprising but there are not a lot of languages supporting namespaces.
I can name C++, C#, PHP, TypeScript and that’s basically it. In fact,
languages with the `namespace` keyword do not have a concept of packages.
Seems like namespaces can cover everything packages provide
but I wonder — why not have both?

# The Decision

There is no good way to put it — all approaches are not great.
The reason is simple — Kotlin drags a ton of JVM baggage and
maintains Java compatibility. Approaches described above are
basically the direct translation from the Java world (except the `object` variant).

However, namespacing can be achieved using nested `interface` declarations.
It is the most efficient approach so far. It would be great to have
the `namespace` keyword though. I imagine it being like an `interface`
which cannot be inherited. Let’s [KEEP](https://github.com/Kotlin/KEEP)
this in mind. For now — `interface` it up!
