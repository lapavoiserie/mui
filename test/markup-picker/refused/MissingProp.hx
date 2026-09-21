import mui.macros.Markup.ui;

/** An option child that carries no value. **/
class MissingProp {
	static function main() {
		var chosen = new pui.state.State(0);
		ui(<Picker label="Sortie" selectedIndex={chosen}><Text/></Picker>);
	}
}
