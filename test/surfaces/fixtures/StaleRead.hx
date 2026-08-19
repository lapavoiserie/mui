import mui.App;
import mui.View;
import mui.ui.Text;

/**
	A surface declaration is a view: it runs inside its surface's effect, so
	it reads under the same rule as `body()`. This is the wiring proof —
	`mui.macros.Bind` registers the rule for `@:surface` metadata, and a plain
	mutable field read here must be refused naming the field.
**/
class StaleRead extends App {
	var hits:Int = 0;

	override function body():View return new Text("body");

	@:surface(Glance)
	function today():View return new Text('hits $hits');

	static function main() {}
}
