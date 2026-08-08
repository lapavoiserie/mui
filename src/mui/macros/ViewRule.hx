package mui.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.Tools;
#end

/**
	**A view may only read things that are immutable or observable.**

	The rule MVCoconut is built on, checked here rather than hoped for.

	## Why it is a rule and not advice

	A view is a function of state, and the framework re-runs it when that state
	changes. It can only do that for state it can *observe*. A view that reads a
	plain mutable field is not wrong-looking — it compiles, it renders once, and
	it then goes quietly stale, because nothing can tell it to run again.

	That is exactly what happened here before this check existed: an example read
	a plain `static var`, nothing could observe it, and the gap was filled by
	calling the backend's `rerenderNui()` by hand — framework plumbing in
	application code, on a backend the application is not supposed to name. The
	symptom was a manual call; the cause was a view depending on something
	unobservable.

	## What counts

	- **Observable** — `rui.state.State<T>`, or anything implementing
	  `rui.Observable`. A write notifies, so the view can re-run.
	- **Immutable** — a `final` field, or a persistent structure like
	  `rui.structures.ImmutableList`. It cannot change under the view, so there
	  is nothing to observe.
	- **Local** — a variable or parameter inside the view. It is recomputed on
	  every run by definition.

	Anything else is a compile error naming the field.

	## What this does not check

	Mutation *through* an observable: `state.value.push(x)` changes an array in
	place, notifies nobody, and reads as a legal observable access. That is what
	`ImmutableList` is for — a structure whose `push` returns a new list makes
	the mistake unwriteable rather than merely detectable.
**/
class ViewRule {
	#if macro
	static var registered = false;

	/** Add to build.hxml: `--macro mui.macros.ViewRule.register()`. **/
	public static function register():Void {
		if (registered) return;
		registered = true;

		Context.onAfterTyping(function(types:Array<ModuleType>) {
			for (mt in types) {
				switch (mt) {
					case TClassDecl(ref):
						var cls = ref.get();
						if (!isApp(cls) || isLibrary(cls)) continue;
						checkView(cls);
					default:
				}
			}
		});
	}

	static function isApp(cls:ClassType):Bool {
		var current = cls.superClass == null ? null : cls.superClass.t.get();
		while (current != null) {
			if (current.name == "App" && current.pack.join(".") == "mui") return true;
			current = current.superClass == null ? null : current.superClass.t.get();
		}
		return false;
	}

	/** `mui.App` itself and the backends' own classes are not user views. **/
	static function isLibrary(cls:ClassType):Bool {
		var root = cls.pack.length == 0 ? "" : cls.pack[0];
		return root == "mui" || root == "wui" || root == "cui" || root == "sui" || root == "aui";
	}

	static function checkView(cls:ClassType):Void {
		for (field in cls.fields.get()) {
			if (field.name != "view") continue;
			var e = field.expr();
			if (e != null) walk(e, cls);
		}
	}

	static function walk(e:TypedExpr, owner:ClassType):Void {
		if (e == null) return;

		switch (e.expr) {
			// A field *read*. A call through a field is code, not state.
			case TField(_, fa):
				var cf = fieldOf(fa);
				if (cf != null && declaredBy(fa, owner) && !isCallable(cf)) {
					if (!acceptable(cf)) {
						Context.error('Une vue ne peut lire que de l\'immuable ou de l\'observable.\n'
							+ '  "${cf.name}" est une variable mutable et non observable, donc rien\n'
							+ '  ne peut prévenir la vue quand elle change : l\'affichage resterait figé.\n'
							+ '  Rendez-la `final`, ou déclarez-la @:state, ou utilisez ImmutableList.',
							cf.pos);
					}
				}
			case _:
		}

		e.iter(function(sub) walk(sub, owner));
	}

	static function fieldOf(fa:FieldAccess):Null<ClassField> {
		return switch (fa) {
			case FInstance(_, _, cf): cf.get();
			case FStatic(_, cf): cf.get();
			case FClosure(_, cf): cf.get();
			case _: null;
		};
	}

	/** Only the app's own fields are judged; library internals are not its doing. **/
	static function declaredBy(fa:FieldAccess, owner:ClassType):Bool {
		var holder = switch (fa) {
			case FInstance(ref, _, _): ref.get();
			case FStatic(ref, _): ref.get();
			case FClosure(_, _): owner;
			case _: null;
		};
		if (holder == null) return false;
		return !isLibrary(holder);
	}

	static function isCallable(cf:ClassField):Bool {
		return switch (cf.type.follow()) {
			case TFun(_, _): true;
			case _: false;
		};
	}

	static function acceptable(cf:ClassField):Bool {
		if (cf.isFinal) return true;

		return switch (cf.type.follow()) {
			case TInst(ref, _):
				var c = ref.get();
				if (c.name == "ImmutableList") return true;
				if (c.name == "State") return true;   // rui.state.State and the backends' subclasses
				implementsObservable(c);
			case _: false;
		};
	}

	static function implementsObservable(cls:ClassType):Bool {
		var current = cls;
		while (current != null) {
			for (i in current.interfaces) {
				if (i.t.get().name == "Observable") return true;
			}
			current = current.superClass == null ? null : current.superClass.t.get();
		}
		return false;
	}
	#end
}
