package mui.surface;

/**
	A set of commands with the name of the menu they belong to.

	```haxe
	@:surface(Commands)
	function chores():CommandMenu
		return new CommandMenu(t("menu.chores"), [
			new Command(t("menu.newChore"), add).key("ctrl+n"),
			new Command(t("menu.refresh"), refresh).key("ctrl+r"),
		]);
	```

	A method may still return a bare `Array<Command>`; this is for an
	application whose menu has a name of its own, in the person's language.
	The surface's id stays its identity (the method's name, or the one
	pinned); the title is read like a view, so a change of language renames
	the menu with nothing to call.

	A backend with no menus names nothing and loses nothing: the title is a
	label for commands it already lists.
**/
class CommandMenu {
	public final title:String;
	public final commands:Array<Command>;

	public function new(title:String, commands:Array<Command>) {
		this.title = title;
		this.commands = commands;
	}
}
