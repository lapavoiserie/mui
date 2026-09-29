import mui.App;
import mui.View;
import mui.ui.Button;
import mui.ui.Divider;
import mui.ui.Spacer;
import mui.ui.Text;
import mui.ui.TextInput;
import mui.ui.VStack;

/**
	One application, two windows, one machine, one process.

	The desk is `body()`; the monitor wall is an `@:surface(Auxiliary)`
	declaration. Neither window knows about the other: what they share is a
	state cell, and what they do not share is everything a pane of glass owns —
	the focus ring, the hover, the drop-down, the scroll offset.

	Run it with `PUI_FRAME_DUMP=/tmp/shot.png` and it photographs itself:
	`/tmp/shot.png` is the desk, `/tmp/shot-1.png` is the monitor wall. A
	claim about a second window that nobody has looked at is not a claim.

	`MUI_TWO_WINDOWS_TAKES` drives it without a hand: that many takes, one per
	half-second, and then the application quits. That is how the pictures in
	the commit were taken.
**/
class TwoWindows extends App {
	@:state var takes:Int = 0;
	@:state var slate:String = "";

	public function new() {
		super();
		appTitle = "Desk";
	}

	override function body():View {
		return new VStack([
			new Text("Desk"),
			new Divider(),
			new Text('takes: $takes'),
			new TextInput("slate", slate_),
			new Button("New take", () -> takes += 1),
			new Spacer(),
		], 8);
	}

	/**
		The monitor wall: the same cells, a different tree, its own window.

		It reads `takes` and `slate`, so a write in either window reaches both —
		one effect per window, each subscribed to the cells its own thunk read.
	**/
	@:surface(Auxiliary)
	function monitors():View {
		return new VStack([
			new Text("Monitors"),
			new Divider(),
			new Text('takes: $takes'),
			new Text(slate == "" ? "(no slate)" : slate),
			new Button("Reset", () -> takes = 0),
			new Spacer(),
		], 8);
	}

	static function main() {
		var app = new TwoWindows();

		#if (sys && mui_owns_main)
		var wanted = Sys.getEnv("MUI_TWO_WINDOWS_TAKES");
		if (wanted != null) {
			var left = Std.parseInt(wanted);
			if (left == null) left = 3;
			// A cell a timer writes is observable like any other, so both
			// windows follow it without either being told.
			var driver = new haxe.Timer(500);
			driver.run = function() {
				if (left > 0) {
					app.takes += 1;
					app.slate = "scene " + app.takes;
					left--;
					return;
				}
				// Stopped BEFORE quitting. A repeating timer keeps the thread's
				// event loop alive, and `pui.App.start` does not come back
				// until that loop drains — so a process that quits with one
				// still ticking hangs with both windows gone.
				driver.stop();
				app.quit();
			};
		}
		#end

		#if mui_owns_main
		app.run();
		#end
	}
}
