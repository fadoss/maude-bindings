//
//	Interface to Maude terms and operations
//

%{
#include "strategicSearch.hh"
#include "rewriteSequenceSearch.hh"
#include "variantSearch.hh"
#include "pattern.hh"
#include "dagArgumentIterator.hh"
#include "narrowingSequenceSearch3.hh"
%}

%import "config.h"

//
//	Simplified interface to Maude terms
//	(defined and documented in easyTerm.cc/hh)
//

%rename (Term) EasyTerm;
%rename (Substitution) EasySubstitution;
%rename (ArgumentIterator) DagArgumentIterator;
%rename (NarrowingSequenceSearch) NarrowingSequenceSearch3;


/**
 * Search types (number of steps).
 */
enum SearchType {
	ONE_STEP,		///< ->1
	AT_LEAST_ONE_STEP,	///< ->+
	ANY_STEPS,		///< ->*
	NORMAL_FORM		///< ->!
};

%{
using PrintFlags = Interpreter::PrintFlags;

// using enum PrintFlags (in C++20)
constexpr PrintFlags PRINT_CONCEAL = PrintFlags::PRINT_CONCEAL;
constexpr PrintFlags PRINT_FORMAT = PrintFlags::PRINT_FORMAT;
constexpr PrintFlags PRINT_MIXFIX = PrintFlags::PRINT_MIXFIX;
constexpr PrintFlags PRINT_WITH_PARENS = PrintFlags::PRINT_WITH_PARENS;
constexpr PrintFlags PRINT_COLOR = PrintFlags::PRINT_COLOR;
constexpr PrintFlags PRINT_DISAMBIG_CONST = PrintFlags::PRINT_DISAMBIG_CONST;
constexpr PrintFlags PRINT_WITH_ALIASES = PrintFlags::PRINT_WITH_ALIASES;
constexpr PrintFlags PRINT_FLAT = PrintFlags::PRINT_FLAT;
constexpr PrintFlags PRINT_NUMBER = PrintFlags::PRINT_NUMBER;
constexpr PrintFlags PRINT_RAT = PrintFlags::PRINT_RAT;
%}

/**
 * Print flags.
 */
enum PrintFlags {
	PRINT_CONCEAL = 0x2,		///< respect concealed argument lists
	PRINT_FORMAT = 0x4,		///< respect format attribute
	PRINT_MIXFIX = 0x8,		///< mixfix notation
	PRINT_WITH_PARENS = 0x10,	///< maximal parens
	PRINT_COLOR = 0x20,		///< dag node coloring based on ctor/reduced status
	PRINT_DISAMBIG_CONST = 0x40,	///< (c).s for every constant c
	PRINT_WITH_ALIASES = 0x100,	///< for variables
	PRINT_FLAT = 0x200,		///< for assoc symbols
	PRINT_NUMBER = 0x400,		///< for nats & ints
	PRINT_RAT = 0x800,		///< for rats
};

/**
 * Maude term with its associated operations.
 */
class EasyTerm {
public:
	EasyTerm() = delete;
	~EasyTerm();

	// Keyword arguments are used when available for some of the
	// methods of this class to avoid writing unnecessary arguments

	%feature("kwargs") match;
	%feature("kwargs") get_variants;
	%feature("kwargs") search;
	%feature("kwargs") vu_narrow;

	// Information about the term

	/**
	 * Get the top symbol of this term.
	 */
	Symbol* symbol() const;

	/**
	 * Is this term ground?
	 */
	bool ground() const;

	/**
	 * Compare two terms for equality.
	 *
 	 * @param other The second term to be compared.
	 */
	bool equal(const EasyTerm* other) const;

	/**
	 * Check whether the sort of this term is a subtype of the given sort.
	 *
	 * @param sort The pretended supertype.
	 */
	bool leq(const Sort* sort) const;

	/**
	 * Get the sort of this term.
	 */
	Sort* getSort() const;

	// Maude operations following Maude commands

	/**
	 * Reduce this term.
	 *
	 * @return The total number of rewrites.
	 */
	int reduce();

