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

The `@:state` macro (inherited from the backend's `App` class) turns the field
into two things at compile time: a reactive **cell** — the backend's `State<T>`
— named with a trailing underscore, `count_`, and a **property** under the
field's own name that forwards to it. You write `count`; the cell does the
work.

## Reading and Writing

A `@:state` field reads and writes like the plain field it was declared as:

```haxe
// Read: subscribes the view (or effect) that reads it
var c = count;

// Write: notifies, reaches the platform, reaches the durable store
count = 5;
count += 1;
count++;
```

Nothing about *when* anything happens is different from the cell's own
`get()` and `set()` — the property is those two calls, spelled as a field.

## The cell: `count_`

Some things want the cell itself rather than its value: a control that binds
two ways, a durable store, an untracked read. That is what the underscore
name is for:

```haxe
<Toggle label="Dark Mode" isOn={darkMode_}/>   // the cell, so the toggle can write back
count_.peek();                         // an untracked read, said out loud
```

`darkMode_` is one character from `darkMode`, and it is the same convention
on every backend: Swift writes `$dark` for this; Haxe has no `$` in an
identifier, so the cell is the name with a trailing underscore. See
[`rui.macros.StateProperty`](https://lapavoiserie.github.io/rui/#/state) for
why a property, and why that spelling.

## State in UI

```haxe
override function body():View {
    return ui(<VStack spacing={8}>
        <Text text={"Count: " + count}/>
        <Button label="Increment" onClick={() -> count += 1}/>
    </VStack>);
}
```

Reading `count` inside `body()` subscribes the view: write to it and that view
is told. A field that is neither `@:state`, `final` nor immutable is **refused
at compile time** and named — a value the view cannot observe is a screen that
quietly goes stale.

## State in Bindings

Toggle and TextInput take the **cell** — the value alone could not tell them
where to write back:

```haxe
@:state var darkMode:Bool = false;
@:state var username:String = "";

<Toggle label="Dark Mode" isOn={darkMode_}/>
<TextInput text={username_} placeholder="Username"/>
```

See [Bindings](bindings.md) for details.

## Shared cells

A cell may be shared with another device running the same application,
with one owner per cell: `@:state(shared(Phone)) var goal:Int`. The owner's
writes replicate; a peer's write becomes an intent the owner applies; a
plain `@:state` never leaves the device. `@:intent(Party)` marks a method
that runs on one party whoever calls it. The rule is `rui.state.Shared`,
the wire is `dui.state.Share`, and the page is
[owned state](https://lapavoiserie.github.io/dui/#/owned-state) in dui.

## The shared core

Every backend's `State<T>` extends
[`rui.state.State`](https://lapavoiserie.github.io/rui/#/state) — the reactive core all
six backends share. So this much behaves **identically** whichever `-D mui_backend`
you select — on the property, and on the cell behind it:

| | |
|---|---|
| `count` — the cell's `get()` / `value` | tracked read — registers a dependency inside an `Effect` |
| `count = v` — the cell's `set(v)` / `value = v` | write — re-runs dependent effects, then the platform |
| `count_.peek()` | untracked read |
| `count_.applyExternal(v)` | a write coming *from* the platform: effects only, no echo back |
| `count_.name` | the state's identifier |

`State` stays dispatched per backend rather than collapsing into `rui.state.State`, because
each backend still has a platform half to run on a write: `cui` raises its redraw flag, `sui`
mirrors into Swift's `AppState`, `aui` into a Compose `MutableState`. What is shared is the
reactive half and the contract — not the platform half.

Two things *are* shared outright, since they need no platform half:

```haxe
import mui.state.Signal;              // Signal, Effect, Scheduler
import mui.structures.ImmutableList;  // persistent list

var count = new Signal(0);
new Effect(() -> trace("count = " + count));  // runs now, and on change
count = 1;
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
| `count_.inc(n)` | -- | Yes | Yes | Yes* | Yes* | Increment (a `StateAction` on wui/aui, void on cui/qui) |
| `count_.dec(n)` | -- | Yes | Yes | Yes* | Yes* | Decrement (same split) |
| `count_.tog()` | -- | Yes | Yes | -- | -- | Toggle boolean (returns a `StateAction`) |
| `count_.toggle()` | -- | -- | -- | Yes | Yes | Toggle boolean (void) |
| `count_.setTo(v)` | -- | Yes | Yes | Yes | Yes | Returns a `StateAction` on wui/aui, the state itself on cui/qui |
| `count_.subscribe()` | -- | Yes | -- | -- | -- | Register a change listener |
| `count_.onValueChanged()` | Yes | -- | -- | -- | -- | Change callback, whichever side wrote |

*`IntState`/`FloatState` on cui and qui have `.inc()`/`.dec()` that mutate directly (void return).
The portable spelling of all of these is the property: `count++`, `count--`,
`dark = !dark`, `count = 0`.
