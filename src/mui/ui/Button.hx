package mui.ui;

// Unified constructor: (label:String, ?action:()->Void)
// Closures are the common denominator across all three backends.

#if (mui_backend == "sui")
class Button extends sui.ui.Button {
    public function new(label:String, ?action:() -> Void) {
        super(label, action);
    }
}
#elseif (mui_backend == "wui")
class Button extends wui.ui.Button {
    public function new(label:String, ?action:() -> Void) {
        super(label);
        // The property, not the field of the same name. `wui.ui.Button` has
        // both a `public var onClick` and a generator that reads `.onClick(fn)`
        // call syntax, but what the push bridge consumes is
        // `properties.get("onClick")` -- so that is where a closure has to land
        // to be reachable. Calling the field did not even compile.
        if (action != null) properties.set("onClick", action);
    }
}
#elseif (mui_backend == "cui")
class Button extends cui.ui.Button {
    public function new(label:String, ?action:() -> Void) {
        super(label, action != null ? action : function() {});
    }
}
#elseif (mui_backend == "aui")
class Button extends aui.ui.Button {
    public function new(label:String, ?action:() -> Void) {
        super(label);
        if (action != null) {
            onTapGesture(action);
        }
    }
}
#elseif (mui_backend == "qui")
class Button extends qui.ui.Button {
    public function new(label:String, ?action:() -> Void) {
        super(label, action);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
