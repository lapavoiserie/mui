import mui.macros.Markup.ui;

/** A list and written children at once: which order would they be in? **/
class Mixed {
	static function main() {
		var chosen = new pui.state.State(0);
		var more = ["NDI"];
		ui(<Picker label="Sortie" selectedIndex={chosen}><Text text="HDMI"/>{more}</Picker>);
	}
}
