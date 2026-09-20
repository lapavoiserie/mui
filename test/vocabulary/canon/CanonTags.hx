import mui.macros.Markup.ui;

/**
	The canonical tags, written as markup against a backend whose own controls
	are named after somebody else's.

	`wui`'s classes carry WinUI's names — `ToggleSwitch`, `TextBox`,
	`ScrollViewer` — and `WinUISink` has translated the canonical ones at the
	door for as long as trees have arrived over the wire. The vocabulary markup
	checks against did not, so `<Toggle/>` was refused at compile time while the
	sink would have rendered it. This fixture is that gap, and it does not
	compile if the gap comes back.
**/
class CanonTags {
	public static function main():Void {
		var tree = build();
		if (tree.type != "VStack") throw "expected a VStack, got " + tree.type;
		Sys.println("ok   canonical tags compile for a backend that names its controls otherwise");
	}

	static function build():nui.Node {
		return ui(<VStack spacing={8}>
			<Text text="canon"/>
			<ProgressView value={0.4}/>
			<ScrollView>
				<Text text="inside"/>
			</ScrollView>
		</VStack>);
	}
}
