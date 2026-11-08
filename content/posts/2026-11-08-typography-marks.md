---
title: "Quotes and Dashes for Typography Novices"
description: "Making text look sharp"
date: "2026-11-08"
slug: "typography-marks"
---

Books are knowledge. Books are fun.
Books are also [on the decline](https://www.sciencedirect.com/science/article/pii/S2589004225015494).
Over time, people opening a book might ask where the emojis are
and why things look different overall.
What about thinking ahead and bringing some of that book look into digital text?

# Guides

> [!WARNING]
> I’m familiar with English, Polish and Russian, so these are the locales covered here.

There are no rules, but there are guides — depending on the locale.
To find which marks a language uses, look at
a book typeset without a computer — one published before 1980 will do.
There are other good reference points though.

Want a free, modern English guide? [Practical Typography](https://practicaltypography.com)
is the one. Writing for the UK? See [The Oxford Style Guide](https://en.wikipedia.org/wiki/Hart's_Rules).
The original was published in 1893 (!) and there are about 40 (!) editions.
US? Popular style guides come from publishers:
[The Chicago Manual of Style](https://en.wikipedia.org/wiki/The_Chicago_Manual_of_Style),
[The New York Times Manual of Style and Usage](https://en.wikipedia.org/wiki/The_New_York_Times_Manual_of_Style_and_Usage) and
[The Associated Press Stylebook](https://en.wikipedia.org/wiki/AP_Stylebook).

Polish has two main references.
[Zasady składania tekstów w języku polskim (PN-83 / P-55366)](https://kalibracje.pl/pliki/normapl.pdf) —
*Polska Norma* from 1983. [Zasady pisowni i interpunkcji](https://sjp.pwn.pl/zasady) is the modern one.
There are books as well, but these are a good start.

Russian is simple: one book. A huge one, but it covers everything —
[Справочник издателя и автора](https://store.artlebedev.ru/books/typography/spravochnik-izdatelya-i-avtora-2024/).

# Tools

On macOS nothing needs to be done. The symbols discussed in this article are built into Input Sources.
To see the mappings,
open System Settings → Keyboard → Text Input → Input Sources, select one and press {{<kbd Option>}}, {{<kbd Shift>}} or both.

On Linux, one option is [Compose](https://en.wikipedia.org/wiki/Compose_key).
A lesser-known option is enabling typographic symbols. On KDE Plasma 6.7
open System Settings → Keyboard → Key Bindings.
Under Compatibility Options check *Enable extra typographic symbols*
and choose a key for the *Key to choose the 3rd level*. The result is macOS-like:
{{<kbd Alt>}} {{<kbd 0>}} types `→` and {{<kbd Alt>}} {{<kbd `.`>}} types `»`.
The keyboard preview even shows the new symbols.
Believe it or not, I [contributed](https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config/-/commit/5ab465db9400c350c279f30b48dc462927ef9dab)
to these symbols in 2014!

On Windows, typing symbols is awkward.
One needs to hold {{<kbd Alt>}} while typing a four-digit code on the numpad (!)
so it looks like {{<kbd Alt>}} {{<kbd 0>}} {{<kbd 1>}} {{<kbd 5>}} {{<kbd 1>}}.
This is bananas. However, Windows 11
[added alternatives](https://windowsforum.com/news/windows-11-adds-win-key-shortcuts-for-en-and-em-dashes.388252/)
like {{<kbd Win>}} {{<kbd Shift>}} {{<kbd ->}}.
There are also [alternative layouts](https://ilyabirman.net/typography-layout/).

> [!WARNING]
> This article does not cover automation tools (like
> [SmartyPants](https://daringfireball.net/projects/smartypants/) and
> [the Goldmark typographer](https://github.com/yuin/goldmark/blob/v2/extension/typographer.go)).

# Quotes

Put together, the guides give this cheat sheet of quote marks.
Note that the guides don’t use straight marks (`'` and `"`) so none of them are in the table.

Name                                                                                                          | Mark | macOS                                          | Linux                                     | Windows
--------------------------------------------------------------------------------------------------------------|------|------------------------------------------------|-------------------------------------------|--------------------------------------------------------------
[Left Single](https://free-symbols.com/symbols/punctuation/left-single-quotation-mark)                        | `‘`  | {{<kbd Option>}} {{<kbd `]`>}}                 | {{<kbd Alt>}} {{<kbd Shift>}} {{<kbd K>}} | {{<kbd Alt>}} {{<kbd 0>}} {{<kbd 1>}} {{<kbd 4>}} {{<kbd 5>}}
[Right Single](https://free-symbols.com/symbols/punctuation/right-single-quotation-mark)                      | `’`  | {{<kbd Option>}} {{<kbd Shift>}} {{<kbd `]`>}} | {{<kbd Alt>}} {{<kbd Shift>}} {{<kbd L>}} | {{<kbd Alt>}} {{<kbd 0>}} {{<kbd 1>}} {{<kbd 4>}} {{<kbd 6>}}
[Low Single](https://free-symbols.com/symbols/punctuation/single-low-9-quotation-mark)                        | `‚`  | {{<kbd Option>}} {{<kbd Shift>}} {{<kbd 0>}}   | {{<kbd Alt>}} {{<kbd Shift>}} {{<kbd J>}} | {{<kbd Alt>}} {{<kbd 0>}} {{<kbd 1>}} {{<kbd 3>}} {{<kbd 0>}}
[Left Double](https://free-symbols.com/symbols/punctuation/left-double-quotation-mark)                        | `“`  | {{<kbd Option>}} {{<kbd `[`>}}                 | {{<kbd Alt>}} {{<kbd K>}}                 | {{<kbd Alt>}} {{<kbd 0>}} {{<kbd 1>}} {{<kbd 4>}} {{<kbd 7>}}
[Right Double](https://free-symbols.com/symbols/punctuation/right-double-quotation-mark)                      | `”`  | {{<kbd Option>}} {{<kbd Shift>}} {{<kbd `[`>}} | {{<kbd Alt>}} {{<kbd L>}}                 | {{<kbd Alt>}} {{<kbd 0>}} {{<kbd 1>}} {{<kbd 4>}} {{<kbd 8>}}
[Low Double](https://free-symbols.com/symbols/punctuation/double-low-9-quotation-mark)                        | `„`  | {{<kbd Option>}} {{<kbd Shift>}} {{<kbd W>}}   | {{<kbd Alt>}} {{<kbd J>}}                 | {{<kbd Alt>}} {{<kbd 0>}} {{<kbd 1>}} {{<kbd 3>}} {{<kbd 2>}}
[Left Double Angle](https://free-symbols.com/symbols/punctuation/left-pointing-double-angle-quotation-mark)   | `«`  | {{<kbd Option>}} {{<kbd `\`>}}                 | {{<kbd Alt>}} {{<kbd ",">}}               | {{<kbd Alt>}} {{<kbd 0>}} {{<kbd 1>}} {{<kbd 7>}} {{<kbd 1>}}
[Right Double Angle](https://free-symbols.com/symbols/punctuation/right-pointing-double-angle-quotation-mark) | `»`  | {{<kbd Option>}} {{<kbd Shift>}} {{<kbd `\`>}} | {{<kbd Alt>}} {{<kbd ".">}}               | {{<kbd Alt>}} {{<kbd 0>}} {{<kbd 1>}} {{<kbd 8>}} {{<kbd 7>}}

That’s intimidating. Fortunately, each locale uses two pairs:
outer marks for regular quotes and inner marks for quotes within quotes.
This is a special case, most of the time outer marks are used.

Locale       | Outer Marks                                   | Inner Marks                                   | Example
-------------|-----------------------------------------------|-----------------------------------------------|----------------------
English (UK) | Left Single {{<br>}} Right Single             | Left Double {{<br>}} Right Double             | ‘Lorem “ipsum” dolor’
English (US) | Left Double {{<br>}} Right Double             | Left Single {{<br>}} Right Single             | “Lorem ‘ipsum’ dolor”
Polish       | Low Double {{<br>}} Right Double              | Left Double Angle {{<br>}} Right Double Angle | „Lorem «ipsum» dolor”
Russian      | Left Double Angle {{<br>}} Right Double Angle | Low Double {{<br>}} Left Double               | «Lorem „ipsum“ dolor»

# Dashes

Dashes are simpler. Note that the hyphen (`-`, left of `=` on most keyboards) joins words (like *well-known*)
and doesn’t separate parts of a sentence. Yes, it’s easier to type, but typographically it’s incorrect.

Name                                                            | Mark | macOS                                        | Linux                                     | Windows
----------------------------------------------------------------|------|----------------------------------------------|-------------------------------------------|--------------------------------------------
[Em Dash](https://free-symbols.com/symbols/punctuation/em-dash) | `—`  | {{<kbd Option>}} {{<kbd Shift>}} {{<kbd ->}} | {{<kbd Alt>}} {{<kbd ->}}                 | {{<kbd Win>}} {{<kbd Shift>}} {{<kbd `-`>}}
[En Dash](https://free-symbols.com/symbols/punctuation/en-dash) | `–`  | {{<kbd Option>}} {{<kbd ->}}                 | {{<kbd Alt>}} {{<kbd Shift>}} {{<kbd ->}} | {{<kbd Win>}} {{<kbd `-`>}}

As with quotes, the locale defines the usage pattern.

Locale       | Mark    | Example
-------------|---------|--------------------
English (UK) | En Dash | Lorem ipsum – dolor
English (US) | Em Dash | Lorem ipsum — dolor
Polish       | En Dash | Lorem ipsum – dolor
Russian      | Em Dash | Lorem ipsum — dolor

> [!WARNING]
> There is [a difference](https://prowritingaid.com/grammar/1000066/Should-I-use-spaces-around-an-em-dash)
> in English (US) approaches to spaces around dashes. This article uses the variant from The Associated Press Stylebook (with spaces).

# That’s It!

Pick a guide, be consistent, and the text will look like it came out of a book.
It takes some getting used to but on macOS and Linux it’s fairly intuitive — apologies, Windows folks.
And even if it’s too much, at least now it should be clear why books look the way they do.
