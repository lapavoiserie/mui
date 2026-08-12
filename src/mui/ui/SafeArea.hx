package mui.ui;

/**
    The part of the screen that is yours, with the margin the platform expects
    around what you put in it.

    Usage:
        new SafeArea([
            new Text("Title", Title),
            new VStack([...]),
        ])

    ## Two things, and the platform answers both

    **What you must stay out of** — a notch, a status bar, a home indicator.
    Only two backends have any: SwiftUI respects them by default, and Compose is
    told to. A desktop window and a terminal have none, which is what the
    `@:muiSupport` notes below have always said.

    **How far in the content sits.** Every platform answers this too, and not
    with the same number -- nor with one an application should be writing down.
    Content used to start hard against the window corner on wui because nothing
    here said otherwise, and a `padding` in the shared vocabulary would only
    have moved the problem: 24 is a reasonable inset on a desktop and a
    wasteful one on a phone.

    So the margin lives here, once per backend, and an app that says `SafeArea`
    gets the right one without naming it.
**/
#if (mui_backend == "sui")
@:muiSupport("none", "SwiftUI handles safe areas by default: nothing to apply")
class SafeArea extends sui.ui.VStack {
    public function new(content:Array<sui.View>) {
        // SwiftUI handles safe areas by default
        super(null, null, content);
        // SwiftUI's own default inset, which is what `.padding()` with no
        // number means -- deliberately not a figure written down here.
        padding();
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
        // WinUI's page inset. A desktop window has no notch to avoid, but it
        // does have an expected margin, and without one the kitchen sink drew
        // its first character in the very corner of the window.
        padding = 24;
    }

    public function safeArea():wui.View {
        return this;
    }
}
#elseif (mui_backend == "aui")
class SafeArea extends aui.ui.SafeArea {
    public function new(content:Array<aui.View>) {
        super(content);
        // Material's page margin, on top of the inset Compose already applies
        // for the system bars: staying out of the notch and sitting a sensible
        // distance from the edge are two different things.
        padding(16);
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
        // One cell. A terminal's margin is measured in characters, and a
        // desktop's 24 pixels would be a quarter of the screen here -- which is
        // exactly why the number is decided per backend rather than passed in.
        padding(1);
    }

    public function safeArea():cui.View {
        return this;
    }
}
#elseif (mui_backend == "qui")
@:muiSupport("none", "Silica keeps the status bar clear on its own")
class SafeArea extends qui.ui.SafeArea {
    public function new(content:Array<qui.View>) {
        super(content);
        // Silica sizes text in pixels and lays a page out from the screen
        // edge, so the inset is stated in the same unit the platform uses.
        // This was left out while `qui.View.padding` was a stub that returned
        // `this`: asking then would have read as applied while the screen
        // showed the first character against the edge.
        padding(24);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
