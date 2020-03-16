//
//	Interface to Maude views
//

/**
 * A Maude view.
 */
class View {
public:
	View() = delete;

	/**
	 * Get the <i>from</i> theory of the view.
	 */

	VisibleModule* getFromTheory() const;

	/**
	 * Get the <i>to</i> module of the view.
	 */
	VisibleModule* getToModule() const;

	%namedEntityPrint;
};
