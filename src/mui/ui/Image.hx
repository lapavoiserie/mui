package mui.ui;

// Image is available on sui and wui but not cui (terminal has no image support)

#if (mui_backend == "sui")
typedef Image = sui.ui.Image;
#elseif (mui_backend == "wui")
typedef Image = wui.ui.Image;
#elseif (mui_backend == "cui")
#error "mui.ui.Image is not available on the cui (terminal) backend. Use #if (mui_backend != \"cui\") to guard Image usage."
#elseif (mui_backend == "aui")
typedef Image = aui.ui.Image;
#elseif (mui_backend == "qui")
typedef Image = qui.ui.Image;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
