package mui.surface;

/**
	What mounting a declaration hands back: the one handle the driver needs.

	Behind `dispose` sits the whole per-surface record — the root effect, the
	surface's own `rui.Lifetime`, whatever the backend allocated natively.
	Dispose is idempotent by contract: the driver calls it on container loss
	*and* on application release, and those overlap.
**/
typedef MountedSurface = {
	var dispose:() -> Void;
}

/**
	A backend's answer for one surface role: how the container is found, and
	how a declaration becomes something on screen.

	One host per supported role per backend. The first implementation is the
	Sailfish cover (`qui.mui.CoverHost`) — the corner of the design that
	exercises everything hard: a container that does not exist at startup, is
	created lazily, and can be destroyed and recreated behind the app's back.

	## The lifecycle, and who owns which half

	The framework owns the states — Declared, Waiting, Attached, Detached,
	Disposed — the host implements the transitions:

	- `acquire` is Waiting: the host watches for its container and calls
	  `onReady` each time one appears, `onLost` each time it goes away. Both
	  may fire many times; `onReady` after `onLost` is the recreate path.
	- `mount` is Attached: build the per-surface record — its own effect, its
	  own `rui.Lifetime` (a shared one would sweep the other surface's `keep`
	  keys) — and render the declaration into the container.
	- `MountedSurface.dispose` is the way back out, for both Detached and
	  Disposed.

	`Container` is the backend's own handle type (`ui.Item` on qui). It never
	crosses into shared code: the driver passes it from `acquire` to `mount`
	and looks at nothing inside it.
**/
interface SurfaceHost<Container> {
	/** What this host can honour — role, cardinality, interactivity, update
		model. Stated, not discovered: this is the machine-readable half of
		graceful degradation. **/
	function capabilities():SurfaceCapability;

	/** Watch for the container. May call back many times — lazy creation,
		destruction, recreation. Never calls `onReady` with a dead container. **/
	function acquire(onReady:Container -> Void, onLost:() -> Void):Void;

	/** Render one declaration into a live container. The returned record is
		the only handle the driver keeps; its `dispose` must be idempotent. **/
	function mount(decl:SurfaceDecl, container:Container):MountedSurface;
}
