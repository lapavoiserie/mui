package mui.structures;

/**
    Persistent list: `push`, `filter` and `map` return a **new instance** instead
    of mutating the receiver.

    Like `mui.state.Signal`, this is not dispatched per backend — it comes from
    [`rui`](https://github.com/lapavoiserie/rui) and behaves identically
    everywhere.

    It exists because a state notifies only when its value *changes*, compared
    with `!=` — a reference comparison for arrays. Mutating an array in place is
    therefore invisible:

    ```haxe
    todos.get().push(item);              // silent: same array instance
    todos.set(todos.get().push(item));   // observed: ImmutableList returns a new one
    ```

    Cost: each operation copies the backing array (O(n), no structural sharing).
    That is the right trade for UI-sized collections — rows, items, tabs. For a
    large or hot data set, keep the data outside the state and put only a version
    marker in it.
**/
typedef ImmutableList<T> = rui.structures.ImmutableList<T>;
