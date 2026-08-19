package mui.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import mui.Contract;

/**
	Resolves `mui`'s vocabulary onto the selected backend, and checks it.

	Run once from the build file:

	```
	--macro mui.macros.Bind.all()
	```

	For every entry in `mui.Contract`, this defines the alias — `mui.ui.Button`
	becomes `pui.mui.Button` — and then verifies that what it just aliased has
	the signature the contract states.

	## Why define first and check after

	`Context.error` aborts the macro, so an error raised while defining types
	leaves the rest undefined, and one honest message is followed by a cascade of
	`Type not found`. Defining everything first means a contract violation is
	reported once, about the thing that is actually wrong.

	## The three failures

	- **an argument whose type differs from the contract's** —
	  `pui.mui.HStack argument 2 is Float, mui.Contract says Int`
	- **an argument required where the contract says optional**, or the reverse —
	  `pui.mui.VStack argument 2 is optional, mui.Contract says it is required`
	- **a type the backend does not provide** — reported by Haxe as
	  `Type not found : pui.mui.Carousel`, at the `defineType` call below.

	The third is left as Haxe words it, and that is deliberate. Dressing it up
	would mean resolving the type before aliasing it, which is exactly the order
	that crashes the compiler; and the message already names the one thing the
	reader needs, next to the machinery that wanted it.

	All three are compile errors rather than a surprise at first use — the rule
	the rest of this ecosystem follows: what can be known at compile time is
	never a marker on screen.
**/
class Bind {
	public static function all():Void {
		var backend = Context.definedValue("mui_backend");
		if (backend == null) {
			Context.error("mui requires -D mui_backend=<backend>, and the backend must "
				+ "provide <backend>.mui.* — see mui.Contract", Context.currentPos());
			return;
		}

		var pos = Context.currentPos();

		// The view rule comes with the vocabulary, not as a line each backend
		// remembers to add. Registered here because every mui build passes
		// through Bind.all() — some init files carried the line, some did not,
		// and the rule silently protected some backends and not others.
		// register() guards against double registration, so builds that still
		// carry their own line lose nothing.
		rui.macros.ViewRule.register(backend + ".mui.App", "body", true);
		// Surface declarations are views too: any `@:surface` method runs
		// inside its surface's effect, so it reads under the same rule as
		// `body()` — matched by metadata, because the methods have no fixed
		// names for a list to name.
		rui.macros.ViewRule.registerMeta(backend + ".mui.App", ":surface", true);

		// Every alias first, and not one type resolved yet.
		//
		// Resolving `<backend>.mui.TabView` before `mui.View` exists pulls
		// `mui.ui.TabItem`, whose `content` is `mui.View` -- a type this macro
		// has not defined yet. Haxe 4.3.6 does not report that as a missing
		// type: it crashes in `forLoop.ml`, several frames from anything a
		// reader would connect to the cause. Defining first costs nothing,
		// because an alias needs no knowledge of what it points at.
		for (binding in Contract.BINDINGS) {
			// An optional binding is resolved before it is aliased, because an
			// alias to a type that does not exist is an error at the alias. That
			// early resolution is safe only because the one optional entry names
			// a type that borrows nothing from `mui`; a required one would hit
			// the crash described above.
			if (binding.optional == true) {
				var here = backend + ".mui." + binding.name;
				if ((try Context.getType(here) catch (_:Dynamic) null) == null) continue;
			}
			var params = binding.params == null ? [] : binding.params;
			Context.defineType({
				pack: binding.pack,
				name: binding.name,
				pos: pos,
				params: [for (p in params) {name: p}],
				kind: TDAlias(TPath({
					pack: [backend, "mui"],
					name: binding.name,
					// `State<T>` aliases `<backend>.mui.State<T>`: the parameter
					// has to be handed on, or the alias asks for none and the
					// target complains that it wanted one.
					params: [for (p in params) TPType(TPath({pack: [], name: p}))],
				})),
				fields: [],
			});
		}

		// One flag, read off the backend's own App.
		//
		// Whether the engine owns the process decides whether an application's
		// `main()` may do anything. It cannot be answered by resolving a type,
		// because the answer is a *fact about* a type — so the backend states it
		// as metadata and this turns it into a define. Examples used to write
		// `#if (mui_backend == "cui" || mui_backend == "pui")`, a list a seventh
		// backend would have had to be added to by hand, in every application.
		ownsMain(backend);

		// The check waits until everything has been typed.
		//
		// Resolving a backend's façade from inside this macro types its
		// constructor while `mui.View` is still an alias nothing has followed —
		// and Haxe 4.3.6 answers that by crashing in `forLoop.ml`, several frames
		// from anything a reader would connect to the cause. After typing, every
		// alias has been followed and the same resolution is ordinary.
		Context.onAfterTyping(_ -> verify(backend, pos));
	}

