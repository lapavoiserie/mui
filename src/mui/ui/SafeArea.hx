package mui.ui;

/**
    Wraps content to respect platform safe areas (notch, status bar,
    home indicator, etc.).

    Usage:
        new SafeArea([
            new Text("Title"),
            new VStack([...]),
        ])

    On sui: SwiftUI respects safe areas by default, so this just renders
    children in a VStack. The .safeArea() modifier on views is a no-op.

    On aui: Sets a viewType that the ComposeGenerator translates to
    Modifier.safeDrawingPadding() on the content.

    On wui/cui: No safe area concept — renders children in a plain stack.
**/
#if (mui_backend == "sui")
@:muiSupport("none", "SwiftUI handles safe areas by default: nothing to apply")
class SafeArea extends sui.ui.VStack {
    public function new(content:Array<sui.View>) {
        // SwiftUI handles safe areas by default
        super(null, null, content);
    }

    /** Modifier form — returns this view unchanged (SwiftUI default). **/
    public function safeArea():sui.View {
        return this;
    }
}
#elseif (mui_backend == "wui")
@:muiSupport("none", "a desktop window has no safe area")
class SafeArea extends wui.ui.VStack {
    public function new(content:Array<wui.View>) {
        super(content);
    }

    public function safeArea():wui.View {
        return this;
    }
}
#elseif (mui_backend == "aui")
class SafeArea extends aui.ui.SafeArea {
    public function new(content:Array<aui.View>) {
        super(content);
    }

    public function safeArea():aui.View {
        return this;
    }
}
#elseif (mui_backend == "cui")
@:muiSupport("none", "a terminal has no safe area")
class SafeArea extends cui.ui.VStack {
    public function new(content:Array<cui.View>) {
        super(content, 0);
    }

    public function safeArea():cui.View {
        return this;
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui"
#end
