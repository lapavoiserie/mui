package mui.ui;

// Overlay stack — children are layered on top of each other.
// Unified constructor: (content:Array<View>)
// On cui: falls back to VStack (terminal can't overlay).

#if (mui_backend == "sui")
class ZStack extends sui.ui.ZStack {
    public function new(content:Array<sui.View>) {
        super(null, content);
    }
}
#elseif (mui_backend == "wui")
class ZStack extends wui.ui.ZStack {
    public function new(content:Array<wui.View>) {
        super(content);
    }
}
#elseif (mui_backend == "aui")
class ZStack extends aui.ui.ZStack {
    public function new(content:Array<aui.View>) {
        super(null, content);
    }
}
#elseif (mui_backend == "cui")
// Terminal can't overlay views — fall back to VStack
@:muiSupport("approx", "a terminal cannot overlay: the views are stacked instead")
class ZStack extends cui.ui.VStack {
    public function new(content:Array<cui.View>) {
        super(content, 0);
    }
}
#elseif (mui_backend == "qui")
class ZStack extends qui.ui.ZStack {
    public function new(content:Array<qui.View>) {
        super(content);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
