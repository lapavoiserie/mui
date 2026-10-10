import mui.App;
import mui.View;
import mui.ui.Text;
import mui.surface.Labelled;
import mui.surface.SurfaceDecl;
import mui.surface.SurfaceRole;

/**
	A Status surface, accepted as optional on cui, collected with its label.
	`main` prints the id, the label's three parts and whether the panel was
	built while only the label was read -- it must not have been.
**/
class StatusLabelled extends App {
	@:state var due:Int = 3;

	override function body():View {
		return new Text("body");
	}

	@:surface(Status, optional)
	function today():Labelled {
		return new Labelled({title: "Chores", icon: Check, badge: due}, () -> {
			PanelProbe.hit();
			return new Text('$due due');
		});
	}

	static function main() {
		var app = new StatusLabelled();
		var one = SurfaceDeclTools.pickOneLabelled(app.surfaces(), SurfaceRole.Status, "status");
		var label = one.label();
		var line = '${one.id} ${label.title} ${(label.icon : String)} ${label.badge} built=${PanelProbe.count}';
		one.content();
		Sys.println(line + ' then=${PanelProbe.count} trees=' + SurfaceDeclTools.treesOf(app.surfaces(), SurfaceRole.Status).length);
	}
}

/** Counts panel builds from outside the application, which a view may not do itself. **/
class PanelProbe {
	public static var count(default, null) = 0;

	public static function hit():Void
		count++;
}
