package mui.enums;

enum FontStyleKind {
    LargeTitle;
    Title;
    Headline;
    Body;
    Caption;
    Custom(name:String, size:Float);
}

abstract FontStyle(FontStyleKind) from FontStyleKind to FontStyleKind {
    public inline function new(v:FontStyleKind) {
        this = v;
    }

    public static inline var LargeTitle = new FontStyle(FontStyleKind.LargeTitle);
    public static inline var Title = new FontStyle(FontStyleKind.Title);
    public static inline var Headline = new FontStyle(FontStyleKind.Headline);
    public static inline var Body = new FontStyle(FontStyleKind.Body);
    public static inline var Caption = new FontStyle(FontStyleKind.Caption);

    public static inline function custom(name:String, size:Float):FontStyle {
        return new FontStyle(FontStyleKind.Custom(name, size));
    }

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
