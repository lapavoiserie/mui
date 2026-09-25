import mui.macros.Markup.ui;

/** A Picker's options, written as data children. See `check.sh`. **/
class Options {
	static function main() {
		// Each backend's own cell: a Picker binds one, and the abstracts that
		// accept it are per backend.
		#if (mui_backend == "pui")
		var chosen = new pui.state.State(1);
		#elseif (mui_backend == "cui")
		var chosen = new cui.state.State.IntState(1, "chosen");
		#elseif (mui_backend == "sui")
		// This backend's controls hold a NAME, so the cell is named.
		var chosen = new sui.state.State(1, "chosen");
		#end
		var written = ui(<Picker label="Sortie" selectedIndex={chosen}>
			<Text text="HDMI"/>
			<Text text="SDI"/>
		</Picker>);
		var list = ["HDMI", "SDI", "NDI"];
		var spliced = ui(<Picker label="Sortie" selectedIndex={chosen}>{list}</Picker>);
		Sys.println("built: " + Type.getClassName(Type.getClass(written))
			+ " | written: " + written.options.join(",")
			+ " | spliced: " + spliced.options.join(","));

		// And they DRAW. A control that holds the right array and shows
		// something else would pass every line above.
		#if (mui_backend == "cui")
		var w = 30, h = 3;
		written.measure(cui.layout.Constraint.AtMost(w, h));
		var buffer = new cui.render.Buffer(w, h);
		written.renderInto(buffer, new cui.layout.Rect(0, 0, w, h));
		var drawn = new StringBuf();
		for (y in 0...h) for (x in 0...w) drawn.add(buffer.get(x, y).char);
		Sys.println("drawn: " + StringTools.trim(drawn.toString()));
		#end
	}
}
