import mui.App;
import mui.View;
import mui.ui.Text;
import mui.ui.VStack;
import mui.ui.HStack;
import mui.ui.Button;
import mui.ui.Spacer;
import mui.ui.TextInput;
import mui.ui.ForEach;

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

    // The Glance surface: the Sailfish cover (live-mounted by qui's CoverHost),
    // a widget elsewhere someday, nothing at all on backends without a glance
    // surface. Display-only — reading state here keeps it live, in the
    // surface's own effect. The method name is the surface's stable id.
    @:surface(Glance)
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
