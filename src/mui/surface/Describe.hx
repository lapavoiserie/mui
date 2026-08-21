package mui.surface;

/**
	The backend's View→Node describer, as a hook.

	The detached corner ships trees as data: a Companion surface projects a
	`nui.Snapshot` to another process, a widget (P4a) hands a sampled tree to
	the OS. Both start from the same missing step — turning the backend's own
	views into `nui.Node` — and that step is the backend's business: only it
	knows its view types and where their values live. So each backend's
	`mui.App` installs its describer here at construction, the same layering
	as sui's `extraRootsOf`: shared code calls the hook, never a backend.

	A backend that has not installed one cannot serve detached surfaces, and
	says so twice over: it leaves `Companion` out of its `@:hostedRoles`, so
	declaring one for that target does not compile — and should the hook still
	be missing at runtime (a describer installed late, a host outside the
	`mui.App` path), `describe` says so with a word and returns null rather
	than projecting an empty tree.

	## The canon

	Describers emit CANONICAL mui prop names — `text`, `label`, `onClick`,
	`spacing`, `value`, `isOn` — not their backend's internal spelling, so a
	snapshot of a cui-served tree and of a wui-served tree look the same on
	the wire, and one sink renders both. wui's `FromViews` is the reference
	implementation of the canon.

	Describing SAMPLES: conditions are evaluated, `ForEach` is expanded —
	the same reason `Snapshot.project` forces children thunks. Liveness is
	the effect around the describe, never the tree.
**/
class Describe {
	/** Installed by the backend's `mui.App` constructor. **/
	public static var impl:Null<mui.View -> nui.Node> = null;

	public static function describe(view:mui.View):Null<nui.Node> {
		if (impl == null) {
			trace("mui.surface.Describe: this backend installed no describer; "
				+ "detached surfaces cannot be served from it");
			return null;
		}
		return impl(view);
	}
}
