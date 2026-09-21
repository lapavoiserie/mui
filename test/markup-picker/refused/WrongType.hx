import mui.macros.Markup.ui;

/** A child of the wrong type, where options are expected. **/
class WrongType {
	static function main() {
		var chosen = new pui.state.State(0);
		ui(<Picker label="Sortie" selectedIndex={chosen}><Button label="HDMI"/></Picker>);
	}
}
