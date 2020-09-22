//
//	Reusable definitions for all the interface files
//

%{
#include <sstream>
std::string printBuffer;
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

// Extend the class with name getter
// for named entities
%define %namedEntityGetName
	%extend {
		const char * getName() {
			return Token::name($self->id());
		}
	}
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
		const char* REPR_METHOD() {
			std::ostringstream stream;
			stream << "$parentclasssymname with " << $self->size() << " elements";
			printBuffer = stream.str();
			return printBuffer.c_str();
		}
	}
	#endif
%enddef

%define %substitutionPrint
	#if defined(REPR_METHOD)
	%extend EasySubstitution {
		const char* REPR_METHOD() {
			int size = $self->size();
			std::ostringstream stream;
			for (int i = 0; i < size; i++)
				stream << ", " << $self->variable(i) << "=" << self->value(i);
			printBuffer = stream.str();
			return printBuffer.c_str() + 2;
		}
	}
	#endif
%enddef
