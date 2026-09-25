# Text & Input

## Text

Displays read-only text.

```haxe
<Text text="Hello, world!"/>
<Text text={"Count: " + count}/>
<Text text="Account" scale="title"/>
<Text text="A note beside it" scale="caption"/>
```

**Constructor**: `Text(content:String, ?scale:TextScale, ?style:TextStyle)`

A family, a weight and the rest of the style are written as attributes too:

```haxe
<Text text="Farceur" scale="title" family={Fonts.family("Inter")}/>
<Text text="00:12:34" weight={600} numbers="tabular"/>
```

### How it is set

`TextStyle` is `{?family, ?weight, ?italic, ?numbers}`, and every field is
optional: what is left out is the platform's own answer. `weight` is 100 to 900
in hundreds — the vocabulary every font file uses, 400 regular and 700 bold — and
a weight a family does not have is the nearest one it does, which is the
platform's rule and not one `mui` invents. `numbers: Tabular` asks for digits of
one width, so a timecode does not jitter as it counts.

A backend honours what it can. A terminal takes the weight as bold and the
italic, and leaves family and scale alone: a cell is one size and one font, and
saying so is not a lack. `pui` and `qui`, which cannot ask a platform for a font
feature, answer `Tabular` with a monospaced family, which does the same job.

### Fonts an application ships

Font files go in `assets/fonts`, beside the build file — the same `assets`
directory pictures use, so a font needs no second mechanism — and `Fonts.family`
names one:

```haxe
<Text text={timecode} family={Fonts.family("Inter")}/>
```

It is a macro: the files are read while the application compiles, and a family
nothing ships is an error at that line, naming the families that *are* shipped.
The file describes itself — a family name, a weight and an italic bit live in a
font's own tables, which is where every platform reads them — so an application
does not declare that `Inter-Bold.ttf` is Inter, bold and upright.

Each backend registers what is shipped the way its platform expects: an
`Info.plist` entry on Apple's, a table from a family to a file on Windows and
Android, `QFontDatabase` on Sailfish. A family the platform does not have — a
tree from elsewhere naming one it never shipped — falls back to the system font,
silently: a wrong picture is a lie, a wrong typeface is a disappointment.

### The scale

Four steps, and no more: `Title`, `Subtitle`, `Body`, `Caption`. Without one you
get the backend's running-text size, which is what every existing call already
meant.

Four, because that is the intersection five platforms can honour. Apple's scale
has eleven steps, Material's twelve, WinUI's five — and a **terminal has none**.
It has bold, dim and colour, and one cell height nothing can change. `cui`
renders the two heading steps bold and leaves the others alone, which is the
only honest reading of "bigger" there.

Each backend is handed the step **its own scale calls this**, never a number. A
title on iOS is not 28 points because `mui` says so; it is whatever Apple
currently says a title is, and it follows the reader's text-size setting.
Passing points would have frozen five platforms to one platform's taste and
broken accessibility on two of them.

Finer steps stay each backend's own business. `sui.View.font(Footnote)` and
`aui.View.font(DisplayLarge)` still work on a view built from `mui`, and
reaching for one is choosing that platform deliberately.

## TextInput

A text input field with a placeholder and state binding.

```haxe
@:state var name:String = "";

<TextInput text={name_} placeholder="Enter your name"/>
```

**Constructor**: `TextInput(placeholder:String, state:TextInputBinding)`

`text` takes the **cell** — `name_`, the one behind `@:state var name`. The
`TextInputBinding` abstract handles the backend conversion automatically via
`@:from`:

- **sui**: extracts the state name for Swift code generation
- **wui**: passes the State object as a binding
- **cui**: wraps in a `Binding<String>` for two-way data flow

No `#if` blocks needed.