	/**
	 * Rewrite a term following the semantics of the @c rewrite command.
	 *
	 * @param bound An upper bound on the number of rule rewrites.
	 *
	 * @return The total number of rewrites.
	 */
	int rewrite(int bound = -1);

	/**
	 * Rewrite a term following the semantics of the @c frewrite command.
	 *
	 * @param bound An upper bound on the number of rule rewrites.
	 * @param gas An upper bound on the number of rule rewrites per position.
	 *
	 * @return The total number of rewrites.
	 */
	int frewrite(int bound = -1, int gas = -1);

	/**
	 * Rewrite a term following the semantics of the @c erewrite command.
	 *
	 * @param bound An upper bound on the number of rule rewrites.
	 * @param gas An upper bound on the number of rule rewrites by position.
	 *
	 * @return The result and the total number of rewrites (the original
	 * term is not modified).
	 */
	std::pair<EasyTerm*, int> erewrite(int bound = -1, int gas = -1);

	/**
	 * Match this term into a given pattern.
	 *
	 * @param pattern Pattern term.
	 * @param condition Equational condition that solutions must satisfy.
	 * @param withExtension Whether the matching should be done with extension modulo axioms.
	 *
	 * @returns An object to iterate through matches.
	 */
	MatchSearchState* match(EasyTerm* pattern,
				const Vector<ConditionFragment*> &condition = NO_CONDITION,
				bool withExtension = false);

	/**
	 * Rewrite a term following a strategy.
	 *
	 * @param expr A strategy expression.
	 * @param depth Whether to perform a depth-first search. By default, a fair search is used.
	 *
	 * @return An object to iterate through strategy solutions.
	 */
	StrategicSearch* srewrite(StrategyExpression* expr, bool depth = false);

	/**
	 * Search states that match into a given pattern and satisfy a given
	 * condition by rewriting from this term.
	 *
	 * @param type Type of search (number of steps).
	 * @param target Patterm term.
	 * @param condition Condition that solutions must satisfy.
	 * @param depth Depth bound.
	 *
	 * @return An object to iterate through matches.
	 */
	RewriteSequenceSearch* search(SearchType type, EasyTerm* target,
				      const Vector<ConditionFragment*> &condition = NO_CONDITION,
				      int depth = -1);

	/**
	 * Compute the most general variants of this term.
	 *
	 * @param irredundant Whether to obtain irredundant variants
	 * (for theories with the finite variant property).
	 * @param irreducible Irreducible terms constraint.
	 *
 	 * @return An object to iterate through variants.
	 */
	VariantSearch* get_variants(bool irredundant = false,
	                            const std::vector<EasyTerm*> &irreducible = {});

	/**
	 * Narrowing-based search of terms that unify with the given target.
	 *
	 * @param type Type of the search (number of steps).
	 * @param target The pattern that has to be reached.
	 * @param depth Depth bound (@c -1 for unbounded).
	 * @param fold Whether to activate folding (@c fvu-narrow command).
	 *
	 * @return An object to iterate through solutions.
	 */
	NarrowingSequenceSearch3* vu_narrow(SearchType type, EasyTerm* target,
					    int depth = -1, bool fold = false);

	#if defined(USE_CVC4) || defined(USE_YICES2)
	/**
	 * Check an SMT formula.
	 *
	 * @return A string, either @c sat, @c unsat or @c undecided.
	 */
	const char* check();
	#endif

	/**
	 * Iterate over the arguments of this term.
	 */
	DagArgumentIterator* arguments();

	/**
	 * Get the floating-point number represented by the given term or
	 * zero otherwise.
	 */
	double toFloat() const;

	/**
	 * Get the integer number represented by the given term or
	 * zero otherwise.
	 */
	long int toInt() const;

	/**
	 * Get the hash value of the term.
	 */
	size_t hash() const;

	/**
	 * Get a copy of this term.
	 */
	EasyTerm* copy() const;

	/**
	 * An empty condition to be used as a placeholder.
	 */
	static const Vector<ConditionFragment*> NO_CONDITION;

