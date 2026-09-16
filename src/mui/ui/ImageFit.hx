package mui.ui;

/**
	How a picture fills the space its `Image` is given, when their shapes differ.
**/
enum abstract ImageFit(String) to String {
	/** All of it, as large as fits; the rest of the space stays empty. What you get without asking. **/
	var Contain = "contain";

	/** The whole space, as small as covers it; what overflows is cut. **/
	var Cover = "cover";

	/** The whole space, stretched to its shape. **/
	var Fill = "fill";
}
