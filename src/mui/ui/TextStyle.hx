package mui.ui;

/**
	How a piece of text is set, beyond its scale.

	```haxe
	new Text(timecode, Body, {family: Fonts.family("Inter"), weight: 600, numbers: Tabular})
	```

	Every field is optional, and what is left out is the platform's own answer:
	no family means the system font, no weight means ordinary text. A backend
	honours what it can -- a terminal has one font, so it takes the weight as
	bold, the italic, and nothing else -- and none of it is an error.

	`weight` is 100 to 900 in hundreds, the vocabulary every font file already
	uses: 400 is regular, 700 is bold. A weight a family does not have is the
	nearest one it does, which is the platform's own rule and not one `mui`
	invents.
**/
typedef TextStyle = {
	@:optional var family:FontFamily;
	@:optional var weight:Int;
	@:optional var italic:Bool;
	@:optional var numbers:Numbers;
}
