import mui.macros.Markup.ui;

class NotTwoWay {
	static function main() {
		var title = new rui.state.State("x");
		var n:nui.Node = ui(<Text text={title}/>);
	}
}
