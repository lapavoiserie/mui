package mui;

/**
	What a backend must provide, as data.

	## Why this exists

	`mui` used to hold 132 `#if (mui_backend == …)` branches across 22 files, of
	which 109 were a `typedef` or a five-line `extends`. The volume was never the
	problem. **The direction of adaptation was**: `mui` adapted to each backend,
	so `mui` had to know all six of them, and adding a seventh meant editing
	twenty-two files in a repository that had nothing to learn from it.

	Inverted, each backend declares its own conformance under `<backend>.mui.*`
	and `mui` only resolves and checks. Nothing in this repository names a
	backend, and adding one touches **zero** files here.

	## How to read an entry

	`name` is the type, `pack` is where the alias lands, and `args` is the
	constructor's signature as printed types — with the literal `View` standing
	for the backend's own view type, whatever it is called.

	`args: null` means "an alias, checked for existence only": a `typedef`, or a
	class whose constructor is the backend's own business.

	`optional: true` means a backend may leave it out, and `mui` then publishes
	nothing under that name. Exactly one entry uses it: a terminal cannot draw an
	image, and `cui` says so by providing no `cui.mui.Image`. An application that
	reaches for `mui.ui.Image` there gets `Type not found`, at the line that
	reached — a compile error, which is the rule, though a blunter one than the
	sentence the old `#error` could write.

	## What this checks, and what it cannot

	Arity, optionality and printed argument types. The check is **nominal, not
	structural**: it says a backend's `Button` takes a `String` and an optional
	closure, and says nothing about what it does with them. Behaviour stays the
	job of `@:muiSupport` and the generated table.
**/
typedef Binding = {
	/** Where the alias is defined: `["mui"]` or `["mui", "ui"]`. **/
	var pack:Array<String>;

	var name:String;

	/**
		The constructor's arguments, printed, or `null` to check existence only.

		`View` means the backend's own view type. `*` means an argument whose
		type is deliberately not checked — a structural type, whose printed form
		is a fair-weather thing to compare strings against.
	**/
	var ?args:Array<String>;

	/** Whether a backend may leave this out entirely. **/
	var ?optional:Bool;

	/** Type parameters the alias carries, e.g. `["T"]` for `State<T>`. **/
	var ?params:Array<String>;

	/**
		Members the backend's type must have, checked by name only.

		Names rather than signatures on purpose: this exists to stop a backend
		from quietly omitting something an application depends on, and comparing
		printed signatures is the fair-weather check `args` already shows the
		limits of. A member that exists with the wrong shape fails at the
		application's call site, where the error names the actual mismatch.
	**/
	var ?requires:Array<String>;

}

class Contract {
	/** Every type `mui` publishes on a backend's behalf. **/
	public static final BINDINGS:Array<Binding> = [
		// ---- the three that carry everything else ----
		{pack: ["mui"], name: "View"},
		// `lifetime` is what an application attaches an effect to, so that
		// starting a watcher does not mean remembering to stop one. Required of
		// every backend, because an application cannot ask whether it is there.
		// `surfaces` is the declaration substrate: the backend's App answers
		// the Primary declaration plus whatever `@:surface` methods collected
		// into `declaredSurfaces()` — see mui.surface.SurfaceDecl.
		{pack: ["mui"], name: "App", requires: ["lifetime", "surfaces"]},
		{pack: ["mui"], name: "ViewComponent"},

		// ---- containers ----
		{pack: ["mui", "ui"], name: "VStack", args: ["Array<View>", "?Float"]},
		{pack: ["mui", "ui"], name: "HStack", args: ["Array<View>", "?Float"]},
		{pack: ["mui", "ui"], name: "ZStack", args: ["Array<View>"]},
		{pack: ["mui", "ui"], name: "ScrollView", args: ["Array<View>"]},
		{pack: ["mui", "ui"], name: "SafeArea", args: ["Array<View>"]},
		{pack: ["mui", "ui"], name: "TabView", args: ["*"]},

		// ---- leaves ----
		{pack: ["mui", "ui"], name: "Text", args: ["String", "?mui.ui.TextScale"]},
		{pack: ["mui", "ui"], name: "Button", args: ["String", "?() -> Void"]},
		{pack: ["mui", "ui"], name: "Divider", args: []},
		{pack: ["mui", "ui"], name: "Spacer"},
		{pack: ["mui", "ui"], name: "Image", optional: true},
		{pack: ["mui", "ui"], name: "ListView"},
		{pack: ["mui", "ui"], name: "ProgressView", args: ["?String", "?Float"]},

		// ---- controls, and the bindings they take ----
		{pack: ["mui", "ui"], name: "Toggle", args: ["String", "*"]},
		{pack: ["mui", "ui"], name: "ToggleBinding"},
		{pack: ["mui", "ui"], name: "Slider", args: ["*", "?Float", "?Float"]},
		{pack: ["mui", "ui"], name: "SliderBinding"},
		{pack: ["mui", "ui"], name: "TextInput", args: ["String", "*"]},
		{pack: ["mui", "ui"], name: "TextInputBinding"},

		// ---- flow ----
		{pack: ["mui", "ui"], name: "ConditionalView", args: ["*", "View", "?View"]},
		{pack: ["mui", "ui"], name: "ForEach"},

		// ---- reactive state ----
		//
		// All optional, and that is the honest reading of what the six backends
		// have rather than a relaxation. `cui` has no `StateAction`, `pui` and
		// `qui` have neither `Observable` nor `StateAction`, and only four have
		// an `AnimationCurve`. An application that reaches for one it does not
		// have gets `Type not found` at the line that reached — which is what it
		// got before, when `mui` simply had no branch.
		{pack: ["mui", "state"], name: "State", params: ["T"], optional: true},
		{pack: ["mui", "state"], name: "Binding", params: ["T"], optional: true},
		{pack: ["mui", "state"], name: "Observable", optional: true},
		{pack: ["mui", "state"], name: "StateAction", optional: true},
		{pack: ["mui", "state"], name: "AnimationCurve", optional: true},
	];
}
