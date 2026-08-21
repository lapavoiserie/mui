# Adding a Backend

Adding a backend touches **no file in this repository**. The backend declares its own conformance under a `mui` package of its own, and `mui` resolves it by name through [`mui.Contract`](https://github.com/lapavoiserie/mui/blob/main/src/mui/Contract.hx) and `mui.macros.Bind`.

## Backend Requirements

A backend library must provide:

1. **`App` base class** with `@:autoBuild` StateMacro, `body():View` override,
   and **`@:hostedRoles(...)`** — the surface roles this backend actually
   mounts (see below)
2. **`View` base class** with modifier methods (padding, font, foregroundColor, etc.)
3. **`ViewComponent`** extending View with its own `body()`
4. **`state/State<T>`** extending [`rui.state.State`](https://lapavoiserie.github.io/rui/#/state) — see below
5. **`state/Binding<T>`** with `.get()` and `.set()`
6. **UI components** in a `ui/` package: Text, VStack, HStack, Button, Spacer, etc.

### Stating what you host

`@:hostedRoles` on your `mui.App` is not documentation, it is the check:
`mui.macros.Surfaces` reads it and refuses, at compile time, any
`@:surface(Role)` declaration your backend has no host for — naming the role,
you, and what you do host. Start honest and empty; widen it the day a host
lands, never to quiet a build.

```haxe
@:hostedRoles(Commands, Companion)
@:autoBuild(mui.macros.Surfaces.build())
@:autoBuild(yourbackend.macros.StateMacro.build())
class App extends yourbackend.App { … }
```

List `Companion` only if you install a `mui.surface.Describe` implementation
in your `App` constructor — that is what a projection needs. It states a
capability, not an appetite: the networked corner stays off in any build that
has not set `-D mui_cafos`.

A backend that states nothing at all is not refused — the application whose
build would stop did nothing wrong — but every application built against it
gets a warning saying its surfaces cannot be checked. That warning is aimed
at you.

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

### 3. Ship a build template

`mui init` writes a `build-<backend>.hxml` for every installed backend, and it
gets each one from the backend. Put yours at `<backend>/mui/init.hxml`, beside
the rest of your conformance; `$MAIN` is substituted with the project's main
class.

A library that ships that file **is** a backend as far as `mui init` is
concerned. There is no list of names to be added to, and a seventh appears in a
scaffolded project the moment it is installed.

### 4. Say whether your engine owns the process

If `run()` blocks and nothing may follow it — as on `cui` and `pui` — put
`@:muiOwnsMain` on your `mui.App`. `mui.macros.Bind` turns that into the
`mui_owns_main` flag, so an application writes its `main()` once:

```haxe
static function main() {
	#if mui_owns_main
	new MyApp().run();
	#end
}
```

Examples used to write `#if (mui_backend == "cui" || mui_backend == "pui")` —
a list a seventh backend would have had to be added to by hand, in every
application.

### 5. Register a markup vocabulary, if you have one

`ui()` markup is checked against the target's schema, and a macro cannot call a
function it was only handed the *name* of. So this one part is registered rather
than resolved — by the backend, from its own build file:

```
--macro gtk.nui.Vocabulary.registerWithMui()
```

That function hands `mui.macros.Backend.register` five closures. A backend that
registers none cannot be markup-checked, and `ui()` refuses to compile rather
than waving `<Hologramme/>` through.

### What still names a backend here

Two things, both in `tools/`, neither a binding:

| File | Why |
|---|---|
| `tools/BackendMatrix.hx` | it *is* a table across backends — a report, not a resolution |
| `tools/cli/Watch.hx` | which reload a backend can do is not something its CLI can be asked; guessing wrong means watching a host that never reloads |
| `tools/cli/Build.hx` | one line: `sui` reads a `sui.json` beside the build file |

`src/` names none. Building and running delegate to `haxelib run <backend>
build|run` for every backend — `cui` grew those two commands so that it could be
delegated to like the rest, instead of `mui` remembering that cui is the one
that compiles straight.

## Why it is this way round

`mui` used to adapt to each backend, which meant `mui` had to know all six of
them — and adding a seventh meant editing twenty-two files in a repository that
had nothing to learn from it. Of the 132 `#if` branches, 109 were a `typedef` or
a five-line `extends`.

The volume was never the problem. The direction was. Inverted, adding a backend
touches **zero** files here, and a backend can be released without waiting for
one.
