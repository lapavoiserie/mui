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

	A backend that has not installed one cannot serve detached surfaces —
	`describe` says so with a word and returns null; the caller degrades (a
	Companion declaration on such a backend simply never projects, the same
	silent no-op as any unsupported role).

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
