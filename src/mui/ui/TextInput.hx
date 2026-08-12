package mui.ui;

import mui.ui.TextInputBinding;

// Unified text input (TextField/TextBox/Input).
// User writes: new TextInput("Enter name...", nameState)
// The TextInputBinding abstract handles conversion via @:from.

#if (mui_backend == "sui")
@:swiftView("TextField")
class TextInput extends sui.ui.TextField {
    public function new(@:swiftLabel("_") placeholder:String,
                        @:swiftLabel("text") @:swiftBinding state:TextInputBinding) {
        super(placeholder, state.unwrap());
    }
}
#elseif (mui_backend == "wui")
class TextInput extends wui.ui.TextBox {
    public function new(placeholder:String, state:TextInputBinding) {
        super(placeholder, state.unwrap());
    }
}
#elseif (mui_backend == "cui")
class TextInput extends cui.ui.Input {
    public function new(placeholder:String, state:TextInputBinding) {
        // cui.ui.Input takes (binding, placeholder) — reversed order
        super(state.unwrap(), placeholder);
    }
}
#elseif (mui_backend == "aui")
class TextInput extends aui.ui.TextField {
    public function new(placeholder:String, state:TextInputBinding) {
        super(placeholder, state.unwrap());
    }
}
#elseif (mui_backend == "qui")
class TextInput extends qui.ui.TextInput {
    public function new(placeholder:String, state:TextInputBinding) {
        super(placeholder, state);
    }
}
#elseif (mui_backend == "pui")
class TextInput extends pui.ui.TextInput {
    public function new(placeholder:String, state:TextInputBinding) {
        super(placeholder, state);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end
