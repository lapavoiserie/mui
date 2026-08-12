package mui.ui;

/**
	A scrollable column of children.

	## One signature, four backends

	The backends disagree about what a scroll container takes: `sui` and `aui`
	take an array, `wui`'s `ScrollViewer` takes a single child, and `cui`'s needs
	a child *and* a scroll offset to read the position from. `mui` used to expose
	that disagreement — three different constructors behind one name — which
	makes the type unusable in anything meant to build everywhere. An example
	whose whole claim is "the same source" could not use it.

	So the signature is the array, everywhere, and the backends that want one
	child get a `VStack` around it. That is what they would have been given
	anyway.

	## The scroll offset, on cui

	A terminal has no scrollbar to drag, so `cui` asks the application where the
	view is scrolled to. Passing one stays possible; leaving it out gets a
	position this view owns, which is the right default for content that is
	merely long rather than navigated.
**/
#if (mui_backend == "sui")
class ScrollView extends sui.ui.ScrollView {
	public function new(content:Array<sui.View>) {
		super(content);
	}
}

#elseif (mui_backend == "aui")
class ScrollView extends aui.ui.ScrollView {
	public function new(content:Array<aui.View>) {
		super(content);
	}
}

#elseif (mui_backend == "wui")
class ScrollView extends wui.ui.ScrollViewer {
	public function new(content:Array<wui.View>) {
		super(new wui.ui.VStack(content));
	}
}

#elseif (mui_backend == "cui")
class ScrollView extends cui.ui.ScrollView {
	public function new(content:Array<cui.View>, ?offset:cui.ui.ScrollView.ScrollOffset) {
		super(new cui.ui.VStack(content), offset != null ? offset : ownPosition());
	}

	/**
		A position this view keeps, for content nothing else scrolls.

		A **static state cell**, like the tab selection beside it: held in a
		local it was new on every frame, so a scroll went back to the top the
		moment anything re-rendered -- and a plain variable never marks the frame
		dirty, so the move would not have been drawn anyway.

		One scrolling page per application. A screen with two independent scroll
		views has to say which position belongs to which, and passing one is what
		that looks like.
	**/
	static var position:cui.state.State<Int> = new cui.state.State(0, "mui.scrollView.position");

	static function ownPosition():cui.ui.ScrollView.ScrollOffset {
		return new cui.ui.ScrollView.ScrollOffset(() -> position.get(), v -> position.set(v));
	}
}

#elseif (mui_backend == "qui")
class ScrollView extends qui.ui.ScrollView {
	// Silica scrolls one child, like WinUI. The stack that would have been
	// written by hand is written here instead, so the shared constructor keeps
	// taking an array on all five.
	public function new(content:Array<qui.View>) {
		super(content.length == 1 ? content[0] : new qui.ui.VStack(content));
	}
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui"
#end
