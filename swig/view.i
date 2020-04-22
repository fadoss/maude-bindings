//
//	Interface to Maude views
//

/**
 * A Maude view.
 */
class View {
public:
	View() = delete;

	%extend {
		/**
		 * Get the <i>from</i> theory of the view.
		 */
		VisibleModule* getFromTheory() const {
			VisibleModule* mod = safeCast(VisibleModule*, $self->getFromTheory());
			mod->protect();
			return mod;
		}

		/**
		 * Get the <i>to</i> module of the view.
		 */
		VisibleModule* getToModule() const {
			VisibleModule* mod = safeCast(VisibleModule*, $self->getToModule());
			mod->protect();
			return mod;
		}
	}

	%namedEntityPrint;
};
