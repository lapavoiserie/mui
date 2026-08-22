package mui.state;

import haxe.macro.Expr;

/**
	Joins the two halves: `rui`'s durable port and `kui`'s device store.

	Neither half may name the other. `rui` is the reactive core and must not
	know that native capabilities exist; `kui-store` is a capability and must
	not depend on the reactive core, which is the layering `kui` exists to
	protect. `mui` is where a backend's pieces are already named — it holds the
	`Describe` and `Resample` registers for the same reason — so it holds this.

	One call, once, before any durable cell is constructed:

	```haxe
	mui.state.Durable.install("app");
	```

	The backend's `mui.App` does it; an application does not.
**/
class Durable {
	/**
		Resolve the device store and hand it to `rui`.

		`writer` names this instance — "app" for the application itself,
		"glance" for a widget extension hosting its own. It is carried into
		every entry, for messages and for recognising "not me"; the sequence,
		not the name, decides who wins.

		Idempotent: a second call replaces the store, which is what a process
		re-entering its own boot does.
	**/
	public static macro function install(?writer:haxe.macro.Expr):haxe.macro.Expr {
		// Expands to nothing where this platform has no store. It has to: the
		// backend's `mui.App` calls this unconditionally, and `kui.Kui.get`
		// errors at macro time for a missing capability — so a build that
		// asked for no durable cell would fail for a feature it never used.
		//
		// Not a silence. An application that *does* ask, with `@:state(durable)`,
		// is refused at the field, by name, with the platform named too.
		if (!rui.macros.DurableState.hasStore())
			return macro {};

		// An omitted optional macro argument arrives as the *expression* `null`,
		// not as Haxe null — so both have to be checked, or the store records
		// every write as coming from nobody.
		var given = switch (writer) {
			case null: false;
			case {expr: EConst(CIdent("null"))}: false;
			case _: true;
		}
		var who = given ? writer : macro "app";
		return macro {
			rui.state.Durable.store = new mui.state.KuiStore(kui.Kui.get(store.Store));
			rui.state.Durable.writer = $who;
		};
	}
}
