package mui.surface;

/**
	What a backend's surface host answers for a role it supports.

	This is the machine-readable half of graceful degradation — the structured
	form of what `@:muiSupport` states for components. A role a backend has no
	host for is simply absent from its answers; an application cannot ask a
	terminal for a cover, only declare a Glance and let it degrade.

	Nothing consumes this yet: it is P1 vocabulary, stated now so the first
	host (the Sailfish cover) implements a contract instead of inventing one.
**/
typedef SurfaceCapability = {
	var role:SurfaceRole;

	/** How many surfaces of this role the platform can mount. When `One`
		meets several declarations, the host mounts the role's default id if
		declared, else the first — documented degradation, an error never. **/
	var cardinality:SurfaceCardinality;

	/** What input the surface accepts. Enforced at compile time where
		knowable: a callback prop on a `DisplayOnly` surface is an error, not
		a dead button. **/
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
