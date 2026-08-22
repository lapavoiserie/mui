# Native capabilities

`mui` gives an application a vocabulary of views. It says nothing about the
battery, the camera, secure storage or haptics — and it should not, because a
view vocabulary that also grew a camera API would be two libraries wearing one
name.

Those live in [`kui`](https://lapavoiserie.github.io/kui/), and a `mui`
application uses them directly:

```haxe
import battery.Battery;

override function body():View {
    var level = kui.Kui.get(Battery).level();
    return new Text(level < 0 ? "no battery" : 'charge: $level %');
}
```

## Nothing in `mui` had to change

That is the recommendation rather than an accident of scheduling.

A capability cannot be a row in `mui.Contract`: the contract is a fixed list
that lives inside `mui`, and capabilities are third-party and open-ended. Nor
does it need to be. `kui` depends on no backend, so an application simply uses
it and it resolves through whichever platform the chosen backend declared.

"Reaching up to `mui`" therefore means **nothing standing in the way** — not a
new binding.

## What each backend contributes

One line in its own `init.hxml`, which `mui init` already writes:

```
--macro <backend>.kui.Platform.registerWithKui()
```

`kui` cannot work the platform out on its own — a macro cannot call a function
it was only handed the name of, which is why `mui.macros.Backend.register` has
the same shape. So each backend states what it is building:

| Backend | Platform | Who performs the link |
|---|---|---|
| `sui` | macOS, iOS, visionOS | hxcpp compiles, **Xcode** links |
| `aui` | Android | **Gradle**, over a JVM jar |
| `wui` | Windows | hxcpp compiles to a `.lib`, **MSBuild** links |
| `cui` | wherever it was built | **hxcpp** does both |
| `pui` | its seven surfaces | hxcpp, Xcode, Gradle or qmake, by surface |
| `qui` | SailfishOS | **qmake**, inside the SDK container |

Two rows are worth reading twice. `aui` and `pui` both reach Android and link
differently; `wui` and `pui` both reach Windows and link differently. That is
why a capability's native payload is keyed by **toolchain** and not by platform,
and why the same operating system may need two things said about it.

## One line is required on Qt, and only there

```
-D kui_platform=sailfish     # or linux
```

Nothing in Haxe separates SailfishOS from desktop Linux: the two build files are
otherwise identical, and only `DEFINES += PUI_SAILFISH` in the `.pro` tells them
apart — the C++ preprocessor, long after macros have run. `kui` asks rather than
guesses, because a guess here is a guess that compiles.

## A capability the platform does not implement

Is a **compile error at the line that reached for it**, naming what was asked
for, what does exist, and where `kui` looked:

```
battery.Battery has no implementation for "browser".
  It implements: android, linux, macos, sailfish, windows.
  kui looked for battery.platform.browser.Battery.
```

Never a runtime `null`, and never a marker on screen — the same rule
`mui.Contract`'s `optional` follows, one layer down. Where a feature is
genuinely optional, `kui.Kui.supports(Battery)` folds to a compile-time constant
and dead-code elimination removes the branch that cannot work.

## Stopping what an application started

A capability that only answers questions needs nothing. One that has to be
**watched** — connectivity, location, anything that changes while the
application runs — means the application owns something that must later be
stopped, and forgetting is a leak that grows with use.

`mui.App` carries a `lifetime` for exactly that:

```haxe
public function new() {
    super();
    var watcher = new Effect(() -> {
        var stop = Watch.changes(net, 1000, v -> online.value = v);
        Effect.onCleanup(stop);
    });
    lifetime.own(watcher.dispose);
}
```

It is released where the application's loop ends and hands control back to
Haxe — `cui` when the loop quits, `pui` when the window closes. Where no loop
returns, the process is ending instead and the system reclaims what is left:
`sui` and `aui` never give the loop back, and `pui` in a browser returns
immediately, which is why it does **not** release there.

`mui.Contract` requires `lifetime` of every backend, so an application can rely
on it without asking whether this one has it.

### Why the effect goes in the constructor, not `body()`

`body()` runs again on every rebuild. An effect created there would start a
second watcher on the first rebuild and a third on the next, each keeping the
last alive — the leak `onCleanup` prevents *inside* an effect, reintroduced
*around* it.

### A view lifetime, expressed as a key

A watcher that should only run while part of the interface is showing does not
belong to the application's whole life. `lifetime.keep` scopes it to a
**declaration**:

```haxe
override function body():View {
    if (showDetail) lifetime.keep("detail", () -> {
        var stop = Watch.changes(net, 1000, onChange);
        return stop;
    });
    …
}
```

Started the first time the key appears, undone once `body()` stops asking for
it.

**Why a key rather than the view itself.** A view has no identity to hang this
on: a rebuild produces new objects, so a pointer means nothing across two
passes. And under the pull contract — `sui`, `aui` — the host expands and
discards views on its own schedule and tells Haxe nothing. The key is the one
identity the application is in a position to state, and it reads the same on all
six backends.

**Why not the host's `onDisappear`.** Because "gone from the screen" is not
"gone from the interface". A view scrolled out of a lazy list, or sitting under
another tab, has disappeared by the host's reckoning and is still perfectly
declared. Stopping its watcher there would be a bug that takes weeks to
attribute. `body()` knows the difference; `onDisappear` does not.

**It is undone when the pass ends.** A pass is bracketed: `beginPass` before the
tree is built, `endPass` once it is fully realised — which under the pull
contract is *after* the host has forced the lazy expansion, not merely after
`body()` returned. Sweeping at the end of the pass rather than at the start of
the next one matters: a backend that only rebuilds on demand might never run
another pass, and a dropped key would then never be undone at all.

## The capabilities that exist

| Capability | haxelib | Platforms |
|---|---|---|
| `battery` | `kui-battery`, in `kui/examples` | macOS, iOS, Linux, Android, Windows, Sailfish |
| `network` | `kui-network`, in `kui/examples` | macOS, Linux, Android, Windows, Sailfish |
| `store` | `kui-store`, its own repository | macOS, Linux, Windows, Android, iOS, visionOS, Sailfish |

`store` is the one an application meets without asking for it: it is what
[`@:state(durable)`](state/durable.md) is built on. Add `-lib kui-store` and a
cell can outlive its process; leave it out and a durable declaration is a
compile error naming the platform, never a cell that quietly stopped saving.

It is also the capability that shows the boundary `kui` keeps. The obvious
Android implementation is `SharedPreferences`, and it is not used: that needs a
`Context`, which a capability is handed none of. The store finds the
application's own private directory instead, from `/proc/self/cmdline`, and
stays inside what a plain JVM object can do — the same line the `battery`
example draws when it reads sysfs rather than `BatteryManager`.

## Further reading

The [`kui` documentation](https://lapavoiserie.github.io/kui/) covers writing a
capability, how a native payload reaches five different link steps, and what
`kui` deliberately does not do — native views and window handles, both stated
boundaries rather than omissions.
