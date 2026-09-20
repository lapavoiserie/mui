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

| backend | manque |
|---|---|
| `sui` (10) | Disclosure, Divider, Icon, Image, PasswordInput, Picker, ProgressView, SafeArea, SecretInput, Tab, Tabs, Tappable |
| `aui` (14) | **Button**, Disclosure, PasswordInput, SafeArea, SecretInput, Tab, Tabs, Tappable |
| `qui` (15) | Button is there; Disclosure, PasswordInput, SafeArea, SecretInput, Tab, Tabs, Tappable |
| `cui` (19) | Disclosure, SafeArea, SecretInput, Tappable |
| `wui` (39) | Disclosure, PasswordInput, SafeArea, Tappable |
| `pui` (22) | — the reference |

`cui` gained `ScrollView`, `Spacer` and `ZStack` on 2026-09-21, and the kitchen
sink builds and draws for it — see `examples/kitchen-sink/build-cui-frame.hxml`,
which renders into a `Buffer` rather than taking over a terminal.

`Box` (cui) and `Grid`, `FontIcon`, `SelectorBar`, `MenuBar`, `NavigationView`
(wui) belong to nobody else. Some are a backend's own idea; some are the same
concept again under a third name, and this table is where that will show.
