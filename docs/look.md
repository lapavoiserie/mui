# One look

A mui application looks the same on every platform. It is drawn with each
platform's own controls, so it reads as native: a Windows switch, a macOS
segmented control. But it is arranged the same way everywhere, so a screen
designed once does not need a second design for each backend.

This page lists the rules that make up that arrangement. Each rule is worded
without naming a platform, and then says how each backend keeps it.

## Two layers

A backend's own vocabulary follows **its platform's conventions**. A plain wui
app looks like a Windows app, and a SwiftUI app written directly against sui
looks like a SwiftUI app. Nothing on this page changes them.

A mui application goes through the backend's conformance package
(`<backend>.mui`). That is where the rules below are applied: the conformance
sets the backend's own options before the tree is drawn. Those options belong
to the backend, not to the canon. A backend prefixes them, `wui.labelPlacement`
for example, so the canon's validators never take them for canon properties,
and an application cannot write them by accident.

The rules are documentation, not data. Each backend translates them into its
own options. A shared list in code would save only the names, and it would fix
a vocabulary before a second backend has needed it. When a second backend has
to map these rules (pui, aui), the list can be lifted here.

## The rules

### A switch carries its label beside it

The label is on the leading side and the switch at the trailing edge, on one
line. The label is not a header above the switch. In a `Form`, the label goes
to the form's label column instead, as for every labelled control (see `Form`
in the canon).

| Backend | How |
|---|---|
| sui | native: SwiftUI's `Toggle` |
| wui | `wui.labelPlacement = "inline"`; a plain wui app keeps WinUI's header |

### A notice appears at the bottom, centred, and leaves by itself

A `Notice` appears at the bottom of the window, centred, over the content and
narrower than the window. A success or an info closes itself after a few
seconds, and longer when it carries an act (Undo) so that the act can still be
reached, from the keyboard and with a screen reader too. The timer
waits while the pointer or the focus is inside the notice. A warning or an
error stays until it is closed.

| Backend | How |
|---|---|
| sui | native: the overlay toast, 4 s, 6 s with an act |
| wui | `wui.placement = "bottomCenter"`, 5 s, 8 s with an act; a plain wui app keeps the InfoBar at the top of its content |

### A child that stretches keeps its width, whatever the alignment

In a stack, `alignment` places children that have a size of their own. A child
that fills, such as a text field or a row holding a `Spacer`, keeps the full
width of the stack (the full height, in a row) even when the stack says
`leading` or `center`.

| Backend | How |
|---|---|
| sui | native: SwiftUI's stack layout |
| wui | `wui.alignStretching = true`; a plain wui app applies the alignment to every child |

### A row centres its children vertically

An `HStack` centres its children on the vertical axis unless it says otherwise.
A row of an avatar, a name and a button lines up on the avatar's centre.

| Backend | How |
|---|---|
| sui | native |
| wui | native since 2026-10 (it applies to every wui app) |

### A row's text gives way before its trailing controls

When a row is short of room, its text narrows and wraps. The controls at the
end of the row (a button, a menu) keep their size and stay visible. With room,
nothing changes.

| Backend | How |
|---|---|
| sui | native: SwiftUI compresses text first |
| wui | native since 2026-10: in an `HStack` with one `Spacer`, the text or stack before it takes the leftover width (it applies to every wui app) |

### Controls that share a field's row are centred on it

When a `Field` holds several controls, they sit side by side on the field's
row, centred on its vertical axis. A caption beside a segmented control lines
up on the control's centre.

| Backend | How |
|---|---|
| sui | native |
| wui | native since 2026-10 (it applies to every wui app) |

## Adding a rule

A rule belongs here when a mui application would otherwise look different on
two backends, and when the difference is in the arrangement, not in the
platform's controls. Word it without naming a platform, then give one row per
backend. Where the platform already does it, write "native". Where a
conformance has to set an option, name the option.
