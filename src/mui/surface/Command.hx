package mui.surface;

/**
	One named command: what it is called, what it does, and optionally the key
	that triggers it.

	Deliberately flat. The menu-bar backend (`sui`) has nested `CommandMenu`s,
	but nesting enters the shared vocabulary only when a backend actually
	consumes it — the same discipline that kept `scenes()` from being copied
	here as dead API. Until then a backend groups a flat list however its
	platform likes: one menu, a command palette, a key table.

	The shortcut is advisory: a backend that has no keyboard (or whose platform
	owns the chords) ignores it. The label is what every backend can honour.
**/
class Command {
	public final label:String;
	public final action:() -> Void;
	public var shortcut:Null<String>;

	public function new(label:String, action:() -> Void) {
		this.label = label;
		this.action = action;
		this.shortcut = null;
	}

	/** Chainable: `new Command("New todo", focusNew).key("ctrl+n")`. **/
	public function key(chord:String):Command {
		this.shortcut = chord;
		return this;
	}
}
