---
title: "Filling Android Autofill Gaps"
description: "Google Smart Lock, Android Autofill, OpenYOLO, Google Credentials, passwords.txt — what else?"
date: 2019-02-13
slug: filling-android-autofill-gaps
---

We can have different opinions but should be able to agree on one thing — we are humans.
Well, except ones who like [Gerrit](https://www.gerritcodereview.com/)
and use [Dashboard on macOS](https://en.wikipedia.org/wiki/Dashboard_(macOS)).
Those are clearly aliens (Mulder was right).
All humans tend to forget things. Important and useless, smart and dumb, beautiful and ugly —
it does not matter, any thought or information can disappear.
Precious credentials for applications we work on are no exception.

Fortunately enough there are things serving as a backup storage for the brain.
Like a password manager. Everybody should use one. We don’t use a single key
for all doors and leave it in the open, right? The digital world should be no different.

Enter Android. I’ve been following the password managing scene here for a while.
Honestly saying, it looks... Let’s say complicated. Google Smart Lock, Android Autofill,
Google Credentials, OpenYOLO. Which one should be used and when?
Let’s explore.

# Options

## `SharedPreferences`

Technically it is possible to store credentials as a plain text in `SharedPreferences`.
Even better — it can be synced across devices!
[`SharedPreferencesBackupHelper`](https://developer.android.com/reference/android/app/backup/SharedPreferencesBackupHelper)
was around since Android 2.2 and [is well documented](https://developer.android.com/guide/topics/data/keyvaluebackup).
Android 6.0 introduced [automatic backups](https://developer.android.com/guide/topics/data/autobackup)
with minimal developer interaction.

Sounds good, but this is what we call in our business _a bad idea_.
`SharedPreferences` are not encrypted and can be read as-is with `root`
privilegies. This is what I would call an analogue to sticky notes with passwords
stiched to a monitor.

## [Google Smart Lock](https://developers.google.com/identity/smartlock-passwords/android/)

This is the OG of the Google effort to streamline credentials storage.
It is obviously not new since it has the word _Smart_ in the name.
Remember times when everything was named smart? Yeah, me neither kids.

It is bundled into Google Play Services and seems to be available on all recent platforms.
There is a nice dialog suggesting to store credentials in Google storage and
another one to pick credentials from an enumeration if there are multiple.
Even better — there is an option for an instant sign in if there is a single
credentials value. In this case Google will show a banner informing a user about what happened.

The interaction is good from both sides. Users see a familiar Google branding
across applications, developers don’t need to implement interactions
over and over again.

The sweet part is the multi-platform availability.
Since credentials are stored by Google it becomes possible
to use same credentials in Chrome. This is useful for services that have both
mobile and web presense.

The meh part is vendor lock-in. All passwords are stored at Google servers
and [can be viewed as a plain text online](https://passwords.google.com/).
There are no sources stating how the data is stored and how secure the method is.
Not a lot of people hacked Google but technically there are no limitations.

## [OpenYOLO](https://github.com/openid/OpenYOLO-Android)

I’m not making this up, it is a real name. It stands for You Only Login Once.

It might seem like an SDK, but actually it is [a full-blown OpenID spec](https://openid.net/specs/openyolo-android-ID1.html).
The motivation behind it is solid — unify password managers under the same API and SPI,
making them interchangeable. Think about it as Smart Lock via any password manager.
Instead of Google the SDK will call a user-preferred application.

It went so well that password managers actually implemented it, including 1Password,
[Dashlane](https://blog.dashlane.com/openyolo-password-managers-in-android-apps/),
[LastPass](https://blog.lastpass.com/2017/11/introducing-lastpass-support-openyolo.html/) and...
Google Smart Lock! Seems like there are no reasons to use Smart Lock directly, right?
There is a good abstraction on top of it to use user-installed applications instead.

Unfortunately the project is half-dead. There are no updates for over a year,
[the tech lead no longer works at Google](https://www.linkedin.com/in/iainmcgin/)
and something happened that ruined the adaptation completely. This thing is called...

## [Android Autofill](https://developer.android.com/guide/topics/text/autofill)

The same year OpenYOLO was released and password managers boarded the ship,
Google decided to open a cannon fire and sink it. Autofill, introduced in Android Oreo,
solves basically same issues as OpenYOLO. Users can change autofill providers —
including 1Password, Dashlane, LastPass and friends. The OS will ask the current provider
for credentials or will suggest to store them using the same provider.

Sounds like a good thing, but why do we need this when OpenYOLO was alive and well?
Why not to use the spec under the hood of the autofill?
I have no idea what happened here. For an observer like me it looks like a classic
_huge company too many teams_ problem. Let’s look at the timeline.

* August 4, 2016. [OpenYOLO initiative is announced](https://blog.dashlane.com/dashlane-google-open-source-api/).
* March 21, 2017. [Android O is announced](https://android-developers.googleblog.com/2017/03/first-preview-of-android-o.html).
* May 3, 2017. [OpenYOLO OpenID draft is published](https://openid.net/2017/05/03/public-review-period-for-openyolo-for-android-specification-started/).
* August 21, 2017. [Android O is released](https://en.wikipedia.org/wiki/Android_Oreo).
* November 4, 2017. [OpenYOLO SDK contributions stopped](https://github.com/openid/OpenYOLO-Android/commit/ff0de4b8651354673a5e2dc97c1b78cf7c353651).

Illuminati... confirmed?

Autofill is limited to Android version, OpenYOLO can be used anywhere.
Autofill is platform-specific, OpenYOLO is platform-agnostic.
And the cherry on top — it is possible to use them side-by-side but the experience
is confusing. There are still no recommendations what to prefer and when.
[The discussion about the dichotomy between Autofill and OpenYOLO](https://github.com/openid/OpenYOLO-Android/issues/127)
stopped — guess when — in October, 2017.

I can feel the confusion of password manager developers who spent time
working on OpenYOLO then being informed that there is a same-same but different Autofill.

## [Google Credentials](https://developers.google.com/android/reference/com/google/android/gms/auth/api/credentials/package-summary)

Don’t worry, this is not another SDK solving same issues in its own way.
Its purpose is [to provide hints](https://developers.google.com/identity/smartlock-passwords/android/retrieve-hints)
for sign in and sign up forms. There are pickers for accounts and phone numbers
which do not require additional system permissions to operate.

Requesting a phone number is obvious, but requesting a Google account will result
in an email address, a name and even a photo URL! This is very useful
for sign up forms. Not sure about sign in ones though.

# Decisions, Decisions
