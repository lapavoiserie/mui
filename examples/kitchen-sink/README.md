# Kitchen sink

One source, written in `mui`'s markup, run on more than one backend.

    haxe build-pui-mac.hxml
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

**Only `wui` has a `view():nui.Node` hook.** The other three expect `body()`
returning their own `View` type, so the markup is written once and `body()`
hands it over three different ways: `pui` builds views from a node in Haxe,
while `sui` and `aui` render a received tree natively and take it through
`readThrough`. The markup is shared; the door it goes through is not.
