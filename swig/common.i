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
#elif defined(SWIGOCAML)
#define REPR_METHOD to_string
#else
#define REPR_METHOD toString
#warning This language is not explicitly supported
#endif

// Extend the class with an object representation function
// defined by operator<<
%define %streamBasedPrint
	%extend {
		std::string REPR_METHOD() {
			std::ostringstream stream;
			stream << $self;
			return stream.str();
		}
	}
%enddef

// Extend the class with equal and hash methods based on the object address
%define %addressIdentifiable(classname, docname)
	%extend {
		/**
		 * Get the hash value of the docname.
		 */
		unsigned int hash() const {
			return (unsigned int) (uintptr_t) $self;
		}
		/**
		 * Check whether two docname are the same.
		 */
		bool equal(classname* other) {
			return $self == other;
		}
	}
%enddef


// Extend the class with an object representation function
// for named entities
%define %namedEntityPrint
	%extend {
		const char * REPR_METHOD() {
			return Token::name($self->id());
		}
	}
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
	%extend Vector {
		std::string REPR_METHOD() {
			std::ostringstream stream;
			stream << "$parentclasssymname with " << $self->size() << " elements";
			return stream.str();
		}
	}
%enddef

%define %substitutionPrint
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
%enddef

//
// Module protection: typemaps to protect a module while
// some objects belonging to it are alive
//

// Destructor for SearchState that removes the protection
// added to the module before the search
%define %unprotectDestructor(name)
	%extend {
		~name() {
			dynamic_cast<ImportModule*>($self->getContext()->root()->symbol()->getModule())->unprotect();
			delete $self;
		}
	}
%enddef

// Extend a type so that it protects its module when an instance is created
// and removes that protection when it is deleted
%define %otherItemProtection(name, prefix)
	%newobject Vector<name*>::GETTER_METHOD;

	%typemap (newfree) name* {
		if ($1 != nullptr)
			dynamic_cast<ImportModule*>($1 prefix->getModule())->protect();
	}

	%extend name {
		~name() {
			dynamic_cast<ImportModule*>($self prefix->getModule())->unprotect();
		}
	}
%enddef

// Particularization of the previous definition for ModuleItem subclasses
%define %moduleItemProtection(name)
	%otherItemProtection(name, )
%enddef

// Extend a Maude vector with module protection during its lifetime
// (this only works for non-empty vectors since we obtain the module
// from the initial element, so memory errors are possible otherwise)
%define %vectorProtection(name, prefix)
	%typemap (newfree) const Vector<name*>& {
		if (!$1->empty())
			dynamic_cast<ImportModule*>((*$1)[0] prefix->getModule())->protect();
	}

	%extend Vector<name*> {
		~Vector<name*>() {
			if (!$self->empty())
				dynamic_cast<ImportModule*>((*$self)[0] prefix->getModule())->unprotect();
		}
	}
%enddef

// Sorts
%newobject EasyTerm::getSort;
%newobject ConnectedComponent::sort;
%newobject SortConstraint::getSort;
%newobject Symbol::getRangeSort;
%newobject RewriteStrategy::getSubjectSort;
%newobject SortTestConditionFragment::getSort;
%moduleItemProtection(Sort);

// Symbols
%newobject HookData::getSymbol;
%newobject VisibleModule::findSymbol;
%newobject VisibleModule::findSort;
%newobject EasyTerm::symbol;
%moduleItemProtection(Symbol);

// Other module items
%moduleItemProtection(SortConstraint);
%moduleItemProtection(Equation);
%moduleItemProtection(Rule);
%moduleItemProtection(RewriteStrategy);
%moduleItemProtection(StrategyDefinition);

// Kinds
%newobject Sort::component;
%newobject Symbol::domainComponent;
%otherItemProtection(ConnectedComponent, ->sort(0));

// Operator declarations
%otherItemProtection(OpDeclaration, ->getDomainAndRange()[0]);

// Protection for Maude vectors returned from the module
// (they are references to the internal vectors held by the module and its
// elements are not objects in the target language until accessed) (this is
// optional since in some languages vectors can also be created by the user
// and we cannot distinguish these situations without adding an extra field)
%define %vectorProtections
	%newobject VisibleModule::getSorts;
	%newobject Sort::getSubsorts;
	%newobject Sort::getSupersorts;
	%newobject RewriteStrategy::getDomain;
	%newobject OpDeclaration::getDomainAndRange;
	%vectorProtection(Sort, );

	%newobject VisibleModule::getSymbols;
	%vectorProtection(Symbol, );

	%newobject VisibleModule::getConnectedComponents;
	%vectorProtection(ConnectedComponent, );

	%newobject VisibleModule::getSortConstraints;
	%vectorProtection(SortConstraint, );

	%newobject VisibleModule::getEquations;
	%vectorProtection(Equation, );

	%newobject VisibleModule::getRules;
	%vectorProtection(Rule, );

	%newobject VisibleModule::getStrategies;
	%vectorProtection(RewriteStrategy, );

	%newobject VisibleModule::getStrategyDefinitions;
	%newobject RewriteStrategy::getDefinitions;
	%vectorProtection(StrategyDefinition, );

	// Protection for strategy definitions (this vector itself
	// should also be released)
	%typemap (newfree) Vector<const OpDeclaration*> {
		if (!$1.empty())
			dynamic_cast<ImportModule*>($1[0]->getDomainAndRange()[0]->getModule())->protect();
	}

	%extend Vector<const OpDeclaration*> {
		~Vector<const OpDeclaration*>() {
			if (!$self->empty())
				dynamic_cast<ImportModule*>((*$self)[0]->getDomainAndRange()[0]->getModule())->unprotect();
			delete $self;
		}
	}
%enddef
