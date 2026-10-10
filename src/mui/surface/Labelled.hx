package mui.surface;

/**
	A surface that is shown by its label before it is opened.

	A menu bar extra, a tray icon: what the person sees all day is the label —
	an icon, a word, a count — and the view is the panel it opens. Both are
	the application's, so a `Status` declaration returns both:

	```haxe
	@:surface(Status)
	function today():Labelled
		return new Labelled({title: "Chores", icon: Check, badge: dueToday}, () -> ui(<VStack>
			…today's chores…
		</VStack>));
	```

	The label is read like any view — inside the surface's own effect — so a
	`badge` taken from `@:state` follows the cell: write it, and the label in
	the menu bar changes, with nothing to call.

	The view is a thunk so that drawing the label does not build the panel: a
	menu bar shows the label all day and the panel only when it is open.
**/
class Labelled {
	public final label:SurfaceLabel;
	public final view:() -> mui.View;

	public function new(label:SurfaceLabel, view:() -> mui.View) {
		this.label = label;
		this.view = view;
	}
}

/**
	What a surface shows before it is opened.

	- `title` — always required, because it is what a screen reader says and
	  what a platform shows when it cannot draw the icon. It is the
	  application's own words, in the person's language: a library writing it
	  would be writing in a language it does not know.
	- `icon` — a name from the shared vocabulary. A host that has room for one
	  thing only shows this one.
	- `badge` — a count, drawn beside the icon when it is above zero. `0` and
	  absent are the same: nothing to say.
**/
typedef SurfaceLabel = {
	var title:String;
	var ?icon:mui.ui.IconName;
	var ?badge:Int;
}
