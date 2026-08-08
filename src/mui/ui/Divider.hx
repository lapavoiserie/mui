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
@:muiSupport("built", "WinUI n'a pas de Divider : un Border de 1 px gris")
class Divider extends wui.View {
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
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui"
#end
