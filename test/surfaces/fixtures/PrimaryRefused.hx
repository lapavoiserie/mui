import mui.App;
import mui.View;
import mui.ui.Text;

/** Primary is body(): declaring it can only shadow that fact. **/
class PrimaryRefused extends App {
	override function body():View return new Text("body");

	@:surface(Primary)
	function second():View return new Text("no");

	static function main() {}
}
