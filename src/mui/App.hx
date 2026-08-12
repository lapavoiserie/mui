package mui;

/**
    Base class for mui applications. Extend this and override body().

    Provides:
    - @:state macro support (inherited from backend)
    - appTitle property (sets window/app title on sui/wui)
    - Default Ctrl+C / q quit handling on cui
**/
#if (mui_backend == "sui")
class App extends sui.App {
    /** Set the application title. Maps to sui's appName. **/
    public var appTitle(get, set):String;

    function get_appTitle():String return appName;
    function set_appTitle(v:String):String { appName = v; return v; }
}

#elseif (mui_backend == "wui")
@:nui
class App extends wui.App {
    var _appTitle:String = "App";

    /**
        The view, as a `nui` node tree — what `ui()` markup produces.

        This is the end-to-end chain: markup checked at compile time against the
        target backend, producing a tree the backend renders. `wui` takes it
        through the push contract; `cui` has a `NodeRenderer` that does the same
        for a terminal. Each backend renders the same tree its own way, which is
        the whole point of a shared node model.
    **/
    public function view():nui.Node {
        return new nui.Node("VStack");
    }

    /**
        What wui's push mode calls.

        Either shape of application answers it. An app that overrides `view()`
        describes nodes directly, and that is handed to the sink. An app that
        overrides `body()` — the shape the other three backends take — has its
        view tree *described* as nodes by `mui.nui.FromViews`.

        Before this, `body()` was a stub the push renderer never called: an app
        written the ordinary way compiled for wui and drew an empty window,
        which is the one thing a layer like this exists to prevent.
    **/
    public function nuiBody():nui.Node {
        var declared = view();
        if (declared != null && !isEmptyRoot(declared)) return declared;
        return mui.nui.FromViews.describe(body());
    }

    /** The placeholder `view()` returns when an app never overrode it. **/
    function isEmptyRoot(node:nui.Node):Bool {
        return node.type == "VStack"
            && (node.children == null || node.children.length == 0)
            && (node.props == null || !node.props.keys().hasNext());
    }

    // wui.App requires it. An app that overrides it gets it described as nodes;
    // one that does not gets an empty root, and its `view()` is what renders.
    override function body():wui.View {
        return new wui.ui.VStack([]);
    }

    /** Set the application title. Maps to wui's appName(). **/
    public var appTitle(get, set):String;

    function get_appTitle():String return _appTitle;
    function set_appTitle(v:String):String { _appTitle = v; return v; }

    override function appName():String return _appTitle;
}

#elseif (mui_backend == "cui")
class App extends cui.App {
    /** App title (informational on cui — terminal has no title bar). **/
    public var appTitle:String = "App";

    /** Default event handler: Ctrl+C and q to quit. Override for custom keys. **/
    override function handleEvent(event:cui.event.Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Char("c") if (key.ctrl): quit(); return true;
                    case Char("q"): quit(); return true;
                    default:
                }
            default:
        }
        return false;
    }
}

#elseif (mui_backend == "aui")
class App extends aui.App {
    public var appTitle(get, set):String;
    function get_appTitle():String return appName;
    function set_appTitle(v:String):String { appName = v; return v; }
}

#elseif (mui_backend == "qui")
// `qui.App` already carries `appTitle`, mapped to its own `appName`: the
// Sailfish backend was written against this contract before it was wired in.
class App extends qui.App {}

#elseif (mui_backend == "pui")
// `pui.App` already carries `appTitle` and the `@:state` build macro. Nothing
// is added here on purpose: the macro must run once, and it runs there.
class App extends pui.App {}

#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end
