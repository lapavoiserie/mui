package mui.ui;

/**
	The size of a piece of text, said in a way four platforms can honour.

	## Why four steps and not eleven

	Every backend already has a typographic scale, and no two agree: Apple's has
	eleven steps, Material's twelve, WinUI's five, and a terminal has **none** —
	it has bold, dim and colour, and a single cell height that nothing can
	change.

	A shared vocabulary can only carry what all four can mean. These four are
	that intersection: a page's title, a section's heading, its running text, and
	something set smaller than the rest. `cui` renders the first two bold and
	leaves the others alone, which is the honest reading of "bigger" on a
	terminal — the only one available.

	Anything finer is a backend's own vocabulary, and reaching for it is choosing
	that platform deliberately: `sui.View.font(Footnote)` and
	`aui.View.font(DisplayLarge)` are still there, and a view built from `mui`
	still accepts them.

	## Why it is on the view and not a modifier

	`mui.ui.Text` takes it as an argument, because a heading's size is part of
	what it *is*, not something applied to it afterwards. It also keeps the shape
	`new Text("...")` untouched: the parameter is optional, and every existing
	call still means what it meant.
**/
enum TextScale {
	/** A page's title. **/
	Title;

	/** A heading inside a page. **/
	Subtitle;

	/** Running text. What you get without asking. **/
	Body;

	/** Set smaller than the rest: a note, a label, an aside. **/
	Caption;
}
