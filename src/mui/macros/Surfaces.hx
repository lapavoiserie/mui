package mui.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
	Collects `@:surface(Role)` methods into `declaredSurfaces()`.

	The `@:state` mechanism applied to surfaces: an ordinary method carrying
	metadata *is* the declaration — no fixed method names, no override
	detection, and as many declarations per role as the application wants
	(an iOS application offers several widgets; a fixed `glance()` capped it
	at one).

	```haxe
	@:surface(Glance) function today():View { … }        // id "today"
	@:surface(Glance, "progress") function p():View { … } // id kept across renames
	@:surface(Commands) function shortcuts():Array<Command> { … }
	```

	The method name is the surface's stable id unless the second argument pins
	it. Each backend's `mui.App` carries `@:autoBuild(mui.macros.Surfaces.build())`,
	so this runs on every mui application — beside the backend's `StateMacro`,
	never instead of it, and never as a second `@:autoBuild` on the same class
	(running a backend's state macro twice corrupts `@:state` fields; this one
	is additive and touches nothing it did not generate).

	Return types are checked by the typer through the generated code: the thunk
	for a `Tree` role must return `mui.View`, for `Commands` an
	`Array<mui.surface.Command>` — a mismatch is a compile error at the method.
	What this macro checks itself is what the typer cannot word well: an
	unknown role, `Primary` (implicit — it is `body()`), `Notification` (no
	declaration form until the detached subsystem), arguments on a declaration,
	and a duplicate role/id pair, including against superclasses.
**/
typedef Parsed = {role:String, id:String, optional:Bool};

class Surfaces {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var decls:Array<Expr> = [];
		var seen = new Map<String, String>(); // "Role/id" -> where it came from

		inheritedDeclarations(seen);

		for (f in fields) {
			var entries = [for (m in f.meta) if (m.name == ":surface") m];
			if (entries.length == 0) continue;
			if (entries.length > 1)
				Context.error("One @:surface per method — a method declares one surface.", f.pos);
			var m = entries[0];

			// `Context.error` reports and returns, so every refusal below also
			// steps past the field: generating a declaration for a half-parsed
			// one would bury the honest message under follow-up noise.
			var fn = switch (f.kind) {
				case FFun(fn): fn;
				case _:
					Context.error("@:surface goes on a method — the method's body is the surface's content.", f.pos);
					continue;
			}
			if (fn.args.length != 0) {
				Context.error('@:surface method "${f.name}" must take no arguments: '
					+ "the framework calls it inside the surface's own effect.", f.pos);
				continue;
			}
			if (f.access != null && f.access.contains(AStatic)) {
				Context.error('@:surface method "${f.name}" cannot be static: '
					+ "a surface reads the application's state.", f.pos);
				continue;
			}

			var parsed = parse(m, f.name, f.pos);
			if (parsed == null) continue;
			checkHosted(parsed, f.name, f.pos);
			var key = parsed.role + "/" + parsed.id;
			if (seen.exists(key)) {
				Context.error('Surface ${parsed.role} "${parsed.id}" is already declared by ${seen.get(key)}. '
					+ 'Ids are stable identity — pin a different one with @:surface(${parsed.role}, "other-id").',
					f.pos);
				continue;
			}
			seen.set(key, 'method "${f.name}"');

			decls.push(declFor(parsed.role, parsed.id, f));
		}

		if (decls.length == 0) return fields;

