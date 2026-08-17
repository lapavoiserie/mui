# Getting Started

## Prerequisites

- [Haxe](https://haxe.org/) 4.3+
- [hxcpp](https://lib.haxe.org/p/hxcpp/)
- At least one backend library installed

Backend-specific requirements:
- **sui**: macOS with Xcode
- **wui**: Windows with Visual Studio 2022 (C++ workload)
- **aui**: Android SDK, Gradle, JDK 17+
- **cui**: any terminal (macOS, Linux)

## Installation

```bash
# Install mui
haxelib git mui https://github.com/lapavoiserie/mui

# Install backend(s)
haxelib git sui https://github.com/lapavoiserie/sui
haxelib git wui https://github.com/lapavoiserie/wui
haxelib git aui https://github.com/lapavoiserie/aui
haxelib git cui https://github.com/lapavoiserie/cui
```

## Create a Project

```bash
haxelib run mui init MyApp
cd MyApp
```

This creates:
- `src/MyApp.hx` -- your app with a counter template
- `build-<backend>.hxml` -- one per **installed** backend, and each comes from
  that backend rather than from `mui`: a library that ships a
  `<backend>/mui/init.hxml` is a backend as far as `mui init` is concerned, so a
  seventh appears here the moment it is installed
- `mui.json` -- project metadata

## Build and Run

```bash
# Terminal (fastest for development)
haxelib run mui build cui
haxelib run mui run cui

# macOS/iOS
haxelib run mui build sui

# Windows
haxelib run mui build wui

# Android
haxelib run mui build aui
```

## Project Structure

A typical mui project:

```
myapp/
  src/
    MyApp.hx          -- your main app class
    MyComponent.hx     -- reusable components
  build-sui.hxml       -- SwiftUI build config
  build-wui.hxml       -- WinUI build config
  build-cui.hxml       -- TUI build config
  mui.json             -- project metadata
```

## Your First App

```haxe
import mui.App;
import mui.View;
import mui.ui.Text;
import mui.ui.VStack;
import mui.ui.Button;

class MyApp extends App {
    @:state var greeting:String = "Hello!";

    public function new() {
        super();
        appTitle = "My First App";
    }

    override function body():View {
        return new VStack([
            new Text(greeting.get()),
            new Button("Change", function() greeting.set("Hi there!")),
        ], 10);
    }

    static function main() {
        #if mui_owns_main
        new MyApp().run();
        #end
    }
}
```

## Next Steps

- [UI Components](ui/README.md) -- layout, text, controls
- [State Management](state/README.md) -- reactive state with `@:state`
- [Examples](examples/README.md) -- counter, form, todo, dashboard
