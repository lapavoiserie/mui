# Examples

Each example is one source, built for every backend. They demonstrate different
parts of the unified API — and two of them ask different questions about it.

| Example | Features | `#if` blocks |
|---------|----------|-------------|
| [Counter](examples/counter.md) | State, buttons, layout | 1 (main) |
| [Form](examples/form.md) | TextInput, Toggle, Divider | 1 (main) |
| [Todo](examples/todo.md) | ForEach macro, dynamic lists | 1 (main) |
| [Settings](examples/settings.md) | Toggle, Divider, appTitle | 1 (main) |
| [Dashboard](examples/dashboard.md) | ProgressView, helper functions | 1 (main) |
| **Kitchen sink** | every shared type, once | 1 (main) |
| **Showcase** | one screen, arranged with care | **0** |

## The last two, and why there are two

They answer different questions, and one example cannot answer both.

The **kitchen sink** asks *does write-once hold?* It uses every shared type once,
in the plainest arrangement that shows each working, and it is deliberately
unstyled: anything it looked like beyond the vocabulary would be a claim the
vocabulary cannot back. When it looks bare, that is information. It runs on all
five backends — Windows, iOS, macOS, Android, SailfishOS and the terminal.

The **showcase** asks *does an app built this way look like it belongs?* It uses
a fraction of the vocabulary and arranges it with care — a title, headings, a
caption, spacing that means something. If it looks unfinished, that is a defect,
and having both is what tells you which of the two kinds of problem you are
looking at. It found two on its first run: a `Spacer` that did not push and a
`Divider` that drew nothing.

## Building Examples

Each example directory has one build file per backend — `build-sui.hxml`,
`build-aui.hxml`, `build-wui.hxml`, `build-cui.hxml` — because the toolchains
want different flags, not because the source differs. Each tool reads the one
named after it:

```bash
cd examples/counter
haxe build-cui.hxml
./build/cui/Counter
```
