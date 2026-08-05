package mui.state;

/**
    Fine-grained reactive primitives, shared by every backend.

    Unlike `mui.state.State`, these are **not** dispatched per backend: they come
    straight from [`rui`](https://github.com/lapavoiserie/rui), the reactive core
    that `sui`, `aui`, `wui`, `cui` and `qui` all build their `State` on. The same
    `Signal` and `Effect` therefore behave identically on every target.

    ```haxe
    import mui.state.Signal;

    var count = new Signal(0);
    new Effect(() -> trace("count = " + count.value)); // runs now, and on change
    count.value = 1;
    ```

    `Effect` lives in this module — `import mui.state.Signal;` brings both, and
    there is no `mui.state.Effect` to import.

    Note that a backend's `State` already reads through a signal, so reading it
    inside an `Effect` tracks it: reach for `Signal` directly only when you want
    reactive state that is *not* bound to a view.
**/
typedef Signal<T> = rui.Signal<T>;

typedef Effect = rui.Signal.Effect;

typedef Scheduler = rui.Signal.Scheduler;
