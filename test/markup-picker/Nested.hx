import mui.macros.Markup.ui;

/** The same picker, inside a stack. **/
class Nested {
	static function main() {
		var chosen = new pui.state.State(1);
		var lit = new pui.state.State(true);
		// The tag AFTER the picker is the one that catches the bug: `written`
		// holds one attribute list per element and data children never reach
		// `buildNode`, so an unconsumed entry shifts every element that
		// follows. It showed as "Text" being refused for carrying no text --
		// naming a tag that was written correctly.
		var screen = ui(<VStack>
			<Text text="before"/>
			<Picker label="Sortie" selectedIndex={chosen}>
				<Text text="HDMI"/>
				<Text text="SDI"/>
			</Picker>
			<Text text="after" scale="caption"/>
			<Toggle label="lit" isOn={lit}/>
		</VStack>);
		var after:Dynamic = screen.children[2];
		Sys.println("nested: " + Type.getClassName(Type.getClass(screen))
			+ " | after: " + after.content + " | options: " + (cast screen.children[1] : pui.ui.Picker).options.join(","));
	}
}
