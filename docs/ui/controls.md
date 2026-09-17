# Controls

## Button

A clickable button with a label and action.

```haxe
new Button("Click me", function() {
    count += 1;
})
```

A button may carry an icon from the shared vocabulary, beside the label or
alone — then the icon's name is what a screen reader says:

```haxe
new Button("TAKE", take, Swap)
new Button("", mute, MicOff)
```

**Constructor**: `Button(label:String, ?action:()->Void, ?icon:mui.ui.IconName)`

All backends are normalized to accept closures. On backends that natively use `StateAction` (sui, wui), the closure is wrapped appropriately.

The icon is the canon's: nui's `Button` node has carried one since pictures
landed. **aui, wui, cui and pui draw it**; on sui and qui the label is drawn and
the icon is not, which the matrix marks ⚠️ with the reason beside the row. The
argument is accepted everywhere rather than refused on two backends, because an
application writes one view for six.

## Toggle

A boolean switch (toggle on sui/wui, checkbox on cui).

```haxe
@:state var darkMode:Bool = false;

new Toggle("Dark Mode", darkMode_)
```

**Constructor**: `Toggle(label:String, state:ToggleBinding)`

Accepts a `@:state Bool` field directly. The `ToggleBinding` abstract handles backend conversion via `@:from`:

- **sui**: extracts the state name string for Swift code generation
- **wui**: passes the State object as a Dynamic binding
- **cui**: creates a `CheckboxBinding` from the `BoolState`

## Slider

A range slider for Float values.

```haxe
@:state var volume:Float = 0.5;

new Slider(volume_, 0.0, 1.0)
```

**Constructor**: `Slider(state:SliderBinding, min:Float = 0.0, max:Float = 1.0)`

Accepts a `@:state Float` field directly. The `SliderBinding` abstract handles backend conversion via `@:from`.

On cui, renders as a horizontal bar (`████████░░░░░░░░  50%`) with Left/Right arrow key control.

## ConditionalView

Shows one view or another based on a Bool state.

```haxe
@:state var isLoggedIn:Bool = false;

new ConditionalView(isLoggedIn_,
    new Text("Welcome!"),
    new Text("Please log in")
)
```

**Constructor**: `ConditionalView(condition:State<Bool>, thenView:View, ?elseView:View)`

Native on sui/wui/aui. On cui, implemented at runtime with measure/render delegation based on the state value.

## ProgressView

A progress indicator.

```haxe
new ProgressView("Loading...", 0.75)  // 75% progress
new ProgressView()                     // indeterminate
```

**Constructor**: `ProgressView(?label:String, ?value:Float)`

Maps to `ProgressView` (sui), `ProgressRing` (wui), `ProgressBar` (cui).

## Picker

A drop-down list: one choice among several. The selection is the chosen option's
**index**, `-1` for none.

```haxe
@:state var transition:Int = 1;

new Picker("Transition", ["Cut", "Fade", "Wipe"], transition_)
```

**Constructor**: `Picker(label:String, options:Array<String>, selection:PickerBinding)` —
the binding is an `@:state` of type `Int`. An empty label shows none.

On all six. How the list opens is each backend's own: `Picker` (sui),
`ComboBox` (wui and qui), a `DropdownMenu` (aui), and a drawn one on `pui`,
whose list is an overlay over the tree because nothing in a tree can paint past
its parent's siblings.

**`cui` is the one that cannot open a list at all.** A terminal buffer is a grid
of cells with no z-order, so its picker shows one option on one row and cycles
through them — `Transition ‹ Mix › 2/4`, Left and Right to move — and the
matrix marks it ⚠️ for that. The contract is the options and the index; the
drawing never was.

On the wire it is a canonical `Picker` node: `label`, `selectedIndex`, `onSelect`
(an index), and one `Text` child per option. A received selection is not applied
while the list is open.

## SecretInput

A value that is typed in and **never enters the tree**: a stream key, a token, a
password.

```haxe
new SecretInput("Stream key — type to replace", key -> engine.setStreamKey(key), true)
```

