package mui.surface;

/**
	One declared surface: a role, a stable id, and what fills it.

	This is the substrate the framework consumes. Applications rarely write it —
	they mark methods `@:surface(Role)` and `mui.macros.Surfaces` collects them
	into `declaredSurfaces()` — but the list is real API: `surfaces()` can be
	overridden to declare past the sugar (`super.surfaces().concat([…])`).

	## The id

	Stable and load-bearing: it is the degradation target when several
	declarations meet a host that can mount one (the host takes the role's
	default id, else the first), and it is where a per-surface invalidation key
	will hang. The sugar derives it from the method name, which is why renaming
	a `@:surface` method is a compatibility event — `@:surface(Glance, "old")`
	keeps the id across a rename.

	## Why constructors per content kind, not `Model(role, Dynamic)`

	A command set and a notification carry different payloads, and `Dynamic`
	would move the mismatch from the compiler to the first run. What can be
	known at compile time is never a marker on screen — a new model-carrying
	role adds a constructor here, additively.

	The detached corner (widgets sampled by the system) adds its own
	constructor when it arrives: a sampled `render(ctx)` is a different
	contract from a live `content()`, and pretending otherwise is exactly what
	the design note warns against.
**/
enum SurfaceDecl {
	/** A living view tree: rendered by the backend, reconciled on change. **/
	Tree(role:SurfaceRole, id:String, content:() -> mui.View);

	/** Named commands, mapped to the platform's command surface. **/
	CommandSet(id:String, commands:() -> Array<Command>);
}

class SurfaceDeclTools {
	/** The role, whatever the constructor. **/
	public static function roleOf(decl:SurfaceDecl):SurfaceRole {
		return switch (decl) {
			case Tree(role, _, _): role;
			case CommandSet(_, _): Commands;
		};
	}

	/** The stable id, whatever the constructor. **/
	public static function idOf(decl:SurfaceDecl):String {
		return switch (decl) {
			case Tree(_, id, _): id;
			case CommandSet(id, _): id;
		};
	}
}
