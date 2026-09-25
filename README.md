# mui

Multi-UI abstraction layer for Haxe. Write your app once, compile to native macOS/iOS (SwiftUI), Windows (WinUI 3), Android (Jetpack Compose), or terminal (TUI).

## Quick Start

```bash
haxelib git mui https://github.com/lapavoiserie/mui
haxelib run mui init MyApp
cd MyApp
mui run cui       # terminal
mui build sui     # macOS/iOS
mui build wui     # Windows
mui build aui     # Android
```

## How It Works

mui is a thin wrapper over four backend libraries:

| Backend | Target Platform | Library |
|---------|----------------|---------|
| `sui`   | macOS, iOS, visionOS (SwiftUI) | [sui](https://github.com/lapavoiserie/sui) |
| `wui`   | Windows (WinUI 3) | [wui](https://github.com/lapavoiserie/wui) |
| `aui`   | Android (Jetpack Compose) | [aui](https://github.com/lapavoiserie/aui) |
| `cui`   | Terminal (TUI) | [cui](https://github.com/lapavoiserie/cui) |

Backend selection is compile-time: `-D mui_backend=sui|wui|aui|cui|qui|pui`, plus
`--macro mui.macros.Bind.all()`, which resolves `mui`'s vocabulary onto that
backend and checks it against `mui.Contract`. All mui types are aliases of the
backend's own, so there is no runtime overhead and no wrapper to step through.

## Example

A user interface is written in **markup**, checked at compile time against the
backend you are building for:

```haxe
import mui.macros.Markup.ui;

class Counter extends mui.App {
    @:state var count:Int = 0;

    override function body():mui.View {
        return ui(<VStack spacing={10}>
            <Text text={"Count: " + count}/>
            <HStack spacing={8}>
                <Button label="−" onClick={() -> count -= 1}/>
                <Button label="+" onClick={() -> count += 1}/>
            </HStack>
        </VStack>);
    }

    static function main() {
        #if mui_owns_main
        new Counter().run();
        #end
    }
}
```

A tag nothing declares, an attribute a control does not carry, a decoration a
backend cannot draw: each is refused by name while you compile, with the
accepted set in the message. Every control is also an ordinary class, so the
same screen can be built by hand where a view comes from code rather than from
a page — see [the markup reference](docs/markup.md).

## Unified Components

| Tag | Built by hand | Notes |
|-----|---------------|-------|
| `<Text text="…"/>` | `Text(content, ?scale, ?style)` | |
| `<VStack spacing={8}>` | `VStack(children, ?spacing)` | |
| `<HStack spacing={8}>` | `HStack(children, ?spacing)` | |
| `<ZStack>` | `ZStack(children)` | |
| `<Button label="…" onClick={…}/>` | `Button(label, ?action, ?icon)` | a closure, everywhere |
| `<Toggle label="…" isOn={flag_}/>` | `Toggle(label, state)` | takes the **cell** |
| `<Slider value={v_} min={0.0} max={1.0}/>` | `Slider(state, ?min, ?max)` | takes the cell |
| `<TextInput text={s_} placeholder="…"/>` | `TextInput(placeholder, state)` | takes the cell |
| `<Picker label="…" selectedIndex={i_}>` | `Picker(label, options, selection)` | options are `Text` children |
| `<ProgressView value={0.5}/>` | `ProgressView(?label, ?value)` | |
| `<Spacer/>` | `Spacer()` | |
| `<Image src="asset:…" alt="…"/>` | `Image(src, alt, ?options)` | |
| `<ScrollView>` | `ScrollView(content)` | |
| `ListView`, `TabView` | backend-specific | behind `#if` |

Several more — `Divider`, `Icon`, `SafeArea`, `Tabs`, `Disclosure`,
`PasswordInput`, `SecretInput`, `Tappable` — exist where the backend declares
them, and a tag it does not declare is refused by name while you compile.
`mui/test/vocabulary` measures who has what;
[Backend support](docs/backend-support.md) is the summary.

## A two-way control binds the cell

`isOn={darkMode_}`, not a value and a callback. The trailing underscore is the
cell behind `@:state var darkMode`, and an abstract with `@:from` turns it into
whatever that backend's control wants:

```haxe
@:state var darkMode:Bool = false;
@:state var username:String = "";

<Toggle label="Dark Mode" isOn={darkMode_}/>
<TextInput text={username_} placeholder="Enter username"/>
```

## Lists

A list of views is a Haxe comprehension, spliced into the children — it is
ordinary Haxe and it runs, so nothing about it can be unsupported:

```haxe
@:state var todos:Array<Todo> = [];

<VStack spacing={4}>
    {[for (todo in todos) ui(<HStack key={todo.id} spacing={8}>
        <Text text={todo.title}/>
        <Spacer/>
    </HStack>)]}
</VStack>
```

`ForEach.build(todos_, builder)` is the same thing for a view built by hand.

## State API

The `@:state` macro works on all backends. The field reads and writes as the field it was declared as; the cell behind it is `count_`, for a control that binds:

```haxe
@:state var count:Int = 0;

// Read
var c = count;    // works everywhere
var c = count;    // works everywhere

// Write
count = 5;           // works everywhere
count = 5;        // works everywhere
```

## App Class

`mui.App` provides a unified base class:

```haxe
class MyApp extends App {
    public function new() {
        super();
        appTitle = "My Application";  // sets window title on sui/wui
    }

    override function body():View { ... }
}
```

On cui, the App class provides default Ctrl+C / q handling to quit. Override `handleEvent` for custom key bindings.

## Unified Enums

`mui.enums.ColorValue` and `mui.enums.FontStyle` provide cross-platform color and font types with `.toBackend()` conversion:

```haxe
import mui.enums.ColorValue;
import mui.enums.FontStyle;

view.foregroundColor(ColorValue.Red.toBackend());
view.font(FontStyle.Title.toBackend());
```

## Platform-Specific Code

Use Haxe's conditional compilation for backend-specific features:

```haxe
#if (mui_backend == "sui")
view.navigationTitle("Settings");
#elseif (mui_backend == "wui")
view.toolTip("Help text");
#elseif (mui_backend == "cui")
view.border(cui.render.BorderStyle.Rounded);
#end
```

## CLI

```
mui init [name]       Scaffold a new project
mui build <backend>   Build for production
mui run <backend>     Build and run once
mui watch <backend>   Hot reload (CPPIA for cui ~0.3s, warm for others)
mui clean             Remove build artifacts
mui version           Show version
```

## Adding a New Backend

**It touches no file in this repository.** The backend declares its own
conformance and `mui` resolves it by name.

1. Create the backend library: an `App`, a `View`, a `State<T>` over
   [`rui`](https://lapavoiserie.github.io/rui/), and its own components.
2. Write `<backend>/mui/*.hx` — one file per entry in
   [`mui.Contract`](src/mui/Contract.hx). A `typedef` where the signature already
   matches, a small subclass where it does not.
3. Ship `<backend>/mui/init.hxml`, the build file `mui init` writes for you.
4. Put `@:muiOwnsMain` on your `mui.App` if `run()` blocks and nothing may follow
   it.
5. Build with `--macro mui.macros.Bind.all()`. It names anything missing or
   mis-shaped at the top of the build rather than at first use.

See [Adding a backend](docs/adding-a-backend.md) for the whole of it.

## Prerequisites

- Haxe 4.3+
- hxcpp
- Backend-specific: Xcode (sui), Visual Studio 2022 (wui), or just a terminal (cui)

## License

MIT
