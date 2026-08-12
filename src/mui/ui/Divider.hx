package mui.ui;

#if (mui_backend == "sui")
// sui's SwiftGenerator falls through to genericViewToSwift for unknown types,
// which uses the class name as the Swift view name. "Divider" maps directly
// to SwiftUI's native Divider() view.
class Divider extends sui.View {
    public function new() {
        super();
        this.viewType = "Divider";
    }
}
#elseif (mui_backend == "wui")
// WinUI has no native Divider. Emits a thin horizontal line via a
// 1px-tall view with a gray background.
@:muiSupport("built", "WinUI has no Divider: a 1px grey Border stands in")
class Divider extends wui.ui.Border {
    public function new() {
        super("Border");
        properties.set("height", 1);
        properties.set("background", "Gray");
    }
}
#elseif (mui_backend == "cui")
class Divider extends cui.ui.Divider {
    public function new() {
        super(true);
    }
}
#elseif (mui_backend == "aui")
class Divider extends aui.ui.Divider {
    public function new() {
        super();
    }
}
#elseif (mui_backend == "qui")
typedef Divider = qui.ui.Divider;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
