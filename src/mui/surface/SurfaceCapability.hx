package mui.surface;

/**
	What a backend's surface host answers for a role it supports.

	This describes a host's *shape* — how many it mounts, what input it takes,
	how it updates. It is not what decides whether a role may be declared at
	all: that is `@:hostedRoles` on each backend's `mui.App`, which
	`mui.macros.Surfaces` reads at compile time to refuse a declaration with
	no host on this target.

	Nothing consumes this yet: it is P1 vocabulary, stated now so the first
	host (the Sailfish cover) implements a contract instead of inventing one.
	Read `qui.mui.CoverHost` for what a host actually does today.
**/
typedef SurfaceCapability = {
	var role:SurfaceRole;

	/** How many surfaces of this role the platform can mount. When `One`
		meets several declarations, the host mounts the role's default id if
		declared, else the first — documented degradation, an error never. **/
	var cardinality:SurfaceCardinality;

	/** What input the surface accepts. Not enforced anywhere yet — the one
		host that cares (`qui.mui.CoverHost`) strips callbacks when it mounts,
		at runtime. Making a callback prop on a `DisplayOnly` surface a
		compile error is the natural next step, the same shape as the
		`@:hostedRoles` check. **/
	var interaction:SurfaceInteraction;

	/** Live surfaces reconcile on state change; snapshot surfaces are sampled
		by the system (the detached corner — P4). **/
	var update:SurfaceUpdate;
}

enum SurfaceCardinality {
	One;
	Many;
}

enum SurfaceInteraction {
	FullTouch;
	ActionsOnly;
	DisplayOnly;
}

enum SurfaceUpdate {
	Live;
	Snapshot;
}
