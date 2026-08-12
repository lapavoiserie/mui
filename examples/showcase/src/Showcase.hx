import mui.App;
import mui.View;
import mui.ui.Button;
import mui.ui.ConditionalView;
import mui.ui.Divider;
import mui.ui.ForEach;
import mui.ui.HStack;
import mui.ui.SafeArea;
import mui.ui.ScrollView;
import mui.ui.Spacer;
import mui.ui.Text;
import mui.ui.TextInput;
import mui.ui.TextScale;
import mui.ui.Toggle;
import mui.ui.VStack;

/**
    One screen, written to be looked at rather than to be counted.

    ## Why this exists next to the kitchen sink

    They answer different questions, and one example cannot answer both.

    The **kitchen sink** asks *does write-once hold?* It uses every shared type
    once, in the plainest arrangement that shows each working, and it is
    deliberately unstyled: anything it looks like beyond the vocabulary would be
    a claim the vocabulary cannot back. When it looks bare, that is information.

    This one asks *does an app built this way look like it belongs?* It uses a
    fraction of the vocabulary and arranges it with care -- a title, headings, a
    caption, spacing that means something, one screen with one job. If it looks
    unfinished, that is a defect, and the difference between the two examples is
    what tells you which kind of problem you are looking at.

    ## The rule it keeps

    Every line here is shared `mui`. Nothing reaches for a backend's own
    vocabulary, and there is not one `#if` -- so whatever it looks like on
    Windows, it is the same source that produced iOS, macOS and Android.

    That is the constraint that makes it worth building. An example allowed to
    special-case a platform would prove only that the platform can be
    special-cased.
**/
class Showcase extends App {
    @:state var name:String = "";
    @:state var notify:Bool = true;
    @:state var digest:Bool = false;
    @:state var saved:Bool = false;

    // Kept as a cell rather than derived while the tree is built: a view reads
    // observable state, and a value computed during body() is neither
    // observable nor something a renderer could follow.
    @:state var recent:Array<String> = [
        "Signed in from a new device",
        "Password changed",
        "Two-factor enabled",
    ];

    // A condition is a cell kept up to date where the list changes, never a
    // value computed while the tree is built. Writing state during body() would
    // re-enter the render that is running, and reading `recent.length` there
    // gives the renderers nothing they can observe.
    @:state var hasAnyActivity:Bool = true;

    public function new() {
        super();
        appTitle = "Account";
    }

    override function body():View {
        return new SafeArea([new ScrollView([new VStack([
            heading(),
            profile(),
            new Divider(),
            preferences(),
            new Divider(),
            activity(),
        ], 20)])]);
    }

    // --- The parts -----------------------------------------------------------

    function heading():View {
        return new VStack([
            new Text("Account", Title),
            new Text("Everything on this screen is shared mui vocabulary.", Caption),
        ], 4);
    }

    function profile():View {
        return new VStack([
            new Text("Profile", Subtitle),
            new TextInput("Your name", name),
            new Text(greeting()),
        ], 8);
    }

    function greeting():String {
        var typed = name.get();
        return typed == "" ? "We will use this to address you." : 'Hello, $typed.';
    }

    function preferences():View {
        return new VStack([
            new Text("Preferences", Subtitle),
            new Toggle("Email notifications", notify),
            new Toggle("Weekly digest", digest),
            new Text(summary(), Caption),

            new HStack([
                new Spacer(),
                new Button(saved.get() ? "Saved" : "Save changes", () -> saved.set(true)),
            ], 8),
        ], 8);
    }

    function summary():String {
        if (!notify.get() && !digest.get()) return "You will not hear from us.";
        if (notify.get() && digest.get()) return "Email as it happens, plus a weekly summary.";
        return notify.get() ? "Email as it happens." : "A weekly summary only.";
    }

    function activity():View {
        return new VStack([
            new Text("Recent activity", Subtitle),

            new ConditionalView(hasAnyActivity,
                new VStack([ForEach.build(recent, line -> new HStack([
                    new Text("•"),
                    new Text(line),
                    new Spacer(),
                ], 8))], 6),
                new Text("Nothing yet.", Caption)),

            new HStack([
                new Button("Clear", () -> {
                    recent.set([]);
                    hasAnyActivity.set(false);
                }),
                new Spacer(),
            ], 8),
        ], 8);
    }

    static function main() {
        // cui and pui are the two backends whose engine owns the process:
        // everywhere else the generated app has its own entry point and this
        // main() must stay empty.
        #if (mui_backend == "cui" || mui_backend == "pui")
        new Showcase().run();
        #end
    }
}
