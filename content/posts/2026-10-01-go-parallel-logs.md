---
title: "Logs in Parallel Go Tests and Where to Find Them"
description: "Making sense of the output when Go things go wrong"
date: "2026-10-01"
slug: "go-parallel-logs"
---

Life is too short to avoid parallel tests.
Go doesn’t really have complicated frameworks, implicit state sharing
and all the fun little nuggets which can make non-flaky parallel execution troublesome.
All is well when life is good and the magical `PASS` status shines through the console window.
Unfortunately, when something goes wrong, figuring out the failing test output can get complicated.

# `os.Stdout`

[Standard streams](https://en.wikipedia.org/wiki/Standard_streams) can do no harm, right?
Even [the `log/slog` package](https://pkg.go.dev/log/slog)
has `os.Stdout` and `os.Stderr` in the overview section, so it should be good to go.

> [!WARNING]
> Don’t read too much into the sample. The goal is to illustrate
> that sometimes there are log entries in the code under test.
> It’s arguable if it’s a good idea — perhaps everything should be available
> in the `error` — but it happens. Also, it’s not unimaginable
> to have integration or end-to-end tests in Go where it can be useful
> to see things like requests and responses.

```go
func NewMagician(sink io.Writer) *Magician {
	return &Magician{
		log: slog.New(slog.NewTextHandler(sink, nil)),
	}
}

type Magician struct {
	log *slog.Logger
}

func (m *Magician) Magic(number float64) error {
	if number < 0 {
		m.log.Warn("psst... negative", "number", number)
	}

	if math.IsNaN(math.Sqrt(number)) {
		return errors.New("not magical")
	}

	return nil
}
```

```go
func Test_Magic(t *testing.T) {
	for range 10 {
		t.Run("magic?", func(t *testing.T) {
			t.Parallel()

			// This is Fine
			magician := NewMagician(os.Stdout)

			if magician.Magic(rand.NormFloat64()) != nil {
				t.Fail()
			}
		})
	}
}
```

```
level=WARN msg="psst... negative" number=-1.6339684492315416
level=WARN msg="psst... negative" number=-1.3237010249897858
level=WARN msg="psst... negative" number=-1.9896133048746591
level=WARN msg="psst... negative" number=-0.2555428000485551
--- FAIL: Test_Magic (0.00s)
    --- FAIL: Test_Magic/magic?#01 (0.00s)
    --- FAIL: Test_Magic/magic?#05 (0.00s)
    --- FAIL: Test_Magic/magic?#07 (0.00s)
    --- FAIL: Test_Magic/magic?#04 (0.00s)
```

Well, that’s disappointing. There are failures but it’s not clear
which data caused them. This happens because each sub-test
writes to `os.Stdout` at the execution time while
test results wait for all tests to complete. No sync whatsoever.
At the same time, there is no association between sink entries and what produced them.

# `t.Output()`

Fortunately, since [Go 1.25](https://go.dev/doc/go1.25) (August 2025)
[the `Output` method](https://pkg.go.dev/testing#T.Output) is available in the `testing` package:

> The output is internally line buffered, and a call to `TB.Log` or
> the end of the test will implicitly flush the buffer, followed by a newline.

Sounds delightful, and it’s a single-line change since the output sink
is passed as an argument to the constructor function.

```diff
- magician := NewMagician(os.Stdout)
+ magician := NewMagician(t.Output())
```

```
--- FAIL: Test_Magic (0.00s)
    --- FAIL: Test_Magic/magic? (0.00s)
        level=WARN msg="psst... negative" number=-0.23453412253127565
    --- FAIL: Test_Magic/magic?#07 (0.00s)
        level=WARN msg="psst... negative" number=-1.121445066325517
    --- FAIL: Test_Magic/magic?#08 (0.00s)
        level=WARN msg="psst... negative" number=-0.28620836519937065
    --- FAIL: Test_Magic/magic?#02 (0.00s)
        level=WARN msg="psst... negative" number=-0.46950245399468793
    --- FAIL: Test_Magic/magic?#03 (0.00s)
        level=WARN msg="psst... negative" number=-2.433193144637306
    --- FAIL: Test_Magic/magic?#09 (0.00s)
        level=WARN msg="psst... negative" number=-0.4987479276079265
```

Now the output becomes useful. Each failure is associated with a corresponding output.
The sample used here is primitive, of course, but the benefit is much more evident
with hundreds of complex calls. It’s fine to debug
a single failure but when there are dozens of them… Well, without this sort of thing it’s not fun at all.

> [!NOTE]
> Before `t.Output()` became available, the workaround was wrapping
> [the `t.Log()` method](https://pkg.go.dev/testing#T.Log) — at the cost
> of prefixing each line with the wrapper’s source location.
> See [the `slogt` project](https://github.com/neilotoole/slogt) for details.

One important note though. If `t.Output()` is taken from the parent test,
the output becomes disorganized:

```go
func Test_Magic(t *testing.T) {
	// Note that the instance is created outside the "t.Run()" call.
	magician := NewMagician(t.Output())

	for range 10 {
		t.Run("magic?", func(t *testing.T) {
			t.Parallel()

			if magician.Magic(rand.NormFloat64()) != nil {
				t.Fail()
			}
		})
	}
}
```

```
--- FAIL: Test_Magic (0.00s)
    level=WARN msg="psst... negative" number=-0.2037386300776194
    level=WARN msg="psst... negative" number=-0.6801286966229625
    --- FAIL: Test_Magic/magic?#06 (0.00s)
    --- FAIL: Test_Magic/magic?#02 (0.00s)
    level=WARN msg="psst... negative" number=-1.8753088691720174
    --- FAIL: Test_Magic/magic?#05 (0.00s)
```

This happens because the output is associated with the parent test and its sink,
not with individual sub-tests.

# What Else?

None of the above is limited to `log/slog`.
Lots of companies have their own logger implementations and (or)
use third-party ones. The majority of them can receive `io.Writer`
which `t.Output()` provides.

Just keep in mind that tests sometimes, in fact, fail,
and in such dire times it’s important to be able to understand the cause.
