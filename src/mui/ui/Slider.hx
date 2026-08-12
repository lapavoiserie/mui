package mui.ui;

import mui.ui.SliderBinding;

// Unified Slider.
// User writes: new Slider(progress, 0.0, 1.0)
// The SliderBinding abstract handles conversion via @:from.
//
// On cui: renders as [████████░░░░░░░░] 50% with arrow key control.

#if (mui_backend == "sui")
@:swiftView("Slider")
class Slider extends sui.ui.Slider {
    public function new(@:swiftBinding state:SliderBinding, min:Float = 0.0, max:Float = 1.0) {
        super(state.unwrap(), min, max);
    }
}
#elseif (mui_backend == "wui")
class Slider extends wui.ui.Slider {
    public function new(state:SliderBinding, min:Float = 0.0, max:Float = 1.0) {
        super(min, max, state.unwrap());
    }
}
#elseif (mui_backend == "aui")
class Slider extends aui.ui.Slider {
    public function new(state:SliderBinding, min:Float = 0.0, max:Float = 1.0) {
        super(state.unwrap(), min, max);
    }
}
#elseif (mui_backend == "cui")
class Slider extends cui.ui.Slider {
    public function new(state:SliderBinding, min:Float = 0.0, max:Float = 1.0) {
        super(state.unwrap(), min, max);
    }
}
#elseif (mui_backend == "qui")
class Slider extends qui.ui.Slider {
    public function new(state:SliderBinding, min:Float = 0.0, max:Float = 1.0) {
        super(state, min, max);
    }
}
#elseif (mui_backend == "pui")
class Slider extends pui.ui.Slider {
    public function new(state:SliderBinding, min:Float = 0.0, max:Float = 1.0) {
        super(state, min, max);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end
