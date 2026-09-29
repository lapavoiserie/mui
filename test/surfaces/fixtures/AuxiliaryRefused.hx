import mui.App;
import mui.View;
import mui.ui.Text;

/**
	A second window where the platform has no second window.

	This is the whole of "several windows in one process" as `mui` spells it:
	the `Auxiliary` role. Which backends host it is a property of the *build* —
	desktop windows on sui, wui and pui-on-macOS, nothing at all in a terminal
	— and a terminal build meeting this declaration must stop, naming the
	backend, rather than opening nothing and saying nothing.

	`LocalWindows` is the other half: the same declaration, accepted on purpose.
**/
class AuxiliaryRefused extends App {
	override function body():View {
		return new Text("body");
	}

	@:surface(Auxiliary)
	function monitors():View {
		return new Text("nowhere to be");
	}

	static function main() {
		new AuxiliaryRefused();
	}
}
