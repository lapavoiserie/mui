import mui.App;
import mui.View;
import mui.ui.Text;

/** A key names an entry in a store this cell was never put in. **/
class DurableKeyAlone extends App {
	@:state(key = "somewhere") var n:Int = 0;

	override function body():View return new Text("x");

	static function main() {}
}
