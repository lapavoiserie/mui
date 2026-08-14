package mui.enums;

enum HorizontalAlignmentKind {
    Leading;
    Center;
    Trailing;
}

abstract HorizontalAlignment(HorizontalAlignmentKind) from HorizontalAlignmentKind to HorizontalAlignmentKind {
    public inline function new(v:HorizontalAlignmentKind) {
        this = v;
    }

    public static inline var Leading = new HorizontalAlignment(HorizontalAlignmentKind.Leading);
    public static inline var Center = new HorizontalAlignment(HorizontalAlignmentKind.Center);
    public static inline var Trailing = new HorizontalAlignment(HorizontalAlignmentKind.Trailing);

/**
		There used to be a `toBackend()` here, mapping this value onto each
		backend's own colour, font or alignment type — six branches, and not one
		caller anywhere in the ecosystem. It was removed rather than inverted:
		a mapping nobody asks for is a mapping nobody has checked.

		When something does need one, it belongs to the backend, as
		`<backend>.mui.*` — not here, where it would put six names back into a
		repository that no longer has any.
	**/

}
