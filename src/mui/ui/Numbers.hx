package mui.ui;

/**
	How digits are spaced.

	A timecode counting in a proportional font moves under the eye, because a
	`1` is narrower than a `0`. `Tabular` asks for digits of one width, which
	every platform has a switch for and a terminal has for free.
**/
enum abstract Numbers(String) to String {
	/** What a font does by default: each digit its own width. **/
	var Proportional = "proportional";

	/** Digits of one width: a counter whose column does not move. **/
	var Tabular = "tabular";
}
