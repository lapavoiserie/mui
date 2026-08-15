# mui

Multi-UI abstraction layer for Haxe. Write your app once, compile to native macOS/iOS (SwiftUI), Windows (WinUI 3), Android (Jetpack Compose), or terminal (TUI).

## Quick Start

```bash
haxelib git mui https://github.com/Pign/mui
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
| `sui`   | macOS, iOS, visionOS (SwiftUI) | [Pign/sui](https://github.com/Pign/sui) |
| `wui`   | Windows (WinUI 3) | [Pign/wui](https://github.com/Pign/wui) |
| `aui`   | Android (Jetpack Compose) | [Pign/aui](https://github.com/Pign/aui) |
| `cui`   | Terminal (TUI) | [Pign/cui](https://github.com/Pign/cui) |

Backend selection is compile-time: `-D mui_backend=sui|wui|aui|cui|qui|pui`, plus
`--macro mui.macros.Bind.all()`, which resolves `mui`'s vocabulary onto that
backend and checks it against `mui.Contract`. All mui types are aliases of the
backend's own, so there is no runtime overhead and no wrapper to step through.

## Example

```haxe
import mui.App;
import mui.View;
import mui.ui.*;

class Counter extends App {
    @:state var count:Int = 0;

    override function body():View {
        return new VStack([
            new Text('Count: ${count.get()}'),
            new HStack([
                new Button("-", function() count.set(count.get() - 1)),
                new Button("+", function() count.set(count.get() + 1)),
            ], 8),
        ], 10);
    }

    static function main() {
        #if mui_owns_main
        new Counter().run();
        #end
    }
}
```

No `#if` blocks in the UI code. The only conditional is `main()`, and it does not
name a backend: `mui_owns_main` is defined when the chosen backend's engine owns
the process — `cui` and `pui` today, where `run()` blocks and nothing may follow
it. Everywhere else a generator drives.

## Unified Components

| mui Component | Constructor | Notes |
|--------------|-------------|-------|
| `Text` | `Text(content)` | |
| `VStack` | `VStack(children, ?spacing)` | |
| `HStack` | `HStack(children, ?spacing)` | |
| `Button` | `Button(label, ?action)` | Closure-based |
| `Toggle` | `Toggle(label, state)` | Accepts `@:state` Bool field directly |
| `TextInput` | `TextInput(placeholder, state)` | Accepts `@:state` String field directly |
| `ForEach` | `ForEach.build(items, item -> view)` | Macro-based, see below |
| `Spacer` | `Spacer()` | |
| `Divider` | `Divider()` | |
| `ProgressView` | `ProgressView(?label, ?value)` | |
| `Image` | `Image(source)` | Not available on cui |
| `ListView` | Backend-specific | |
| `ScrollView` | Backend-specific | |
| `TabView` | Backend-specific | |

## Toggle and TextInput

Toggle and TextInput accept `@:state` fields directly via type-safe abstract bindings (`ToggleBinding` / `TextInputBinding`). The `@:from` conversion handles the backend differences automatically:

```haxe
@:state var darkMode:Bool = false;
@:state var username:String = "";

// Works on all backends — no #if needed
new Toggle("Dark Mode", darkMode),
new TextInput("Enter username", username),
```

## ForEach

`ForEach.build()` is a compile-time macro that transforms a builder closure into the correct backend representation:

```haxe
@:state var todos:Array<String> = [];

// Works on all backends
ForEach.build(todos, item -> new Text(item))

// With object fields
ForEach.build(todos, item -> new HStack([
    new Text(item.title),
    new Spacer(),
]))
```

On SUI, the macro transforms `item.title` references into string templates for Swift code generation. On CUI/WUI, the builder closure runs at runtime.

## State API

The `@:state` macro works on all backends. All backends support both `.get()`/`.set()` and `.value`:

```haxe
@:state var count:Int = 0;

// Read
var c = count.get();    // works everywhere
var c = count.value;    // works everywhere

// Write
count.set(5);           // works everywhere
count.value = 5;        // works everywhere
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
