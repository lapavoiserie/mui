import mui.App;
import mui.View;
import mui.ui.Text;

/** The framework calls a declaration inside its surface's effect — no args. **/
class ArgsRefused extends App {
	override function body():View return new Text("body");

	@:surface(Glance)
	function sized(width:Int):View return new Text('w $width');

	static function main() {}
}
