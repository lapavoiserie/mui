# Surfaces

An application is not one render root. It has a main window — and, depending on
the platform, a cover, a widget, a settings scene, a menu bar. mui calls each of
those an **app surface**, and lets an application declare them portably: the
declaration is shared, each backend maps it onto the surface its platform
actually has, and a role a backend cannot honour degrades to a silent no-op.

> **Status.** This page describes the *declaration* vocabulary, which is
> implemented and checked. No backend mounts a declared surface yet — the first
> host (the Sailfish cover) is the next step. Declaring today is safe
> everywhere: it compiles, it is checked, and it renders nothing extra.

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

## Degradation

Roles degrade per backend, deliberately and visibly: a terminal has no cover,
so a `Glance` declaration is never mounted there — no error, no placeholder.
When a platform can mount only one surface of a role (the Sailfish cover) and
several are declared, the host takes the role's default id (`"glance"`) if
declared, else the first declaration. The per-backend answers will be stated
by each backend's surface host capabilities as hosts land, the same way
component support is stated by `@:muiSupport` in the
[backend support table](backend-support.md).
