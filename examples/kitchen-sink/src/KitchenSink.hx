import mui.App;
import mui.View;
import mui.ui.Button;
import mui.ui.ConditionalView;
import mui.ui.Divider;
import mui.ui.ForEach;
import mui.ui.HStack;
import mui.ui.ProgressView;
import mui.ui.SafeArea;
import mui.ui.ScrollView;
import mui.ui.Slider;
import mui.ui.Spacer;
import mui.ui.TabView;
import mui.ui.Text;
import mui.ui.TextInput;
import mui.ui.Toggle;
import mui.ui.VStack;
import mui.ui.ZStack;

/**
    One app, every `mui` type the targeted backends share, on all of them.

    This is the example that answers "does write-once actually hold?" — not by
    asserting it, but by being the same source built for iOS, macOS and Android
    (and Windows, which the `wui` column of
    [Backend support](../../docs/backend-support.md) says is covered too).

    ## What it deliberately does not use, and why

    One absence, for a stated reason rather than for convenience — a kitchen
    sink that quietly skipped a type would be the wrong kind of example.

    - **`Image` and `ListView`** are in `mui`'s vocabulary and in all three
      backends, but not in **aui's dynamic renderer**, which is a narrower thing
      than the backend. Being outside it is a compile error naming the type, not
      a blank area on screen.

    ## Reading it

    Three tabs, each a different question:

    - **Layout** — do stacks, spacing, dividers and scrolling agree across
      platforms?
    - **Controls** — does a value edited by a native control reach Haxe, and
      does a Haxe write reach the screen?
    - **Data** — do a loop and a condition produce the same shape everywhere?
**/
class KitchenSink extends App {
    @:state var count:Int = 0;
    @:state var darkMode:Bool = false;
    @:state var notify:Bool = true;
    @:state var name:String = "";
    @:state var level:Float = 0.4;
    @:state var items:Array<String> = ["alpha", "beta", "gamma"];

    // A condition has to be something the renderers can follow, so it is a
    // cell kept up to date where the list changes -- not a value computed
    // while the tree is built, which the view rule refuses and no renderer
    // could observe.
    @:state var hasAny:Bool = true;

    public function new() {
        super();
        appTitle = "Kitchen Sink";
    }

    override function body():View {
        return new SafeArea([new TabView([
            {label: "Layout", content: layoutTab()},
            {label: "Controls", content: controlsTab()},
            {label: "Data", content: dataTab()},
        ])]);
    }

    // --- Layout ------------------------------------------------------------

    function layoutTab():View {
        return new ScrollView([new VStack([
            heading("Stacks"),
            new Text("A row of three, spaced evenly."),
            new HStack([
                new Text("left"),
                new Spacer(),
                new Text("middle"),
                new Spacer(),
                new Text("right"),
            ], 8),

            new Divider(),

            heading("Depth"),
            new Text("A ZStack lays its children on top of each other."),
            new ZStack([
                new Text("behind"),
                new Text("in front"),
            ]),

            new Divider(),

            heading("Spacing"),
            new Text("This column is built with an explicit gap, so the same\n"
                + "number produces the same rhythm on every backend."),
            new VStack([
                new Text("one"),
                new Text("two"),
                new Text("three"),
            ], 4),
        ], 12)]);
    }

    // --- Controls ----------------------------------------------------------

    function controlsTab():View {
        return new ScrollView([new VStack([
            heading("Buttons and state"),
            new Text('Count: ${count.get()}'),
            new HStack([
                new Button("-", () -> count.set(count.get() - 1)),
                new Button("Reset", () -> count.set(0)),
                new Button("+", () -> count.set(count.get() + 1)),
            ], 8),

            new Divider(),

            heading("Toggles"),
            new Toggle("Notifications", notify),
            new Toggle("Dark mode", darkMode),
            new Text('Notifications are ${notify.get() ? "on" : "off"}.'),

            new Divider(),

            heading("Text input"),
            new TextInput("Your name", name),
            new Text(greeting()),

            new Divider(),

            heading("A value, two ways"),
            new Slider(level),
            new ProgressView("Level", level.get()),
        ], 12)]);
    }

    function greeting():String {
        var typed = name.get();
        return typed == "" ? "Type above, and this line follows." : 'Hello, $typed.';
    }

    // --- Data --------------------------------------------------------------

    function dataTab():View {
        return new ScrollView([new VStack([
            heading("A loop"),
            new Text("Each row below is built by the same closure."),
            new VStack([ForEach.build(items, item -> new HStack([
                new Text("•"),
                new Text(item),
                new Spacer(),
            ], 6))], 4),

            new HStack([
                new Button("Add", () -> {
                    items.set(items.get().concat(["item " + (items.get().length + 1)]));
                    hasAny.set(true);
                }),
                new Button("Drop", () -> {
                    var current = items.get();
                    if (current.length > 0) items.set(current.slice(0, current.length - 1));
                    hasAny.set(items.get().length > 0);
                }),
            ], 8),

            new Divider(),

            heading("A condition"),
            new Text("The line below swaps when the list empties."),
            new ConditionalView(hasAny,
                new Text("The list has something in it."),
                new Text("The list is empty.")),
        ], 12)]);
    }

    // --- Shared ------------------------------------------------------------

    function heading(label:String):View {
        return new Text(label);
    }

    static function main() {
        #if (mui_backend == "cui")
        new KitchenSink().run();
        #end
    }
}
