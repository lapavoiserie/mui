package mui.state;

/**
    Reactive state, dispatched to the selected backend.

    Every backend's `State<T>` now **extends `rui.state.State<T>`**, the reactive
    core shared across the family, so the contract below is the same everywhere
    regardless of `-D mui_backend`:

    | | |
    |---|---|
    | `get()` / `value` | tracked read — registers a dependency inside an `Effect` |
    | `set(v)` / `value = v` | write — re-runs dependent effects, then the platform |
    | `peek()` | untracked read |
    | `applyExternal(v)` | write coming *from* the platform: effects only, no echo back |
    | `name` | the state's identifier |

    The typedef stays per-backend rather than collapsing to `rui.state.State`
    because each backend still has to do something platform-specific on a write:
    `cui` raises a redraw flag, `sui` mirrors into Swift's `AppState`, `aui`
    mirrors into a Compose `MutableState`. What is shared is the reactive half
    and the contract — not the platform half.

    Backend-local extras (`setTo`, `inc`/`dec`/`toggle`, the typed `IntState`
    /`BoolState` subclasses, `StateAction` builders) are deliberately **not**
    part of this contract: the backends disagree on them, so an app that uses
    them is no longer portable.

    See also `mui.state.Signal` and `mui.structures.ImmutableList`, which are
    shared outright.
**/
#if (mui_backend == "sui")
typedef State<T> = sui.state.State<T>;
#elseif (mui_backend == "wui")
typedef State<T> = wui.state.State<T>;
#elseif (mui_backend == "cui")
typedef State<T> = cui.state.State<T>;
#elseif (mui_backend == "aui")
typedef State<T> = aui.state.State<T>;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