	%extend {
		/**
		 * Pretty prints this term.
		 *
		 * @param flags Flags that affect the term output.
		 */
		const char* prettyPrint(PrintFlags flags) {
			std::ostringstream stream;
			$self->print(stream, flags);
			printBuffer = stream.str();
			return printBuffer.c_str();
		}
	}

	%newobject match;
	%newobject srewrite;
	%newobject search;
	%newobject arguments;
	%newobject copy;

	%streamBasedPrint;
};

//
//	Iterators for the operations that return more than one solution
//

/**
 * An iterator through the solutions of a strategy search.
 */
class StrategicSearch {
public:
	StrategicSearch() = delete;

	%extend {
		/**
		 * Get the number of rewrites until the solution has been found.
		 */
		int getRewriteCount() {
			return $self->getContext()->getTotalCount();
		}

		/**
		 * Get the next solution for the strategic search.
		 *
		 * @return That solution or null pointer if the end has
		 * been reached.
		 */
		EasyTerm* __next() {
			DagNode* d = $self->findNextSolution();
			return d == nullptr ? nullptr : new EasyTerm(d);
		}
	}

	%newobject __next;
};

/**
 * Substitution (mapping from variables to terms).
 */
class EasySubstitution {
public:
	EasySubstitution() = delete;

	/**
	 * Get the number of variables in the substitution.
	 */
	int size() const;

	/**
	 * Get the variable at the given index.
	 *
	 * @param index The index of the variable.
	 */
	EasyTerm* variable(int index) const;

	/**
	 * Get the value of the variable at the given index.
	 *
	 * @param index The index of the variable.
	 */
	EasyTerm* value(int index) const;

	/**
	 * Get the matched portion when matching with extension.
	 *
	 * @return The matched portion or null if the
	 * whole term matched.
	 */
	EasyTerm* matchedPortion() const;

	/**
	 * Find the value of a given variable by name.
	 *
	 * @param name Variable name (without sort).
	 * @param sort Sort of the variable (optional).
	 *
	 * @return The value of the variable or null if not found.
	 * If the sort of the variable is not given, multiple results
	 * are possible.
	 */
 	EasyTerm* find(const char* name, Sort* sort = nullptr) const;

	/**
	 * Instantiate a term with this substitution.
	 *
	 * @param term The term to be instantiated.
	 *
	 * @return The instantiated term.
	 */
	EasyTerm* instantiate(EasyTerm* term) const;

	%newobject variable;
	%newobject value;
	%newobject matchedPortion;
	%newobject find;
	%newobject instantiate;
};

/**
 * An iterator through the matching a term into a pattern.
 */
class MatchSearchState {
public:
	MatchSearchState() = delete;

	%extend {
		/**
		 * Get the next match.
		 *
		 * @return A matching substitution or null pointer if
		 * there is no more matches.
		 */
		EasySubstitution* __next() {
			bool nextMatch = $self->findNextMatch();
			return nextMatch ? new EasySubstitution($self->getContext(),
								$self->getPattern(),
								$self->getExtensionInfo())
					 : nullptr;
		}
	}

	%newobject __next;
};

/**
 * An iterator through the solutions of a search.
 */
class RewriteSequenceSearch {
public:
	StrategicSearch() = delete;

	%extend {
		/**
		 * Get the number of rewrites until this term has been found.
		 */
		int getRewriteCount() {
			return $self->getContext()->getTotalCount();
		}

		/**
		 * Get the substitution the matching substitution of the
		 * solution into the pattern.
		 */
		EasySubstitution* getSubstitution() {
			return new EasySubstitution($self->getSubstitution(),
						    $self->getGoal(),
						    nullptr);
		}

		/**
		 * Get the rule leading to the given state.
		 * 
		 * @param stateNr The number of a state in the search graph
		 * or -1 for the current one.
		 */
		Rule* getRule(int stateNr = -1) {
			return $self->getStateRule(stateNr == -1
				? $self->getStateNr() : stateNr);
		}

		/**
		 * Get the term of a given state.
		 * 
		 * @param stateNr The number of a state in the search graph.
		 */
		EasyTerm* getStateTerm(int stateNr) {
			return new EasyTerm($self->getStateDag(stateNr));
		}


		/**
		 * Get the next match.
		 *
		 * @return A term or a null pointer if there is no more matches.
		 */
		EasyTerm* __next() {
			bool hasNext = $self->findNextMatch();
			return hasNext ? new EasyTerm($self->getStateDag($self->getStateNr())) : nullptr;
		}
	}

