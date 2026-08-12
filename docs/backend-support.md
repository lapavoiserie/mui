# Backend support

> This page is **generated**: `haxe -cp tools --run BackendMatrix`.
> It reads the `#if (mui_backend == …)` branches in `src/mui/ui/`, so it
> cannot promise what the code no longer does.

| `mui` type | sui | aui | wui | cui | qui | pui |
|---|---|---|---|---|---|---|
| **Button** | Button | Button | Button | Button | Button | Button |
| **ConditionalView** | ConditionalView | ConditionalView | ConditionalView | View ⚙️ | ConditionalView | ConditionalView |
| **Divider** | Divider | Divider | Border ⚙️ | Divider | Divider | Divider |
| **ForEach** | macro | macro | macro | macro | macro | macro |
| **HStack** | HStack | HStack | HStack | HStack | HStack | HStack |
| **Image** | Image | Image | Image | **refused** | Image | Image |
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
| SafeArea | qui | ○ | Silica keeps the status bar clear on its own |
| ZStack | cui | ⚠️ | a terminal cannot overlay: the views are stacked instead |

## What the table does not say

`qui` joined as the fifth backend. It had been written against this contract
before it was wired to one -- the same twenty-one views, the same `App` shape,
and an `appTitle` already mapped to its own `appName` -- so the column is a
binding like the others, not a copy.

The `aui` column is the *mapping* -- which Compose widget a type is meant to
become -- not the renderer's coverage. `aui` draws through its dynamic
renderer, whose vocabulary is a subset of this table: a type outside it
**refuses to compile**, naming the type and listing what is covered. The
compile-time transpiler that covered everything listed here is
[decommissioned](https://lapavoiserie.github.io/aui/#/render-paths).
