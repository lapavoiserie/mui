import mui.App;
import mui.View;
import mui.ui.Text;
import mui.surface.Command;
import mui.surface.Labelled;
import mui.surface.SurfaceDecl;
import mui.surface.SurfaceRole;

/**
	A settings window that names itself, and a status item with a menu of its
	own. `main` prints the window's title and content as a host reads them,
	that a bare-view window has no title, and the status menu's labels.
**/
class WindowTitled extends App {
	@:state var lang:String = "fr";

	override function body():View {
		return new Text("body");
	}

	@:surface(Preferences, optional)
	function settings():Labelled {
		return new Labelled({title: lang == "fr" ? "Réglages" : "Settings"}, () -> new Text("prefs"));
	}

	@:surface(Auxiliary, optional)
	function plain():View {
		return new Text("plain");
	}

	@:surface(Status, optional)
	function tray():Labelled {
		return new Labelled({title: "Chores"}, () -> new Text("panel"),
			[new Command("Ouvrir", () -> {}), new Command("Quitter", () -> {})]);
	}

	static function main() {
		var app = new WindowTitled();
		var decls = app.surfaces();
		var prefs = SurfaceDeclTools.pickOne(decls, SurfaceRole.Preferences, "preferences");
		var title = SurfaceDeclTools.windowTitleOf(decls, prefs.id);
		var plain = SurfaceDeclTools.windowTitleOf(decls, "plain");
		var tray = SurfaceDeclTools.pickOneLabelled(decls, SurfaceRole.Status, "status");
		// The menu is read the way a host reads it: off the declaration, on demand.
		var menu:Array<String> = [];
		for (d in decls) switch (d) {
			case LabelledTree(_, id, labelled) if (id == tray.id):
				for (c in labelled().menu) menu.push(c.label);
			case _:
		}
		Sys.println('${prefs.id} ${title()} ${plain == null ? "untitled" : "titled"} menu=${menu.join(",")}');
	}
}
