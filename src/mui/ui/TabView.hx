package mui.ui;

// Unified TabItem -- the common subset across backends
typedef TabItem = {
    label:String,
    content:mui.View,
};

#if (mui_backend == "sui")
class TabView extends sui.ui.TabView {
    public function new(tabs:Array<TabItem>) {
        super([for (t in tabs) {label: t.label, systemImage: "", content: t.content}]);
    }
}
#elseif (mui_backend == "wui")
class TabView extends wui.ui.TabView {
    public function new(tabs:Array<TabItem>) {
        super([for (t in tabs) {label: t.label, content: t.content}]);
    }
}
#elseif (mui_backend == "cui")
class TabView extends cui.ui.Tabs {
    /**
        The selection is optional here, as it is absent everywhere else.

        `cui` asks the application which tab is active, because a terminal has
        no widget keeping that for you. The other three backends keep it
        themselves, so requiring it here gave `mui.ui.TabView` two signatures --
        and an example whose whole claim is one source could not use it.

        Passing one stays possible, and is what you want when something else
        drives the selection. Leaving it out gets a selection this view owns.
    **/
    public function new(tabs:Array<TabItem>, ?active:cui.ui.Tabs.TabSelection) {
        super([for (t in tabs) {label: t.label, content: t.content}],
            active != null ? active : ownSelection());
    }

    /** A selection this view keeps, for tabs nothing else drives. **/
    static function ownSelection():cui.ui.Tabs.TabSelection {
        var index = 0;
        return new cui.ui.Tabs.TabSelection(() -> index, i -> index = i);
    }
}
#elseif (mui_backend == "aui")
class TabView extends aui.ui.TabView {
    public function new(tabs:Array<TabItem>) {
        super([for (t in tabs) new aui.ui.Tab(t.label, "", t.content)]);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui"
#end
