import mui.App;
import mui.View;
import mui.ui.Text;

/** Only the four scalars survive the marshalling boundaries, and only they
	compare by value -- an array mutated in place never reaches the store. **/
class DurableBadType extends App {
	@:state(durable) var items:Array<String> = [];

	override function body():View return new Text("x");

	static function main() {}
}
