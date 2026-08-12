package mui.ui;

import mui.ui.ToggleBinding;

// Unified Toggle/Checkbox.
// User writes: new Toggle("Dark Mode", darkMode)
// The ToggleBinding abstract handles conversion via @:from.

#if (mui_backend == "sui")
@:swiftView("Toggle")
class Toggle extends sui.ui.Toggle {
    public function new(@:swiftLabel("_") label:String,
                        @:swiftLabel("isOn") @:swiftBinding state:ToggleBinding) {
        super(label, state.unwrap());
    }
}
#elseif (mui_backend == "wui")
class Toggle extends wui.ui.ToggleSwitch {
    public function new(label:String, state:ToggleBinding) {
        super(label, state.unwrap());
    }
}
#elseif (mui_backend == "cui")
class Toggle extends cui.ui.Checkbox {
    public function new(label:String, state:ToggleBinding) {
        super(label, state.unwrap());
    }
}
#elseif (mui_backend == "aui")
class Toggle extends aui.ui.Toggle {
    public function new(label:String, state:ToggleBinding) {
        super(label, state.unwrap());
    }
}
#elseif (mui_backend == "qui")
class Toggle extends qui.ui.Toggle {
    public function new(label:String, state:ToggleBinding) {
        super(label, state);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
