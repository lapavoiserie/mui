# Backend support

> This page is **generated**: `haxe -cp tools --run BackendMatrix`.
> It reads each backend's own `<backend>/mui/` conformance, so it cannot
> promise what the code no longer does.

| `mui` type | sui | aui | wui | cui | qui | pui |
|---|---|---|---|---|---|---|
| **Button** | Button | Button | Button | Button | Button | Button |
| **ConditionalView** | ConditionalView | ConditionalView | ConditionalView | View ⚙️ | ConditionalView | ConditionalView |
| **Divider** | Divider | Divider | Border ⚙️ | Divider | Divider | Divider |
| **ForEach** | macro | macro | macro | macro | macro | macro |
| **HStack** | HStack | HStack | HStack | HStack | HStack | HStack |
| **Image** | Image | Image | Image | — | Image | Image |
| **ListView** | List | LazyColumn | ListView | ListView | ListView | ListView |
| **ProgressView** | ProgressView | ProgressView | ProgressRing | ProgressBar | ProgressView | ProgressView |
| **SafeArea** | VStack ○ | SafeArea | VStack ○ | VStack ○ | SafeArea ○ | SafeArea |
| **ScrollView** | ScrollView | ScrollView | ScrollViewer | ScrollView | ScrollView | ScrollView |
| **Slider** | Slider | Slider | Slider | Slider | Slider | Slider |
| **Spacer** | Spacer | Spacer | Spacer | Spacer | Spacer | Spacer |
| **TabView** | TabView | TabView | NavigationView | Tabs | TabView | TabView |
| **Text** | Text | Text | Text | Text | Text | Text |
| **TextInput** | TextField | TextField | TextBox | Input | TextInput | TextInput |
| **Toggle** | Toggle | Toggle | ToggleSwitch | Checkbox | Toggle | Toggle |
| **VStack** | VStack | VStack | VStack | VStack | VStack | VStack |
| **ZStack** | ZStack | ZStack | ZStack | VStack ⚠️ | ZStack | ZStack |

## Legend

Unmarked, the backend has the concept natively and `mui` binds straight to it.

- ⚙️ **built** — the backend composes it from its own primitives.
- ○ **not applicable** — the platform has no such concept; doing nothing is the right answer.
- ⚠️ **approximation** — what is drawn differs from what the type promises. This is the only row where your UI will not behave as it does elsewhere.
- **refused** — using it does not compile, rather than rendering something wrong.
- — **absent** — the backend provides no such type. `mui.Contract` marks the
  entry optional, and reaching for it there is a compile error at the line
  that reached.

## The cases that are not native

| Type | Backend | | What happens |
|---|---|---|---|
| ConditionalView | cui | ⚙️ | cui has no conditional view: the branch is chosen at construction |
| Divider | wui | ⚙️ | WinUI has no Divider: a 1px grey Border stands in |
| SafeArea | sui | ○ | SwiftUI handles safe areas by default: nothing to apply |
| SafeArea | wui | ○ | a desktop window has no safe area |
| SafeArea | cui | ○ | a terminal has no safe area |
| SafeArea | qui | ○ | Silica keeps the status bar clear on its own |
| ZStack | cui | ⚠️ | a terminal cannot overlay: the views are stacked instead |

## What the table does not say

The three types that carry everything else — `View`, `App` and
`ViewComponent` — and the five reactive ones under `mui.state` are in
[the contract](https://github.com/lapavoiserie/mui/blob/main/src/mui/Contract.hx)
but not tabulated. There is nothing to compare: a backend either provides
them, or `mui.macros.Bind` names what is missing at the top of the build.

The `aui` column is the *mapping* — which Compose widget a type is meant to
become — not the renderer's coverage. `aui` draws through its dynamic
renderer, whose vocabulary is a subset of this table: a type outside it
**refuses to compile**, naming the type and listing what is covered. The
compile-time transpiler that covered everything listed here is
[decommissioned](https://lapavoiserie.github.io/aui/#/render-paths).
