package mui.surface;

/**
	What a surface is *for* — portable across backends, never a native surface.

	An application declares roles; each backend maps a role onto the surface its
	platform actually has: `Glance` is the Sailfish cover, an iOS widget, and
	nothing at all on a terminal. Exposing the native surfaces themselves —
	"cover", "widget", "live tile" — would have made every application name a
	platform; several of those are the same thing wearing different clothes.

	A role a backend does not support degrades to a silent no-op. That is the
	role system's whole promise: degradation *declared* by the backend's host
	capabilities, instead of accidental (the pre-surface state of things, where
	an unsupported modifier was simply dropped on the floor).

	`Primary` never appears in a declaration: it is implicit, it is `body()`,
	and it is required everywhere. `@:surface(Primary)` is a compile error
	saying so.
**/
enum SurfaceRole {
	/** The main window. Implicit — `body()` — and universal. **/
	Primary;

	/** A read-at-a-glance summary: Sailfish cover, iOS/Android widget. **/
	Glance;

	/** The platform's settings surface: macOS Settings scene, settings page. **/
	Preferences;

	/** Named commands: menu bar on macOS, key bindings on a terminal. **/
	Commands;

	/** A system notification. No declaration form yet — arrives with the
		detached subsystem, whose serialized-state contract it needs. **/
	Notification;

	/** An additional top-level window, where the platform has windows. **/
	Auxiliary;

	/** A companion device or remote view. Declared for completeness; no
		backend maps it yet. **/
	Companion;
}
