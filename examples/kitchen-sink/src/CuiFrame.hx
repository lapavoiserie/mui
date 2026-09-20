import cui.layout.Constraint;
import cui.layout.Rect;
import cui.render.Buffer;

/**
	The kitchen sink drawn into a buffer and printed, with no terminal.

	`cui` writes to a TTY and waits for keys, which a test harness has neither
	of; its own suites render into a `Buffer` and read the cells back, and this
	is the same thing applied to a whole screen. So the picture is made the way
	the other backends' are — off-screen, nobody's display taken over.
**/
class CuiFrame {
	public static function main():Void {
		var app = new KitchenSink();
		var view:cui.View = cast app.body();

		var width = 80;
		var height = 140;
		view.measure(Constraint.AtMost(width, height));

		Sys.stderr().writeString("root " + Type.getClassName(Type.getClass(view))
			+ " children=" + view.children.length + "\n");
		for (child in view.children) {
			var cs = child.measure(Constraint.AtMost(width, height));
			Sys.stderr().writeString("  " + Type.getClassName(Type.getClass(child))
				+ " " + cs.width + "x" + cs.height + "\n");
		}

		var buffer = new Buffer(width, height);
		view.renderInto(buffer, new Rect(0, 0, width, height));

		for (y in 0...height) {
			var line = new StringBuf();
			for (x in 0...width) line.add(buffer.get(x, y).char);
			Sys.println(StringTools.rtrim(line.toString()));
		}
	}
}
