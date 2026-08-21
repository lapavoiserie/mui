# Surfaces

An application is not one render root. It has a main window — and, depending on
the platform, a cover, a widget, a settings scene, a menu bar. mui calls each of
those an **app surface**, and lets an application declare them portably: the
declaration is shared, each backend maps it onto the surface its platform
actually has, and a role a backend cannot honour degrades to a silent no-op.

> **Status.** The vocabulary is implemented and checked, and hosts exist
> across the family — all validated on their platforms:
>
> | Role | Where it lives today |
> |---|---|
> | `Primary` | everywhere — it is `body()` |
> | `Glance` | Sailfish: the cover, live-mounted by `qui.mui.CoverHost` |
> | `Preferences` | macOS: the Settings scene (⌘,), a second live root |
> | `Commands` | macOS: the menu bar (with derived shortcuts); terminal: key bindings; Windows: the MenuBar, injected as ordinary nodes |
> | `Auxiliary` | Windows and macOS: real extra windows, one per declaration, each with its own lifetime |
> | `Companion` | any machine on the CAFOS network — see below |
> | `Notification` | not yet — waits for the detached subsystem |
>
> A role with no host on a backend still degrades to a silent no-op:
> declaring is safe everywhere.

## Declaring a surface

Mark a method with `@:surface(Role)`. The method is the surface's content; the
method's *name* is the surface's stable id.

```haxe
class TodoApp extends mui.App {
	@:state var todos:ImmutableList<Todo> = ImmutableList.empty();

	override function body():View { … }          // Primary — implicit, required

	// The Sailfish cover, an iOS widget… "today" is the id.
	@:surface(Glance)
	function today():View {
		return new VStack([
			new Text("Todos", Title),
			new Text('${remaining()} left'),
		]);
	}

	@:surface(Commands)
	function shortcuts():Array<Command> {
		return [new Command("New todo", focusNew).key("ctrl+n")];
	}
}
```

Declare as many surfaces of a role as the application wants — an iOS
application offers several widgets. Renaming a method is a compatibility event
(the id is identity); pin the id across a rename with
`@:surface(Glance, "today")`.

## Roles

| Role | Means | Examples |
|---|---|---|
| `Primary` | The main window. Implicit — it is `body()`. | everywhere |
| `Glance` | A read-at-a-glance summary. | Sailfish cover, iOS/Android widget |
| `Preferences` | The platform's settings surface. | macOS Settings scene |
| `Commands` | Named commands. | menu bar, key bindings |
| `Notification` | A system notification. *No declaration form yet.* | — |
| `Auxiliary` | Another top-level window. | desktop platforms |
| `Companion` | A companion device. *No backend maps it yet.* | — |

## What is checked, and where

- **A declaration is a view.** It runs inside its surface's own effect, so it
  reads under the same rule as `body()`: immutable or observable only, and no
  raw `rui.Signal` — `@:state` instead. Refused at compile time, naming the
  field.
- **Return types, per role.** A `Glance` method returns `View`; a `Commands`
  method returns `Array<mui.surface.Command>`. The typer refuses a mismatch at
  the method.
- **`@:surface(Primary)`** is refused: Primary is `body()`.
- **`@:surface(Notification)`** is refused until the detached-surface
  subsystem brings the contract it needs.
- **Duplicate role/id pairs** are refused, including against superclasses.

## Under the sugar

The framework consumes one thing: `surfaces():Array<SurfaceDecl>` — a list of
`Tree(role, id, () -> View)` and `CommandSet(id, () -> Array<Command>)`.
`@:surface` methods are collected into it by `mui.macros.Surfaces` (each
backend's `mui.App` carries the `@:autoBuild`). Declaring past the sugar is
overriding the list:

```haxe
override function surfaces():Array<SurfaceDecl> {
	return super.surfaces().concat([
		Tree(Auxiliary, "inspector", () -> inspectorWindow()),
	]);
}
```

`mui.Contract` requires `surfaces` of every backend, next to `lifetime`.

## Companion: a surface on another machine

A `@:surface(Companion)` declaration is not rendered by this process at all:
it is *projected* — over the local [CAFOS](../../cafos/) agent — onto whatever
machine serves a surface of that id, and rendered there by that machine's own
renderer. The remote taps come back as action ids and run your closures; ids
are stable by place, so a tap racing a re-render does what the unchanged
button says.

```haxe
@:surface(Companion)
function panel():View {
	return new VStack([
		new Text('count: ${count.get()}'),
		new Button("Add", () -> count.set(count.get() + 10)),
	]);
}

// once, after construction (the app opts into the transport):
var projector = cafos.mui.CompanionServe.serve(app);
app.lifetime.own(() -> projector.stop());
```

Reading state inside the method keeps the remote surface live — the same rule
as every other surface. The machinery underneath: the backend's **describer**
(`mui.surface.Describe`, installed by each backend's `mui.App`) turns views
into canonical `nui.Node`s; `nui.Snapshot` ships them as pure data with
closures replaced by table ids; the far side inflates and renders with any
backend's `NodeRenderer`. See nui's *Snapshot* page and cafos's *nui-wire*
page for the contracts.

## The describer

Serving detached surfaces (Companion today, widget snapshots in P4a) needs
the backend's views as `nui.Node` data. Each backend installs its describer
on `mui.surface.Describe.impl` at `mui.App` construction, emitting the
**canonical prop names** (`text`, `label`/`onClick`, `isOn`/`onToggle`,
`value`/`min`/`max`/`onValue`, `text`/`placeholder`/`onText`) so a tree
served from any backend looks the same on the wire. A backend without a
describer degrades with a word: the declaration never projects.

## Degradation

Roles degrade per backend, deliberately and visibly: a terminal has no cover,
so a `Glance` declaration is never mounted there — no error, no placeholder.
When a platform can mount only one surface of a role (the Sailfish cover) and
several are declared, the host takes the role's default id (`"glance"`) if
declared, else the first declaration. Roles with `Many` cardinality (widgets,
auxiliary windows, companions) mount every declaration, in declaration order.
Each backend's answers are stated by its surface hosts' `capabilities()`
(`mui.surface.SurfaceHost`), the same way component support is stated by
`@:muiSupport` in the [backend support table](backend-support.md).
