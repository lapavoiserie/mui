package mui.state;

/**
	`rui`'s port, spoken by `kui`'s capability. Nothing but a forward — the
	shapes were made to match, which is the point of having designed them
	together rather than adapting one to the other afterwards.
**/
class KuiStore implements rui.state.Durable.DurableStore {
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
