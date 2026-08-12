package mui.state;

#if (mui_backend == "sui")
typedef Observable = sui.state.Observable;
#elseif (mui_backend == "wui")
typedef Observable = wui.state.Observable;
#elseif (mui_backend == "cui")
typedef Observable = cui.state.Observable;
#elseif (mui_backend == "aui")
typedef Observable = aui.state.Observable;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
