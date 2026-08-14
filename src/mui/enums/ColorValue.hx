package mui.enums;

enum ColorValueKind {
    // Semantic
    Primary;
    Secondary;
    Accent;

    // Named
    Red;
    Orange;
    Yellow;
    Green;
    Blue;
    Purple;
    Pink;
    White;
    Black;
    Gray;
    Clear;

    // Custom
    Rgb(r:Int, g:Int, b:Int);
    Hex(hex:String);
}

abstract ColorValue(ColorValueKind) from ColorValueKind to ColorValueKind {
    public inline function new(v:ColorValueKind) {
        this = v;
    }

    // Convenience constructors matching enum cases
    public static inline var Primary = new ColorValue(ColorValueKind.Primary);
    public static inline var Secondary = new ColorValue(ColorValueKind.Secondary);
    public static inline var Accent = new ColorValue(ColorValueKind.Accent);
    public static inline var Red = new ColorValue(ColorValueKind.Red);
    public static inline var Orange = new ColorValue(ColorValueKind.Orange);
    public static inline var Yellow = new ColorValue(ColorValueKind.Yellow);
    public static inline var Green = new ColorValue(ColorValueKind.Green);
    public static inline var Blue = new ColorValue(ColorValueKind.Blue);
    public static inline var Purple = new ColorValue(ColorValueKind.Purple);
    public static inline var Pink = new ColorValue(ColorValueKind.Pink);
    public static inline var White = new ColorValue(ColorValueKind.White);
    public static inline var Black = new ColorValue(ColorValueKind.Black);
    public static inline var Gray = new ColorValue(ColorValueKind.Gray);
    public static inline var Clear = new ColorValue(ColorValueKind.Clear);

    public static inline function rgb(r:Int, g:Int, b:Int):ColorValue {
        return new ColorValue(ColorValueKind.Rgb(r, g, b));
    }

    public static inline function hex(h:String):ColorValue {
        return new ColorValue(ColorValueKind.Hex(h));
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
