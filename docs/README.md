# mui

**mui** is a cross-platform UI abstraction layer for Haxe. It wraps four backend libraries under a single API:

| Backend | Platform | Library |
|---------|----------|---------|
| `sui` | macOS, iOS, visionOS (SwiftUI) | [sui](https://github.com/lapavoiserie/sui) |
| `wui` | Windows (WinUI 3) | [wui](https://github.com/lapavoiserie/wui) |
| `aui` | Android (Jetpack Compose) | [aui](https://github.com/lapavoiserie/aui) |
| `cui` | Terminal (TUI) | [cui](https://github.com/lapavoiserie/cui) |

You write your app once and compile to any backend by setting a `-D mui_backend` flag. All mui types compile down to backend types with zero runtime overhead.

## Minimal Example

```haxe
import mui.App;
import mui.View;
import mui.ui.*;

class Counter extends App {
    @:state var count:Int = 0;

    override function body():View {
        return new VStack([
            new Text('Count: ${count.get()}'),
            new HStack([
                new Button("-", function() count.set(count.get() - 1)),
                new Button("+", function() count.set(count.get() + 1)),
            ], 8),
        ], 10);
    }

    static function main() {
        #if mui_owns_main
        new Counter().run();
        #end
    }
}
```

No `#if` blocks in the UI code itself. The only conditional is `main()`, and
it does not name a backend: `mui_owns_main` is defined when the chosen
backend's engine owns the process — `cui` and `pui` today — because there
`run()` blocks and nothing may follow it. Everywhere else a generator drives,
and anything in `main()` would run at the wrong time.

## How It Works

**The backend adapts to `mui`, not the other way round.** That is the whole
architecture, and it used to be the reverse: `mui` held 132
`#if (mui_backend == …)` branches across 22 files, of which 109 were a typedef or
a five-line `extends`. The volume was never the problem — the direction was.
`mui` had to know all six backends, and adding a seventh meant editing
twenty-two files in a repository that had nothing to learn from it.

Now:

- [`mui.Contract`](https://github.com/lapavoiserie/mui/blob/main/src/mui/Contract.hx)
  states the vocabulary **as data** — each type, where it lands, and its
  constructor's signature.
- Each backend declares its own conformance under `<backend>.mui.*`: a `typedef`
  when the signature already matches, a small subclass when it does not.
- `--macro mui.macros.Bind.all()`, one line in the build file, defines every
  alias — `mui.ui.Button` becomes `<backend>.mui.Button` — then checks each
  constructor against the contract and names what does not match.

`src/mui` contains **no conditional compilation at all**, and adding a backend
touches **zero files** here. What remains in `tools/` names backends on purpose:
the support matrix is a table *across* them, and the watch command has to know
which reload each is capable of.

Two rules the six backends made necessary rather than an ideal: a backend may add
**trailing optional** arguments the contract does not name, and an entry may be
**optional** — exactly one is, because a terminal cannot draw an image.
