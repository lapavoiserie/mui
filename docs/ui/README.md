# UI Components

A user interface is written in [markup](../markup.md), and every tag below is a
control `mui` normalises across the backends: you write the same thing whichever
one you build for.

```haxe
<VStack spacing={8}>
    <Text text="Hello"/>
    <Button label="Go" onClick={go}/>
</VStack>
```

## What every backend has

These are declared by all six, so a screen made of them is one source for every
target:

| Tag | Written | Built by hand |
|-----|---------|---------------|
| [Text](text-and-input.md) | `<Text text="…" scale="title"/>` | `Text(content, ?scale, ?style)` |
| [VStack](layout.md) | `<VStack spacing={8}>…</VStack>` | `VStack(children, ?spacing)` |
| [HStack](layout.md) | `<HStack spacing={8}>…</HStack>` | `HStack(children, ?spacing)` |
| [ZStack](layout.md) | `<ZStack>…</ZStack>` | `ZStack(children)` |
| [Spacer](layout.md) | `<Spacer/>` | `Spacer()` |
| [Button](controls.md) | `<Button label="…" onClick={…}/>` | `Button(label, ?action, ?icon)` |
| [Toggle](controls.md) | `<Toggle label="…" isOn={flag_}/>` | `Toggle(label, state)` |
| [Slider](controls.md) | `<Slider value={v_} min={0.0} max={1.0}/>` | `Slider(state, ?min, ?max)` |
| [TextInput](text-and-input.md) | `<TextInput text={s_} placeholder="…"/>` | `TextInput(placeholder, state)` |
| [Picker](controls.md) | `<Picker label="…" selectedIndex={i_}>…</Picker>` | `Picker(label, options, selection)` |
| [ProgressView](controls.md) | `<ProgressView label="…" value={0.5}/>` | `ProgressView(?label, ?value)` |
| [ScrollView](lists-and-iteration.md) | `<ScrollView>…</ScrollView>` | `ScrollView(content)` |
| [Image](controls.md) | `<Image src="asset:logo.png" alt="…"/>` | `Image(src, alt, ?options)` |

## What some have

A tag a backend does not declare is **refused while you compile**, by name, with
the accepted set in the message — never drawn as a placeholder. Who declares
what is measured rather than remembered: `mui/test/vocabulary` compiles each
backend's vocabulary and records the table.

| Tag | pui | cui | sui | aui | qui | wui |
|-----|-----|-----|-----|-----|-----|-----|
| `Divider` | ✓ | ✓ | | ✓ | ✓ | |
| `Icon` | ✓ | ✓ | | ✓ | ✓ | ✓ |
| `SafeArea` | ✓ | | | ✓ | ✓ | |
| `Tabs` / `Tab` | ✓ | ✓ | | | | ✓ |
| `Disclosure` | ✓ | | ✓ | | | |
| `PasswordInput` | ✓ | ✓ | | | | |
| `SecretInput` | ✓ | | ✓ | | | ✓ |
| `Tappable` | ✓ | | | | | |

## Markup reaches further than the class list

`mui.ui.*` holds the controls the builder API normalises — `mui.Contract` states
their signatures and `mui.macros.Bind` checks them. Markup does **not** go
through that list: `ui()` asks the backend's own declarations, so a tag that
backend declares works even where no `mui.ui` class exists for it.

`Tabs`, `Tab`, `Disclosure` and `Tappable` are in that position today. Written
in markup they compile; there is no `new mui.ui.Disclosure(…)` to write instead.

## Backend-specific components

A few types have irreconcilable APIs and are exposed as direct typedefs, to be
used behind `#if`:

- **ListView** — a different constructor per backend
- **TabView** — the builder API's tabs; `cui` requires an active-tab binding
