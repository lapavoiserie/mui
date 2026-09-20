# What each backend declares

`./check.sh` asks every backend, through the door markup itself asks
(`mui.macros.Backend.types()`), and compares the answer to `matrix.txt`.
`./check.sh --record` accepts a change.

Reading `@:node` out of the sources with a regular expression would have been
easier and would have answered a different question — the one about what is
written, not about what `ui()` would accept.

## What the table says today

Two different problems, and only one of them is a gap.

**`wui` speaks WinUI, not the shared vocabulary.** It declares `ToggleSwitch`,
`TextBox`, `ScrollViewer`, `TabView`, `ComboBox`, `PasswordBox`, `ProgressBar`,
`StackPanel`, `TextBlock` — the names of the controls it maps to. That is
deliberate and documented in `wui.nui.Vocabulary.nodeNameOf`: a control *is* a
node type, and `@:winuiType` already says which one, so nothing was restated.

The reasoning held while the name was wui's own business. It stopped holding
when markup began checking a tag against the target's vocabulary: the name is
now **shared**, and one concept has two of them. `<Toggle/>` does not compile
for `wui`, and `<ToggleSwitch/>` compiles for nothing else.

**The others are missing types**, which is an ordinary debt: the concept has
one name everywhere, some backends have not declared it yet. `sui` is the
thinnest at ten; `cui` has no `ScrollView`, `Spacer` or `ZStack`, which is why
`mui/examples/kitchen-sink` cannot be built for it.

`Box` (cui) and `Grid`, `FontIcon`, `SelectorBar`, `MenuBar`, `NavigationView`
(wui) belong to nobody else. Some are a backend's own idea; some are the same
concept again under a third name.
