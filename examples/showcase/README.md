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
haxe build.hxml                      # iOS / macOS, through sui
haxe build-aui.hxml                  # Android, through aui
haxelib run wui build                # Windows, through wui
```

## What it does not prove yet

Two things are visibly wrong on Windows and are not this example's doing:

- **`Spacer` does not push.** A WinUI `StackPanel` hands each child its
  desired size and distributes nothing, so the buttons sit left instead of
  right. Making it work means an `HStack` carrying a spacer has to become a
  `Grid` with a star column.
- **`Divider` draws nothing.** It is a one-pixel `Border`, and its background
  is not arriving.

Both are wui defects, and both are listed here rather than worked around: an
example that quietly avoided them would hide exactly what it exists to show.
