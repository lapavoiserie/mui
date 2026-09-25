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

A user interface is written in **markup**, checked against the backend you are
building for:

```haxe
import mui.macros.Markup.ui;

class MyApp extends mui.App {
    @:state var greeting:String = "Hello!";

    public function new() {
        super();
        appTitle = "My First App";
    }

    override function body():mui.View {
        return ui(<VStack spacing={10}>
            <Text text={greeting} scale="title"/>
            <Button label="Change" onClick={() -> greeting = "Hi there!"}/>
        </VStack>);
    }

    static function main() {
        #if mui_owns_main
        new MyApp().run();
        #end
    }
}
```

Three things are worth noticing.

**`@:state var greeting`** is observable state: `greeting` reads it,
`greeting = …` writes it, and the screen follows on every backend.

**`ui(<VStack>…</VStack>)`** is the view. Misspell a tag or an attribute and
the build stops and names it, with what that backend does accept.

**Nothing in it names a backend.** The build file does, and `mui init` wrote
one per backend you have installed — each already carrying the two lines markup
needs (`--macro <backend>.nui.Vocabulary.registerWithMui()` and
`-D mui_views`).

## Next Steps

- [Markup](markup.md) -- the reference for writing a view
- [UI Components](ui/README.md) -- every control, and what to write for it
- [State Management](state/README.md) -- reactive state with `@:state`
- [Examples](examples/README.md) -- counter, form, todo, dashboard
