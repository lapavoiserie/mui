# Components

A component is a reusable piece of view. There are two ways to write one, and
the difference is whether it needs **state of its own**.

## A method, when it has no state

If the piece is a function of its arguments, a method returning `View` is all it
takes. Nothing to extend, nothing to register, and it works on every backend.

```haxe
function row(title:String, value:String):View {
    return ui(<HStack spacing={8}>
        <Text text={title}/>
        <Spacer/>
        <Text text={value}/>
    </HStack>);
}
```

and it goes into a view like any other list of children:

```haxe
<VStack spacing={4}>
    {[row("Codec", "ProRes"), row("Rate", "50p")]}
</VStack>
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
        return ui(<HStack spacing={8}>
            <Text text={label + ": " + n}/>
            <Button label="+" onClick={() -> n += 1}/>
        </HStack>);
    }
}
```

Used like any other view — in markup, spliced in with braces:

```haxe
override public function body():View {
    return ui(<VStack spacing={8}>
        <Text text="Above"/>
        {new Counter("clicks")}
    </VStack>);
}
```

or by hand:

```haxe
return new VStack([new Text("Above"), new Counter("clicks")]);
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
| `aui` | expanded by the tree reader, on the device | |
| `pui` | it splices: the component is replaced by its `body()` | it cannot fill its children in its own constructor, because a subclass's fields are not set until `super()` has returned |

There is no exception left to state: `aui` used to render through a compile-time
Kotlin transpiler, which would have needed a composable carrying the component's
own state and did not produce one. That path is
[decommissioned](https://lapavoiserie.github.io/aui/#/render-paths) and `aui`
renders through its tree reader, where a component is expanded like everywhere
else.

## A worked example

[A component of your own](examples/component.md) builds one end to end — a
mixer row with a label, a level and a mute button of its own — and shows it
drawn.

## What a component is not

**It is not a new node type.** Composing views `mui` provides is unlimited;
introducing a *new kind of leaf* — one that maps to a native widget nothing else
produces — is a change to the backend, not to your app.

That distinction matters more here than in a single-platform framework: a new
leaf has to exist on **every** backend you build for, or the code that uses it
stops being write-once. Check what each one actually provides in
[Backend support](backend-support.md).
