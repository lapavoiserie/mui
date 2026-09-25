# Bindings

**A two-way control binds the cell** — `isOn={darkMode_}`, not a value and a
callback — and that is the same word in markup and by hand. What follows is
what makes one spelling work on six backends.

## The Problem

Toggle and TextInput require different binding types per backend:

- **sui**: a string name of the `@:state` variable (for Swift code generation)
- **wui**: the `State<T>` object directly
- **cui**: a `CheckboxBinding` or `Binding<String>` wrapper

## The Solution: Abstract Types

mui provides `ToggleBinding` and `TextInputBinding` -- Haxe abstract types with `@:from` implicit conversions. When you pass a `@:state` field, Haxe automatically converts it to the correct backend type at compile time.

### ToggleBinding

```haxe
@:state var darkMode:Bool = false;

// The same on every backend, in markup:
<Toggle label="Dark Mode" isOn={darkMode_}/>

// ...and written by hand:
new Toggle("Dark Mode", darkMode_)
```

The `ToggleBinding` abstract wraps a different underlying type per backend:

| Backend | Underlying type | `@:from` conversion |
|---------|----------------|---------------------|
| sui | `String` | Extracts `state.name` |
| wui | `State<Bool>` | Passes through |
| cui | `CheckboxBinding` | Calls `CheckboxBinding.fromState()` |

### TextInputBinding

```haxe
@:state var email:String = "";

<TextInput text={email_} placeholder="Enter email"/>
```

| Backend | Underlying type | `@:from` conversion |
|---------|----------------|---------------------|
| sui | `String` | Extracts `state.name` |
| wui | `State<String>` | Passes through |
| cui | `Binding<String>` | Calls `Binding.from()` |

## How @:from Works

Haxe's `@:from` on abstract types enables implicit conversion at the call site. When the compiler sees:

```haxe
<Toggle label="Dark Mode" isOn={darkMode_}/>   // or new Toggle("Dark Mode", darkMode_)
```

It recognizes that `darkMode` (a `BoolState` on cui, `State<Bool>` on sui/wui) doesn't match `ToggleBinding`, so it looks for an `@:from` function that accepts the source type. The conversion runs at compile time with zero runtime overhead.
