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

	/** A read-at-a-glance summary: the Sailfish cover (mounted live), a
		WidgetKit widget on iOS, an App Widget on Android — the last two
		sampled, and kept current by `nui.Follow`. **/
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

	/**
		A live panel on another device — a machine on the network, or a paired
		watch — rendered there by that device's own renderer, its taps running
		this application's closures back home.

		Hosted by every backend that installs a describer (five of six; `qui`
		has none). Carried by `dui`, and off until the build says
		`-D mui_carry`; even then it goes nowhere until somebody pairs it.
	**/
	Companion;
	/**
		A small presence in the system's status area, shown by its label all
		day and opened into a panel: the macOS menu bar extra, the Windows
		notification area, a tray icon.

		Declared with a label — `mui.surface.Labelled` — because the label is
		most of what the surface is. Cardinality One: a platform shows one per
		application, the role's default id ("status") else the first.
	**/
	Status;
}
