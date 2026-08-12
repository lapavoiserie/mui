package mui.state;

#if (mui_backend == "sui")
typedef StateAction = sui.state.StateAction;
#elseif (mui_backend == "wui")
typedef StateAction = wui.state.StateAction;
#elseif (mui_backend == "cui")
// cui uses direct state method calls instead of declarative StateActions.
// Use state.set()/state.get() with closures for cross-backend compatibility.
enum StateAction {
    Increment(state:Dynamic, amount:Int);
    Decrement(state:Dynamic, amount:Int);
    SetValue(state:Dynamic, value:Dynamic);
    Toggle(state:Dynamic);
    Append(state:Dynamic, value:Dynamic);
}
#elseif (mui_backend == "aui")
typedef StateAction = aui.state.StateAction;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
