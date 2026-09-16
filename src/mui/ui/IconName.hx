package mui.ui;

/**
	The name of an icon, from the shared vocabulary of `nui.Icons`.

	```haxe
	new Icon(Mic)
	new Icon(SpeakerOff, "Monitor muted")
	```

	One constant per name — `mic-off` is `MicOff` — generated from `nui.Icons`,
	so the list exists once. There is no conversion from `String`: a name that is
	not in the vocabulary does not compile, at the line that wrote it. A name that
	arrives as data goes through `fromString`, which says when it is unknown.
**/
@:build(mui.macros.IconNames.build())
enum abstract IconName(String) to String {
	inline function new(name:String)
		this = name;

	/** The name as data, or null when the vocabulary has no such name. **/
	public static function fromString(name:Null<String>):Null<IconName>
		return nui.Icons.knows(name) ? new IconName(name) : null;
}
