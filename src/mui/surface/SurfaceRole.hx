package mui.surface;

/**
	What a surface is *for* — portable across backends, never a native surface.

	An application declares roles; each backend maps a role onto the surface its
	platform actually has: `Glance` is the Sailfish cover, an iOS widget, and
	nothing at all on a terminal. Exposing the native surfaces themselves —
	"cover", "widget", "live tile" — would have made every application name a
	platform; several of those are the same thing wearing different clothes.

	A role the backend being built has no host for is a **compile error**, not
	a silence: each backend states what it hosts as `@:hostedRoles` on its
	`mui.App`, and `mui.macros.Surfaces` refuses a declaration that would fly
	nowhere on this target. An application built for several platforms accepts
	the gap explicitly — `@:surface(Glance, optional)` — which is what makes
	the degradation *declared* rather than accidental: declared by the
	application, in its own source, instead of a `case _:` dropping it on the
	floor the way an unsupported modifier used to.

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
