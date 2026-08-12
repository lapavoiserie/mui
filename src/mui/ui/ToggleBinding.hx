package mui.ui;

/**
    Type-safe binding for Toggle. Accepts a backend @:state Bool field
    and converts to the backend's native binding type via @:from.

    Usage: new Toggle("Dark Mode", darkMode)
    The @:from conversion happens implicitly at the call site.
**/
#if (mui_backend == "sui")
abstract ToggleBinding(String) {
    public inline function new(v:String) this = v;

    @:from static inline function fromState(s:sui.state.State<Bool>):ToggleBinding
        return new ToggleBinding(s.name);

    public inline function unwrap():String return this;
}
#elseif (mui_backend == "wui")
abstract ToggleBinding(wui.state.State<Bool>) {
    public inline function new(v:wui.state.State<Bool>) this = v;

    @:from static inline function fromState(s:wui.state.State<Bool>):ToggleBinding
        return new ToggleBinding(s);

    public inline function unwrap():wui.state.State<Bool> return this;
}
#elseif (mui_backend == "cui")
abstract ToggleBinding(cui.ui.Checkbox.CheckboxBinding) {
    public inline function new(v:cui.ui.Checkbox.CheckboxBinding) this = v;

    @:from static inline function fromBoolState(s:cui.state.State.BoolState):ToggleBinding
        return new ToggleBinding(cui.ui.Checkbox.CheckboxBinding.fromState(s));

    @:from static inline function fromState(s:cui.state.State<Bool>):ToggleBinding
        return new ToggleBinding(new cui.ui.Checkbox.CheckboxBinding(
            () -> s.get(),
            (v) -> s.set(v)
        ));

    public inline function unwrap():cui.ui.Checkbox.CheckboxBinding return this;
}
#elseif (mui_backend == "aui")
abstract ToggleBinding(aui.state.State<Bool>) {
    public inline function new(v:aui.state.State<Bool>) this = v;

    @:from static inline function fromState(s:aui.state.State<Bool>):ToggleBinding
        return new ToggleBinding(s);

    public inline function unwrap():aui.state.State<Bool> return this;
}
#elseif (mui_backend == "qui")
typedef ToggleBinding = qui.ui.ToggleBinding;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
