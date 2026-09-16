# Controls

## Button

A clickable button with a label and action.

```haxe
new Button("Click me", function() {
    count += 1;
})
```

**Constructor**: `Button(label:String, ?action:()->Void)`

All backends are normalized to accept closures. On backends that natively use `StateAction` (sui, wui), the closure is wrapped appropriately.

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

Maps to `Picker` (sui) and `ComboBox` (wui). **Not yet on aui, cui, qui or pui**:
`mui.Contract` marks it optional while it reaches every backend, so using it there
is a compile error at that line.

On the wire it is a canonical `Picker` node: `label`, `selectedIndex`, `onSelect`
(an index), and one `Text` child per option. A received selection is not applied
while the list is open.

## Image

Displays an image (not available on cui).

```haxe
new Image("photo.png")
```

**Constructor**: `Image(source:String)`

`cui` provides no `Image`: a terminal cannot draw one, and `mui.Contract` marks
the entry optional, so `mui.ui.Image` does not exist there. Using it on that
backend is a compile error at the line that used it — which is the rule this
ecosystem follows, that what can be known at compile time is never a marker on
screen. Guard with `#if (mui_backend != "cui")` in code meant for every
backend.
