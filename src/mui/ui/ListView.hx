package mui.ui;

// ListView APIs differ significantly:
//   sui: List(content:Array<View>) -- static content
//   wui: ListView(items:Dynamic, ?itemTemplate) -- dynamic items
//   cui: ListView(items:Array<String>, selection, ?onSelect, ?onDelete)

#if (mui_backend == "sui")
typedef ListView = sui.ui.List;
#elseif (mui_backend == "wui")
typedef ListView = wui.ui.ListView;
#elseif (mui_backend == "cui")
typedef ListView = cui.ui.ListView;
#elseif (mui_backend == "aui")
typedef ListView = aui.ui.LazyColumn;
#elseif (mui_backend == "qui")
typedef ListView = qui.ui.ListView;
#elseif (mui_backend == "pui")
typedef ListView = pui.ui.ListView;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end
