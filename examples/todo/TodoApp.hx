import mui.App;
import mui.View;
import mui.ui.Text;
import mui.ui.VStack;
import mui.ui.HStack;
import mui.ui.Button;
import mui.ui.Spacer;
import mui.ui.TextInput;
import mui.ui.ForEach;
import mui.surface.Command;

class TodoApp extends App {
    @:state var inputText:String = "";
    @:state var todos:Array<String> = [];

    public function new() {
        super();
        appTitle = "Todo";
        todos.set(["Buy groceries", "Write documentation", "Review pull request"]);
    }

    override function body():View {
        return new VStack([
            new Text("Todo List"),
            new Text('${todos.get().length} items'),
            new HStack([
                new TextInput("New item...", inputText),
                new Button("Add", function() {
                    var text = inputText.get();
                    if (text.length > 0) {
                        var list = todos.get().copy();
                        list.push(text);
                        todos.set(list);
                        inputText.set("");
                    }
                }),
            ], 8),
            new Spacer(),
            ForEach.build(todos, function(item) {
                return new HStack([
                    new Text(item),
                    new Spacer(),
                ]);
            }),
            new Spacer(),
        ], 8);
    }

    // The Commands surface: the menu bar on sui (a "Shortcuts" menu — the
    // portable chord names the platform's primary modifier, so ctrl+n is
    // Cmd+N there), key bindings on cui, nothing on backends without a
    // command surface. One command carries a chord, one deliberately does
    // not: on a menu bar it still shows and clicks.
    @:surface(Commands, optional)
    function shortcuts():Array<Command> {
        return [
            new Command("Clear completed", function() todos.set([])).key("ctrl+k"),
            new Command("Reset examples", function()
                todos.set(["Buy groceries", "Write documentation", "Review pull request"])),
        ];
    }

    // The Preferences surface: the macOS Settings scene on sui (Cmd+, — a
    // second live root rendered by DynamicSurfaceView). No other backend here
    // hosts Preferences, and this app is built for four — hence `optional`,
    // the application accepting in its own source that it flies nowhere on
    // those. Same rules as any surface: display reads state live, in the
    // shared rebuild.
    @:surface(Preferences, optional)
    function preferences():View {
        return new VStack([
            new Text("Todo preferences"),
            new Text('${todos.get().length} items kept'),
        ], 8);
    }

    // The Glance surface: the Sailfish cover (live-mounted by qui's CoverHost),
    // a widget elsewhere someday. Only qui hosts it today, so `optional` says
    // the app accepts it flying nowhere on the four backends built here.
    // Display-only — reading state here keeps it live, in the surface's own
    // effect. The method name is the surface's stable id.
    @:surface(Glance, optional)
    function glance():View {
        return new VStack([
            new Text("Todo"),
            new Text('${todos.get().length} items'),
        ], 8);
    }

    static function main() {
        #if (mui_backend == "cui")
        new TodoApp().run();
        #end
    }
}
