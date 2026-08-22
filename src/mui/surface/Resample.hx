package mui.surface;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Ask for a new sample of a **snapshot** surface.

	A live surface needs nothing like this: it is an effect, it reconciles when
	the state it read changes, and asking would be asking twice. A snapshot
	surface is the other half of the model — the system samples it when it
	decides, which on a home screen means "when it bound the widget, and then
	never again on its own". Something has to say *now*, and only the
	application knows when its content became worth showing.

	So this is the one call the detached-snapshot corner needs, and every host
	of it answers the same way under different names: Android pushes a fresh
	picture into the widget's state, WidgetKit calls `reloadTimelines`, a
	self-drawn painter repaints. The application says the same sentence to all
	of them.

	```haxe
	count.set(count.get() + 1);
	mui.surface.Resample.request(Glance);   // the widget is worth redrawing
	```

	## Why it is a macro

	Because the honest answer on a backend that hosts no such surface is
	*nothing at all*, and nothing should also cost nothing. The role a backend
	hosts is knowable at compile time — each states `@:hostedRoles` on its
	`mui.App`, which is what `mui.macros.Surfaces` already refuses declarations
	against — so a `request(Glance)` in a build targeting a terminal compiles
	to no code whatever. That is not a silence: the application could not have
	declared the surface here without writing `optional`, which is where it
	accepted, in its own source, that this surface flies nowhere on this
	target. Refreshing what flies nowhere is a no-op by construction.

	Where the role IS hosted, the call is real, and a backend that hosts the
	role but installed no resampler says so with a word — that hole belongs to
	the backend, not to the application.
**/
class Resample {
	#if !macro
	/**
		How this backend takes a new sample. Installed by the backend's
		`mui.App`, the same shape as `mui.surface.Describe.impl`: shared code
		calls the hook, never a backend.
	**/
	public static var impl:Null<(SurfaceRole, Null<String>) -> Void> = null;

	/**
		The runtime half. `request` compiles to this wherever the role is
		hosted; call it directly only if you already know it is.
	**/
	public static function now(role:SurfaceRole, ?id:String):Void {
		if (impl == null) {
			trace("mui.surface.Resample: this backend hosts " + role
				+ " but installed no resampler; the surface will not refresh");
			return;
		}
		impl(role, id);
	}
	#end

	/**
		Ask for a new sample of the surfaces of `role` — or of the one whose id
		is `id`, when several are declared.

		Compiles to nothing where this backend hosts no such role. See the
		class doc for why that is a no-op and not a silence.
	**/
	public static macro function request(role:Expr, ?id:Expr):Expr {
		var idExpr = id == null ? macro null : id;

		// A role named literally is the case worth resolving: anything else
		// (a variable, a computed value) cannot be checked here, so it keeps
		// the runtime call and the runtime answer.
		var named = switch (role.expr) {
			case EConst(CIdent(name)): name;
			case EField(_, name): name;
			case _: null;
		};
		if (named != null) {
			var hosted = mui.macros.Surfaces.hostedRoles();
			if (hosted != null && !hosted.contains(named)) {
				// Not hosted here: the declaration itself had to say
				// `optional` to compile, so refreshing it is nothing.
				return macro {};
			}
		}

		var roleExpr = named != null
			? {expr: EField(macro mui.surface.SurfaceRole, named), pos: role.pos}
			: role;
		return macro mui.surface.Resample.now($e{roleExpr}, $e{idExpr});
	}
}
