import mui.App;
import mui.View;
import mui.ui.Text;
import mui.surface.Command;
import mui.surface.SurfaceDecl;

/**
	The whole happy path: two Glance declarations (one id pinned), a command
	set, and the Primary that is always there. `main` prints the collected ids
	so the runner can assert the *result*, not just that it compiled.

	The fixtures bind against cui, which hosts no Glance — so both Glance
	declarations carry `optional`, which is the point: they are still
	collected, and the application said in its own source that it accepts them
	flying nowhere on this target.
**/
class Collected extends App {
	@:state var count:Int = 0;

	override function body():View {
		return new Text("body");
	}

	@:surface(Glance, optional)
	function today():View {
		return new Text('count ${count.get()}');
	}

	@:surface(Glance, "pinned", optional)
	function renamedSinceThenButStable():View {
		return new Text("pinned");
	}

	@:surface(Commands)
	function shortcuts():Array<Command> {
		return [new Command("Quit", () -> {}).key("ctrl+q")];
	}

	static function main() {
		var app = new Collected();
		Sys.println([for (d in app.surfaces()) SurfaceDeclTools.idOf(d)].join(","));
	}
}
