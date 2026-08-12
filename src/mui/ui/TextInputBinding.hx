package mui.ui;

/**
    Type-safe binding for TextInput. Accepts a backend @:state String field
    and converts to the backend's native binding type via @:from.

    Usage: new TextInput("Enter name...", nameState)
    The @:from conversion happens implicitly at the call site.
**/
#if (mui_backend == "sui")
abstract TextInputBinding(String) {
    public inline function new(v:String) this = v;

    @:from static inline function fromState(s:sui.state.State<String>):TextInputBinding
        return new TextInputBinding(s.name);

    public inline function unwrap():String return this;
}
#elseif (mui_backend == "wui")
abstract TextInputBinding(wui.state.State<String>) {
    public inline function new(v:wui.state.State<String>) this = v;

    @:from static inline function fromState(s:wui.state.State<String>):TextInputBinding
        return new TextInputBinding(s);

    public inline function unwrap():wui.state.State<String> return this;
}
#elseif (mui_backend == "cui")
abstract TextInputBinding(cui.state.Binding<String>) {
    public inline function new(v:cui.state.Binding<String>) this = v;

    @:from static inline function fromStringState(s:cui.state.State.StringState):TextInputBinding
        return new TextInputBinding(cui.state.Binding.from(s));

    @:from static inline function fromState(s:cui.state.State<String>):TextInputBinding
        return new TextInputBinding(cui.state.Binding.from(s));

    public inline function unwrap():cui.state.Binding<String> return this;
}
#elseif (mui_backend == "aui")
abstract TextInputBinding(aui.state.State<String>) {
    public inline function new(v:aui.state.State<String>) this = v;

    @:from static inline function fromState(s:aui.state.State<String>):TextInputBinding
        return new TextInputBinding(s);

    public inline function unwrap():aui.state.State<String> return this;
}
#elseif (mui_backend == "qui")
typedef TextInputBinding = qui.ui.TextInputBinding;
#elseif (mui_backend == "pui")
typedef TextInputBinding = pui.ui.TextInputBinding;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end
