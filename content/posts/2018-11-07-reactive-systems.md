---
title: "Reactive Systems"
description: "The beauty of Functional Reactive Programming in action."
date: 2018-11-05
slug: reactive-systems
---

Human beings are reactive by nature — fortunately or not.
The reason is mostly physiology. The dopamine hormone helps us
to feel comfortable and secure while we do things we are familiar with.
Eating a sandwich sounds and feels far better than gardening, doesn’t it?
Doing unpleasant, hard decisions is a complex task.
Essentially it is a fight between psychology (the mind) and physiology (the body).
But that makes us human.

In CS object-oriented programming (OOP) is a king of the hill and
functional programming (FP) is for nerds, right? Well, it is this way because
the OOP is more comfortable for everyone. We, as society, made it this way.
The educational system includes a mandatory OOP course and rarely there
is an FP one. And then there is reactive programming which forms a wild beast
called functional-reactive programming (FRP)...

Taking everything above in account makes it easy... to give up.
Of course, we’ll make the next project FRP-based, resolving all multithreading,
mutability and flow issues. But, for now, it is fine. The current one works just fine, right?
Well, let me show how it can be done in real life and how beautiful the result might be.

# Concepts

Don’t worry, I am not going to explain FP and FRP all over again. We’ll need only two terms.

* Producer.
* Consumer.

The success of our enterprise (not be confused with the USS one)
depends on providing enough abstractions to connect producers and consumers.
Easy.

