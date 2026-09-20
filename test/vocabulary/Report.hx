package;

/**
	Print what a backend declares, through the door markup itself asks.

	`mui.macros.Backend.types()` is what `ui()` consults to accept or refuse a
	tag, so a report built from it cannot drift from what compiling would do.
	Reading `@:node` out of the sources with a regular expression would have
	been easier and would have answered a different question.

	Run after the backend's own `registerWithMui()` line, which is why the
	order in each `.hxml` here is not decorative.
**/
class Report {
	#if macro
	public static function run():Void {
		var types = mui.macros.Backend.types();
		types.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
		Sys.println(mui.macros.Backend.name() + " " + types.join(" "));
	}
	#end
}
