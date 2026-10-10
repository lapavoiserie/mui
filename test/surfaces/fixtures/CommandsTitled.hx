import mui.App;
import mui.View;
import mui.ui.Text;
import mui.surface.Command;
import mui.surface.CommandMenu;
import mui.surface.SurfaceDecl;

/**
	A command set with a menu name, written in the person's language and
	read like a view: `main` prints the title, then the commands it carries.
**/
class CommandsTitled extends App {
	@:state var french:Bool = true;

	override function body():View {
		return new Text("body");
	}

	@:surface(Commands)
	function chores():CommandMenu {
		return new CommandMenu(french ? "Tâches" : "Chores", [
			new Command(french ? "Nouvelle tâche" : "New chore", () -> {}).key("ctrl+n"),
		]);
	}

	static function main() {
		var app = new CommandsTitled();
		var decls = app.surfaces();
		var title = SurfaceDeclTools.commandTitleOf(decls, "chores");
		var commands = [for (d in decls) switch d { case CommandSet(_, c): c(); case _: null; }].filter(c -> c != null)[0];
		Sys.println('${title()} ${commands.map(c -> c.label + "/" + c.shortcut).join(",")}');
	}
}
