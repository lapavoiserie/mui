#if macro
/** A two-tag vocabulary for the node route: enough to test cells and nothing else. **/
class FakeVocabulary {
	public static function register():Void {
		var kinds = [
			"Toggle" => ["label" => "KString", "isOn" => "KBool", "onToggle" => "KCallbackBool"],
			"Text" => ["text" => "KString"],
		];
		mui.macros.Backend.register({
			knows: t -> kinds.exists(t),
			keysOf: t -> kinds.exists(t) ? [for (k in kinds.get(t).keys()) k] : [],
			requiredOf: _ -> [],
			kindOf: (t, k) -> kinds.exists(t) ? kinds.get(t).get(k) : null,
			types: () -> [for (t in kinds.keys()) t],
			cellOf: (t, k) -> (t == "Toggle" && k == "isOn") ? "onToggle" : null,
		});
	}
}
#end
