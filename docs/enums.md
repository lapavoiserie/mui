# Enums

`mui` carries three shared vocabularies — a colour, a font style, an alignment —
as enums every backend can name. They are values, not bindings: nothing in `mui`
converts them to a backend's own type any more.

## Why there is no `.toBackend()`

There used to be. Each enum carried a `toBackend()` returning `sui.View.ColorValue`,
`wui.modifiers.ViewModifier.ColorValue` and so on — six branches per enum,
eighteen in all.

They were removed with the [binding inversion](adding-a-backend.md), and not
because the inversion demanded it: **nothing in this ecosystem ever called
them.** A mapping nobody asks for is a mapping nobody has checked, and eighteen
branches of unchecked colour conversion is a promise that would break the first
time someone believed it.

When something does need one, it belongs to the backend that means it, as
`<backend>.mui.*` — not here, in a repository that no longer names any backend.

Until then a view's colour comes from the backend's own modifier, which is a
deliberate choice of platform:
`sui.View.foregroundColor`, `pui`'s theme, `cui`'s named terminal colours.

## ColorValue

```haxe
import mui.enums.ColorValue;

var accent = ColorValue.Accent;
var brand = ColorValue.rgb(66, 133, 244);
var exact = ColorValue.hex("#4285F4");
```

**Semantic** — `Primary`, `Secondary`, `Accent`, `Clear`.

**Named** — `Red`, `Orange`, `Yellow`, `Green`, `Blue`, `Purple`, `Pink`,
`White`, `Black`, `Gray`.

**Custom** — `ColorValue.rgb(r, g, b)` with values 0–255, or
`ColorValue.hex("#RRGGBB")`.

## FontStyle

```haxe
import mui.enums.FontStyle;

var heading = FontStyle.Title;
```

`LargeTitle`, `Title`, `Headline`, `Body`, `Caption`.

`FontStyle` also answers `.isBold()` and `.isDim()`, which is what a terminal can
honour: `cui` has no font system, and bold and dim are the whole of what "bigger"
can mean there.

For text inside a `mui.ui.Text`, prefer [`TextScale`](ui/text-and-input.md) — four steps
every backend maps in its own `Text`, and the parameter is part of what a
heading *is* rather than something applied to it afterwards.

## Alignment

```haxe
import mui.enums.Alignment;

// HorizontalAlignment: Leading, Center, Trailing
// VerticalAlignment:   Top, Center, Bottom
```

`Leading` and `Trailing` rather than left and right, because the two swap in a
right-to-left script and a name that says "left" would be wrong there.
