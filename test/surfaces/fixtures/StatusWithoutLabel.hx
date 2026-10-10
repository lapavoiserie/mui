import mui.App;
import mui.View;
import mui.ui.Text;

/** A Status surface is shown by its label: returning a bare View is refused by the typer. **/
class StatusWithoutLabel extends App {
	override function body():View {
		return new Text("body");
	}

	@:surface(Status, optional)
	function today():View {
		return new Text("no label");
	}

	static function main() {
		new StatusWithoutLabel();
	}
}
