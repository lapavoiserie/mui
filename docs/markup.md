# Markup

**This is how a user interface is written in `mui`.** Everything else on this
page is detail.

```haxe
import mui.macros.Markup.ui;

class Counter extends mui.App {
    @:state var count:Int = 0;

    override function body():mui.View {
        return ui(<VStack spacing={8} padding={{top: 16.0, right: 16.0, bottom: 16.0, left: 16.0}}>
            <Text text={"Count: " + count} scale="title"/>
            <HStack spacing={8}>
                <Button label="−" onClick={() -> count -= 1}/>
                <Button label="+" onClick={() -> count += 1}/>
            </HStack>
        </VStack>);
    }
}
```

That source compiles for every backend, and each draws it with its own
controls: a SwiftUI `Button` on macOS, a Material one on Android, `[ + ]` in a
terminal.

## It is checked while you compile

`-D mui_backend` names the backend, and `ui()` asks **that backend's own
declarations** what exists. A tag nothing declares, an attribute a control does
not carry, a decoration it cannot draw: each is refused by name, with the
accepted set in the message, before the program runs.

```
"Tappable" n'a pas d'attribut "onTap".
  Attributs acceptés : label, onClick.
```

There is no `?Button` drawn on a screen for something you typed. See
[written, assembled, received](#written-assembled-received) for where that rule
stops applying, and why.

## The build file

`mui init` writes one per installed backend, and each already carries the two
lines markup needs:

```
--macro pui.nui.Vocabulary.registerWithMui()
-D mui_views
```

The first is what `ui()` checks against. The second makes it build that
backend's **own controls**; without it `ui()` answers a `nui.Node`, which is
what `wui` wants — it is in push mode and renders nodes — and what a tree
crossing a wire is made of.

## Writing a view

### A tag is a control, an attribute is a property

```haxe
<Text text="Hello" scale="title"/>
<Slider value={level_} min={0.0} max={1.0}/>
```

A value in braces is Haxe: a literal, an expression, a closure, a cell. A value
in quotes is a string.

### Children are children

```haxe
<VStack spacing={8}>
    <Text text="Above"/>
    <HStack spacing={8}>
        <Text text="left"/>
        <Spacer/>
        <Text text="right"/>
    </HStack>
</VStack>
```

### A two-way control binds a cell

```haxe
<TextInput text={name_} placeholder="your name"/>
<Toggle label="Dark mode" isOn={dark_}/>
<Slider value={level_} min={0.0} max={1.0}/>
```

The **cell**, not a value and a callback. `name_` is the cell behind
`@:state var name`, and it is what a view written by hand binds too. Reading is
`name`, writing is `name = …`; see [Bindings](state/bindings.md).

### A computed list

A Haxe comprehension, spliced in:

```haxe
<VStack spacing={4}>
    {[for (row in rows) ui(<Text key={row} text={row}/>)]}
</VStack>
```

It is ordinary Haxe and it **runs** — `if`, `switch`, a method call, anything.
Nothing translates it, so nothing about it can be unsupported.

A single view goes in the same way: `{open ? ui(<Text text="…"/>) : null}`.

### A key, for rows that move

```haxe
{[for (row in rows) ui(<HStack key={row.id}>…</HStack>)]}
```

Identity is positional by default — a view is "the third child" — and whatever
is remembered about it (a field's caret and draft, the focus, the handle a
native renderer kept) is remembered under that place. That holds while rows stay
put. A list that sorts, filters or gains a row at the top moves every row below
it, and a key is how a row says it is still itself.

A control that edits a cell needs none: `pui`, `cui` and `sui` follow the cell,
so a field keeps its caret through an insertion. Two unkeyed siblings of one
type that say the same thing — a column of "Delete" buttons — are the case where
a key is not optional.

### Options that are data

A `Picker` carries its options as text, which the canon writes as `Text`
children:

```haxe
<Picker label="Output" selectedIndex={output_}>
    <Text text="HDMI"/>
    <Text text="SDI"/>
</Picker>
```

A list the application already has goes in directly:

```haxe
<Picker label="Output" selectedIndex={output_}>{outputs}</Picker>
```

Like anything else a view reads, that list is `final`, `@:state` or immutable —
a plain mutable field is refused at compile time, naming it.

Not both at once, and not a child of another type: each is refused by name,
because a dropped row in a picker reads as "the application does not offer that"
rather than as a bug.

### A component

A reusable piece with state of its own is a view like any other — put it in with
braces:

```haxe
{new Badge("clicks")}
```

See [Components](components.md).

## Decorations

The canon's nine are written as attributes on any tag, **in the order you write
them**, because the order is the semantics:

```haxe
<Text text="Warning"
    padding={8.0}
    backgroundColor={nui.Color.role(Surface)}
    border={{colour: nui.Color.role(Border), width: 1.0, radius: 6.0}}/>
```

`padding`, `backgroundColor`, `foregroundColor`, `border`, `opacity`, `clip`,
`width`, `height`, `flex`. **A backend refuses the ones it cannot draw**, by
name, with the list of what it can. See [Modifiers](modifiers.md) for the table
of who draws what, and for why a length is in **points** on every backend,
including the terminal.

## Written, assembled, received

This is the distinction everything else follows from. The
[node model](https://lapavoiserie.github.io/nui/#/node-model) states it; here is
what it means for you.

A **written** tree is this — in your source, against a backend you chose. Every
mistake in it is knowable while compiling, so every mistake in it is a compile
error.

A **received** tree arrived as data: a Companion frame, a relayed surface. It
cannot be checked — failing a build is not on offer for something that arrives
while the app is running — so a backend honours what it can, skips the rest and
says which.

An **assembled** tree is neither: built by your own code at runtime with type
names as strings, `new Node("Spacer")`. Nothing checks it. Prefer markup; where
you genuinely cannot, treat it as received and expect it to degrade.

## What `ui()` gives back

Two shapes, and which one depends on the backend and on `-D mui_views`.

**The backend's own view** — `new pui.ui.VStack(...)`, with your closures bound
directly and nothing described. This is what a build file from `mui init` turns
on, and what markup means on a backend that renders its own controls.

**A `nui.Node`** — the tree as data. This is what `wui` wants: it is in push
mode, it renders nodes, and markup for it needs nothing else.

| backend | builds its own views |
|---|---|
| `pui`, `cui`, `qui`, `aui`, `sui` | yes |
| `wui` | no, and by design — push mode: it wants nodes |

The second shape used to be the only one, and it could not reach most backends.
`pui` could turn a node into views; `sui` and `aui` cannot, by design — they
read a received tree natively and never copy it into views — so markup that
produced a node could only reach them through the **read** door, the one a
Companion frame uses. Sending your own screen through it puts your closures in a
string-id registry and bypasses the fine-grained read tracking those backends
exist for. It works, and it is wrong.

## Writing a view by hand

Every control is an ordinary class, and markup is a syntax over those
constructors — `<Text text="Hello"/>` is `new mui.ui.Text("Hello")`. Both
compile, side by side, in the same project:

```haxe
return new VStack([
    new Text("Count: " + count),
    new Button("+", () -> count += 1),
], 8);
```

Reach for it when a view is built by code rather than written — a tree that
comes from a protocol, a test fixture. For everything else write the markup: it
is checked against the backend, and a constructor is not.
