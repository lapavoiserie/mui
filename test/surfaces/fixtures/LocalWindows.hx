import mui.App;
import mui.View;
import mui.ui.Text;
import mui.surface.SurfaceDecl;

/**
	Two more windows, on this machine, in this process.

	The point of the fixture is the *shape* of the answer, which is why it
	runs: `SurfaceDeclTools.treesOf` is what a host asks for the declarations
	of one role, in declaration order, and three backends now go through it
	instead of each writing the same walk with its own `case _:`.

	Bound against cui, which hosts no `Auxiliary` and says so — so both
	declarations carry `optional`. That is not a way round the check: it is the
	application stating, in its own source, that this build has one screen and
	that it accepts it.
**/
class LocalWindows extends App {
	@:state var takes:Int = 0;

	override function body():View {
		return new Text('desk $takes');
	}

	@:surface(Auxiliary, optional)
	function monitors():View {
		return new Text('monitors $takes');
	}

	@:surface(Auxiliary, "gauges", optional)
	function renamedButStable():View {
		return new Text('gauges $takes');
	}

	static function main() {
		var app = new LocalWindows();
		var windows = SurfaceDeclTools.treesOf(app.surfaces(), Auxiliary);
		// The ids, in declaration order, and what each one draws — a window is
		// a tree, so the thunk has to answer.
		Sys.println([for (w in windows) w.id].join(",")
			+ " | " + SurfaceDeclTools.treesOf(app.surfaces(), Primary).length
			+ " primary");
	}
}
