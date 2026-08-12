# Text & Input

## Text

Displays read-only text.

```haxe
new Text("Hello, world!")
new Text('Count: ${count.get()}')  // string interpolation
new Text("Account", Title)         // set at a shared step
new Text("A note beside it", Caption)
```

**Constructor**: `Text(content:String, ?scale:TextScale)`

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

new TextInput("Enter your name", name)
```

**Constructor**: `TextInput(placeholder:String, state:TextInputBinding)`

The second argument accepts a `@:state String` field directly. The `TextInputBinding` abstract handles the backend conversion automatically via `@:from`:

- **sui**: extracts the state name for Swift code generation
- **wui**: passes the State object as a binding
- **cui**: wraps in a `Binding<String>` for two-way data flow

No `#if` blocks needed.
