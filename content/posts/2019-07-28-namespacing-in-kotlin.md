---
title: "Namespacing in Kotlin"
description: "Well, the lack of it."
date: 2019-07-28
slug: namespacing-in-kotlin
---

The development process is a research. Find the state machine,
organize mutations, wire it for consumers — here we go. However, the process
repeats and leads to the meta-research. We investigate scenarios and
search for reusable parts. Patterns arise, implementations follow.
This creates an interesting problem — the pattern might be the same,
implementations might look the same but cover different areas.
Ideally the code resembles a fractal structure.

> An architecture is said to be fractal if subcomponents are structured
> in the same way as the whole is.
>
> — [*André Staltz*](https://staltz.com/unidirectional-user-interface-architectures.html)

How do we organize the components graph in this scenario?

# Sample

```kotlin
interface MovieView
interface MovieViewModel

interface MovieCastView
interface MovieCastViewModel

interface MovieRatingView
interface MovieRatingViewModel
```

# Kotlin

## `object`

```kotlin
object Component {
    interface View
    interface ViewModel
}
```

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

## `class`

```kotlin
class Component {
    interface View
    interface ViewModel
}
```

```java
public final class Component {
```

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

## `interface`

```kotlin
interface Component {
    interface View
    interface ViewModel
}
```

```java
interface Component {
```

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

## `object` vs. `class` vs. `interface`

* `object` — the worst of the worst since it creates a useless singleton.
* `interface` — possible to inherit from, impossible to create an object.
* `class` — impossible to inherit from (`final` in Kotlin without the `open` modifier)`,
  possible to create an object.
* `interface` is smaller than `class` in memory — 6 constants in pool vs. 12,
  0 instructions vs. 3.
* `interface` is smaller than `class` on disk — 101 bytes vs. 194.
