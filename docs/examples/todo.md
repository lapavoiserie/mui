# Todo App

A dynamic todo list using `ForEach.build()` to iterate over items.

```haxe
import mui.App;
import mui.View;
import mui.ui.*;

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

    static function main() {
        #if mui_owns_main
        new TodoApp().run();
        #end
    }
}
```

## What it demonstrates

- `ForEach.build()` macro -- works across all backends without `#if`
- Dynamic array state with `.get()` / `.set()`
- `TextInput` for adding new items
