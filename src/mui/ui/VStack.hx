package mui.ui;

// Unified constructor: (content:Array<View>, ?spacing:Float)
// sui: (?alignment, ?spacing, content) -- reordered
// wui: (children, ?spacing)
// cui: (children, spacing:Int=0) -- Float->Int conversion

#if (mui_backend == "sui")
class VStack extends sui.ui.VStack {
    public function new(content:Array<sui.View>, ?spacing:Float) {
        super(null, spacing, content);
    }
}
#elseif (mui_backend == "wui")
class VStack extends wui.ui.VStack {
    public function new(content:Array<wui.View>, ?spacing:Float) {
        super(content, spacing);
    }
}
#elseif (mui_backend == "cui")
class VStack extends cui.ui.VStack {
    public function new(content:Array<cui.View>, ?spacing:Float) {
        // GUI spacing is in pixels; terminal spacing is in rows.
        // Scale down: 1-7 → 1 row, 8+ → 1 row per 8px, capped at 2.
        var s = 0;
        if (spacing != null && spacing > 0) {
            s = Std.int(Math.max(1, Math.min(2, Math.ceil(spacing / 8))));
        }
        super(content, s);
    }
}
#elseif (mui_backend == "aui")
class VStack extends aui.ui.VStack {
    public function new(content:Array<aui.View>, ?spacing:Float) {
        super(null, spacing, content);
    }
}
#elseif (mui_backend == "qui")
class VStack extends qui.ui.VStack {
    public function new(content:Array<qui.View>, ?spacing:Float) {
        super(content, spacing);
    }
}
#elseif (mui_backend == "pui")
class VStack extends pui.ui.VStack {
    public function new(content:Array<pui.View>, ?spacing:Float) {
        super(content, spacing == null ? 8 : spacing);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end
