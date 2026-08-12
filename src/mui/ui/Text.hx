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
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui"
#end
