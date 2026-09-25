# Kitchen sink

One source, written in `mui`'s markup, run on more than one backend.

    haxe build-pui.hxml       # or build-aui.hxml
    haxe build-pui-mac.hxml   # and, on macOS, a window
    PUI_FRAME_DUMP=/tmp/ks-pui.png ./build/mac/KitchenSink
    haxelib run sui build macos          # sui has its own CLI

Two things this example exists to show, and neither is the controls.

**It holds eleven node types, because that is every type `pui`, `sui`, `aui` and
`cui` all declare.** The markup is checked at compile time against the backend
named by `-D mui_backend`, so anything else fails to build rather than to draw;
`mui/test/vocabulary` keeps the table. The tenth is `Button`, which `aui` could
not declare until 2026-09-21 — it had no control able to carry a closure.

**It is built through `-D mui_views`**, so `ui()` answers the backend's own
view rather than a `nui.Node`, and the markup is a syntax over that backend's
API: closures bound directly, nothing described, nothing read back.

**Its decorations are what all three can draw**, which is four of the canon's
nine: no colours and no border, because `sui` cannot put a role on one of its
views and `aui`'s border takes a colour value a role cannot become. Writing one
here does not produce a plain screen — it does not compile. That table is a
statement of debt, not of design.

**A two-way control binds the cell** — `isOn={lit_}` — which is what a view
written by hand does.

## Where each backend stands

`pui`, `aui` and `sui` all draw it, and the three pictures are the same screen:
the field, the toggle, the slider, the text following all three, the row with
its spacer, the ZStack and the computed rows.

    haxe build-pui-mac.hxml && PUI_FRAME_DUMP=/tmp/ks.png ./build/mac/KitchenSink
    haxe build-aui.hxml && (cd android && ./gradlew :app:assembleDebug)
    haxelib run sui build macos
    SUI_FRAME_DUMP=/tmp/ks-sui ./build/macos/DerivedData/Build/Products/Debug/KitchenSink.app/Contents/MacOS/KitchenSink

Each of the three writes its picture off-screen — `ImageRenderer` on `sui`, a
frame dump on `pui`, `adb exec-out screencap` on the emulator — so nobody's
display is taken over for a test.

## The comprehension runs; it is not translated

`{[for (i in 0...12) ui(<HStack…/>)]}` is a **Haxe comprehension**, and all
three backends simply run it: twelve rows, `"row " + (i + 1)` counting from
one, `i % 2 == 0 ? "even" : "odd"` alternating. Measured on `pui`, on the
Android emulator, and on macOS through `sui`.

That is worth stating because it was believed otherwise here for a day. `sui`
has **two** render paths and
[its docs](https://lapavoiserie.github.io/sui/#/render-paths) are explicit
about which is which: the **dynamic renderer** is the path — the app runs,
`body()` builds a Haxe view tree, `DynamicView.swift` walks it — and the
SwiftUI transpiler behind `--static` is *decommissioned*. A markup screen
reaches the dynamic renderer the same way a hand-written one does, so a
comprehension inside it costs nothing, and so does any other Haxe.

The version of this file that said "`sui` draws no rows" was reasoning from
the transpiler, and had also added a `forEachOf` hook to `mui`'s markup so a
comprehension could become a SwiftUI `ForEach`. That hook made the rows
disappear on the path that was actually running: `sui.ui.ForEach` wants a state
array, it was handed an `IntIterator`, and it drew nothing at all. Removing it
is what produced the picture above.

## What each picture still gets wrong

Worth reading before trusting any of them.

**`sui`'s capture cannot draw a `TextField`.** `ImageRenderer` renders a view
tree without a window, and an interactive control has nothing to draw there —
the yellow bar with a slash is the renderer saying so, not the app. The field
is in the tree and works in the real window.

**`sui`'s capture draws no rows inside a `ScrollView`.** Measured: with the
rows under `<ScrollView clip={true}>` the picture reserves their full height
and paints none of them; with the same rows under a `VStack` all twelve appear.
Most likely the same limitation as the field — an AppKit-backed `NSScrollView`
has nothing to rasterise off-screen — but that is deduced from the symptom, not
confirmed at the window.

Three defects had to be fixed to get this far, and all three type-checked in
Haxe: a constructor argument matched by field name where the declaration names
it otherwise (every string came out empty), a binding read only in the shape a
hand-written app uses (`$null`), and a cell bound as `$count_` where the state
is `count`.

## `cui`, and what it costs a terminal

    haxe build-cui.hxml                  # a real TUI, needs a terminal
    haxe build-cui-frame.hxml            # the same screen into a Buffer, printed

The second is how the picture is taken here: `cui` writes to a TTY and waits
for keys, which a test harness has neither of, so the tree is rendered into a
`cui.render.Buffer` and the cells are printed. Off-screen, like the other three.

**It used to need 140 rows.** The canon's lengths carry no unit, so `cui` read
them as cells: `spacing={12}` was twelve blank lines. Since nui 0a272d6 they
are **points**, and `cui` converts at its door (a cell is 8 by 16) -- the whole
screen, twelve computed rows included, fits an 80x44 terminal.

Two defects are open and named rather than hidden:

- ~~the `Bound to state` group lays out and draws nothing~~ — it was the unit,
  and it is fixed. It had been squeezed to 22 rows while its padding asked for
  24, so its inside was negative and there was nothing to draw, which was
  correct all along.
- ~~`cui` showed `row 1` and nothing after it~~ — `cui.ui.ScrollView` took one
  child and markup handed it twelve: it kept the first and dropped eleven in
  silence. It holds a list now (cui 9a9eefb).
- ~~`opacity` was accepted by markup for `cui` and nothing read it.~~ Fixed:
  `cui` draws `opacity`, `width` and `height` now, and refuses `flex` by name.
