# Todo App

A dynamic todo list: the rows are a Haxe comprehension, spliced into the view.

```haxe
import mui.macros.Markup.ui;

class TodoApp extends mui.App {
    @:state var inputText:String = "";
    @:state var todos:Array<String> = [];

    public function new() {
        super();
        appTitle = "Todo";
        todos = ["Buy groceries", "Write documentation", "Review pull request"];
    }

    override function body():mui.View {
        return ui(<VStack spacing={8}>
            <Text text="Todo List" scale="title"/>
            <Text text={todos.length + " items"}/>
            <HStack spacing={8}>
                <TextInput text={inputText_} placeholder="New item..."/>
                <Button label="Add" onClick={add}/>
            </HStack>
            <Spacer/>
            {[for (item in todos) ui(<HStack key={item} spacing={8}>
                <Text text={item}/>
                <Spacer/>
            </HStack>)]}
            <Spacer/>
        </VStack>);
    }

    function add() {
        if (inputText.length == 0) return;
        var list = todos.copy();
        list.push(inputText);
        todos = list;
        inputText = "";
    }

    static function main() {
        #if mui_owns_main
        new TodoApp().run();
        #end
    }
}
```

## What it demonstrates

- a comprehension in markup: `{[for (item in todos) ui(<HStack key={item}>…)]}`
- a `key` per row, so a row that moves keeps what is remembered about it
- An `ImmutableList` in a `@:state` field: a new list is a new value, so the view is told
- `TextInput` for adding new items
