package mui;

#if (mui_backend == "sui")
typedef ViewComponent = sui.ViewComponent;
#elseif (mui_backend == "wui")
typedef ViewComponent = wui.ViewComponent;
#elseif (mui_backend == "cui")
typedef ViewComponent = cui.ViewComponent;
#elseif (mui_backend == "aui")
// Was declared inline here for want of a real one -- which meant no
// @:autoBuild, so a component's own @:state fields were never turned into
// cells. aui has had aui.ViewComponent since 2026-08-09.
typedef ViewComponent = aui.ViewComponent;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui"
#end
