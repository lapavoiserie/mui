# Adding a Backend

Adding a backend touches **no file in this repository**. The backend declares its own conformance under a `mui` package of its own, and `mui` resolves it by name through [`mui.Contract`](https://github.com/lapavoiserie/mui/blob/main/src/mui/Contract.hx) and `mui.macros.Bind`.

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

Nothing here is edited. A backend declares its own conformance, and `mui`
resolves it by name.

### 1. Write `<backend>.mui.*`

One file per entry in [`mui.Contract`](https://github.com/lapavoiserie/mui/blob/main/src/mui/Contract.hx),
in your own repository, under a `mui` package. A `typedef` when the signature
already matches, a small subclass when it does not:

```haxe
package gtk.mui;

typedef View = gtk.View;
```

```haxe
package gtk.mui;

class VStack extends gtk.ui.VStack {
	public function new(content:Array<gtk.View>, ?spacing:Float) {
		super(content, spacing == null ? 8 : spacing);
	}
}
```

Two types come the other way, and they are the only two: `mui.ui.TextScale` and
`mui.ui.TabItem`. They exist because they are what the backends had to *agree*
on, not what any one of them provides.

### 2. Run the macro from your build file

```
-D mui_backend=gtk
--macro mui.macros.Bind.all()
```

That is the whole wiring. `Bind` defines `mui.View`, `mui.ui.Button` and the
rest as aliases onto `gtk.mui.*`, then checks each constructor against the
contract — arity, optionality and argument types — and names what does not
match:

```
gtk.mui.HStack argument 2 is Int, mui.Contract says Float
gtk.mui.VStack argument 2 is optional, mui.Contract says it is required
Type not found : gtk.mui.Carousel
```

You may add **trailing optional arguments** the contract does not name. `cui`
does: its `ScrollView` and `TabView` let the application own the offset and the
selection, because a terminal keeps neither for you. Code written against the
contract still compiles.

You may leave out an entry marked optional in the contract. Exactly one is: a
terminal cannot draw an image, so `cui` provides no `cui.mui.Image`, and
`mui.ui.Image` does not exist there.

### 3. What is still shared, and still needs a case

The inversion covers the view vocabulary. Four things in `mui` still name
backends, and adding one means editing them:

| File | Change |
|------|--------|
| `mui/macros/ForEachMacro.hx` | a `case "gtk":` producing the backend's loop |
| `mui/macros/Backend.hx` | the backend's name, for `Backend.name()` |
| `mui/enums/{ColorValue,FontStyle,Alignment}.hx` | a `toBackend()` mapping |
| `mui/state/*.hx` | typedefs — and `qui` and `pui` have none today |
| `tools/cli/{Build,Run}.hx` | a build and run case |

These are the next candidates for the same treatment. They were left alone
deliberately: the view vocabulary was 132 of the branches, and inverting it
first is what proves the mechanism on the part that matters.

## Why it is this way round

`mui` used to adapt to each backend, which meant `mui` had to know all six of
them — and adding a seventh meant editing twenty-two files in a repository that
had nothing to learn from it. Of the 132 `#if` branches, 109 were a `typedef` or
a five-line `extends`.

The volume was never the problem. The direction was. Inverted, adding a backend
touches **zero** files here, and a backend can be released without waiting for
one.