		// An explicit EArrayDecl: `$a{}` in call-argument position splices the
		// declarations as separate arguments, and `concat` got handed one bare
		// SurfaceDecl. Found by the first fixture that declared anything.
		var list:Expr = {expr: EArrayDecl(decls), pos: Context.currentPos()};
		fields.push({
			name: "declaredSurfaces",
			access: [APublic, AOverride],
			pos: Context.currentPos(),
			doc: "Collected from this class's @:surface methods by mui.macros.Surfaces.",
			kind: FFun({
				args: [],
				ret: macro :Array<mui.surface.SurfaceDecl>,
				expr: macro return super.declaredSurfaces().concat($e{list}),
			}),
		});
		return fields;
	}

	/** Role, id and the `optional` flag out of one `@:surface(…)`.
		`null` after a reported refusal — the caller skips the field. **/
	static function parse(m:MetadataEntry, methodName:String, pos:Position):Null<Parsed> {
		var roles = roleNames();

		if (m.params == null || m.params.length == 0) {
			Context.error('@:surface names a role: @:surface(${sayRoles(roles)}).', pos);
			return null;
		}
		if (m.params.length > 3) {
			Context.error("@:surface takes a role, optionally an id, optionally `optional` — nothing more.", pos);
			return null;
		}

		var role = switch (m.params[0].expr) {
			case EConst(CIdent(name)) if (roles.contains(name)): name;
			case EConst(CIdent(name)):
				Context.error('"$name" is not a mui.surface.SurfaceRole. Roles: ${sayRoles(roles)}.', m.params[0].pos);
				return null;
			case _:
				Context.error('@:surface\'s first argument is a role name: @:surface(${sayRoles(roles)}).', m.params[0].pos);
				return null;
		}

		// Primary is body(), everywhere, required — a declaration of it can
		// only ever shadow that fact.
		if (role == "Primary") {
			Context.error("Primary is implicit: it is body(). Remove @:surface(Primary).", pos);
			return null;
		}
		// Refused rather than accepted-and-ignored: a notification needs the
		// serialized-state contract of the detached subsystem, and pretending
		// a live tree covers it would be a marker on screen later.
		if (role == "Notification") {
			Context.error("Notification has no declaration form yet — it arrives with the "
				+ "detached-surface subsystem (P4).", pos);
			return null;
		}

		var id = methodName;
		var optional = false;
		for (i in 1...m.params.length) {
			switch (m.params[i].expr) {
				case EConst(CString(s, _)): id = s;
				case EConst(CIdent("optional")): optional = true;
				case _:
					Context.error("After the role, @:surface takes the surface's id as a string "
						+ "and/or `optional`.", m.params[i].pos);
					return null;
			}
		}
		return {role: role, id: id, optional: optional};
	}

	/**
		Refuse a role the backend being compiled has no host for.

		The rule the family keeps: what is knowable at compile time is a
		compile error, never a silence. Which roles a backend hosts *is*
		knowable — each backend states them as `@:hostedRoles` on its
		`mui.App` — so a declaration that would fly nowhere on this target is
		refused at the declaration, naming the backend.

		Accepting one is then an act of the application, in the source, where
		the next reader sees it: `@:surface(Glance, optional)`. That is what
		"degradation is declared, not accidental" has to mean to be worth
		anything — declared by the application for this build, not asserted in
		a doc comment.

		A backend that states nothing cannot be checked; that is a hole in the
		framework, not in the application, so it warns here rather than
		failing someone else's build.
	**/
	static function checkHosted(parsed:Parsed, methodName:String, pos:Position):Void {
		if (parsed.optional) return;

		var hosted = hostedRoles();
		var backend = Context.defined("mui_backend") ? Context.definedValue("mui_backend") : "this backend";
		if (hosted == null) {
			Context.warning('$backend states no @:hostedRoles on its mui.App, so surface '
				+ 'declarations cannot be checked against it.', pos);
			return;
		}
		// A Companion is served over the network, to machines this one has
		// merely *met*. Nothing about declaring surfaces implies wanting that,
		// so the whole detached-over-cafos corner is off unless the build asks
		// for it — and asking is one define, in the build file, where it is
		// reviewable. A backend that states Companion is saying it *could*
		// serve one (it installs a describer), never that this build does.
		if (parsed.role == "Companion" && !Context.defined(CAFOS_DEFINE)) {
			Context.error('a Companion surface is served over the network by cafos, which is off in '
				+ 'this build: "${parsed.id}" would be declared but never reachable.\n'
				+ '  Turn it on for this build with -D $CAFOS_DEFINE (and cafos on the classpath), '
				+ 'or mark the declaration optional.',
				pos);
			return;
		}

		if (hosted.contains(parsed.role)) return;

		Context.error('$backend hosts no ${parsed.role}: surface "${parsed.id}" would fly nowhere here'
			+ (hosted.length == 0 ? " (it hosts no declared surface at all)" : ' (it hosts ${hosted.join(", ")})')
			+ '. Accept that with @:surface(${parsed.role}, optional), or build for a backend that hosts it.',
			pos);
	}

	/**
		The one switch that turns the networked corner on.

		Pavois is two things at once — a way to write native applications, and
		a way to let their surfaces live on other machines — and the second
		must never arrive by default with the first. Off, a `Companion`
		declaration does not compile; on, it does, and the application still
		has to call `cafos.mui.CompanionServe.serve` before anything reaches
		the network. Two deliberate acts, neither of them a default.
	**/
	public static inline var CAFOS_DEFINE = "mui_cafos";

	/**
		The roles the backend states it hosts, or `null` if none says.

		Read off the superclass chain rather than by resolving `mui.App`: the
		application being built already extends the backend's class, and the
		metadata rides up that chain — which also lets an application's own
		intermediate base class widen the set if it ever hosts something
		itself.
	**/
	public static function hostedRoles():Null<Array<String>> {
		var cls = Context.getLocalClass();
		if (cls == null) return null;

		var at = cls.get().superClass == null ? null : cls.get().superClass.t.get();
		while (at != null) {
			if (at.meta.has(":hostedRoles")) {
				var out:Array<String> = [];
				for (m in at.meta.extract(":hostedRoles")) {
					if (m.params == null) continue;
					for (p in m.params) switch (p.expr) {
						case EConst(CIdent(name)): out.push(name);
						case EConst(CString(name, _)): out.push(name);
						case _:
					}
				}
				return out;
			}
			at = at.superClass == null ? null : at.superClass.t.get();
		}
		return null;
	}

	/** `Tree(role, id, thunk)` for tree roles, `CommandSet(id, thunk)` for Commands. **/
	static function declFor(role:String, id:String, f:Field):Expr {
		// The call carries the method's position: a wrong return type is then
		// reported at the method, by the typer, in the typer's own words.
		var call:Expr = {
			expr: ECall({expr: EField({expr: EConst(CIdent("this")), pos: f.pos}, f.name), pos: f.pos}, []),
			pos: f.pos,
		};
		var thunk = macro function() return $e{call};

		return if (role == "Commands") {
			macro mui.surface.SurfaceDecl.CommandSet($v{id}, $e{thunk});
		} else {
			var roleExpr:Expr = {expr: EField(macro mui.surface.SurfaceRole, role), pos: f.pos};
			macro mui.surface.SurfaceDecl.Tree($e{roleExpr}, $v{id}, $e{thunk});
		}
	}

	/**
		Role/id pairs the superclasses already declared.

		A subclass overriding the *method* inherits the declaration and merely
		changes its content — that is dynamic dispatch and it is wanted. What
		must be refused is a second *declaration* of the same role/id, which
		would mount twice.
	**/
	static function inheritedDeclarations(seen:Map<String, String>):Void {
		var cls = Context.getLocalClass();
		if (cls == null) return;
		var at = cls.get().superClass == null ? null : cls.get().superClass.t.get();
		while (at != null) {
			for (field in at.fields.get()) {
				if (!field.meta.has(":surface")) continue;
				for (m in field.meta.extract(":surface")) {
					var role = switch (m.params[0].expr) {
						case EConst(CIdent(name)): name;
						case _: continue;
					}
					var id = field.name;
					if (m.params.length == 2) switch (m.params[1].expr) {
						case EConst(CString(s, _)): id = s;
						case _:
					}
					seen.set(role + "/" + id, at.name);
				}
			}
			at = at.superClass == null ? null : at.superClass.t.get();
		}
	}

	static function roleNames():Array<String> {
		return switch (Context.follow(Context.getType("mui.surface.SurfaceRole"))) {
			case TEnum(ref, _): ref.get().names;
			case _: [];
		};
	}

	static function sayRoles(roles:Array<String>):String
		return roles.filter(r -> r != "Primary" && r != "Notification").join(" | ");
}
#else
class Surfaces {}
#end
