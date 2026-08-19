import mui.App;
import mui.View;
import mui.ui.Text;

/** A role name the vocabulary does not have. **/
class UnknownRole extends App {
	override function body():View return new Text("body");

	@:surface(Cover)
	function today():View return new Text("no");

	static function main() {}
}
