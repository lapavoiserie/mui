package mui.ui;

// Unified constructor: (?label:String, ?value:Float)
// sui: ProgressView(?label, ?valueBinding:String, ?total:Float) -- binding-based
// wui: ProgressRing(?value:Float) -- value only
// cui: ProgressBar(value:Float, label:String="") -- value + label

#if (mui_backend == "sui")
class ProgressView extends sui.ui.ProgressView {
    public function new(?label:String, ?value:Float) {
        super(label);
    }
}
#elseif (mui_backend == "wui")
class ProgressView extends wui.ui.ProgressRing {
    public function new(?label:String, ?value:Float) {
        super(value);
    }
}
#elseif (mui_backend == "cui")
class ProgressView extends cui.ui.ProgressBar {
    public function new(?label:String, ?value:Float) {
        super(value != null ? value : 0.0, label != null ? label : "");
    }
}
#elseif (mui_backend == "aui")
class ProgressView extends aui.ui.ProgressView {
    public function new(?label:String, ?value:Float) {
        super(null);
    }
}
#elseif (mui_backend == "qui")
class ProgressView extends qui.ui.ProgressView {
    public function new(?label:String, ?value:Float) {
        super(label, value);
    }
}
#elseif (mui_backend == "pui")
@:muiSupport("approx", "pui draws the indeterminate ring at a fixed angle rather than spinning it, until pui has a ticker")
class ProgressView extends pui.ui.ProgressView {
    public function new(?label:String, ?value:Float) {
        super(label, value);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end
