# What each backend declares

`./check.sh` asks every backend, through the door markup itself asks
(`mui.macros.Backend.types()`), and compares the answer to `matrix.txt`.
`./check.sh --record` accepts a change.

Reading `@:node` out of the sources with a regular expression would have been
easier and would have answered a different question — the one about what is
written, not about what `ui()` would accept.

## What the table says today

**`wui` now speaks the canon too** — fixed 2026-09-21. Its classes are still
named after WinUI's controls (`ToggleSwitch`, `TextBox`, `ScrollViewer`), which
is what a WinUI reader should read; what changed is that `nodeNameOf` reports
the canonical name when `wui.nui.Canonical` has one, and the vocabulary answers
to both. `WinUISink` had been translating those names at the door all along —
only the schema markup consults had not been told.

`canon/` is the fixture that keeps it: canonical tags compiled against `wui`.
Without the change it fails with *Le backend cible ne sait pas construire
"ProgressView"*.

**What is left is missing types**, an ordinary debt: the concept has one name
everywhere, some backends have not declared it yet.

| backend | manque | pourquoi |
|---|---|---|
| `sui` (14) | Divider, Icon, PasswordInput, Picker, SafeArea, Tab, Tabs, Tappable | `Picker`, `Tabs` and `Tab` exist and hold their options/pages in a shape the canon does not; `Divider`, `Icon`, `SafeArea`, `Tappable` are not written |
| `qui` (16) | Disclosure, PasswordInput, SecretInput, Tab, Tabs, Tappable | `TabView` exists and is not a canon `Tabs` |
| `aui` (15) | **Button**, Disclosure, PasswordInput, SecretInput, Tab, Tabs, Tappable | **`Button` is the one that is not a declaration away**: `aui.state.StateAction` has no `Custom(callback)`, so no control in this backend can carry a closure at all |
| `cui` (19) | Disclosure, SafeArea, SecretInput, Tappable | |
| `wui` (39) | Disclosure, PasswordInput, SafeArea, Tappable | `Expander` exists and is not declared |
| `pui` (22) | — | the reference |

Most of what was missing on 2026-09-21 was **written and undeclared**, which is
the failure this table exists to make visible: the control is there, the canon
names it, and markup refuses the tag because nothing said so. Eleven were closed
that night by declaring them (cui 3, sui 4, aui 1, qui 1, plus wui's eight
aliases). What is left is either a control nobody has written or one whose shape
is not the canon's — and `aui`'s `Button` is neither, it is a missing capability.

`cui` gained `ScrollView`, `Spacer` and `ZStack` on 2026-09-21, and the kitchen
sink builds and draws for it — see `examples/kitchen-sink/build-cui-frame.hxml`,
which renders into a `Buffer` rather than taking over a terminal.

`Box` (cui) and `Grid`, `FontIcon`, `SelectorBar`, `MenuBar`, `NavigationView`
(wui) belong to nobody else. Some are a backend's own idea; some are the same
concept again under a third name, and this table is where that will show.
