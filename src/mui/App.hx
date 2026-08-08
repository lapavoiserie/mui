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

    /** What wui's push mode calls. Handed straight to the sink. **/
    public function nuiBody():nui.Node {
        return view();
    }

    // wui.App requires it, and push mode ignores it: the window gets an empty
    // root and the node tree is mounted into it.
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

#else
#error "mui requires -D mui_backend=sui|wui|cui|aui"
#end
