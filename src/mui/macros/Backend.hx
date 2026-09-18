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

	## The kinds a backend may name

	`KString`, `KInt`, `KFloat`, `KBool` for values, and for acts `KCallback`
	when it carries nothing plus `KCallbackString`, `KCallbackFloat`,
	`KCallbackInt` and `KCallbackBool` when it carries something — one per
	constructor of `nui.PropValue`. Anything else is a compile error naming the
	tag, the attribute and the kind: a schema exists to say what a value is, and
	a default that guesses undoes it.

	The four carrying kinds were added for `pui`. Until then the only declared
	callback in any backend was `wui.ui.Button.onClick`, a `Void->Void`, so
	`KCallback` had never been asked to carry anything — and a two-way control
	in markup asks immediately:

	```haxe
	<Toggle isOn={muet} onToggle={v -> moteur.muet(v)}/>
	```

	## Acts are keys; children are not

	`keysOf` lists what may be written as an ATTRIBUTE, so it includes acts —
	`wui` has done this from the start, its `onClick` being an ordinary
	`@:winrt` field of function type. Children are a different axis: the markup
	builds them from child ELEMENTS, so a control whose children are not views
	(`pui.ui.Picker`, whose options cross as one `Text` child each) declares
	that where it declares its children, and nothing about it belongs in
	`keysOf`.
**/
typedef Vocabulary = {
	var knows:String->Bool;
	var keysOf:String->Array<String>;
	var requiredOf:String->Array<String>;
	var kindOf:String->String->Null<String>;
	var types:Void->Array<String>;

	/**
		For an EXTENSION only: the type path whose `node(props)` builds this
		tag, or null to have the markup build a `nui.Node` itself.

		A backend leaves this out. A component library does not, and the
		difference is where the defaults live: `vui.meter.LevelMeter.node()`
		fills in `channels`, `floorDb`, `warnDb` and four more, and normalises
		the channel count. Markup that emitted a bare `nui.Node` would produce
		a meter missing all of them — the same tag meaning two things depending
		on whether it was written in Haxe or in markup.
	**/
	@:optional var builderOf:String->Null<String>;
};

class Backend {
	#if macro
	static var registered:Null<Vocabulary> = null;
	static var extensions:Array<Vocabulary> = [];

	/** Called by a backend's own init macro. See the class documentation. **/
	public static function register(vocabulary:Vocabulary):Void
		registered = vocabulary;

	/**
		A library adding types of its own to whatever backend is being built.

		`vui` is why. Its components are contracts rather than controls: the
		node is data, carried in a tree that a panel WITHOUT the component
		still receives and draws a fallback for, so `LevelMeter` is not `pui`'s
		vocabulary nor `wui`'s — it is the same on all of them. Registering it
		through the backend would have meant six copies, and teaching `pui`
		about `vui` would have meant a backend depending on a library that
		depends on backends.

		So an extension registers beside the backend rather than inside it, and
		nobody learns anybody's name:

		```
		--macro pui.nui.Vocabulary.registerWithMui()
		--macro vui.macros.Vocabulary.declare("vui.meter.LevelMeter")
		```

		The backend is asked first, and a type BOTH claim is a compile error
		rather than a silent shadow: two answers for one tag is the drift this
		whole schema exists to prevent, and the one place it could still get in.
	**/
	public static function extend(vocabulary:Vocabulary):Void {
		if (extensions.indexOf(vocabulary) < 0) extensions.push(vocabulary);
	}

	/**
		The vocabulary that answers for this type: the backend, or an extension.

		The clash is caught HERE rather than when an extension registers,
		because `--macro` lines run in the order they are written and an
		extension declared before the backend would have found nothing to clash
		with. Checked where it is asked, it cannot depend on that order.
	**/
	static function owner(type:String):Null<Vocabulary> {
		var mine = registered != null && registered.knows(type);
		var theirs = null;
		for (extension in extensions) if (extension.knows(type)) { theirs = extension; break; }

		if (mine && theirs != null) {
			haxe.macro.Context.error('"$type" est à la fois un type du backend '
				+ name() + " et d'une extension. Une balise ne peut pas avoir deux "
				+ "réponses.", haxe.macro.Context.currentPos());
		}
		return mine ? registered : theirs;
	}

	/**
		The type path whose `node(props)` builds this tag, if it is not a plain
		node. See `Vocabulary.builderOf`.
	**/
	public static function builderOf(type:String):Null<String> {
		var found = owner(type);
		if (found == null || found.builderOf == null) return null;
		return found.builderOf(type);
	}

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
		// Unreachable when registered is null: ui() stops at hasVocabulary().
		return owner(type) != null;

	/** Every attribute the target accepts on this type. **/
	public static function keysOf(type:String):Array<String> {
		var found = owner(type);
		return found == null ? [] : found.keysOf(type);
	}

	/** Attributes the target requires on this type. **/
	public static function requiredOf(type:String):Array<String> {
		var found = owner(type);
		return found == null ? [] : found.requiredOf(type);
	}

	/**
		Which `PropValue` constructor an attribute takes, by name.

		`null` means the target has no such attribute — which the markup reports
		as an error.
	**/
	public static function kindOf(type:String, key:String):Null<String> {
		var found = owner(type);
		return found == null ? null : found.kindOf(type, key);
	}

	/** Types the target knows, for an error message that helps. **/
	public static function types():Array<String> {
		var out = registered == null ? [] : registered.types();
		for (extension in extensions) for (type in extension.types()) out.push(type);
		return out;
	}
	#end
}
