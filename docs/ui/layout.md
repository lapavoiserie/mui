# Layout

Written in [markup](../markup.md); the constructor beside each one is the same
control built by hand.

`spacing`, `padding` and every other length are in **points**, on every backend
— a terminal converts them to cells at its door. See
[Modifiers](../modifiers.md).

## VStack

Children down the screen, with optional spacing between them.

```haxe
<VStack spacing={10}>
    <Text text="First"/>
    <Text text="Second"/>
    <Text text="Third"/>
</VStack>
```

**Constructor**: `VStack(content:Array<View>, ?spacing:Float)`

Internally, VStack normalizes the backend differences:
- sui: `VStack(?alignment, ?spacing, content)` -- reordered
- wui: `VStack(children, ?spacing)` -- matches
- cui: `VStack(children, spacing:Int)` -- points to cells

## HStack

Children across the screen.

```haxe
<HStack spacing={8}>
    <Button label="Cancel" onClick={onCancel}/>
    <Spacer/>
    <Button label="OK" onClick={onOk}/>
</HStack>
```

**Constructor**: `HStack(content:Array<View>, ?spacing:Float)`

## Spacer

Flexible space that fills available room.

```haxe
<VStack>
    <Text text="Top"/>
    <Spacer/>
    <Text text="Bottom"/>
</VStack>
```

**Constructor**: `Spacer()`

## When the children do not fit

A row of three labels wanting 224 points in 180 has to do something. What it
does is **shrink what can give way, then cut what cannot**:

```haxe
<HStack spacing={8}>
    <Text text="Source"/>
    <Text text="Transitions"/>
    <Text text="Diffusion"/>
</HStack>
```

In 600 points those measure 48, 88 and 72 and keep it. In 180 they become 38,
69 and 57 — they wrap — and nothing is cut. Replace them with three buttons and
nothing gives way: a button is as wide as its label, so the row overflows for
real and is cut at its edge.

A view **told** a size keeps it: `width={90}` is a size asked for, not a
suggestion, so the squeeze falls on its neighbours instead.

None of this crosses the wire. A container that shrinks or cuts is deciding
*this* layout, and a panel on a wider screen has nothing to shrink — which is
why it is not [`clip`](../modifiers.md), the one that means "cut here whether
or not it fits".

## Divider

A horizontal separator line.

```haxe
<VStack>
    <Text text="Section 1"/>
    <Divider/>
    <Text text="Section 2"/>
</VStack>
```

**Constructor**: `Divider()`

Maps to SwiftUI `Divider`, a styled `Border` on WinUI, `HorizontalDivider` on Compose, and a terminal line on cui.

## ZStack

Overlay stack — children are layered on top of each other.

```haxe
<ZStack>
    <Image src="asset:background.png" alt=""/>
    <Text text="Overlay text"/>
</ZStack>
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
<SafeArea>
    <Text text="Title" scale="title"/>
    <VStack spacing={8}>…</VStack>
</SafeArea>
```

**Constructor**: `SafeArea(children:Array<View>)`

Also available as a modifier: `new SafeArea([...]).safeArea()`

| Backend | Behavior |
|---------|----------|
| sui | No-op (SwiftUI respects safe areas by default) |
| aui | `Column` with `Modifier.safeDrawingPadding()` |
| wui | No-op (Windows has no safe areas) |
| cui | No-op (terminal has no safe areas) |
