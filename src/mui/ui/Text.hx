package mui.ui;

/**
    Read-only text, optionally set at one of four shared sizes.

    `new Text("hello")` is unchanged and always was: the scale is optional, and
    without it every backend uses its own running-text size. See `TextScale` for
    why there are four steps and not eleven.

    Each backend is handed the step **its own scale calls this**, rather than a
    number. A title on iOS is not 28 points because `mui` says so; it is whatever
    Apple currently says a title is, and it follows the reader's text-size
    setting. Passing points would have frozen all four to one platform's taste
    and broken accessibility on two of them.

    This was a `typedef` to each backend's own Text until the scale arrived. It
    is a class now for the same reason `Toggle` and `Slider` are: the shared
    vocabulary says something the four spell differently.
**/
#if (mui_backend == "sui")
class Text extends sui.ui.Text {
    public function new(content:String, ?scale:TextScale) {
        super(content);
        if (scale != null) font(switch (scale) {
            case Title: sui.View.FontStyle.Title;
            // Apple has no "subtitle". Headline is its semibold heading step,
            // which is what a section heading is here.
            case Subtitle: sui.View.FontStyle.Headline;
            case Body: sui.View.FontStyle.Body;
            case Caption: sui.View.FontStyle.Caption;
        });
    }
}
#elseif (mui_backend == "wui")
class Text extends wui.ui.Text {
    public function new(content:String, ?scale:TextScale) {
        super(content);
        if (scale != null) this.font = switch (scale) {
            case Title: "Title";
            case Subtitle: "Subtitle";
            // WinUI's step table has no Body: it is the size a TextBlock takes
            // when nothing is said, and naming it keeps the four symmetrical.
            case Body: "Body";
            case Caption: "Caption";
        };
    }
}
#elseif (mui_backend == "aui")
class Text extends aui.ui.Text {
    public function new(content:String, ?scale:TextScale) {
        super(content);
        if (scale != null) font(switch (scale) {
            // Material's Display steps are for a single number filling a
            // screen, not for a page title. Headline is the step its own
            // guidance points at, which is where the mapping starts.
            case Title: aui.modifiers.ViewModifier.FontStyle.HeadlineSmall;
            case Subtitle: aui.modifiers.ViewModifier.FontStyle.TitleMedium;
            case Body: aui.modifiers.ViewModifier.FontStyle.BodyLarge;
            case Caption: aui.modifiers.ViewModifier.FontStyle.BodySmall;
        });
    }
}
#elseif (mui_backend == "cui")
class Text extends cui.ui.Text {
    public function new(content:String, ?scale:TextScale) {
        super(content);
        // A terminal cell is one size, so "bigger" can only be rendered as
        // heavier. The two heading steps are bold and the two others are not,
        // which is the whole of what this scale can honestly mean here.
        if (scale != null) switch (scale) {
            case Title | Subtitle: bold();
            case Body | Caption:
        }
    }
}
#elseif (mui_backend == "qui")
class Text extends qui.ui.Text {
    public function new(content:String, ?scale:TextScale) {
        super(content);
        // Silica follows Apple's scale, as sui does, so the four steps land on
        // the same names.
        if (scale != null) font(switch (scale) {
            case Title: qui.View.FontStyle.Title;
            case Subtitle: qui.View.FontStyle.Headline;
            case Body: qui.View.FontStyle.Body;
            case Caption: qui.View.FontStyle.Caption;
        });
    }
}
#elseif (mui_backend == "pui")
class Text extends pui.ui.Text {
    public function new(content:String, ?scale:TextScale) {
        // pui is the only backend where the four steps are the whole scale
        // rather than a selection from someone else's ramp, so the mapping is
        // one to one and there is nothing to approximate.
        super(content, scale == null ? null : switch (scale) {
            case Title: pui.ui.Text.TextScale.Title;
            case Subtitle: pui.ui.Text.TextScale.Subtitle;
            case Body: pui.ui.Text.TextScale.Body;
            case Caption: pui.ui.Text.TextScale.Caption;
        });
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end
