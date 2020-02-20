//
//	Reusable definitions for all the interface files
//

%{
#include <sstream>
std::string printBuffer;
%}

#if defined(SWIGPYTHON)
#define REPR_METHOD __repr__
#elif defined(SWIGJAVA)
#define REPR_METHOD toString
#else
#warning Unsupported language
#endif

// Extend the class with an object representation function
// defined by operator<<
%define %streamBasedPrint
	#if defined(REPR_METHOD)
	%extend {
		const char* REPR_METHOD() {
			std::ostringstream stream;
			stream << $self;
			printBuffer = stream.str();
			return printBuffer.c_str();
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

// Extend the class with getters for the left and right hand side
// terms of a two sided object
%define %twoSidedObject
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

	%newobject getLhs;
	%newobject getRhs;
%enddef

// Extend the class with the getLabel function for preequations
%define %labeledObject
	%extend {
		const char* getLabel() const {
			int label = $self->getLabel().id();
			return label != NONE ? Token::name(label) : nullptr;
		}
	}
%enddef
