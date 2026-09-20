# Kitchen sink

One source, written in `mui`'s markup, run on more than one backend.

    haxe build-pui.hxml       # or build-sui.hxml, build-aui.hxml
    haxe build-pui-mac.hxml   # and, on macOS, a window
    PUI_FRAME_DUMP=/tmp/ks-pui.png ./build/mac/KitchenSink

Two things this example exists to show, and neither is the controls.

**It holds nine node types, because that is every type `pui`, `sui` and `aui`
all three declare.** The markup is checked at compile time against the backend
named by `-D mui_backend`, so anything else fails to build rather than to draw.
`pui` declares 22, `aui` 14 — **and no `Button`** — and `sui` 10. There is no
button in this file for that reason.

**It is built through `-D mui_views`**, so `ui()` answers a `pui.View` rather
than a `nui.Node` and the markup is a syntax over pui's own API: closures bound
directly, nothing described, nothing read back.

**Its decorations are what all three can draw**, which is four of the canon's
nine: no colours and no border, because `sui` cannot put a role on one of its
views and `aui`'s border takes a colour value a role cannot become. Writing one
here does not produce a plain screen — it does not compile. That table is a
statement of debt, not of design.

**A two-way control binds the cell** — `isOn={lit_}` — which is what a view
written by hand does.

**Only `wui` has a `view():nui.Node` hook.** The other three expect `body()`
returning their own `View` type, so the markup is written once and `body()`
hands it over three different ways: `pui` builds views from a node in Haxe,
while `sui` and `aui` render a received tree natively and take it through
`readThrough`. The markup is shared; the door it goes through is not.

## Where each backend stands

`pui` and `aui` draw it, and both pictures are the same screen: the field, the
toggle, the slider, the text following all three, the row with its spacer, the
ZStack and the computed rows.

    haxe build-pui-mac.hxml && PUI_FRAME_DUMP=/tmp/ks.png ./build/mac/KitchenSink
    haxe build-aui.hxml && (cd android && ./gradlew :app:assembleDebug)

`sui` draws it too:

    KS_DUMP=/tmp/ks-sui.png ./run-sui.sh

`ImageRenderer`, not a screenshot: the picture is made off-screen and nobody's
display is taken over for a test, which is the rule the emulator check follows
too. `sui`'s own `SUI_FRAME_DUMP` photographs the DYNAMIC tree, so it says
nothing about the `ContentView` a transpiled app shows.

## What each picture still gets wrong

Worth reading before trusting any of them.

**`sui` draws no rows.** Not the same reason as the text, and not a bug in the
generator: `{[for (i in 0…12) ui(<HStack…/>)]}` is a **Haxe comprehension**,
which a backend that builds its views at runtime can simply run — `pui` and
`aui` do — and a backend that transpiles cannot, because there is no Swift for
a loop that has already produced views.

SwiftUI's own answer is `ForEach` over a collection, and `sui` supports exactly
that: `ForEach(cellName, item -> view)`. But **nothing declares `ForEach` as a
node**, on any backend, so markup has no way to say it. Until it does, a
computed list is portable to the backends that build at runtime and to no
others.

**`sui`'s capture cannot draw a `TextField`.** `ImageRenderer` renders a view
tree without a window, and an interactive control has nothing to draw there --
the yellow bar with a slash is the renderer saying so, not the app. The field
is in the tree and works in the real window.

Three defects had to be fixed to get this far, and all three type-checked in
Haxe: a constructor argument matched by field name where the declaration names
it otherwise (every string came out empty), a binding read only in the shape a
hand-written app uses (`$null`), and a cell bound as `$count_` where the state
is `count`.
