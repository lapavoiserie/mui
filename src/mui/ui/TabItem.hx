package mui.ui;

/**
	One tab: a label, and the page behind it.

	Shared vocabulary rather than a per-backend type, and one of only two things
	a backend borrows from `mui` instead of the other way round — the other being
	`mui.ui.TextScale`. Both exist for the same reason: they are what the six
	backends had to *agree* on, not what any of them provides.

	`content` is `mui.View`, which `mui.macros.Bind` has already resolved to the
	backend's own view type by the time anything reads this.
**/
typedef TabItem = {
	label:String,
	content:mui.View,
};
