#if macro
/** One tag whose children are data, for the node route. **/
class FakeVocabulary {
	public static function register():Void {
		var kinds = ["Picker" => ["label" => "KString"], "Text" => ["text" => "KString"]];
		mui.macros.Backend.register({
			knows: t -> kinds.exists(t),
			keysOf: t -> kinds.exists(t) ? [for (k in kinds.get(t).keys()) k] : [],
			requiredOf: _ -> [],
			kindOf: (t, k) -> kinds.exists(t) ? kinds.get(t).get(k) : null,
			types: () -> [for (t in kinds.keys()) t],
			dataChildren: t -> t == "Picker" ? {type: "Text", prop: "text", field: "options"} : null,
		});
	}
}
#end
