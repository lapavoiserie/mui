# CLI Reference

The mui CLI is invoked via `haxelib run mui <command>`.

## Commands

### init

```bash
mui init [name]
```

Scaffolds a new project with:
- `src/<Name>.hx` -- app template with a counter
- `build-sui.hxml` / `build-wui.hxml` / `build-cui.hxml` -- build configs
- `mui.json` -- project metadata
- `.gitignore`

### build

```bash
mui build <backend> [options]
```

Builds the project for the specified backend.

| Backend | What happens |
|---------|-------------|
| `sui` | Delegates to `haxelib run sui build` (Haxe + Swift + Xcode) |
| `wui` | Delegates to `haxelib run wui build` (Haxe + C++/WinRT + MSBuild) |
| `aui` | Delegates to `haxelib run aui build` (Haxe + JVM + Kotlin + Gradle) |
| `cui` | Runs `haxe build-cui.hxml` directly (Haxe + hxcpp) |

### run

```bash
mui run <backend> [options]
```

Builds (if needed) and runs the app.

### watch

```bash
mui watch <backend>
```

Watches `.hx` source files and auto-rebuilds on save.

| Backend | Strategy | Reload speed |
|---------|----------|-------------|
| `cui` | CPPIA script recompile | ~0.3s |
| `sui` | Dynamic renderer + Xcode incremental | ~10-20s |
| `aui` | Dynamic renderer + Gradle incremental | ~15-30s |
| `wui` | Full warm rebuild via MSBuild | ~10-15s |

The first build for `sui` includes a dynamic view renderer (`--watch` flag) so the native host can interpret the Haxe view tree at runtime. Subsequent rebuilds only recompile the Haxe side. `aui` needs no flag: interpreting the tree at runtime is how it draws, watching or not.

See [Hot Reload](hot-reload.md) for a step-by-step guide and architecture details.

### clean

```bash
mui clean
```

Removes the `build/` directory.

### version

```bash
mui version
```

Prints `mui 0.1.0`.

## Build Files

Each backend has its own `.hxml` build file:

```
# build-sui.hxml
-cp src
-lib mui
-lib sui
-D mui_backend=sui
--macro sui.macros.SwiftGenerator.register()
-main MyApp
-cpp build/sui

# build-wui.hxml
-cp src
-lib mui
-lib wui
-D mui_backend=wui
-main MyApp
-cpp build/wui

# build-cui.hxml
-cp src
-lib mui
-lib cui
-D mui_backend=cui
-main MyApp
-cpp build/cui
```

The key line is `-D mui_backend=<backend>` which activates the correct backend at compile time.
