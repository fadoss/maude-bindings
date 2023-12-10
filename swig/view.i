//
//	Interface to Maude views
//

%{
#include "syntacticView.hh"
%}

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

		/**
		 * Get the LaTeX representation of the view.
		 *
		 * @param all Whether to show the processed view.
		 */
		std::string toLatex(bool all = false) const {
			SyntacticView* sview = dynamic_cast<SyntacticView*>(const_cast<View*>($self));
			// Only object-level views can be printed to LaTeX
			if (sview != nullptr) {
				std::ostringstream stream;
				if (all) sview->latexShowProcessedView(stream);
				else sview->latexShowView(stream);
				return stream.str();
			}
			return "<metalevel>";
		}
	}

	%namedEntityPrint;
};
