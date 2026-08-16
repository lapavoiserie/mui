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

## Further reading

The [`kui` documentation](https://lapavoiserie.github.io/kui/) covers writing a
capability, how a native payload reaches five different link steps, and what
`kui` deliberately does not do — native views and window handles, both stated
boundaries rather than omissions.
