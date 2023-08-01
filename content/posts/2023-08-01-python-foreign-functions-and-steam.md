---
title: "Python, foreign functions and Steam"
description: "Calling Steamworks from Python without overhead"
date: "2023-08-01"
slug: "python-foreign-functions-and-steam"
---

Language ecosystems are not perfect. Sometimes resulting executables are performant
but the syntax is horrible, sometimes there is a nice package manager
but standard functions are scarce to a fault --- it's all about the compromise.

Python is nice to use but the performance might be not great. The latter causes
such tools as [NumPy](https://numpy.org/) to emerge. How does it work?
Well, [it uses C calls](https://numpy.org/doc/stable/user/whatisnumpy.html#why-is-numpy-fast) ---
essentially borrowing performance improvements from the C ecosystem.
In this article, I'll show how to use foreign C functions from dynamic libraries in Python.
Calls will be done to [the Steamworks SDK](https://partner.steamgames.com/doc/sdk)
which games use to communicate with Steam.

# Overview

When talking about calling foreign functions from Python, at least two solutions come to mind ---
[`ctypes`](https://docs.python.org/3/library/ctypes.html) and
[`cython`](https://cython.readthedocs.io/en/latest/index.html).
`ctypes` is a standard package, does not require additional compilation steps or tools ---
basically, Plug and Play for dynamic libraries. `cython` is an external package and is a bit more involved ---
having a different (but similar to Python) syntax, tools and so on. I'll use `ctypes` below but `cython`
can be useful in more complicated situations.

As for Steam, [the Steamworks API](https://partner.steamgames.com/doc/sdk/api) is the point of interest.
It's a collection of C++ calls --- including interfaces, classes, methods and all of that.
Unfortunately, `ctypes` doesn't bode well with C++, preferring C signatures instead.
Fortunately, the Steamworks API provides [a special API](https://partner.steamgames.com/doc/sdk/api#flat_interface)
for interop purposes -- `ctypes` is capable of using it without issues or side-effects.

# Making the Call

## Linking

The Steamworks SDK has following Steamworks API binaries.

```
redistributable_bin
├── linux32
│   └── libsteam_api.so
├── linux64
│   └── libsteam_api.so
├── osx
│   └── libsteam_api.dylib
├── steam_api.dll
├── steam_api.lib
└── win64
    ├── steam_api64.dll
    └── steam_api64.lib
```

An appropriate file must be picked based on the OS and passed to `ctypes` to receive a dynamic library object (`ctypes.CDLL`).
I have a Mac and a Steam Deck so the code below is for macOS and Linux since I cannot check how Windows works but it should be similar.

```python
import ctypes
import pathlib
import platform

class Steam:

    _dll: ctypes.CDLL

    def __init__(self, sdk_path: pathlib.Path) -> None:
        self._dll = ctypes.CDLL(Steam._resolve_dll_path(sdk_path))

    @staticmethod
    def _resolve_dll_path(sdk_path: pathlib.Path) -> pathlib.Path:
        dlls_path = sdk_path / "redistributable_bin"

        system = platform.system()

        if system == "Darwin":
            return dlls_path / "osx" / "libsteam_api.dylib"
        elif system == "Linux":
            (system_bits, _) = platform.architecture()

            if system_bits == "64bit":
                return dlls_path / "linux64" / "libsteam_api.so"
            elif system_bits == "32bit":
                return dlls_path / "linux32" / "libsteam_api.so"
            else:
                raise SteamException(f"unsupported system bits: {bits}")
        else:
            raise SteamException(f"unsupported system: {platform.system()}")
```

## Binding: C

To call functions from a dynamic library, `ctypes` needs to know their signature.
To feed this knowledge, functions are defined on the `ctypes.CDLL` object ---
including their arguments and results.

From the C perspective, these calls look like this (see `sdk/public/steam/steam_api.h`):

```c
S_API bool S_CALLTYPE SteamAPI_Init();
S_API void S_CALLTYPE SteamAPI_Shutdown();
```

As such, the Python declaration will be (note `argtypes` and `restype`):

```python
import ctypes

class Steam:

    def __init__(self, sdk_path: pathlib.Path) -> None:
        # S_API bool S_CALLTYPE SteamAPI_Init();
        self._dll.SteamAPI_Init.argtypes = []
        self._dll.SteamAPI_Init.restype = ctypes.c_bool

        # S_API void S_CALLTYPE SteamAPI_Shutdown();
        self._dll.SteamAPI_Shutdown.argtypes = []
        self._dll.SteamAPI_Shutdown.restype = None
```

Python calls refer to `ctypes.CDLL` and can benefit from the context management:

```python
class SteamException(Exception):
    pass

class Steam:

    def __enter__(self):
        if not self._dll.SteamAPI_Init():
            raise SteamException("unable to init")

        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._dll.SteamAPI_Shutdown()
```
```python
with Steam(pathlib.Path("./sdk")) as steam:
    print("Success!")
```

If the Steam application is running in the background, the Steamworks SDK is unpacked near
the Python file and the file itself is executed, it will be successfull indeed. However,
the call is not that useful. What if I want to check game achievements?

## Binding: C++

The Steamworks API is available as multiple C++ interfaces --- each interface covers its own area.
For example, achievements and stats are available at [`ISteamUserStats`](https://partner.steamgames.com/doc/api/ISteamUserStats).
As I've mentioned above, `ctypes` works with C calls, not C++ ones. Fortunately, a compatible --- C-like --- flat API is available.

C++ API:

```cpp
class ISteamUserStats
{
public:
    virtual uint32 GetNumAchievements() = 0;
    virtual const char *GetAchievementName( uint32 iAchievement ) = 0;
    virtual const char *GetAchievementDisplayAttribute( const char *pchName, const char *pchKey ) = 0;
};
```

C++ flat API (see `sdk/public/steam/steam_api_flat.h`):

```cpp
S_API ISteamUserStats *SteamAPI_SteamUserStats_v012();

S_API uint32 SteamAPI_ISteamUserStats_GetNumAchievements( ISteamUserStats* self );
S_API const char * SteamAPI_ISteamUserStats_GetAchievementName( ISteamUserStats* self, uint32 iAchievement );
S_API const char * SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute( ISteamUserStats* self, const char * pchName, const char * pchKey );
```

These calls have arguments and pointers unlike the ones before. However, the same `ctypes` approach works fine.
Pick a C signature, provide a `ctypes` binding based on C arguments and results, call resulting functions.

```python
import ctypes
import os

# Alias for "ISteamUserStats*"
# A pointer is needed and not its type so a "void*" works
class SteamUserStatsPtr(ctypes.c_void_p):
    pass

class SteamUserStats:

    _dll: ctypes.CDLL
    _ptr: SteamUserStatsPtr

    def __init__(self, dll: ctypes.CDLL, ptr: SteamUserStatsPtr) -> None:
        self._dll = dll
        self._ptr = ptr

        # S_API uint32 SteamAPI_ISteamUserStats_GetNumAchievements( ISteamUserStats* self );
        self._dll.SteamAPI_ISteamUserStats_GetNumAchievements.argtypes = [SteamUserStatsPtr]
        self._dll.SteamAPI_ISteamUserStats_GetNumAchievements.restype = ctypes.c_uint32

        # S_API const char * SteamAPI_ISteamUserStats_GetAchievementName( ISteamUserStats* self, uint32 iAchievement );
        self._dll.SteamAPI_ISteamUserStats_GetAchievementName.argtypes = [SteamUserStatsPtr, ctypes.c_uint32]
        self._dll.SteamAPI_ISteamUserStats_GetAchievementName.restype = ctypes.c_char_p

        # S_API const char * SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute( ISteamUserStats* self, const char * pchName, const char * pchKey );
        self._dll.SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute.argtypes = [SteamUserStatsPtr, ctypes.c_char_p, ctypes.c_char_p]
        self._dll.SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute.restype = ctypes.c_char_p

    def get_achievements_count(self) -> int:
        return self._dll.SteamAPI_ISteamUserStats_GetNumAchievements(self._ptr)

    def get_achievement_id(self, achievement_index: int) -> str:
        return self._dll.SteamAPI_ISteamUserStats_GetAchievementName(self._ptr, achievement_index).decode("utf-8")

    def get_achievement_name(self, achievement_id: str) -> str:
        return self._dll.SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute(self._ptr, achievement_id.encode("utf-8"), "name".encode("utf-8")).decode("utf-8")

class Steam:

    def __init__(self, sdk_path: pathlib.Path, application_id: int) -> None:
        # S_API ISteamUserStats *SteamAPI_SteamUserStats_v012();
        self._dll.SteamAPI_SteamUserStats_v012.argtypes = []
        self._dll.SteamAPI_SteamUserStats_v012.restype = SteamUserStatsPtr

        # This is where Steam picks the Steam Application ID
        # ID can be found at Steam URLs and at SteamDB
        os.environ["SteamAppId"] = f"{application_id}"

    def get_user_stats(self) -> SteamUserStats:
        return SteamUserStats(self._dll, self._dll.SteamAPI_SteamUserStats_v012())
```

Might be a bit daunting to look at but at its core it's a simple concept. Usage:

```python
import pathlib

# Planescape: Torment @ https://store.steampowered.com/app/466300
with Steam(pathlib.Path("./sdk"), 466300) as steam:
    steam_user_stats = steam.get_user_stats()

    for achievement_index in range(steam_user_stats.get_achievements_count()):
        achievement_id = steam_user_stats.get_achievement_id(achievement_index)
        achievement_name = steam_user_stats.get_achievement_name(achievement_id)

        print(f"{achievement_id:30}{achievement_name:30}")
```
```
BD_ACH_001                    Call of the Blade
BD_ACH_002                    Call of the Art
BD_ACH_003                    Call of the Shadows
BD_ACH_004                    Master of Blades
BD_ACH_005                    Master of the Art
...
```

Of course, there are more use cases IRL ---
[using callbacks](https://docs.python.org/3/library/ctypes.html#callback-functions),
[passing non-standard pointers](https://docs.python.org/3/library/ctypes.html#pointers),
checking incorrect states and so on. However, it's not that different / difficult.

# Thoughts

Overall, `ctypes` is a good starting point when working with dynamic libraries.
It doesn't require additional steps --- a Python file and a `*.dylib` / `*.so` file are enough, no tools,
no dependencies. I've checked the code above on a Mac and on a Steam Deck with system-level
Python interpreters and it worked great. As such, the `ctypes`-based code can be used
for scripting and even for something more complicated.

However, if the task at hand is too complex for `ctypes` --- there is `cython`.

