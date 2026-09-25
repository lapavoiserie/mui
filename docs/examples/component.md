# A component of your own

A reusable piece of interface, with arguments from whoever places it and state
of its own. Here: one source's row in a mixer — its name, its level, and a mute
button that nobody outside needs to know about.

## The component

```haxe
import mui.macros.Markup.ui;

/**
    One source's row: its name, its level, and a mute button that remembers
    nothing but its own state.
**/
class Gauge extends mui.ViewComponent {
    /** What the row is called. Given by whoever places it. **/
    public final label:String;

    /** The level to show, 0 to 1. **/
    public final level:Float;

    /** Muted or not — the component's own, nobody else's. **/
    @:state var muted:Bool = false;

    public function new(label:String, level:Float) {
        super();
        this.label = label;
        this.level = level;
    }

    override public function body():mui.View {
        return ui(<HStack spacing={8}>
            <Text text={label}/>
            <Spacer/>
            <ProgressView value={muted ? 0.0 : level}/>
            <Button label={muted ? "Unmute" : "Mute"} onClick={() -> muted = !muted}/>
        </HStack>);
    }
}
```

Four things, and each is a rule rather than a habit:

**It extends `mui.ViewComponent`** — not `mui.App`, which is the whole
application, and not nothing at all. That is what gives it `@:state` and a
`body()` the backend knows how to expand.

**Its arguments are `final`.** A view may only read what is immutable or
observable; a plain `var label` would be **refused at compile time**, naming
the field, because nothing could tell the row it changed. See
[State](../state/README.md).

**Its own state is `@:state`.** `muted` belongs to this row. The screen around
it neither declares it nor knows it exists, and two rows have one each.

**Its `body()` is markup**, checked against the backend like any other view.

## Using it

A component is a view: put it in with braces.

```haxe
class Mixer extends mui.App {
    final sources = [{name: "Camera 1", level: 0.7}, {name: "Camera 2", level: 0.3}];

    override function body():mui.View {
        return ui(<VStack spacing={8}>
            <Text text="Mixer" scale="title"/>
            {[for (source in sources) ui(<VStack key={source.name}>
                {new Gauge(source.name, source.level)}
            </VStack>)]}
        </VStack>);
    }

    static function main() {
        #if mui_owns_main
        new Mixer().run();
        #end
    }
}
```

Each class goes in a file of its own — `Gauge.hx`, `Mixer.hx` — as Haxe asks.

Drawn into a terminal by `cui`, before a mute:

```
Mixer

Camera 1       ██████████████████▎░░░░░░░ 70% [ Mute ]

Camera 2       ███████▉░░░░░░░░░░░░░░░░░░ 30% [ Mute ]
```

Press one row's button and that row alone changes: `muted` is its own cell, and
the other `Gauge` never reads it.

## The key is on the row, not on the component

`key={source.name}` sits on the `VStack` the comprehension makes, because that
is the child whose **place** moves when the list is sorted or filtered. A
component with no key inside a keyed row is fine; a keyed row with none is the
case where a reordering hands one row's state to another. See
[Markup](../markup.md#a-key-for-rows-that-move).

## When you do not need a component

If the piece is a function of its arguments and remembers nothing, a method
returning a view is all it takes — no class, no state, nothing to place:

```haxe
function row(title:String, said:String):mui.View {
    return ui(<HStack spacing={8}>
        <Text text={title}/>
        <Spacer/>
        <Text text={said}/>
    </HStack>);
}
```

and it goes in the same way: `{[row("Codec", "ProRes"), row("Rate", "50p")]}`.

[Components](../components.md) has the rest: what each backend does with one,
and what a component is *not*.
