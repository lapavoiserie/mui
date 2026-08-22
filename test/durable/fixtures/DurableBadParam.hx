import mui.App;
import mui.View;
import mui.ui.Text;

/** A near-miss spelling is the case that matters: silently ignoring it would
	leave an application believing it had persistence. **/
class DurableBadParam extends App {
	@:state(persistent) var n:Int = 0;

	override function body():View return new Text("x");

	static function main() {}
}