	/** Define `mui_owns_main` if `<backend>.mui.App` carries `@:muiOwnsMain`. **/
	static function ownsMain(backend:String):Void {
		// Safe to resolve here, before the aliases: an App borrows nothing from
		// `mui`, so this cannot walk into the half-defined vocabulary.
		var app = try Context.getType(backend + ".mui.App") catch (_:Dynamic) null;
		if (app == null) return;
		switch (Context.follow(app)) {
			case TInst(t, _):
				if (t.get().meta.has(":muiOwnsMain"))
					haxe.macro.Compiler.define("mui_owns_main");
			case _:
		}
	}

	static function verify(backend:String, pos:Position):Void {
		for (binding in Contract.BINDINGS) {
			var path = backend + ".mui." + binding.name;
			var type = try Context.getType(path) catch (_:Dynamic) null;

			if (type == null) {
				if (binding.optional == true) continue;
				Context.error('backend "$backend" does not provide $path — '
					+ 'mui.Contract lists ${binding.name}', pos);
				continue;
			}
			checkRequired(backend, binding, type, pos);
			check(backend, binding, type, pos);
		}
	}

	/**
		Every member `mui.Contract` says the backend must carry.

		By name only — see the note on `Binding.requires`. What this catches is
		the omission, which an application has no way to detect: `mui.App` is an
		alias for the backend's own class, so a missing member is a compile error
		in the application, naming the backend's type, for something the
		application never mentioned.
	**/
	static function checkRequired(backend:String, binding:Binding, type:Type, pos:Position):Void {
		if (binding.requires == null) return;

		var cls = switch (Context.follow(type)) {
			case TInst(t, _): t.get();
			case _: null;
		}
		if (cls == null) return;

		for (name in binding.requires) {
			if (!hasField(cls, name))
				Context.error('${backend}.mui.${binding.name} has no "$name" — '
					+ 'mui.Contract requires it', pos);
		}
	}

	/**
		Walk the superclasses too.

		`ClassType.fields` lists only what a class declares itself, and every
		backend's `mui.App` is a thin façade over its own `App` — so a member
		that is there and inherited would read as missing, and the check would
		fail on all six at once. Found the first time it ran.
	**/
	static function hasField(cls:Null<haxe.macro.Type.ClassType>, name:String):Bool {
		var at = cls;
		while (at != null) {
			for (field in at.fields.get())
				if (field.name == name) return true;
			at = at.superClass == null ? null : at.superClass.t.get();
		}
		return false;
	}

	static function check(backend:String, binding:Binding, type:Type, pos:Position):Void {
		if (binding.args == null) return;

		var cls = switch (Context.follow(type)) {
			case TInst(t, _): t.get();
			case _: null;
		}
		if (cls == null || cls.constructor == null) {
			Context.error('${backend}.mui.${binding.name} has no constructor — '
				+ 'mui.Contract states one', pos);
			return;
		}

		var args = switch (Context.follow(cls.constructor.get().type)) {
			case TFun(a, _): a;
			case _: null;
		}
		if (args == null) return;

		if (args.length < binding.args.length) {
			Context.error('${backend}.mui.${binding.name} takes ${args.length} argument(s), '
				+ 'mui.Contract says ${binding.args.length}', pos);
			return;
		}

		// A backend may add arguments beyond the contract, as long as they are
		// optional: code written against the contract still compiles, and the
		// extra is there for someone who has chosen this platform deliberately.
		// `cui` does exactly that -- its `ScrollView` and `TabView` let the
		// application own the offset and the selection, because a terminal keeps
		// neither for you.
		for (i in binding.args.length...args.length) {
			if (args[i].opt) continue;
			Context.error('${backend}.mui.${binding.name} argument ${i + 1} is required, '
				+ 'and mui.Contract does not name it — an argument past the contract '
				+ 'has to be optional', pos);
			return;
		}

		for (i in 0...binding.args.length) {
			var wanted = binding.args[i];
			if (wanted == "*") continue;

			var optional = StringTools.startsWith(wanted, "?");
			if (optional) wanted = wanted.substr(1);

			if (args[i].opt != optional) {
				Context.error('${backend}.mui.${binding.name} argument ${i + 1} is '
					+ (args[i].opt ? "optional" : "required") + ', mui.Contract says it is '
					+ (optional ? "optional" : "required"), pos);
				continue;
			}

			// An optional argument's type is `Null<T>`; the contract states `T`.
			var got = TypeTools.toString(args[i].t);
			if (StringTools.startsWith(got, "Null<") && StringTools.endsWith(got, ">"))
				got = got.substr(5, got.length - 6);

			// `View` in the contract means whatever this backend calls its view.
			var expected = StringTools.replace(wanted, "View", backend + ".View");
			if (expected == wanted) expected = wanted;

			if (normalise(got) != normalise(expected) && normalise(got) != normalise(wanted))
				Context.error('${backend}.mui.${binding.name} argument ${i + 1} is $got, '
					+ 'mui.Contract says $wanted', pos);
		}
	}

	/** Printed types differ by whitespace alone often enough to be worth this. **/
	static function normalise(s:String):String
		return StringTools.replace(StringTools.replace(s, " ", ""), "\t", "");
}
#else
class Bind {}
#end
