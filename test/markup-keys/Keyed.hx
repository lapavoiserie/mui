import mui.macros.Markup.ui;

/** A key written in markup reaches the backend's own view. See `check.sh`. **/
class Keyed {
	static function main() {
		var screen = ui(<VStack>
			<Text key="a" text="first row"/>
			<Text key={"b"} text="second row"/>
		</VStack>);
		Sys.println("keys: " + screen.children[0].key + "," + screen.children[1].key);
	}
}
