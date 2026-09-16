package mui.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/** Generates `mui.ui.IconName`'s constants from `nui.Icons.NAMES`. **/
class IconNames {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		for (name in nui.Icons.NAMES) {
			fields.push({
				name: constantOf(name),
				doc: 'The `$name` icon.',
				// A plain `var` in an `enum abstract`: the compiler makes it a
				// constant of the abstract, which is what lets `new Icon(Mic)`
				// find `Mic` from the expected type.
				access: [],
				kind: FVar(null, macro $v{name}),
				pos: pos,
			});
		}
		return fields;
	}

	/** `mic-off` -> `MicOff`. **/
	public static function constantOf(name:String):String
		return [for (word in name.split("-")) word.charAt(0).toUpperCase() + word.substr(1)].join("");
}
#end
