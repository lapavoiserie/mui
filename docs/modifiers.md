# Modifiers

A modifier decorates a node: padding, a colour, a border, a share of the space
left over. It belongs to no control in particular — a `padding` is no more a
`Button`'s business than a `VStack`'s — so no backend declares it, and the same
nine names work on every tag.

## The nine

The set is closed, and `nui.Modifiers` holds it:

| | carries |
|---|---|
| `padding` | four floats: top, right, bottom, left |
| `backgroundColor` | a colour, and the radius it is drawn with |
| `foregroundColor` | a colour: what text and icons are drawn in |
| `border` | a colour, then a width and a radius |
| `opacity` | one float, 0 to 1 |
| `clip` | nothing: children are cut at this view's edge |
| `width` / `height` | one float each: a size asked for rather than measured |
| `flex` | one float: this view's share of what is left over |

Three things are deliberately absent, and the [node
model](https://lapavoiserie.github.io/nui/#/node-model) gives the reasons at
length: a free-standing `cornerRadius` (a radius belongs to the thing it
rounds), `font`, `bold` and `italic` (they are `Text`'s own properties since the
fonts canon), and `alignment` (it is how a parent places a child, not a
decoration).

A backend that cannot honour one skips that entry and honours the rest.

## In markup, a modifier is an attribute

```haxe
ui(<VStack padding={8} backgroundColor={Color.role(Surface)}>
    <Button label="TAKE" onClick={take}
        backgroundColor={Color.role(Danger)}
        foregroundColor={Color.rgb(255, 255, 255)}/>
</VStack>)
```

**In the order they are written.** A modifier list is a chain, and a border
applied after a padding is not the same as one applied before it, so `ui()`
reads the order from the source — `Xml.attributes()` does not keep it.

A misspelt one is refused by name, like a misspelt property: `backgroundColour`
is not a decoration and not an attribute of any tag, and the message says so and
lists both sets.

`clip` carries nothing, so it is written as a flag: `clip={true}` adds it,
`clip={false}` does not. That is the only way to write "not clipped" without a
second name for it.

## A modifier with several parts can be written whole

```haxe
ui(<Tappable label="Pick this source"
        border={{colour: Color.role(Border), width: 3.0, radius: 6.0}}
        padding={{top: 8.0, left: 12.0}}
        onClick={select}>
    …
</Tappable>)
```

The wire has carried a border's width and radius since there was a wire; the
markup could write only the colour, so a panel that wanted a three-pixel border
added the modifier by hand **beside markup that was checked**.
`nui.Modifiers.partsOf` names the parts, and a field that is not one of them is
refused with the list.

Three names — `borderColor`, `borderWidth`, `borderRadius` — would have reopened
the door the set closed on a free-standing `cornerRadius`. Naming the parts of
one modifier keeps the radius attached to the thing it rounds.

**An unnamed part does not mean the same thing everywhere.** `padding`'s floats
are four edges, and an edge nobody mentioned has no padding: `{top: 8}` is a
padding at the top and nowhere else. It is *not* the positional `padding={8}`,
which is eight all round — an object is not a short form, and reading it as one
would give a panel three edges it never asked for. `border` and
`backgroundColor` end in a radius, and an unnamed radius is the one the control
draws with naturally; a zero would square the corners of a button that had round
ones. So an unnamed trailing part is not written at all, and naming a later part
without an earlier one — a radius with no width, which draws no border — is
refused rather than filled with a zero.

## A length is in points

`padding`, `width`, `height`, a border's width and radius: all of them are
**points**, the device-independent unit every surface in this family draws in.
The canon says so once and every backend converts at its own door — `cui` above
all, whose unit is a character cell, taken as 8 points wide and 16 tall.

That was unsaid until 2026-09-21, and it cost what an unsaid unit costs:
`spacing={12}`, a fair gap between two rows of a form, was **twelve blank
lines** on a terminal. The kitchen sink example needed a 140-row screen; it fits
44 now.

Rounding is to the nearest cell there, so 8 points is one row rather than none,
and anything below half a cell rounds away — the honest answer, since a terminal
has nothing smaller.

## What each backend draws

A decoration a backend cannot draw is **refused at compile time**, by name, with
the list of what it can. The table is a statement of debt, not of design:

| backend | draws |
|---|---|
| `pui` | all nine |
| `cui` | eight — not `flex`; no stack there reads a weight. `opacity` is what a terminal can do of it: hidden at zero, dim below one |
| `aui` | seven — not `border` (its own takes a colour value a role cannot become) or `flex` |
| `sui` | five — not the colours (same reason, the other way round), nor `border` or `flex` |
| `qui` | four: `padding`, `foregroundColor`, `width`, `height` |

## A colour is a role or its components

```haxe
Color.role(Danger)        // what it is FOR — the receiver resolves it
Color.rgb(200, 50, 60)    // what it IS — nobody resolves anything
```

`nui.Color` is an abstract over the string the wire carries, so a colour is an
ordinary attribute value and needs nothing special to write. A role crosses as
the word `role:danger` and is resolved by whoever draws it, against that
platform's own palette — the accent the person chose on Windows, the sixteen a
terminal has, the Material scheme on Android. An application that wants a
particular red says `rgb` and means it.

`mui.enums.ColorValue` predates all of this and **no backend reads it**. Use
`nui.Color`.

## Outside the canon

A backend's own `View` still has its own chaining API, reachable behind `#if`:

```haxe
#if (mui_backend == "sui")
view.navigationTitle("Page");
#elseif (mui_backend == "wui")
view.toolTip("Tooltip text");
#elseif (mui_backend == "cui")
view.underline();
#end
```

Anything written that way is by definition outside the canon: it does not cross
the wire, and a panel on another platform will not see it.
