# Layout

## VStack

Arranges children vertically with optional spacing.

```haxe
new VStack([
    new Text("First"),
    new Text("Second"),
    new Text("Third"),
], 10)  // 10px spacing
```

**Constructor**: `VStack(content:Array<View>, ?spacing:Float)`

Internally, VStack normalizes the backend differences:
- sui: `VStack(?alignment, ?spacing, content)` -- reordered
- wui: `VStack(children, ?spacing)` -- matches
- cui: `VStack(children, spacing:Int)` -- Float-to-Int conversion

## HStack

Arranges children horizontally with optional spacing.

```haxe
new HStack([
    new Button("Cancel", onCancel),
    new Spacer(),
    new Button("OK", onOk),
], 8)
```

**Constructor**: `HStack(content:Array<View>, ?spacing:Float)`

## Spacer

Flexible space that fills available room.

```haxe
new VStack([
    new Text("Top"),
    new Spacer(),
    new Text("Bottom"),
])
```

**Constructor**: `Spacer()`

## Divider

A horizontal separator line.

```haxe
new VStack([
    new Text("Section 1"),
    new Divider(),
    new Text("Section 2"),
])
```

**Constructor**: `Divider()`

Maps to SwiftUI `Divider`, a styled `Border` on WinUI, `HorizontalDivider` on Compose, and a terminal line on cui.

## ZStack

Overlay stack — children are layered on top of each other.

```haxe
new ZStack([
    new Image("background"),
    new Text("Overlay text"),
])
```

**Constructor**: `ZStack(content:Array<View>)`

Maps to SwiftUI `ZStack`, WinUI/Compose `Box`. On cui, falls back to a vertical stack (terminal can't overlay views).

## SafeArea

The part of the screen that is yours, with the margin the platform expects
around what you put in it.

Two things, and the platform answers both. **What you must stay out of** — a
notch, a status bar, a home indicator — which only some platforms have. And
**how far in the content sits**, which all of them answer, and not with the same
number: 24 pixels is a reasonable inset on a desktop, a wasteful one on a phone,
and a quarter of the screen in a terminal, where the margin is one cell.

That is why the margin lives here rather than as a shared `padding`. An app that
says `SafeArea` gets the right one without naming it — and content used to start
hard against the window corner because nothing said otherwise.

```haxe
new SafeArea([
    new Text("Title"),
    new VStack([...]),
])
```

**Constructor**: `SafeArea(children:Array<View>)`

Also available as a modifier: `new SafeArea([...]).safeArea()`

| Backend | Behavior |
|---------|----------|
| sui | No-op (SwiftUI respects safe areas by default) |
| aui | `Column` with `Modifier.safeDrawingPadding()` |
| wui | No-op (Windows has no safe areas) |
| cui | No-op (terminal has no safe areas) |
