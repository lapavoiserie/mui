import mui.App;
import mui.View;
import mui.ui.Text;

/**
	A role the backend being compiled has no host for is a compile error.

	Knowable at compile time, therefore refused at compile time: cui has
	nowhere to put a cover, and an application that learns this from an empty
	screen learned it too late. `optional` is the way to accept it — see
	`Collected`.
**/
class UnhostedRefused extends App {
	override function body():View {
		return new Text("body");
	}

	@:surface(Glance)
	function today():View {
		return new Text("nowhere to fly");
	}

	static function main() {
		new UnhostedRefused();
	}
}
