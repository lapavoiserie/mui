import mui.App;
import mui.View;
import mui.ui.Text;

/** Ids are stable identity: one role/id pair, one declaration. **/
class DupIdRefused extends App {
	override function body():View return new Text("body");

	@:surface(Glance, "today", optional)
	function today():View return new Text("a");

	@:surface(Glance, "today", optional)
	function alsoToday():View return new Text("b");

	static function main() {}
}
