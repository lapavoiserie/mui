package mui.ui;

/**
	The name of a font family an application ships.

	A `String` underneath, and deliberately not one you can write: the only way
	to make one is `mui.Fonts.family`, which looks for the file while the
	application compiles. A family named as a plain string would be a name
	nobody checked, and the screen would say so months later, on one platform.

	It reads back as a string, because that is what crosses a wire and what
	every platform's font API takes.
**/
abstract FontFamily(String) to String {
	/** Made by `mui.Fonts.family`, which is where the checking happens. **/
	public inline function new(name:String) {
		this = name;
	}

	/**
		A family named in data -- a tree that arrived over a wire.

		There is no checking to do here: the receiving application either ships
		that family or draws its own default. See nui's node model.
	**/
	public static inline function fromString(name:String):FontFamily
		return new FontFamily(name);
}
