# Two windows, one process

One application showing its tree in two windows on the same machine: the desk
is `body()`, the monitor wall is an `@:surface(Auxiliary)` declaration. They
share the state cells and nothing else — focus, hover, drop-downs and scroll
offsets each belong to one pane of glass.

`Auxiliary` is not new vocabulary. It is the role `mui` has had since the
surfaces chantier, hosted by `sui` (macOS scenes) and `wui` (WinUI windows);
what this example is for is that `pui` now hosts one too, and draws both
windows itself. See [Surfaces](../../docs/surfaces.md#several-windows-one-process).

## Run it, and look at it

```bash
haxe build-pui-mac.hxml
PUI_FRAME_DUMP=/tmp/shot.png MUI_TWO_WINDOWS_TAKES=3 ./build/mac/TwoWindows
```

Two windows open. `MUI_TWO_WINDOWS_TAKES` drives them without a hand — three
takes, one per half-second, then the application quits — and each window
photographs its own last frame: `/tmp/shot.png` is the desk, `/tmp/shot-1.png`
is the monitor wall. Both read `takes: 3` and `scene 3`, written once, by a
timer neither window knows about.

Without `MUI_TWO_WINDOWS_TAKES` it just runs: press **New take** on the desk
and watch the wall follow, press **Reset** on the wall and watch the desk.

## Where it does not build

```
TwoWindows.hx:53: pui hosts no Auxiliary: surface "monitors" would fly nowhere
  here (it hosts Companion). Accept that with @:surface(Auxiliary, optional),
  or build for a backend that hosts it.
```

That is `haxe build-pui-mac.hxml -D pui_surface=ios`, and it is the point: a
phone has one pane of glass, which is knowable while compiling, so it is a
compile error and not an empty screen.
