package mui.ui;

// Spacer has compatible constructors across all backends

#if (mui_backend == "sui")
typedef Spacer = sui.ui.Spacer;
#elseif (mui_backend == "wui")
typedef Spacer = wui.ui.Spacer;
#elseif (mui_backend == "cui")
typedef Spacer = cui.ui.Spacer;
#elseif (mui_backend == "aui")
typedef Spacer = aui.ui.Spacer;
#elseif (mui_backend == "qui")
typedef Spacer = qui.ui.Spacer;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
