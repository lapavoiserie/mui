# Adding a Backend

mui is designed for extensibility. Adding a new backend (e.g., `gtk` for Linux) involves ~20 files with mechanical changes.

## Backend Requirements

A backend library must provide:

1. **`App` base class** with `@:autoBuild` StateMacro and `body():View` override
2. **`View` base class** with modifier methods (padding, font, foregroundColor, etc.)
3. **`ViewComponent`** extending View with its own `body()`
4. **`state/State<T>`** extending [`rui.state.State`](https://lapavoiserie.github.io/rui/#/state) — see below
5. **`state/Binding<T>`** with `.get()` and `.set()`
6. **UI components** in a `ui/` package: Text, VStack, HStack, Button, Spacer, etc.

### What comes from the shared libraries

Two of these are not yours to reinvent:

- **State.** `state/State<T>` must extend
  [`rui.state.State`](https://lapavoiserie.github.io/rui/#/state), which gives you
  `get`/`value`/`set`/`peek`/`applyExternal`/`name` and the reactive half for
  free. You add only the *platform half*: register a sink with
  `setPlatformSink(...)` to push a new value to the native side, and route writes
  arriving *from* the platform through `applyExternal` so they reach Haxe effects
  without being echoed back.
- **The view tree.** How a node is described — type, children, key, typed
  properties, ordered modifiers, actions — and how a renderer consumes it, is
  [`nui`](https://lapavoiserie.github.io/nui/). It offers two contracts, and which
  one you implement is decided by your host, not by preference. The question that
  settles it is **does the host preserve widget state across a rebuild?** —
  **push** (`Node` + `NodeSink`) when it does and must be patched, like Qt or
  WinUI; **pull** (`NodeSource`) when it does not, whether because it re-renders
  on its own like SwiftUI and Compose, or because it has no widget state at all
  and repaints from a freshly walked tree, like `cui` and `pui`. See
  [Adopting nui](https://lapavoiserie.github.io/nui/#/adopting).

  This page used to file "a terminal" under push. That was wrong on the criterion
  above, and both backends that draw their own widgets implement pull.

## Steps

### 1. Add `#elseif` blocks

Each mui source file needs a new `#elseif (mui_backend == "gtk")` block. Example for `mui/View.hx`:

```haxe
#elseif (mui_backend == "gtk")
typedef View = gtk.View;
```

For components with constructor normalization (VStack, HStack, Button, etc.), adapt the constructor:

```haxe
#elseif (mui_backend == "gtk")
class VStack extends gtk.ui.VStack {
    public function new(content:Array<gtk.View>, ?spacing:Float) {
        super(content, spacing);
    }
}
```

### 2. Add binding abstracts

In `ToggleBinding.hx`:

```haxe
#elseif (mui_backend == "gtk")
abstract ToggleBinding(gtk.ui.Switch.SwitchBinding) {
    @:from static function fromState(s:gtk.state.State<Bool>):ToggleBinding
        return cast gtk.ui.Switch.SwitchBinding.fromState(s);
    public inline function unwrap():gtk.ui.Switch.SwitchBinding return this;
}
```

Same pattern for `TextInputBinding.hx`.

### 3. Add color/font mappings

In `mui/enums/ColorValue.hx`, add a `toBackend()` case:

```haxe
#elseif (mui_backend == "gtk")
public function toBackend():gtk.Color {
    return switch (cast this : ColorValueKind) {
        case Red: gtk.Color.Red;
        // ... map all values
    };
}
```

Same for `FontStyle.hx` and `Alignment.hx`.

### 4. Add ForEach macro path

In `mui/macros/ForEachMacro.hx`, add the backend case. For runtime backends (like cui/wui), this is typically one line:

```haxe
case "gtk":
    return macro new gtk.ui.ForEach($items, $builder);
```

### 5. Add CLI support

In `tools/cli/Build.hx` and `Run.hx`, add a case for the new backend.

### 6. Add App class

In `mui/App.hx`, add the `#elseif` block extending the backend's App class.

## Files to Modify

| File | Change |
|------|--------|
| `mui/View.hx` | typedef |
| `mui/App.hx` | class extending backend App |
| `mui/ViewComponent.hx` | typedef |
| `mui/state/State.hx` | typedef |
| `mui/state/Binding.hx` | typedef |
| `mui/state/Observable.hx` | typedef |
| `mui/state/StateAction.hx` | typedef or stub |
| `mui/state/AnimationCurve.hx` | typedef or stub |
| `mui/ui/*.hx` (14 files) | subclass or typedef |
| `mui/ui/ToggleBinding.hx` | @:from abstract |
| `mui/ui/TextInputBinding.hx` | @:from abstract |
| `mui/enums/ColorValue.hx` | toBackend() mapping |
| `mui/enums/FontStyle.hx` | toBackend() mapping |
| `mui/enums/Alignment.hx` | toBackend() mapping |
| `mui/macros/ForEachMacro.hx` | backend case |
| `tools/cli/Build.hx` | build case |
| `tools/cli/Run.hx` | run case |
