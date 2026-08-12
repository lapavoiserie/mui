package mui.ui;

// Unified constructor: (content:Array<View>, ?spacing:Float)

#if (mui_backend == "sui")
class HStack extends sui.ui.HStack {
    public function new(content:Array<sui.View>, ?spacing:Float) {
        super(null, spacing, content);
    }
}
#elseif (mui_backend == "wui")
class HStack extends wui.ui.HStack {
    public function new(content:Array<wui.View>, ?spacing:Float) {
        super(content, spacing);
    }
}
#elseif (mui_backend == "cui")
class HStack extends cui.ui.HStack {
    public function new(content:Array<cui.View>, ?spacing:Float) {
        var s = 0;
        if (spacing != null && spacing > 0) {
            s = Std.int(Math.max(1, Math.min(4, Math.ceil(spacing / 4))));
        }
        super(content, s);
    }
}
#elseif (mui_backend == "aui")
class HStack extends aui.ui.HStack {
    public function new(content:Array<aui.View>, ?spacing:Float) {
        super(null, spacing, content);
    }
}
#elseif (mui_backend == "qui")
class HStack extends qui.ui.HStack {
    public function new(content:Array<qui.View>, ?spacing:Float) {
        super(content, spacing);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
