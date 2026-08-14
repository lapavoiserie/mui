package mui.macros;

/**
	The target backend's vocabulary, seen from `mui` — and registered by it.

	This is the whole reason the markup lives here rather than in `nui`: at macro
	time `mui` knows which backend is being built for, so it can check a tag and
	its attributes against **that** backend's schema. `nui` cannot — it does not
	know who you are compiling for, and giving it a common core to check against
	would turn it from a model into a vocabulary.

	## Why this one is registered rather than resolved

	Every other part of the inversion works by *resolution*: `mui.macros.Bind`
	looks up `<backend>.mui.Button` by name and aliases it. That works because
	the result is a **type**, and a macro can name a type it was handed as a
	string.

	This one needs to *call* the backend's schema at macro time, and macro code
	cannot dispatch to a function it does not name. Resolution is not available;
	registration is. So the backend declares itself, from its own build file:

	```
	--macro wui.nui.Vocabulary.registerWithMui()
	```

	and that function — compiled into the macro context, where it may name
	itself — hands over five closures. `mui` names nobody, which was the point.

	## The shape a backend registers

	```haxe
	mui.macros.Backend.register({
	    knows:      type -> Bool,
	    keysOf:     type -> Array<String>,
	    requiredOf: type -> Array<String>,
	    kindOf:     (type, key) -> Null<String>,
	    types:      () -> Array<String>,
	});
	```

	A target that registers nothing does **not** fall through to "accept
	everything": that turned an absence into tacit approval, which is the exact
	failure mode a schema exists to remove. `ui()` refuses to compile against a
	backend it cannot check, and says so.

	The way out is not to hand-write five more schemas. `qui`'s components
	already declare their properties as typed Haxe fields
	(`public var value(default, set):Float`), so its vocabulary can be **derived
	from the types** — exhaustive by construction, and unable to drift from the
	code it describes. `wui` is the exception that has to declare: its vocabulary
	lives in C++, where nothing can be read back.

	The kind crosses as a **string**, not as an enum. Each backend owns its own
	`PropKind`, and `mui` only needs the name of the constructor to emit; sharing
	the enum would mean hoisting it somewhere common for no benefit.
**/
typedef Vocabulary = {
	var knows:String->Bool;
	var keysOf:String->Array<String>;
	var requiredOf:String->Array<String>;
	var kindOf:String->String->Null<String>;
	var types:Void->Array<String>;
};

class Backend {
	#if macro
	static var registered:Null<Vocabulary> = null;

	/** Called by a backend's own init macro. See the class documentation. **/
	public static function register(vocabulary:Vocabulary):Void
		registered = vocabulary;

	/**
		Does the target declare a vocabulary at all?

		`ui()` refuses to compile when this is false. Checking nothing and saying
		nothing would let `<Hologramme/>` through on five backends out of six.
	**/
	public static function hasVocabulary():Bool
		return registered != null;

	/**
		The target's name, for a message that says which backend is meant.

		Read from the define rather than listed. The list used to answer
		`"inconnu"` for `qui` and `pui`, because nobody had added them to it —
		the shape of bug a list of names produces on its own.
	**/
	public static function name():String {
		var named = haxe.macro.Context.definedValue("mui_backend");
		return named == null ? "inconnu" : named;
	}

	/** Does the target know how to build this node type? **/
	public static function knows(type:String):Bool
		// Unreachable when null: ui() stops at hasVocabulary() before asking.
		return registered == null ? false : registered.knows(type);

	/** Every attribute the target accepts on this type. **/
	public static function keysOf(type:String):Array<String>
		return registered == null ? [] : registered.keysOf(type);

	/** Attributes the target requires on this type. **/
	public static function requiredOf(type:String):Array<String>
		return registered == null ? [] : registered.requiredOf(type);

	/**
		Which `PropValue` constructor an attribute takes, by name.

		`null` means the target has no such attribute — which the markup reports
		as an error.
	**/
	public static function kindOf(type:String, key:String):Null<String>
		return registered == null ? null : registered.kindOf(type, key);

	/** Types the target knows, for an error message that helps. **/
	public static function types():Array<String>
		return registered == null ? [] : registered.types();
	#end
}
