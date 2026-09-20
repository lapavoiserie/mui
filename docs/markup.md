# Markup

```haxe
import mui.macros.Markup.ui;

override function body():View {
    return ui(<VStack spacing={8} padding={{top: 16, left: 16}}>
        <Text text="Hello" scale="title"/>
        <Toggle label="Lit" isOn={lit} onToggle={setLit}/>
        {[for (row in rows) ui(<Text text={row}/>)]}
    </VStack>);
}
```

It is **checked against the backend you are building for**. `-D mui_backend`
names it, and `ui()` asks that backend's own declarations what exists: a tag
nothing declares, an attribute a control does not carry, a decoration it cannot
draw are refused by name, with the accepted set in the message, before the
program runs.

## Written, assembled, received

This is the distinction everything else follows from, and the one worth getting
right before writing much. The
[node model](https://lapavoiserie.github.io/nui/#/node-model) states it; here is
what it means for you.

A **written** tree is this — in your source, against a backend you chose. Every
mistake in it is knowable while compiling, so every mistake in it is a compile
error. There is no `?Button` on screen for something you typed.

A **received** tree arrived as data: a Companion frame, a relayed surface. It
cannot be checked — failing a build is not on offer for something that arrives
while the app is running — so a backend honours what it can, skips the rest and
says which.

An **assembled** tree is neither: built by your own code at runtime with type
names as strings, `new Node("Spacer")`. Nothing checks it. Prefer markup or the
backend's own constructors; where you genuinely cannot, treat it as received and
expect it to degrade.

## What `ui()` gives back

Two shapes, and which one depends on the backend and on `-D mui_views`.

**A `nui.Node`** — the tree as data. This is what `wui` wants: it is in push
mode, it renders nodes, and markup for it needs nothing else.

**The backend's own view** — `new pui.ui.VStack(...)`, with your closures bound
directly and nothing described. This is what `-D mui_views` turns on, and it is
what markup means on a backend that renders its own controls.

The second exists because the first could not reach most backends. `pui` could
turn a node into views; `sui` and `aui` cannot, by design — they read a received
tree natively and never copy it into views — so markup that produced a node
could only reach them through the **read** door, the one a Companion frame uses.
Sending your own screen through it puts your closures in a string-id registry
and bypasses the fine-grained read tracking those backends exist for. It works,
and it is wrong.

| backend | builds its own views | notes |
|---|---|---|
| `pui` | yes | |
| `cui` | yes | |
| `qui` | yes | its sink has no builder at all, so this is the only way markup reaches it |
| `aui` | yes | |
| `sui` | yes | its two-way controls take a **cell**, not a value and a callback — `<Toggle isOn={lit_}/>` |
| `wui` | no, and by design | push mode: it wants nodes |

## Decorations

The canon's nine are written as attributes on any tag, in the order you write
them, because the order is the semantics. See [Modifiers](modifiers.md).

**A backend refuses the ones it cannot draw**, by name, with the list of what it
can. Not every backend draws all nine on one of its own views:

| backend | draws |
|---|---|
| `pui`, `cui` | all nine |
| `aui` | seven — not `border` (its own takes a colour value a role cannot become) or `flex` |
| `sui` | five — not the colours (same reason, the other way round) nor `border` or `flex` |
| `qui` | four: `padding`, `foregroundColor`, `width`, `height` |

That table is a statement of debt, not of design. Each gap is named where it
lives, so it can be closed rather than discovered.
