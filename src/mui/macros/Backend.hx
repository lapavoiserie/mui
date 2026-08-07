package mui.macros;

/**
	The target backend's vocabulary, seen from `mui`.

	This is the whole reason the markup lives here rather than in `nui`: at macro
	time `mui` knows which backend is being built for, so it can check a tag and
	its attributes against **that** backend's schema. `nui` cannot — it does not
	know who you are compiling for, and giving it a common core to check against
	would turn it from a model into a vocabulary.

	## The shape a backend must expose

	A backend that wants markup declares `<backend>.nui.Vocabulary` with:

	```haxe
	static function knows(type:String):Bool;
	static function keysOf(type:String):Array<String>;
	static function requiredOf(type:String):Array<String>;
	static function kindOf(type:String, key:String):Null<PropKind>;
	```

	Only `wui` declares one today. A target that declares none does **not** fall
	through to "accept everything": that turned an absence into tacit approval,
	which is the exact failure mode a schema exists to remove. `ui()` refuses to
	compile against a backend it cannot check, and says so.

	The way out is not to hand-write four more schemas. `qui`'s components
	already declare their properties as typed Haxe fields
	(`public var value(default, set):Float`), so its vocabulary can be **derived
	from the types** — exhaustive by construction, and unable to drift from the
	code it describes. `wui` is the exception that has to declare: its vocabulary
	lives in C++, where nothing can be read back.

	The kind crosses as a **string**, not as an enum. Each backend owns its own
	`PropKind`, and `mui` only needs the name of the constructor to emit; sharing
	the enum would mean hoisting it somewhere common for no benefit.
**/
class Backend {
	#if macro
	/**
		Does the target declare a vocabulary at all?

		`ui()` refuses to compile when this is false. Checking nothing and saying
		nothing would let `<Hologramme/>` through on four backends out of five.
	**/
	public static function hasVocabulary():Bool {
		#if (mui_backend == "wui")
		return true;
		#else
		return false;
		#end
	}

	/** The target's name, for a message that says which backend is meant. **/
	public static function name():String {
		#if (mui_backend == "wui") return "wui";
		#elseif (mui_backend == "sui") return "sui";
		#elseif (mui_backend == "aui") return "aui";
		#elseif (mui_backend == "cui") return "cui";
		#else return "inconnu"; #end
	}

	/** Does the target know how to build this node type? **/
	public static function knows(type:String):Bool {
		#if (mui_backend == "wui")
		return wui.nui.Vocabulary.knows(type);
		#else
		// Unreachable: ui() stops at hasVocabulary() before asking.
		return false;
		#end
	}

	/** Every attribute the target accepts on this type. **/
	public static function keysOf(type:String):Array<String> {
		#if (mui_backend == "wui")
		return wui.nui.Vocabulary.keysOf(type);
		#else
		return [];
		#end
	}

	/** Attributes the target requires on this type. **/
	public static function requiredOf(type:String):Array<String> {
		#if (mui_backend == "wui")
		return wui.nui.Vocabulary.requiredOf(type);
		#else
		return [];
		#end
	}

	/**
		Which `PropValue` constructor an attribute takes, by name.

		`null` means the target has no such attribute — which the markup reports
		as an error. On a backend with no schema, everything is a string, which
		is what the markup did before schemas existed.
	**/
	public static function kindOf(type:String, key:String):Null<String> {
		#if (mui_backend == "wui")
		var k = wui.nui.Vocabulary.kindOf(type, key);
		return k == null ? null : Std.string(k);
		#else
		return null;
		#end
	}

	/** Types the target knows, for an error message that helps. **/
	public static function types():Array<String> {
		#if (mui_backend == "wui")
		var out = [for (t in wui.nui.Vocabulary.types.keys()) t];
		out.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
		return out;
		#else
		return [];
		#end
	}
	#end
}