	%newobject getSubstitution;
	%newobject getStateTerm;
	%newobject __next;

	/**
	 * Get an internal state number that allows reconstructing 
	 * the path to this term.
	 */
	int getStateNr() const;

	/**
	 * Get the parent state.
	 *
	 * @param stateNr The number of a state in the search graph.
	 *
	 * @return The number of the parent or -1 for the root.
	 */
	int getStateParent(int stateNr) const;
};

/**
 * An iterator through narrowing solutions.
 */
class NarrowingSequenceSearch3 {
public:
	NarrowingSequenceSearch3() = delete;

	/**
	 * Whether some solutions may have been missed due to incomplete unification algorithms.
	 */
	bool isIncomplete() const;

	%extend {
		/**
		 * Get the next solution of the narrowing search.
		 */
		EasyTerm* __next() {
			if (!$self->findNextUnifier())
				return nullptr;

			DagNode* stateDag;
			int variableFamily;
			Substitution* substitution;

			$self->getStateInfo(stateDag, variableFamily, substitution);
			return new EasyTerm(stateDag);
		}

		/**
		 * Get the accumulated substitution.
		 */
		EasySubstitution* getSubstitution() const {
			DagNode* stateDag;
			int variableFamily;
			Substitution* substitution;

			$self->getStateInfo(stateDag, variableFamily, substitution);
			return new EasySubstitution(substitution, &$self->getInitialVariableInfo(), false);
		}

		/**
		 * Get the variant unifier.
		 */
		EasySubstitution* getUnifier() const {
			const Vector<DagNode*>* unifier = $self->getUnifier();
			size_t nrVariables = unifier->size();

			Substitution* subs = new Substitution(nrVariables);

			for (size_t i = 0; i < nrVariables; i++)
				subs->bind(i, (*unifier)[i]);

			return new EasySubstitution(subs, &$self->getUnifierVariableInfo());
		}
	}

	%newobject __next;
	%newobject getSubstitution;
	%newobject getUnifier;
};

/**
 * An iterator through variants.
 */
class VariantSearch {
public:
	VariantSearch() = delete;

	/**
	 * Whether some variants may have been missed due to incomplete unification algorithms.
	 */
	bool isIncomplete() const;

	%extend {
		/**
		 * Get the next variant.
		 *
		 * @return The variant term or null if there is no more.
		 */
		std::pair<EasyTerm*, EasySubstitution*> * __next() {

			if (!$self->findNextVariant())
				return nullptr;

			int nrFreeVariables, variableFamily;
			const Vector<DagNode*>& variant = $self->getCurrentVariant(nrFreeVariables, variableFamily);

			int nrVariables = variant.size() - 1;

			DagNode* d = variant[nrVariables];

			// Create a substitution
			Substitution* subs = new Substitution(nrVariables);

			for (int i = 0; i < nrVariables; i++)
				subs->bind(i, variant[i]);

			return new std::pair<EasyTerm*, EasySubstitution*>(new EasyTerm(d),
			          new EasySubstitution(subs, &$self->getVariableInfo()));
		}
	};

	%newobject __next;
};

/**
 * An iterator through the arguments of a term.
 */
class DagArgumentIterator {
public:
	DagArgumentIterator() = delete;

	/**
	 * Is this iterator pointing to a valid argument?
	 */
	bool valid() const;

	%rename(__next) next;

	/**
	 * Advance the iterator to the next argument.
	 */
	void next();

	%extend {
		/**
		 * Get the argument pointed by this iterator.
		 */
		EasyTerm* argument() const {
			return new EasyTerm($self->argument());
		}
	}

	%newobject argument;
};
