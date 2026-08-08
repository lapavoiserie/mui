# Backend support

> This page is **generated**: `haxe -cp tools --run BackendMatrix`.
> It reads the `#if (mui_backend == …)` branches in `src/mui/ui/`, so it
> cannot promise what the code no longer does.

| `mui` type | sui | aui | wui | cui |
|---|---|---|---|---|
| **Button** | Button | Button | Button | Button |
| **ConditionalView** | ConditionalView | ConditionalView | ConditionalView | View ⚙️ |
| **Divider** | Divider | Divider | View ⚙️ | Divider |
| **ForEach** | macro | macro | macro | macro |
| **HStack** | HStack | HStack | HStack | HStack |
| **Image** | Image | Image | Image | **refused** |
| **ListView** | List | LazyColumn | ListView | ListView |
| **ProgressView** | ProgressView | ProgressView | ProgressRing | ProgressBar |
| **SafeArea** | VStack ○ | SafeArea | VStack ○ | VStack ○ |
| **ScrollView** | ScrollView | ScrollView | ScrollViewer | ScrollView |
| **Slider** | Slider | Slider | Slider | Slider |
| **Spacer** | Spacer | Spacer | Spacer | Spacer |
| **TabView** | TabView | TabView | TabView | Tabs |
| **Text** | Text | Text | Text | Text |
| **TextInput** | TextField | TextField | TextBox | Input |
| **Toggle** | Toggle | Toggle | ToggleSwitch | Checkbox |
| **VStack** | VStack | VStack | VStack | VStack |
| **ZStack** | ZStack | ZStack | ZStack | VStack ⚠️ |

## Legend

Unmarked, the backend has the concept natively and `mui` binds straight to it.

- ⚙️ **built** — `mui` composes it from the backend's primitives.
- ○ **not applicable** — the platform has no such concept; doing nothing is the right answer.
- ⚠️ **approximation** — what is drawn differs from what the type promises. This is the only row where your UI will not behave as it does elsewhere.
- **refused** — using it does not compile, rather than rendering something wrong.

## The cases that are not native

| Type | Backend | | What happens |
|---|---|---|---|
| ConditionalView | cui | ⚙️ | cui has no conditional view: the branch is chosen at construction |
| Divider | wui | ⚙️ | WinUI has no Divider: a 1px grey Border stands in |
| Image | cui | **refused** | using it does not compile, with a message that says why |
| SafeArea | sui | ○ | SwiftUI handles safe areas by default: nothing to apply |
| SafeArea | wui | ○ | a desktop window has no safe area |
| SafeArea | cui | ○ | a terminal has no safe area |
| ZStack | cui | ⚠️ | a terminal cannot overlay: the views are stacked instead |

## What the table does not say

`qui` is absent because it **is not a `mui` backend**. The `#else` says so
(`mui requires -D mui_backend=sui|wui|cui|aui`), and `qui/src/qui/ui/` holds the
same files as `src/mui/ui/` — a copy, not a binding.

`aui` has two paths: the static one covers everything listed here, while the
dynamic renderer (`-D aui_dynamic`) covers a subset and **refuses to compile**
what it cannot draw.
