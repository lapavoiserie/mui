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
/**
    Sections, not documents.

    This used to extend `wui.ui.TabView`, which is WinUI's **document** control:
    browser tabs, each carrying a close button, the strip carrying a "+" to open
    another. Both offers are wrong for the sections of an app -- nothing about
    "Layout, Controls, Data" can be closed or added -- and both were on screen.

    `NavigationView` in `Top` mode is what WinUI offers for this, and it reads
    the way tabs read on the other three backends. It owns the selection too, so
    this constructor still asks for none: one signature, four backends.
**/
class TabView extends wui.ui.NavigationView {
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
#elseif (mui_backend == "qui")
class TabView extends qui.ui.TabView {
    /**
        Silica has no tab bar, so `qui` composes one -- and asks who owns the
        selection, as `cui` does. Nothing else drives it here, so this view
        does.
    **/
    public function new(tabs:Array<TabItem>) {
        super([for (t in tabs) {label: t.label, content: t.content}], selection);
    }

    /**
        Static, because it has to outlive a rebuild. Created per construction it
        would be new every time the tree is rebuilt, and the selection would
        snap back to the first tab on the write the tap itself caused --
        the lesson `wui.ui.NavigationView` and `sui`'s renderer both paid for.
        One tab bar per application, said rather than discovered.
    **/
    static var selection:qui.state.State<Int> = new qui.state.State(0);
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
