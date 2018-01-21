---
title: "Kotlin: The Problem with `null`"
description: "A story about Kotlin. And null. And Java. And kind of about Swift."
date: 2018-01-10
slug: kotlin-the-problem-with-null
---

I think almost everybody in the CS world knows about the
[Null References: The Billion Dollar Mistake](https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare) talk.
However, it does not really matter if the concept of `null` references a good idea or a really bad one.
We live in the world where we just have to deal with `null` this way or another.
Yep, just deal with it. So let’s ask the “How” question instead of the “Why” one.

# Enter Kotlin

The drug of choice of mine at this point in time is Kotlin,
but you cannot forget about Java when using Kotlin.
Well, the JVM probably can be avoided by using Kotlin Native,
but at least on Android you are stuck with the JVM as an intermediate bytecode provider.

Kotlin was, and is a great language.
Backed by a team at JetBrains behind the best IDE platform available,
reasonable and pragmatic design decisions — what else to wish for?
And, more importantly, it brought the concept of Null Safety
to the production table for developers.

All Java objects are essentially implicitly can be `null`,
when Kotlin objects have to be declared nullable explicitly,
otherwise the type system assumes them be to be non-nullable by default.

Finally! We can use the JVM and forget about the `NullPointerException`!
[Well, not exactly](https://en.wikipedia.org/wiki/Forgot_About_Dre).

Let’s take a look at a very short Kotlin + RxJava sample.

```kotlin
Observable.just(null).subscribe()
```

This code will not be highlighted by the IDE, compiler will not show
any warnings or errors and yet it will crash _in runtime_.
Well, at least when using RxJava 2.1.8 and Kotlin 1.2.10.

Why? Fortunately enough, [RxJava is open source](https://github.com/ReactiveX/RxJava), so we can take a look ourselves.

```java
public static <T> Observable<T> just(T item) {
    ObjectHelper.requireNonNull(item, "The item is null");
    return RxJavaPlugins.onAssembly(new ObservableJust<T>(item));
}
```

In other words, the underlying code checks the `item` to not be `null`. And yet, Kotlin did not save us.
The reason is quite simple. When using RxJava we are using Java bytecode which does not have enough metadata.
To actually have it the Java code should be annotated with so-called Nullability Annotations.
The platform itself does not have enough introspection knowledge about if a value can be `null` or not.

OK, so now we’ve established that we need annotations in the Java code to make Kotlin happy.
In other words, the RxJava source code should be changed to be like this.

```java
public static <T> Observable<T> just(@NonNull T item) {
    ObjectHelper.requireNonNull(item, "The item is null");
    return RxJavaPlugins.onAssembly(new ObservableJust<T>(item));
}
```

The difference is in the `@NonNull` annotation. The IDE will highlight the original code as an error,
the Kotlin compiler will stop compilation... The End.

It is totally another story about mutiple _different_ Nullability Annotations artifacts
from JetBrains, FindBugs, The Checker Framework, Lombok, Android Support Library and others,
but [Jesse has it covered](https://medium.com/square-corner-blog/rolling-out-nullable-42dd823fbd89).

# The Problem

## Java

At least from my personal perspective, it is extremely naive to expect that every single Java library
available will follow the lead of Nullability Annotations usage in their code.
Asking people to adopt these is actually asking them to change their development culture,
habits and even entire system designs. And sometimes the benefit is too small for the effort.

Yes, it will help with the documentation and IDE inspections, not only with the Kotlin usage,
but if you have a billion of public methods in a huge framework without any particular knowledge
if a return value or an argument can be `null`...
The situation becomes even worse with non-library and non-open source projects with deadlines and priorities.

## Habits

I’ve spent something about 1.5 years writing Kotlin-only code every single workday.
Sometimes Python, sometimes Bash, but it does not change the picture.

The human mindset adapts very well. Typing Kotlin code and thinking with Kotlin concepts every day
_will_ make you forget about simple things, which
you tend to take for granted — like the one we are discussing here — Java does not have
nullability metadata out of the box. You will expect that everything you touch actually has it
(a classic [Midas mistake](https://en.wikipedia.org/wiki/Midas#Golden_Touch)),
because your shiny Kotlin codebase has it and you have a great confidence in that.

Prepare for unforeseen consequences.

# The Solution

## The Obvious

This is a hard one since it is based on a non-automated semantics mechanism — the mind.
It is always better to remember when you are using Java code and when you are using the Kotlin one.

Ask more _strange_ questions during a code review — _Are we guarded against this Java code?_
It may sound dumb and people are often too lazy to check but it is better to raise a question instead of doing nothing.

## Upstream Changes

Let’s face it — a lot of code we use as libraries is open source.
For example, the entire Android Framework is here — clone it, read it, modify it.
Yes, it is not so easy to talk people into using nullability annotations,
especially if your main argument is “I use Kotlin, so...”.

* The Kotlin argument does not work all the time and it should be the last one you have up your sleeve.
  Not so many people actually use Kotlin at this point, but there is a huge amount of Java code.
* Nullability annotations improve documentation and IDE support for everyone who uses the Java code,
  so it seems like a better argument.
* Pull Requests are always welcome!

## Abstract the Hell of It

The worst case scenario — you do not have access to the source code, maintainers are quiet for years.

Make your own abstraction using Kotlin! Almost everything is doable,
excluding codebases with a huge number of public methods — like RxJava.
As a side benefit — you will make your code more testable encapsulating implementation behind an interface.

Sample time!

```java
class CorporateCalculator {
    void calculate(Argument argument) {
        if (argument == null) throw new NullPointerException("Gotcha!");

        calculateUsingCorporateBlackMagic(argument);
    }
}
```
```kotlin
interface Calculator {
    fun calculate(argument: Argument)

    class CorporateImpl : Calculator {
        override fun calculate(argument: Argument) {
            CorporateCalculator().calculate(argument)
        }
    }
}
```

As you see, we hide the `CorporateCalculator` behind a Kotlin-based abstraction
which will save us from passing `null` to the `calculate` method.

# Making a Swift Turn

The good news is — we are not alone. Like, on the planet!

The Java and Kotlin situation is kind of similar to the Objective-C and Swift one.
Objective-C objects are represented by pointers, which can be `nil` in Objective-C terms.
In other words, these objects are implicitly nullable.
On other hand, Swift requires all values to have nullability defined explicitly.

Sounds exactly like our case, right?

Apple provides Nullability Annotations for Objective-C as well — `nullable` and `nonnull`.
You use them — Swift fetches them using the Objective-C and Swift bridging.
But what happens when you don’t use annotations in your Objective-C code? This is where things are getting interesting.

Swift declares such types as
[_implicitly unwrapped optionals_](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/TheBasics.html).
Practically speaking Swift kind of unwraps values for you,
but you are doing it at your own risk since it is basically an equivalent of doing unsafe unwrapping in Kotlin.
At the same time, it gives you a benefit of the non-warning-hostile environment.

In fact, Kotlin has a very similar concept named
[_platform types_](https://kotlinlang.org/docs/reference/java-interop.html#null-safety-and-platform-types),
which is applied to Java values on a bytecode level.
The difference with Swift is in the application --- there is no syntax in Kotlin to declare
a platform type value, so you cannot do that on your own. Swift allows that.
At the same time, you can see the Kotlin declaration in IDE hints and error messages
as a type with an exclamation mark (`String!`).
Actually the same syntax is used for implicitly unwrapped optionals.

## Side Road: Swift `Optional`

Turns out Swift does not have `null` pointers. At all!

```swift
let text: String? = nil
```

`text` there is not actually `null` (`nil`). Let’s change it a bit to show its true nature.

```swift
let text: Optional<String> = Optional.none

enum Optional<Wrapped> {
    case none
    case some(Wrapped)
}
```

Pretty cool, right? The Swift compiler makes all nullable values `Optional` under the hood.
In other words, `?` and `nil` are just syntax sugar literals for
[`enum Optional`](https://developer.apple.com/documentation/swift/optional),
which is extremely similar to a Kotlin `sealed class Optional`
from third-party --- you can reference
[Koptional](https://github.com/gojuno/koptional) as an example.
Swift is open source so you can take a look at
[the `Optional` implementation](https://github.com/apple/swift/blob/master/stdlib/public/core/Optional.swift)
yourself since I’ve simplified it drastacially at the code sample above.

Unfortunately, it is not really possible to change Kotlin behave the same way.
Apple uses a bridging mechanism to connect Objective-C and Swift binaries, when Kotlin
uses the same bytecode as Java. To make a simpler mental picture,
imagine Objective-C and Swift being connected side-by-side and
Kotlin and Java as a stack, where Kotlin is on top.
I presume it would be pretty challenging to provide a proper compatibility with Java,
transforming all nullable Kotlin values to `Optional` and vice-versa,
especially in such tight areas like Java reflection.

From my point of view the `Optional` usage is a fundamental difference
in `null` handling between Kotlin and Swift. Kotlin takes the compatibility
path, providing a compile-time validation, but you are using the exact same
`null` as you did in Java. At the same time, Swift essentially eliminates
`null` as a concept, replacing it with `Optional` and syntax sugar on top of it.

# In Retrospect

Chris Lattner, the author of LLVM, Clang and Swift,
has [a great quote about Kotlin](https://oleb.net/blog/2017/06/chris-lattner-wwdc-swift-panel/).
I’m gonna put it right here since I deeply agree with him on the subject.

> Swift and Kotlin evolved at about the same point in time with the same contemporary
languages around them. And so the surface-level syntax does look very similar.
But if you go one level down below the syntax, the semantics are quite different.
Kotlin is very reference semantics, it’s a thin layer on top of Java, and
so it perpetuates through a lot of the Javaisms in its model.

> If we had done an analog to that for Objective-C it would be like,
everything is an `NSObject` and it’s `objc_msgSend` everywhere,
just with parentheses instead of square brackets. And a lot of people
would have been happy with that for sure, but that wouldn’t
have gotten us the functional features, that wouldn’t have gotten us value semantics,
that wouldn’t have gotten us a lot of the safety things that are happening [in Swift].

> I think that Kotlin is a great language. I really mean that.
Kotlin is a great language, and they’re doing great things.
They’re just under a different set of constraints.

Kotlin hits a nice middle ground between compatibility with the whole Java world and, at the same time,
a set of features and abilities of a truly modern language. Unfortunately, it brings some
caveats related to its Java roots and it is too easy to simply forget about them.
Well, unless you shoot yourself in a foot really badly, so be carefull.

---

PS Bonus points to everyone who got [the Futurama reference](https://en.wikipedia.org/wiki/The_Problem_with_Popplers) :wink:

---

Thanks to [Artem Zinnatullin](https://twitter.com/artem_zin),
[Hannes Dorfmann](https://twitter.com/sockeqwe)
and [Alexander Bekert](https://twitter.com/abekert) for the review!
