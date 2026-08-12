# Showcase

One screen, written to be looked at.

## Why this exists next to the kitchen sink

They answer different questions, and one example cannot answer both.

The [kitchen sink](../kitchen-sink) asks **does write-once hold?** It uses every
shared type once, in the plainest arrangement that shows each working, and it is
deliberately unstyled — anything it looked like beyond the vocabulary would be a
claim the vocabulary cannot back. When it looks bare, that is information.

This one asks **does an app built this way look like it belongs?** It uses a
fraction of the vocabulary and arranges it with care: a title, headings, a
caption, spacing that means something, one screen with one job. If it looks
unfinished, that is a defect — and having both examples is what tells you which
of the two kinds of problem you are looking at.

## The rule it keeps

Every line is shared `mui`. Nothing reaches for a backend's own vocabulary, and
there is not one `#if`. Whatever it looks like on Windows, it is the same source
that produced iOS, macOS and Android.

That constraint is what makes it worth building. An example allowed to
special-case a platform would prove only that the platform can be
special-cased.

## Building it

```bash
haxelib run sui build macos          # macOS / iOS, through sui
haxelib run aui run                  # Android, through aui
haxelib run wui build                # Windows, through wui
```

## What building it found

Two defects, both in wui and neither in this example. Listing them here rather
than working around them is the point — an example that quietly avoided them
would hide exactly what it exists to show. Both are fixed now, and the note
stays because *how* they were found is the argument for having this example at
all.

- **`Spacer` did not push.** A WinUI `StackPanel` hands each child the size it
  asks for and distributes nothing, so an empty `Border` between two labels came
  out zero wide. An `HStack` is a `Grid` now: every child gets a column, sized
  `Auto` for content and `*` for a spacer.
- **`Divider` drew nothing.** It asked for the colour `"Gray"`; the runtime's
  table was keyed `"gray"`, and the mismatch cost it its whole background. Names
  are folded now, and an unrecognised one is reported instead of ignored.

A spacer still does nothing in a **`VStack`**, which is a StackPanel and
distributes nothing vertically. Stated rather than discovered.