**Constructor**: `SecretInput(placeholder:String, ?onSecret:String->Void, isSet:Bool = false)` —
`isSet` says a value is already stored somewhere this control cannot see, so a
panel can say "saved" without the value crossing.

There is no binding and no `text`, and that is the definition of the type rather
than a rule a renderer has to remember. The value leaves through `onSecret`
once, on submission, and the field is cleared. So it is not republished on every
frame, a diagnostic has nothing to print from the node, and a received value
cannot be applied because there is none.

**Why a type rather than a flag on `TextInput`.** A forgotten flag fails *open* —
a renderer that does not know it draws an ordinary field with the secret in
clear, and nothing says so. An unknown type fails *closed*. For an ordinary
defect that is a preference; for a secret it is the difference between a bug and
a leak.

**Where it is: `pui` only, and the entry is optional on purpose.** A backend that
has not built a control which masks, refuses the clipboard, tells the input
method nothing and reports once does not get an approximation — an application
naming it there fails to compile at that line. That is the only honest answer
for a secret. nui's canon (*node model*) states the type and what a renderer
owes it.

## Image

A picture. `src` says where it lives, by scheme; `alt` says what it shows.

```haxe
new Image("asset:farceur/logo.png", "Farceur")
new Image("https://example.org/cover.jpg", "Album cover", {width: 120, fit: Cover})
new Image(thumbnailDataUri, "")            // "" declares it decorative
```

**Constructor**: `Image(src:String, alt:String, ?options:ImageOptions)` — `options` is
`{?width, ?height, ?fit}` in points; `fit` is `Contain` (default), `Cover` or `Fill`.

| `src` | names |
|---|---|
| `asset:path` | a file shipped in the application, in its `assets` directory |
| `https://…` | a picture on the web |
| `data:image/png;base64,…` | a small picture carried in the tree |
| `file:///…` | a local path |

**What an application ships** goes in an `assets` directory beside the build file,
and `Assets.src` names one:

```haxe
new Image(Assets.src("logo.png"), "Farceur")
```

It is a macro: the file is looked for while this compiles, and a name that is not
there is an error at that line rather than an `alt` noticed on a device. Every
backend's build copies the directory to wherever its runtime reads one — a
bundle's `Resources/assets`, `app/src/main/assets`, an `assets` folder beside the
executable, `/usr/share/<name>/assets` — so the same tree draws the same picture
on all six. `-D mui_assets=<directory>` moves it.

While a picture is loading, and whenever it cannot be drawn — refused, not found,
not a PNG or a JPEG — its `alt` is drawn in its place, never a broken-image glyph. A
tree received from elsewhere may not name a local file, loads `https:` only from
hosts the panel trusts, and carries `data:` up to 256 KiB (see nui's *node model*).

**Where it is**: all six backends, and the contract checks the signature — sui
(`AsyncImage` and `NSImage`), wui (a WinUI `Image`), aui (decoded off the main
thread), pui (drawn by `pui.Pictures` through the platform), qui (a QML `Image`
whose `alt` is a `Label` inside it), cui (no pixels yet: it draws the `alt` in
brackets, and Sixel is what will change that).

## Icon

A glyph from the shared vocabulary, drawn with the platform's own icons and
coloured like the text around it.

```haxe
new Icon(Mic)
new Icon(SpeakerOff, "Monitor muted")
```

**Constructor**: `Icon(name:IconName, ?label:String)`. `IconName` has one constant per
name of `nui.Icons` — `mic-off` is `MicOff` — and no conversion from `String`, so a
name outside the vocabulary does not compile. `IconName.fromString` reads one that
arrives as data. The label is what a screen reader says; without one, the name.

**Where it is**: all six, each with what its platform draws — sui (SF Symbols),
wui (Segoe Fluent Icons), aui (Material icons, the ones `material-icons-core`
lacks carried as path data), pui and qui (the shapes of `nui.IconShapes`, filled
with the non-zero rule so their holes stay holes), cui (one character per name,
an `-off` name stroked in the same cell).

`mui.ui.Button` takes one too, as a third optional argument — see **Button**
above. aui, wui, cui and pui draw it; sui and qui draw the label, neither having
a verified place for an icon inside a button.
