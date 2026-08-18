# State Management

mui uses the backend's reactive state system. Declare state with `@:state` and the UI re-renders automatically when values change.

## Declaring State

```haxe
class MyApp extends App {
    @:state var count:Int = 0;
    @:state var name:String = "";
    @:state var active:Bool = false;
}
```

The `@:state` macro (inherited from the backend's `App` class) transforms fields into reactive `State<T>` wrappers at compile time.

## Reading and Writing

All backends support both `.get()`/`.set()` and `.value`:

```haxe
// Read
var c = count.get();
var c = count.value;      // equivalent

// Write
count.set(5);
count.value = 5;          // equivalent
```

Use whichever style you prefer. Both work on all backends.

## State in UI

```haxe
override function body():View {
    return new VStack([
        new Text('Count: ${count.get()}'),
        new Button("Increment", function() count.set(count.get() + 1)),
    ]);
}
```

## State in Bindings

Toggle and TextInput accept `@:state` fields directly:

```haxe
@:state var darkMode:Bool = false;
@:state var username:String = "";

new Toggle("Dark Mode", darkMode),      // auto-converted via ToggleBinding
new TextInput("Username", username),     // auto-converted via TextInputBinding
```

See [Bindings](state/bindings.md) for details.

## The shared core

Every backend's `State<T>` extends
[`rui.state.State`](https://lapavoiserie.github.io/rui/#/state) — the reactive core all
six backends share. So this much behaves **identically** whichever `-D mui_backend`
you select:

| | |
|---|---|
| `get()` / `value` | tracked read — registers a dependency inside an `Effect` |
| `set(v)` / `value = v` | write — re-runs dependent effects, then the platform |
| `peek()` | untracked read |
| `applyExternal(v)` | a write coming *from* the platform: effects only, no echo back |
| `name` | the state's identifier |

`State` stays dispatched per backend rather than collapsing into `rui.state.State`, because
each backend still has a platform half to run on a write: `cui` raises its redraw flag, `sui`
mirrors into Swift's `AppState`, `aui` into a Compose `MutableState`. What is shared is the
reactive half and the contract — not the platform half.

Two things *are* shared outright, since they need no platform half:

```haxe
import mui.state.Signal;              // Signal, Effect, Scheduler
import mui.structures.ImmutableList;  // persistent list

var count = new Signal(0);
new Effect(() -> trace("count = " + count.value));  // runs now, and on change
count.value = 1;
```

Use `Signal` for reactive state that is not bound to a view — a queue length a worker
watches, a value two effects coordinate on. **Not in `body()`**: a raw `Signal` notifies
its subscribers, but on the backends that rebuild from their own dirty flag nothing
subscribes the view tree, so the screen would quietly never update. The compiler refuses
the read and names the field; what a view displays is declared `@:state`, which carries
the platform half. Use `ImmutableList` for a collection held in a state — a write only
notifies when the value *changes*, compared with `!=`, so mutating an array in place is
invisible while a new instance is not.

## Backend-Specific Methods

Everything above is portable. The methods below are **not** part of the contract — the
backends disagree on them, so an app that uses them stops being portable:

| Method | sui | wui | aui | cui | qui | Description |
|--------|-----|-----|-----|-----|-----|-------------|
| `.inc(n)` | -- | Yes | Yes | Yes* | Yes* | Increment (a `StateAction` on wui/aui, void on cui/qui) |
| `.dec(n)` | -- | Yes | Yes | Yes* | Yes* | Decrement (same split) |
| `.tog()` | -- | Yes | Yes | -- | -- | Toggle boolean (returns a `StateAction`) |
| `.toggle()` | -- | -- | -- | Yes | Yes | Toggle boolean (void) |
| `.setTo(v)` | -- | Yes | Yes | Yes | Yes | Returns a `StateAction` on wui/aui, the state itself on cui/qui |
| `.subscribe()` | -- | Yes | -- | -- | -- | Register a change listener |
| `.onValueChanged()` | Yes | -- | -- | -- | -- | Change callback, whichever side wrote |

*`IntState`/`FloatState` on cui and qui have `.inc()`/`.dec()` that mutate directly (void return).
