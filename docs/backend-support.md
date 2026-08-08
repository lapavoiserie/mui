# Ce que chaque backend supporte

> Cette page est **générée** : `haxe -cp tools --run BackendMatrix`.
> Elle lit les branches `#if (mui_backend == …)` de `src/mui/ui/`,
> donc elle ne peut pas promettre ce que le code ne fait plus.

| Type `mui` | sui | aui | wui | cui |
|---|---|---|---|---|
| **Button** | Button | Button | Button | Button |
| **ConditionalView** | ConditionalView | ConditionalView | ConditionalView | View ⚙️ |
| **Divider** | Divider | Divider | View ⚙️ | Divider |
| **ForEach** | macro | macro | macro | macro |
| **HStack** | HStack | HStack | HStack | HStack |
| **Image** | Image | Image | Image | **refusé** |
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

## Légende

Sans marque, le backend a nativement la notion et `mui` s'y branche.

- ⚙️ **construit** — `mui` le compose à partir de primitives du backend.
- ○ **sans objet** — la plateforme n'a pas cette notion ; ne rien faire est la bonne réponse.
- ⚠️ **approximation** — le rendu diffère de ce que le type promet. C'est la seule catégorie où votre interface ne se comportera pas comme ailleurs.
- **refusé** — l'usage ne compile pas, plutôt que de rendre quelque chose de faux.

## Les cas qui ne sont pas natifs

| Type | Backend | | Ce qui se passe |
|---|---|---|---|
| ConditionalView | cui | ⚙️ | cui n'a pas de vue conditionnelle : la branche est choisie à la construction |
| Divider | wui | ⚙️ | WinUI n'a pas de Divider : un Border de 1 px gris |
| Image | cui | **refusé** | l'usage ne compile pas, avec un message qui le dit |
| SafeArea | sui | ○ | SwiftUI gère les zones sûres par défaut : rien à poser |
| SafeArea | wui | ○ | une fenêtre de bureau n'a pas de zone sûre |
| SafeArea | cui | ○ | un terminal n'a pas de zone sûre |
| ZStack | cui | ⚠️ | le terminal ne superpose pas : les vues sont empilées |

## Ce que la table ne dit pas

`qui` n'y figure pas : il **n'est pas un backend `mui`**. Son `#else` l'énonce
(`mui requires -D mui_backend=sui|wui|cui|aui`), et `qui/src/qui/ui/` contient
les mêmes fichiers que `src/mui/ui/` — une copie, pas un branchement.

`aui` a deux chemins : le statique couvre tout ce qui est listé ici, le renderer
dynamique (`-D aui_dynamic`) en couvre un sous-ensemble et **refuse de compiler**
ce qu'il ne dessine pas.
