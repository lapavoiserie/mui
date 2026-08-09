# Components

A component is a reusable piece of view. There are two ways to write one, and
the difference is whether it needs **state of its own**.

## A method, when it has no state

If the piece is a function of its arguments, a method returning `View` is all it
takes. Nothing to extend, nothing to register, and it works on every backend.

```haxe
function row(title:String, value:String):View {
    return new HStack([
        new Text(title),
        new Spacer(),
        new Text(value)
    ]);
}
```

## `ViewComponent`, when it has state

When the piece owns state the rest of the app should not see, extend
`mui.ViewComponent` and override `body()`:

```haxe
import mui.ViewComponent;

class Counter extends ViewComponent {
    @:state var n:Int = 0;
    public var label:String;

    public function new(label:String) {
        super();
        this.label = label;
    }

    override public function body():View {
        return new HStack([
            new Text(label + ": " + n.get()),
            new Button("+", n.inc())
        ]);
    }
}
```

Used like any other view:

```haxe
override public function body():View {
    return new VStack([
        new Text("Above"),
        new Counter("clicks")
    ]);
}
```

`mui.ViewComponent` resolves to the backend's own, so the component you write is
the backend's component — there is no `mui` layer to pay for at runtime.

## What each backend does with it

A component has no rendering of its own: it is *expanded* into whatever `body()`
returns. **How** that expansion happens differs, and so does what it costs you.

| Backend | How a component is rendered | Notes |
|---|---|---|
| `sui` | a separate SwiftUI struct, generated | `@:binding` fields become `@Binding var` |
| `wui` | a separate C++/WinRT construction function | |
| `cui` | expanded at draw time — `measure`/`render` delegate to `body()` | |
| `aui` | expanded by the tree reader, **on the dynamic path only** | `-D aui_dynamic`; the static path refuses, with a message |

The `aui` exception is worth stating plainly: its static path emits Kotlin ahead
of time and would need to produce a composable carrying the component's own
state, which it does not do. Building a component without `-D aui_dynamic` is a
compile error that says so.

## What a component is not

**It is not a new node type.** Composing views `mui` provides is unlimited;
introducing a *new kind of leaf* — one that maps to a native widget nothing else
produces — is a change to the backend, not to your app.

That distinction matters more here than in a single-platform framework: a new
leaf has to exist on **every** backend you build for, or the code that uses it
stops being write-once. Check what each one actually provides in
[Backend support](backend-support.md).
