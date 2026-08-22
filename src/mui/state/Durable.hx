package mui.state;

/**
	Joins the two halves: `rui`'s durable port and `kui`'s device store.

	Neither half may name the other. `rui` is the reactive core and must not
	know that native capabilities exist; `kui-store` is a capability and must
	not depend on the reactive core, which is the layering `kui` exists to
	protect. `mui` is where a backend's pieces are already named — it holds the
	`Describe` and `Resample` registers for the same reason — so it holds this.

	One call, once, before any durable cell is constructed:

	```haxe
	mui.state.Durable.install("app");
	```

	The backend's `mui.App` does it; an application does not.
**/
class Durable {
	/**
		Resolve the device store and hand it to `rui`.

		`writer` names this instance — "app" for the application itself,
		"glance" for a widget extension hosting its own. It is carried into
		every entry, for messages and for recognising "not me"; the sequence,
		not the name, decides who wins.

		Idempotent: a second call replaces the store, which is what a process
		re-entering its own boot does.
	**/
	public static function install(writer:String = "app"):Void {
		rui.state.Durable.store = new KuiStore(kui.Kui.get(store.Store));
		rui.state.Durable.writer = writer;
	}
}

/**
	`rui`'s port, spoken by `kui`'s capability. Nothing but a forward — the
	shapes were made to match, which is the point of having designed them
	together rather than adapting one to the other afterwards.
**/
private class KuiStore implements rui.state.Durable.DurableStore {
	final backing:store.Store;

	public function new(backing:store.Store) {
		this.backing = backing;
	}

	public function read(key:String):Null<String>
		return backing.read(key);

	public function seqOf(key:String):Int
		return backing.seqOf(key);

	public function put(key:String, packed:String, expectedSeq:Int, writer:String):Bool
		return backing.put(key, packed, expectedSeq, writer);

	public function epoch():Int
		return backing.epoch();
}
