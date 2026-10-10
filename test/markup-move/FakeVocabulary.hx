#if macro
/** One tag, for the node route: enough to test `KCallbackMove` and nothing else. **/
class FakeVocabulary {
	public static function register():Void {
		var kinds = ["ReorderList" => ["onMove" => "KCallbackMove", "moveUpLabel" => "KString"]];
		mui.macros.Backend.register({
			knows: t -> kinds.exists(t),
			keysOf: t -> kinds.exists(t) ? [for (k in kinds.get(t).keys()) k] : [],
			requiredOf: _ -> [],
			kindOf: (t, k) -> kinds.exists(t) ? kinds.get(t).get(k) : null,
			types: () -> [for (t in kinds.keys()) t],
		});
	}
}
#end
