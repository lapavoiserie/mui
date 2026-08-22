# Durable state

A cell declared durable survives the process that wrote it, and is shared with
the application's own detached surfaces on the same device.

```haxe
class Counter extends App {
    @:state(durable) var count:Int = 0;
    @:state var scratch:Int = 0;     // ordinary: back to 0 on every launch
}
```

That is the whole of the API. `count` is read and written exactly like any
other `@:state` cell — `count.get()`, `count.set(3)`, bindings, effects. What
changes is where its value comes from when the cell is built, and where it goes
when it is written.

## What it buys

Two things, and the second is the one that made this necessary.

**The application reopens where it was.** Kill the process, relaunch, and the
cell is back at its last value rather than at the default in your source.

**A widget's button can do something.** On Android the widget already ran in
the application's process, so its buttons worked; on iOS a WidgetKit widget is
a separate binary, and its tap arrives in an extension where the application's
closures do not exist. The extension therefore boots its own instance of the
application and runs the closure *there* — and a durable cell is what makes
that instance's value the same value the application holds. See
[Surfaces](../surfaces.md).

## What may be durable

`Int`, `Float`, `Bool`, `String`. Anything else is refused at compile time,
naming the field:

```
@:state(durable) carries Int, Float, Bool or String, and "items" is Array.
  A reference type mutated in place compares equal to itself, so its write never
  reaches the store, and what a detached surface shows goes quietly stale.
  Persist what you can name.
```

The refusal is not arbitrary. A signal decides that something changed by
comparing with `!=`, so an array you mutated in place is equal to itself and its
write never happens. These four are also the four `nui.Snapshot` already carries
and the only four every native bridge in this ecosystem can marshal.

## The key

Each cell gets a key of `ClassName.fieldName` — `Counter.count` above. Name it
yourself when you want the value to outlive a rename:

```haxe
@:state(durable, key = "score") var count:Int = 0;
```

Renaming a field without a key is a silent loss: the old key stays in the store,
the new one has never been written, and the cell comes back at its default. If a
value matters to a user, give it a key.

## Where it is kept

A `kui` capability, `kui-store`, one implementation per platform:

| Platform | Where |
| --- | --- |
| macOS | `~/Library/Application Support/pavois/store` |
| Linux | `$XDG_DATA_HOME/pavois/store`, else `~/.local/share/pavois/store` |
| Windows | `%APPDATA%\pavois\store` |
| Android | `/data/data/<package>/files/pavois/store` |
| iOS | the App Group container, shared with the widget extension |
| visionOS | the app's container, `Library/Application Support/pavois/store` |
| Sailfish | `~/.local/share/<app>/pavois-store` — the app's own, per Sailjail |

A text file in every case, one line per entry, readable by a human at the moment
it disagrees with the screen — which is exactly the moment nobody has a debugger
attached.

```
epoch	8
Counter.count	8	glance	i:8
```

Add it to your build with `-lib kui-store`. Without it, a `@:state(durable)`
field is refused at compile time — naming the platform, the missing type and
the fix. It is never ignored: a cell that silently stopped persisting is how a
user loses their data.

## Two writers

On iOS the application and its widget extension are two processes over one
container, and both write. So a write is a **compare-and-set**: every entry
carries a sequence, and a write that finds the sequence moved does not
overwrite. It re-reads and adopts the other's value.

You do not call any of that. What you should know is the consequence: a losing
write is not lost work you can retry, it is a value that changed underneath you,
and the cell will hold the winner's.

The application takes in whatever the other process wrote when it returns to the
foreground — one integer read when nothing happened. Nothing rehydrates on a
timer or on a background thread, because a cell rewritten under a running effect
is a far worse problem than a number that is briefly stale.

## What is not durable, and is easy to forget

**Everything you did not declare.** A closure running in a widget extension sees
your durable cells at their shared value and every other cell at its *initial*
value — a draft that never existed anywhere. For a counter that is obvious; for
a closure that reads three cells and writes one, it is a wrong answer with
nothing to see. Keep widget closures to what they can honestly reach.

**Whole-object state.** There is no schema, no migration, no transaction. A
closure interrupted halfway leaves some keys advanced and others not, because
the compare-and-set is per key. An application that needs more than four scalar
kinds and last-write-wins needs a real store, and should say so in its own code
rather than grow this one.

**Anything across the network.** Durable state is a *device* story. `cafos`
carries pictures and action ids between machines and never state.
