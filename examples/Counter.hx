import mui.App;
import mui.View;
import mui.ui.Text;
import mui.ui.VStack;
import mui.ui.HStack;
import mui.ui.Button;
import mui.ui.Spacer;

class Counter extends App {
    @:state var count:Int = 0;

    // A read-at-a-glance summary — the Sailfish cover once its host lands;
    // declared today, mounted by no backend yet. The method name is the
    // surface's stable id: Tree(Glance, "glance", …).
    @:surface(Glance)
    function glance():View {
        return new Text('Count: ${count.get()}');
    }

    // An Auxiliary window: a second top-level window on wui (live, its own
    // surface record), nothing anywhere else — windowless backends degrade it
    // to a silent no-op. The method name, prettified, is the window title.
    @:surface(Auxiliary)
    function inspector():View {
        return new VStack([
            new Text("Inspector"),
            new Text('Count is ${count.get()}'),
        ], 8);
    }

    override function body():View {
        return new VStack([
            new Spacer(),
            new Text("Counter"),
            new Text('Count: ${count.get()}'),
            new HStack([
                new Button("-", function() count.set(count.get() - 1)),
                new Button("Reset", function() count.set(0)),
                new Button("+", function() count.set(count.get() + 1)),
            ], 8),
            new Spacer(),
        ], 10);
    }

    static function main() {
        #if (mui_backend == "cui")
        new Counter().run();
        #end
    }
}
