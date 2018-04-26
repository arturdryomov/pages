---
title: "A Dagger to Remember"
description: "Replacing Dagger with Kotlin. Wait, what?"
date: 2018-04-22
slug: a-dagger-to-remember
---

# Story Time!

Kotlin and Java annotations have a complicated relationship. This goes from the syntax to the toolchain.

Does anybody remember that at the beginning of time Kotlin annotations were placed in square brackets?
[In 2015 the syntax was changed to the current form](https://blog.jetbrains.com/kotlin/2015/04/upcoming-change-syntax-for-annotations/).
Before that, it was `[Inject]` instead of `@Inject`. Yep.

The syntax is fine at this point, but `kapt`
([Kotlin annotation processing tool](https://kotlinlang.org/docs/reference/kapt.html))
from the Kotlin toolchain can be... cruel.

## `kapt`: denial

The project I’m working on started using Kotlin from the very beginning — in 2015.
At the beginning of 2017, there was the following situation.

* There was a _kind of_ incremental Kotlin compiler. It was enabled for everyone
  [only in 1.1.1](https://kotlinlang.org/docs/reference/using-gradle.html#incremental-compilation)
  and, believe me, it was done that late for a good reason.
* `kapt` eliminated almost every chance to make an incremental build so there was a full-rebuild
  on each change. It was so bad that these kind of builds were jokingly called as decremental.
* At the same time, `kapt` had a chance to corrupt a compilation process completely, requiring a `clean` and
  a full rebuild. If you saw something like `*_MemberInjector.java: error: package does not exist`
  you know what I’m talking about.

When you are working on a constantly growing codebase
and your builds take up to 5 minutes, even if you’ve changed only a single line...
It is a horrible experience and a plain bad development environment which leads to decreased productivity
and to [potential financial losses](https://blog.gradle.com/quantifying-the-cost-of-builds/).

How do you solve this? There is a nice method — throw more hardware at it!
That’s a short story about how [Mainframer](https://github.com/gojuno/mainframer) was born.

## `kapt`: anger

Using Mainframer was fine for a while. Yes, the issue was solved using quantity over quality,
but it was a good idea and it scaled well. If you don’t have enough expertise to change `kapt`,
you can at least change the environment it is being run in. Besides, the Kotlin toolchain became
better over time, so there was a pretty good chance to get an incremental build.

Unfortunately, `kapt` [struck again in Kotlin 1.2.21](https://youtrack.jetbrains.com/issue/KT-22763).
Increasing `kapt` processing time for unit tests by a magnitude of `3` was too much,
especially if you are running tests more often than the project executable itself.
I’ve asked myself a million dollar question.

> Do you even need `kapt`?

Turns out there was only a single annotation-processing dependency in the project.
I think you already know which one. Yep, it was [Dagger](https://google.github.io/dagger/).
Down the rabbit hole we go.

# Adventure Time!

## Do You Even Need ~~`kapt`~~ Dagger?

I’m going to talk about the [Google Dagger](https://github.com/google/dagger).
It was forked from the [Square Dagger](https://github.com/square/dagger).
The Square one did some lookups at runtime but generated code as well
using the annotation processing, just like the Google one. At the same time,
the Google version doesn’t use reflection and generates everything beforehand.
This is actually great. No reflection usage — better runtime performance
and compile-time `Context` validation.

> There might be a confusion among Android developers about the `Context` naming.
I’m going to use it as a more broad term than
[a framework class name](https://developer.android.com/reference/android/content/Context).
The `Context` is a dependencies container (or just a container of sorts).
You can observe this naming in different environments, such as
[Go](https://golang.org/pkg/context/) and
[Spring](https://spring.io/understanding/application-context).
You can associate it with Google Dagger `@Component` or
a Square Dagger `ObjectGraph`.

There is a downside though. The Square version had a small but extensive API.
In my opinion, it covered almost everything you need from a dependency injection.
The Google version has grown up big and sometimes not in a good way.
The API includes Android support module (let’s just forget about `DaggerActivity`
which... [exists](https://github.com/google/dagger/blob/e1ed045d59ef8fcbbd664939a476083ac8614b32/java/dagger/android/DaggerActivity.java)),
multibindings, reusable dependencies, components and subcomponents, modules and producer modules...

The project I’m working on didn’t use anything magical. Hell, most likely Dagger was used wrong!

* _Model_ components, such as services, have dependencies passed via constructor.
* _Presentation_ components, such as `ViewModel` have dependencies passed via constructor as a `Context`.
* `Context` is a result of combining a number of modules.
* Modules contain all dependency declarations, no components have `@Inject` annotations on them.

Basically, the DI glue is separated from the main codebase.

```kotlin
// Model

interface Repository {
    val content: Observable<RepositoryContent>

    class Impl : Repository {
        override val content = Observable.just(RepositoryContent())
    }
}

interface Service {
    val content: Observable<ServiceContent>

    class Impl(repository: Repository) : Service {
        override val content = repository.content.map { it.toServiceContent() }
    }
}

// Presentation

class ViewModel(context: Context) {

    @Inject lateinit var service: Service

    init {
        context.inject(this)
    }
}

// Dagger

@Module
class RepositoryModule {
    @Provides @Singleton
    fun provideRepository(): Repository = Repository.Impl()
}

@Module
class ServiceModule {
    @Provides @Singleton
    fun provideService(repository: Repository): Service = Service.Impl(repository)
}

interface Context {
    fun inject(vm: ViewModel)
}

@Singleton
@Component(modules = [RepositoryModule::class, ServiceModule::class])
interface ContextComponent : Context
```

I know, I know, that’s not how you do it, but it is just a use case I have on hand.

How do you test things using this structure? Well, it is pretty simple.

* For _model_ components, you can mock or stub your dependencies and pass them to constructor, no biggie.
* For _presentation_ components, it is possible to build your own `Context` and pass it instead.

## Decisions, Decisions

All of the above got me thinking.

> Do you need complex tools to solve simple problems?

As you can see, the setup is pretty simple.
Yes, _potentially_ Dagger could give some benefits,
but is it worth it increasing build time for every developer on the team
dozens of times per day? And taking into an account the fact
that this setup worked for years without any change at all?

> Do you need to keep using tools designed for different conditions?

Let’s face it — the annotation processing is a nice idea but meant
for special environments.
It is too verbose to declare everything by hand using Java, so here we go,
there is a code generator which does this for us.
Is it a good fit if you are using Kotlin for the entire codebase?
I have no idea, it is your codebase and your call. I did mine.

## Back to the Roots

> Having a library isn’t cool. You know what’s cool? Not having a library.

Let’s go crazy and use Kotlin to make our own
[inversion of control](https://en.wikipedia.org/wiki/Inversion_of_control) implementation.
Not [Koin](https://github.com/Ekito/koin),
not [Kodein](https://github.com/SalomonBrys/Kodein),
not [Kapsule](https://github.com/traversals/kapsule) —
just some patterns and language features.

> I highly suggest reading
[a Martin Fowler article](https://martinfowler.com/articles/injection.html)
about inversion of control (IoC) containers.
It contains almost everything you need to know about IoC, so I’m going to talk about practice only here.


### Modules

What is a module? It is a registry of dependencies.
What properties a module has? Dependencies on other modules.
Sounds simple enough.

```kotlin
interface RepositoryModule {
    val repository: Repository

    class Impl : RepositoryModule {
        override val repository by lazy { Repository.Impl() }
    }
}

interface ServiceModule {
    val service: Service

    class Impl(repositoryModule: RepositoryModule) {
        override val service by lazy { Service.Impl(repositoryModule.repository) }
    }
}
```

Notice the `lazy` delegate.
It makes our [properties lazy singletons](https://kotlinlang.org/docs/reference/delegated-properties.html#lazy),
just like Dagger would do it for you!
In other words, creating a module would not create all dependencies in it at once,
but will do it only on the first access.

### `Context`

Talking about `Context`... It is just a composition of modules, right?

```kotlin
interface Context :
    RepositoryModule,
    ServiceModule {

    class Impl(
        repositoryModule: RepositoryModule,
        serviceModule: ServiceModule
    ) : Context,
        RepositoryModule by repositoryModule,
        ServiceModule by serviceModule
}
```

We are using [Kotlin delegation](https://kotlinlang.org/docs/reference/delegation.html) here.
The `Context` will be translated to something like this to the end user.

```kotlin
interface Context {
    val repository: Repository
    val service: Service
}
```

You have to create it by hand though, creating all modules first.
Dagger would’ve done it for you, but it is no biggie.

```kotlin
fun createContext(): Context {
    val repositoryModule = RepositoryModule.Impl()
    val serviceModule = ServiceModule.Impl(repositoryModule)

    return Context.Impl(repositoryModule, serviceModule)
}
```

Yep, it is a bit verbose, but you are in a total control because it is your code.

### Tricks

You can define non-lazy dependencies which will be created at the same time as a module.

```kotlin
interface RepositoryModule {
    val repository: Repository

    class Impl : Module {
        override val repository = Repository.Impl()
    }
}
```

You can define non-singleton dependencies.

```kotlin
interface RepositoryModule {
    val repository: Repository

    class Impl : Module {
        override val repository: Repository
            get() = Repository.Impl()
    }
}
```

You can define scopes using the same delegation approach as with the `Context`.

```kotlin
interface UserContext :
    Context,
    UserModule {

    class Impl(
        context: Context,
        userModule: UserModule
    ) : UserContext,
        Context by context,
        UserModule by userModule
}

interface Context {
    fun plus(userModule: UserModule): UserContext

    class Impl : Context {
        override fun plus(userModule: UserModule) = UserContext.Impl(this, userModule)
    }
}
```

You can define multiple dependencies with the same interface.

```kotlin
interface ServiceModule {
    val yinService: Service
    val yangService: Service
}
```

You can move from `lateinit var` to `private val`.

```kotlin
class ViewModel(context: Context) {
    private val service = context.service
}
```

### Results

Seems like it is possible to do the inversion of control without Dagger, who knew?

#### Pros

* Inversion of control is based on your code and patterns instead of frameworks.
* Since it is your code you can do whatever you want with it and it is extremely simple to understand how it actually works.
* Compile-time validation with meaningful messages.
* No annotation processing, i. e. faster and more reliable builds.

#### Cons

* It is a gross [service locator](https://en.wikipedia.org/wiki/Service_locator_pattern).
   * Well, it is mostly true, but can I live with it? Certainly.
     Especially when taking into an account that the goal
     was to achieve the inversion of control and not a dependency injection.
* It is verbose.
   * It is, thanks! You have to actually think about how your `Context` is made and I actually like it.
* No Dagger — no cool points.
   * I’m typing this text on a Plan 9 machine, so...

Jokes aside though — it works in real life.

* `kapt` removal finally brought team confidence in the Kotlin compiler.
  I haven’t heard any complaints about either performance or weird compilation errors
  for a long time, which is a good sign.
  I’ve observed 25% reduction in build time and proper incremental builds.
* At the same time, I’ve noticed that people start to care for the IoC-related code
  like they do for the main codebase since it is no longer a pile of dependencies
  no one understands. It is a good thing as well.

# Exploration Time!

Since I’m trying to advocate a more broad-minded approach to the development process,
let’s take a look at other languages and how people try to achieve
the inversion of control in their code without using frameworks for that purpose.

## Scala

The research I’ve made for framework-less IoC brought me to frequent mentions
of the Cake and Thin Cake patterns originated from Scala.
I highly suggest reading [the explanation article](https://www.cakesolutions.net/teamblogs/2011/12/19/cake-pattern-in-depth)
since it covers everything you need to know about the Cake pattern.
There is also [a great presentation](https://www.youtube.com/watch?v=OJe0Dm3t5wQ)
on the topic comparing Cake, Thin Cake and a couple of other approaches, including Guice.

I don’t think it is possible to do the exact Thin Cake translation
to Kotlin, but here is an attempt to do so anyway.

```kotlin
interface RepositoryModule {
    fun repository() = Repository.Impl()
}

interface ServiceModule : RepositoryModule {
    fun service() = Service.Impl(repository())
}

interface Context : RepositoryModule, ServiceModule
```

The code is not identical to the original approach though since
we don’t have
[traits](https://docs.scala-lang.org/tour/traits.html) and
[self-types](https://docs.scala-lang.org/tour/self-types.html) in Kotlin.
I think the closest true match is actually using the delegation,
just like I’ve described above. So I guess the Kotlin approach
is a rough adaptation of the Thin Cake pattern!

## Swift

Passing `Context` to `ViewModel` in the described approach is actually messy.

```kotlin
class ViewModel(context: Context) {
    private val service = context.service
}
```

The `Context` is a dependency container and passing it basically means
a complete access to all dependencies, whether you like it or not.

Swift has a nice method to isolate the scope of the `Context`
via declaring child `Context` using
[protocol composition](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Protocols.html#//apple_ref/doc/uid/TP40014097-CH25-ID282).
This approach is described
[here](http://merowing.info/2017/04/using-protocol-compositon-for-dependency-injection/)
and
[there](https://5sw.de/2017/04/protocol-composition-and-dependency-injection/).

A rough Kotlin translation seems to be something like this.

```kotlin
class ViewModel(context: ViewModel.Context) {
    interface Context : ServiceModule
}

fun create() {
    ViewModel(createGlobalContext()) // Error: type mismatch.
}
```

Unfortunately for this to work all child `Context` variations should be declared
at the top-level `Context`.

```kotlin
interface Context : RepositoryModule, ServiceModule, ViewModel.Context

fun create() {
    ViewModel(createGlobalContext()) // It works!
}
```

A more sane approach actually can be just passing all dependencies
in `ViewModel` constructors directly, without a `Context` instance.
Plus, this requires declaring a module per dependency to be able
to construct `Context` from singular dependencies instead of their enumerations.
But, at the same time, it would be nice to have protocol composition
for such cases as an alternative.

# Fin

Developers tend to search for _a silver bullet_ all the time.
Do you parse JSON? You absolutely have to use the most performant
parser available on this planet, otherwise... Have you played
[Doom](https://en.wikipedia.org/wiki/Doom_(2016_video_game))? Well, it
goes exactly this way. Oh, you parse it only once and it is an object with two fields?
You need the most performant parser, remember!

Don’t let a tool to become [a MacGuffin](https://en.wikipedia.org/wiki/MacGuffin) —
pick it based on your needs and do not adapt your needs to a tool.
We develop things to solve issues, not to create them.

---

PS Bonus points to everyone who got [the Futurama reference](https://en.wikipedia.org/wiki/A_Flight_to_Remember) :wink:

---

Thanks to [Artem Zinnatullin](https://twitter.com/artem_zin) and
[Danny Preussler](https://twitter.com/PreusslerBerlin) for the review!
