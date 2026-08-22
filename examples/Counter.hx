import mui.App;
import mui.View;
import mui.ui.Text;
import mui.ui.VStack;
import mui.ui.HStack;
import mui.ui.Button;
import mui.ui.Spacer;

class Counter extends App {
    @:state var count:Int = 0;

    // A read-at-a-glance summary: the Sailfish cover, hosted by qui, and the
    // Android App Widget, hosted by aui. The other backends host no Glance,
    // and this example is built for all of them — so it says `optional`,
    // which is the application accepting, in its own source, that this
    // surface flies nowhere on those targets. Drop the word and a cui or wui
    // build stops, naming the role: that is the point of the check.
    //
    // The button is here to be tapped from the home screen. Nothing about it
    // is widget-specific: it is the ordinary vocabulary, and its closure runs
    // in the application's process when the tap comes back as an action id.
    // A cover that only displays strips it — degradation the host performs,
    // not something the declaration has to know.
    //
    // The method name is the surface's stable id: Tree(Glance, "glance", …).
    @:surface(Glance, optional)
    function glance():View {
        return new VStack([
            new Text('Count: ${count.get()}'),
            new Button("+1", function() count.set(count.get() + 1)),
        ], 8);
    }

    // An Auxiliary window: a second top-level window on wui and sui, each
    // live with its own surface record. cui and pui host none, so the same
    // `optional` applies. The method name, prettified, is the window title.
    @:surface(Auxiliary, optional)
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
                // The one snapshot surfaces need: a live surface reconciles
                // on its own, a sampled one has to be told the picture is
                // worth retaking. On a backend hosting no Glance this call
                // compiles to nothing at all — see mui.surface.Resample.
                new Button("+", function() {
                    count.set(count.get() + 1);
                    mui.surface.Resample.request(Glance);
                }),
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
