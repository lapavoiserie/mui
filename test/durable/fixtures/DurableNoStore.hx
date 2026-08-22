import mui.App;
import mui.View;
import mui.ui.Text;

/** Compiled without `-lib kui-store`: the platform is known, its store is
	not there. Refused by name rather than quietly kept in memory. **/
class DurableNoStore extends App {
	@:state(durable) var n:Int = 0;

	override function body():View return new Text("x");

	static function main() {}
}
