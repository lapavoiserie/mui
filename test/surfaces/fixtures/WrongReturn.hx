import mui.App;
import mui.View;
import mui.ui.Text;

/** Commands carries Array<Command>; the typer refuses this at the method. **/
class WrongReturn extends App {
	override function body():View return new Text("body");

	@:surface(Commands)
	function shortcuts():View return new Text("not a command list");

	static function main() {}
}
