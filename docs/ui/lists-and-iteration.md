# Lists & Iteration

## ForEach

`ForEach.build()` is a compile-time macro that lets you iterate over a state array with a builder function, producing the correct code for each backend.

### Basic usage

```haxe
@:state var items:Array<String> = [];

ForEach.build(items, function(item) {
    return new Text(item);
})
```

### With object fields

```haxe
ForEach.build(todos, function(item) {
    return new HStack([
        new Text(item.title),
        new Spacer(),
    ]);
})
```

### How it works

`mui.ui.ForEach` resolves to `<backend>.mui.ForEach`, and each backend's is a
macro that rewrites the call into its own iteration. `mui` used to hold all six
shapes side by side in a `ForEachMacro`; each now lives with the backend that
means it, which is why nothing here has to be edited when a seventh appears.

What they emit differs in a way worth knowing, because it decides *when* the
array is read:

| Backend | Emits | The array is |
|---|---|---|
| `sui` | `new sui.ui.ForEach(items, "_i", …)` | walked at compile time — the builder body becomes string templates, `item.title` → `{todos[_i].title}` |
| `qui`, `wui`, `aui` | `new <backend>.ui.ForEach(items, builder)` | the **cell**, handed over: the list rebuilds itself when it changes |
| `cui`, `pui` | `new <backend>.ui.ForEach(items.get(), builder)` | read here — both rebuild their whole tree on a write, so handing the cell over would buy nothing |

### Supported patterns

The macro handles these item reference patterns in the builder body:

| Pattern | SUI template | CUI/WUI |
|---------|-------------|---------|
| `item` | `{items[_i]}` | direct reference |
| `item.field` | `{items[_i].field}` | direct field access |
| `new Text(item)` | `Text.withState(...)` | `new Text(item)` |
| `new Text(item.field)` | `Text.withState(...)` | `new Text(item.field)` |

Expressions that don't reference the item parameter pass through unchanged on all backends.

### Limitations

- On SUI, only item references in `Text` constructors are converted to templates. Complex expressions (string concatenation, method calls on the item) may need `#if` blocks.
- Actions (delete buttons, toggles) within ForEach items typically need backend-specific code since SUI uses `StateAction.CustomSwift` while CUI/WUI use closures.

## ScrollView takes a list of views, everywhere

```haxe
new ScrollView([
    new Text("one"),
    new Text("two"),
])
```

`mui.Contract` states that signature and `mui.macros.Bind` checks it, so the
six agree by construction. A backend may add **trailing optional** arguments the
contract does not name — `cui` lets the application own the scroll offset,
because a terminal keeps none for you — and code written against the contract
still compiles.

## ListView is the one type with no agreed signature

`mui.ui.ListView` resolves like everything else, but the constructors behind it
genuinely differ: `sui` binds `List`, `aui` a `LazyColumn`, `qui` a generic
`ListView<T>` fixed to `String`, `cui` one that takes a selection and optional
handlers. The contract therefore lists it as **existence only** — checked to be
there, not checked for shape.

So `new ListView(...)` is not portable, and that is stated rather than papered
over. Use `ForEach` for a list you want on every backend, and reach for
`ListView` when you have chosen a platform deliberately.

`cui` has no `Image` at all — a terminal cannot draw one — and the contract marks
that entry optional. Reaching for `mui.ui.Image` there is a compile error at the
line that reached.
