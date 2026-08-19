import mui.App;
import mui.View;
import mui.ui.Text;
import mui.surface.Command;
import mui.surface.SurfaceDecl;

/**
	The whole happy path: two Glance declarations (one id pinned), a command
	set, and the Primary that is always there. `main` prints the collected ids
	so the runner can assert the *result*, not just that it compiled.
**/
class Collected extends App {
	@:state var count:Int = 0;

	override function body():View {
		return new Text("body");
	}

	@:surface(Glance)
	function today():View {
		return new Text('count ${count.get()}');
	}

	@:surface(Glance, "pinned")
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
