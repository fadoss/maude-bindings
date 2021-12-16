//
//	Reusable definitions for all the interface files
//

%{
#include <sstream>
%}

#if defined(SWIGJAVA)
#define GETTER_METHOD get
#define SETTER_METHOD set
#else
#define GETTER_METHOD __getitem__
#define SETTER_METHOD __setitem__
#endif

#if defined(SWIGPYTHON)
#define REPR_METHOD __repr__
#elif defined(SWIGJAVA)
#define REPR_METHOD toString
#elif defined(SWIGLUA)
#define REPR_METHOD __str__
#elif defined(SWIGR)
#define REPR_METHOD show
#elif defined(SWIGJAVASCRIPT)
#define REPR_METHOD toString
#elif defined(SWIGCSHARP)
#define REPR_METHOD ToString
#else
#warning This language is not explicitly supported
#endif

// Extend the class with an object representation function
// defined by operator<<
%define %streamBasedPrint
	#if defined(REPR_METHOD)
	%extend {
		std::string REPR_METHOD() {
			std::ostringstream stream;
			stream << $self;
			return stream.str();
		}
	}
	#endif
%enddef

// Extend the class with an object representation function
// for named entities
%define %namedEntityPrint
	#if defined(REPR_METHOD)
	%extend {
		const char * REPR_METHOD() {
			return Token::name($self->id());
		}
	}
	#endif
%enddef

// Extend the class with name getter
// for named entities
%define %namedEntityGetName
	%extend {
		const char * getName() {
			return Token::name($self->id());
		}
	}
%enddef

// Extend the class with a getter for metadata
%define %getMetadataItem(itype)
	%extend {
		/**
		 * Get the free text @c metadata attribute of this statement.
		 */
		const char * getMetadata() {
			VisibleModule* mod = safeCast(VisibleModule*, $self->getModule());
			int metadata = mod->getMetadata(MixfixModule::itype, $self);
			return metadata == NONE ? nullptr : Token::name(metadata);
		}
	}
%enddef

// Extend the class with a getter for line number information
%define %getLineNumber
	%extend {
		/**
		 * Get the line number information for this item as formatted by Maude.
		 *
		 * The format of the string is usually <code>filename, line line (module)</code>
		 * where the second @c line is the integral line number, and @c module is
		 * the module type and name where this item was originally defined. The
		 * @c filename may be an actual quoted filename or some special name
		 * between angle brackets.
		 */
		std::string getLineNumber() const {
			ostringstream stream;
			stream << *$self;
			return stream.str();
		}
	}
%enddef

// Extend the class with getters for the left and right hand side
// terms of a two sided object
%define %twoSidedObject
	%newobject getLhs;
	%newobject getRhs;

	%extend {
		/**
		 * Get the left-hand-side term.
		 */
		EasyTerm* getLhs() const {
			return new EasyTerm($self->getLhs(), false);
		}

		/**
		 * Get the right-hand-side term.
		 */
		EasyTerm* getRhs() const {
			return new EasyTerm($self->getRhs(), false);
		}
	}
%enddef

// Extend the class with the getLabel function for preequations
%define %labeledObject
	%extend {
		/**
		 * Get the label attribute.
		 */
		const char* getLabel() const {
			int label = $self->getLabel().id();
			return label != NONE ? Token::name(label) : nullptr;
		}
	}
%enddef

%define %vectorPrint
	#if defined(REPR_METHOD)
	%extend Vector {
		std::string REPR_METHOD() {
			std::ostringstream stream;
			stream << "$parentclasssymname with " << $self->size() << " elements";
			return stream.str();
		}
	}
	#endif
%enddef

%define %substitutionPrint
	#if defined(REPR_METHOD)
	%extend EasySubstitution {
		std::string REPR_METHOD() {
			Vector<Term*> variables;
			Vector<DagRoot*> values;

			$self->getSubstitution(variables, values);
			size_t size = variables.size();

			std::ostringstream stream;
			for (size_t i = 0; i < size; ++i) {
				stream << (i > 0 ? ", " : "")
				       << variables[i] << "=" << values[i]->getNode();
				variables[i]->deepSelfDestruct();
			}
			return stream.str();
		}
	}
	#endif
%enddef

// Destructor of SearchState that removes the protection
// added to the module before the search
%define %unprotectDestructor(name)
	%extend {
		~name() {
			dynamic_cast<ImportModule*>($self->getContext()->root()->symbol()->getModule())->unprotect();
			delete $self;
		}
	}
%enddef
