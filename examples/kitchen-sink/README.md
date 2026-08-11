# Kitchen sink

One source, every `mui` type the targeted backends share, built for each of
them. This is the example that answers "does write-once actually hold?" — not
by asserting it, but by being the same file.

```bash
haxelib run sui build ios      # iOS simulator   — uses build.hxml
haxelib run sui build macos    # macOS           — uses build.hxml
haxelib run aui build --run    # Android         — uses build-aui.hxml
```

`sui`'s CLI reads `build.hxml` by name, so that is the sui one; `aui`'s takes
its own. Two files because the two toolchains disagree about the name, not
because the source differs.

## What it leaves out, and why

A kitchen sink that quietly skipped a type would be the wrong kind of example,
so each absence has a reason:

| Left out | Why |
|---|---|
| `Image`, `ListView` | In `mui`'s vocabulary and in all three backends, but not in **aui's dynamic renderer**, which is narrower than the backend. Being outside it is a compile error naming the type, not a blank area on screen. |
| `ScrollView` | It does not have one API: `Array<View>` on sui and aui, a single child on wui, a child plus a scroll offset on cui. Until that is one signature it cannot appear in an example whose whole claim is that the source is the same everywhere. |

## What building it found

Nothing here was written to fix a known bug; every one of these was found by
running this example on a device, and none announced itself:

- `aui` instantiated the wrong application class — `mui.App` is also an
  `aui.App`, and the generator took the last candidate it saw. The app drew
  `?EmptyView`.
- A `mui` button's closure was invisible to `aui`, whose own buttons carry a
  declarative action. Buttons were drawn greyed out.
- A `Slider`'s `min`/`max` read as 0, because `aui`'s walk read only the
  properties map and those live in fields.
- Both backends' coverage checks refused `TextInput` by its Haxe class name,
  though it *is* a `TextField` and renders perfectly.
- `mui`'s `ForEach` emitted sui's legacy string-template form — the one the
  decommissioned transpiler resolved, and the one the dynamic renderer cannot.
- An empty tab icon made SwiftUI draw its unsupported-view placeholder.

## Not yet seen

**Windows.** `wui` is in the table above and this example should build for it;
nobody has run it. Nothing about the source is iOS- or Android-specific.

**macOS, on screen.** It builds and runs, but the only capture available there
rasterises the SwiftUI hierarchy rather than reading the window, and it cannot
handle a `TabView` — it draws SwiftUI's unsupported placeholder for the whole
tree. iOS renders the same tree correctly through a real screen capture, which
is the evidence that the tree is fine.
