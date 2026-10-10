import mui.App;
import mui.View;
import mui.ui.Text;
import mui.surface.Labelled;

/** cui has no status area: a Status declaration is refused, naming the backend. **/
class StatusUnhosted extends App {
	override function body():View {
		return new Text("body");
	}

	@:surface(Status)
	function today():Labelled {
		return new Labelled({title: "Chores"}, () -> new Text("panel"));
	}

	static function main() {
		new StatusUnhosted();
	}
}
