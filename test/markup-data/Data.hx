import mui.macros.Markup.ui;

/** A picker's options on the node route, written and spliced. See `check.sh`. **/
class Data {
	static function texts(n:nui.Node):String
		return [for (c in n.children) c.type + ":" + Std.string(c.props.get("text"))].join(" ");

	static function main() {
		var outputs = ["HDMI", "SDI"];
		var written:nui.Node = ui(<Picker label="Sortie"><Text text="A"/><Text text="B"/></Picker>);
		var spliced:nui.Node = ui(<Picker label="Sortie">{outputs}</Picker>);
		Sys.println("written: " + texts(written));
		Sys.println("spliced: " + texts(spliced));
	}
}
