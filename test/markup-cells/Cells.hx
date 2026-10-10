import mui.macros.Markup.ui;

/** A cell given to a two-way value on the node route. See `check.sh`. **/
class Cells {
	static function main() {
		var muted = new rui.state.State(true);
		var plain:nui.Node = ui(<Toggle label="Muet" isOn={true}/>);
		var bound:nui.Node = ui(<Toggle label="Muet" isOn={muted}/>);
		Sys.println("plain: " + Std.string(plain.props.get("isOn")) + " callback=" + plain.props.exists("onToggle"));
		Sys.println("bound: " + Std.string(bound.props.get("isOn")) + " callback=" + bound.props.exists("onToggle"));
		switch (bound.props.get("onToggle")) {
			case PCallbackBool(f): f(false);
			case _:
		}
		Sys.println("after: " + muted.get());
	}
}
