import mui.macros.Markup.ui;

/** A move written `(from, to) -> …` on the node route. See `check.sh`. **/
class Moves {
	static function main() {
		var moves:Array<String> = [];
		var list:nui.Node = ui(<ReorderList onMove={(from, to) -> moves.push(from + "->" + to)} moveUpLabel="Monter"/>);
		switch (list.props.get("onMove")) {
			case PCallbackString(f):
				f("2,0");
				f("garbage");
				f("1,");
				Sys.println("moves: " + moves.join(" "));
			case other: Sys.println("wrapped as: " + Std.string(other));
		}
	}
}
