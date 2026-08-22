import mui.App;
import mui.View;
import mui.ui.Text;

/**
	The happy path, and the only fixture here that is meant to be *run*: twice
	over one store, so the second process reads what the first wrote.

	`volatile` is the control. Without it a fixture that never persisted
	anything and a fixture that persisted everything would print the same
	thing on the first pass.
**/
class Durable extends App {
	@:state(durable) var count:Int = 0;
	@:state(durable, key = "durable.fixture.label") var label:String = "none";
	@:state var volatile:Int = 100;

	override function body():View return new Text('${count.get()}');

	static function main() {
		var app = new Durable();
		Sys.println('read ${app.count.get()} ${app.label.get()} ${app.volatile.get()}');
		app.count.set(app.count.get() + 1);
		app.label.set("wrote-" + app.count.get());
		app.volatile.set(app.volatile.get() + 1);
	}
}
