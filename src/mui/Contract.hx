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
	nothing under that name. An application that reaches for a name its backend
	does not have gets `Type not found`, at the line that reached — a compile
	error, which is the rule, though a blunter one than the sentence the old
	`#error` could write. `Picker` is the entry that uses it today, while it is
	brought to the backends that have no drop-down yet.

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
		// How it is set, beyond its scale: a family the application ships, a
		// weight, italic, digits of one width. Every backend takes it, and
		// honours what it can -- a terminal has one font, so it takes the
		// weight as bold and the italic and leaves the rest.
		{pack: ["mui", "ui"], name: "Text", args: ["String", "?mui.ui.TextScale", "?mui.ui.TextStyle"]},
		// The icon is the canon's: `nui`'s `Button` node has carried one since
		// pictures landed, and four backends draw it. Optional, so an
		// application that wants none writes none -- and named `mui.ui.IconName`
		// so a name outside the vocabulary does not compile.
		{pack: ["mui", "ui"], name: "Button", args: ["String", "?() -> Void", "?mui.ui.IconName"]},
		{pack: ["mui", "ui"], name: "Divider", args: []},
		{pack: ["mui", "ui"], name: "Spacer"},
		// Where the picture comes from, what stands in its place, and how it is
		// sized: required of all six since 2026-09-16, cui included -- a
		// terminal draws the alt rather than nothing.
		{pack: ["mui", "ui"], name: "Image", args: ["String", "String", "?mui.ui.ImageOptions"]},
		{pack: ["mui", "ui"], name: "Icon", args: ["mui.ui.IconName", "?String"]},
		{pack: ["mui", "ui"], name: "ListView"},
		{pack: ["mui", "ui"], name: "ProgressView", args: ["?String", "?Float"]},

		// ---- controls, and the bindings they take ----
		{pack: ["mui", "ui"], name: "Toggle", args: ["String", "*"]},
		{pack: ["mui", "ui"], name: "ToggleBinding"},
		{pack: ["mui", "ui"], name: "Slider", args: ["*", "?Float", "?Float"]},
		{pack: ["mui", "ui"], name: "SliderBinding"},
		{pack: ["mui", "ui"], name: "TextInput", args: ["String", "*"]},
		{pack: ["mui", "ui"], name: "TextInputBinding"},
		// A value typed in that never enters the tree: a stream key, a token.
		// `placeholder`, whether one is already stored, and where the value goes
		// once -- no binding, because there is nothing to bind to. nui's canon
		// states the type and what a renderer owes it.
		//
		// **Optional, and meant to stay optional.** A backend that has not built
		// one does not get a silent approximation: an application naming it
		// there fails to compile at that line, which for a secret is the only
		// honest answer. Only `pui` has one today.
		{pack: ["mui", "ui"], name: "SecretInput", args: ["String", "*", "?Bool", "?String"], optional: true},
		// A drop-down list, its options as text, its selection an index (-1 for
		// none). Required since 2026-09-16: all six have one. How it opens is
		// each backend's own -- a popup on Android, a menu on Silica and WinUI,
		// an overlay pui had to build, and a row that cycles in a terminal,
		// whose buffer has no z-order. The contract is the options and the
		// index; the drawing never was.
		{pack: ["mui", "ui"], name: "Picker", args: ["String", "Array<String>", "*"]},
		{pack: ["mui", "ui"], name: "PickerBinding"},

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
