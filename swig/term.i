//
//	Interface to Maude terms and operations
//

%{
#include "strategicSearch.hh"
#include "rewriteSequenceSearch.hh"
#include "strategySequenceSearch.hh"
#include "variantSearch.hh"
#include "pattern.hh"
#include "dagArgumentIterator.hh"
#include "narrowingSequenceSearch3.hh"
#include "rewriteSearchState.hh"
#include "variableDagNode.hh"
%}

%import "config.h"

//
//	Simplified interface to Maude terms
//	(defined and documented in easyTerm.cc/hh)
//

%rename (Term) EasyTerm;
%rename (Substitution) EasySubstitution;
%rename (ArgumentIterator) EasyArgumentIterator;
%rename (NarrowingSequenceSearch) NarrowingSequenceSearch3;


/**
 * Search types (number of steps).
 */
enum SearchType {
	ONE_STEP,		///< ->1
	AT_LEAST_ONE_STEP,	///< ->+
	ANY_STEPS,		///< ->*
	NORMAL_FORM,		///< ->!
        BRANCH			///< ->#
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
 * NarrowingFlags
 */
enum NarrowingFlags {
	/// Whether to activate folding (@c fold option or @c fvu-narrow command).
	FOLD = NarrowingSequenceSearch3::FOLD,
	/// Whether to activate variant folding (@c vfold option).
	VFOLD = NarrowingSequenceSearch3::VFOLD,
	/// Whether to allow for narrowing trace reconstruction (expensive).
	PATH = NarrowingSequenceSearch3::KEEP_PATHS,
	/// Whether variant unifiers are filtered before using the first one for narrowing (@c delay option in the command).
	DELAY = VariantSearch::IRREDUNDANT_MODE,
	/// Whether to activate filtered variant unification (@c filter option in the command).
	FILTER = VariantUnificationProblem::FILTER_VARIANT_UNIFIERS,
};

/**
 * Maude term with its associated operations.
 */
class EasyTerm {
public:
	EasyTerm() = delete;
	~EasyTerm();

	%newobject apply;
	%newobject match;
	%newobject srewrite;
	%newobject search;
	%newobject arguments;
	%newobject copy;

	// Keyword arguments are used when available for some of the
	// methods of this class to avoid writing unnecessary arguments

	%feature("kwargs") match;
	%feature("kwargs") get_variants;
	%feature("kwargs") vu_narrow;
	%feature("kwargs") apply;

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
	 * Normalize this term modulo axioms.
	 *
	 * @param full Whether to normalize in depth.
	 */
	void normalize(bool full = true);

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
	 * @param withExtension Whether the matching should be done with extension modulo axioms
	 * (deprecated, use @c maxDepth=0 instead).
	 * @param minDepth Minimum matching depth.
	 * @param maxDepth Maximum matching depth (@c -1 to match on top without extension, @c 0
	 * to match on top with extension, @c UNBOUNDED to match anywhere, or any intermediate value).
	 *
	 * @returns An object to iterate through matches.
	 */
	MatchSearchState* match(EasyTerm* pattern,
				const Vector<ConditionFragment*> &condition = NO_CONDITION,
				bool withExtension = false,
				int minDepth = 0,
				int maxDepth = -1);

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
	 * Search states that match into a given pattern and satisfy a given
	 * condition by rewriting from this term using a strategy.
	 *
	 * @param type Type of search (number of steps).
	 * @param target Patterm term.
	 * @param strategy Strategy to control the search.
	 * @param condition Condition that solutions must satisfy.
	 * @param depth Depth bound.
	 *
	 * @return An object to iterate through matches.
	 */
	StrategySequenceSearch* search(SearchType type, EasyTerm* target, StrategyExpression* strategy,
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
	 * @param flags Narrowing search flags (@c fold, @c vfold, @c path, @c delay, or @c filter flag).
	 *
	 * @return An object to iterate through solutions.
	 */
	NarrowingSequenceSearch3* vu_narrow(SearchType type, EasyTerm* target,
					    int depth = -1, NarrowingFlags flags = 0);

	/**
	 * Apply any rule with the given label.
	 *
	 * @param label Rule label (or null for any executable rule).
	 * @param substitution Initial substitution that will be applied on the rule before matching.
	 * @param minDepth Minimum matching depth.
	 * @param maxDepth Maximum matching depth.
	 *
	 * @return An object to iterate through the rewritten terms.
	 */
	RewriteSearchState* apply(const char* label, EasySubstitution* substitution = nullptr,
	                          int minDepth = 0, int maxDepth = UNBOUNDED);

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
	 *
	 * @param normalize Whether to normalize before iterating over its arguments.
	 */
	EasyArgumentIterator* arguments(bool normalize = true);

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
	 * Get whether the term is a variable.
	 */
	bool isVariable() const;

	/**
	 * Get the name of the variable if the current term is a variable or
	 * a null value otherwise.
	 */
	const char* getVarName() const;

	/**
	 * Get the exponent of an iterable symbol or zero otherwise.
	 */
	unsigned long int getIterExponent() const;

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
		std::string prettyPrint(PrintFlags flags) {
			std::ostringstream stream;
			$self->print(stream, flags);
			return stream.str();
		}
	}

	/**
	 * Obtain the LaTeX representation of this term.
	 */
	std::string toLatex();

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

	%newobject __next;

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

	%unprotectDestructor(StrategicSearch);
};

/**
 * Substitution (mapping from variables to terms).
 */
class EasySubstitution {
public:
	EasySubstitution() = delete;

	%newobject value;
	%newobject matchedPortion;
	%newobject find;
	%newobject instantiate;
	%newobject iterator;

	/**
	 * Create a substitution with the given variables and values.
	 *
	 * @param vars Variables in the substitution.
	 * @param values values Values for these variables in the substitution.
	 */
	EasySubstitution(const std::vector<EasyTerm*> &vars,
	                 const std::vector<EasyTerm*> &values);

	/**
	 * Get the number of variables in the substitution.
	 */
	int size() const;

	/**
	 * Get the value of a given variable.
	 *
	 * @param variable The variable whose value is looked up.
	 */
	EasyTerm* value(EasyTerm* variable) const;

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

	class Iterator {
	public:
		Iterator() = delete;

		%newobject getVariable;
		%newobject getValue;

		void nextAssignment();

		EasyTerm* getVariable() const;
		EasyTerm* getValue() const;
	};

	%extend {
		/**
		 * Get an iterator to the substitution assignments.
		 */
		Iterator* iterator() const {
			return new EasySubstitution::Iterator($self);
		}
	}

};

/**
 * An iterator through the matching a term into a pattern.
 */
class MatchSearchState {
public:
	MatchSearchState() = delete;

	%newobject __next;

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

		/**
		 * Get the context of the match filled with the given term.
		 *
		 * @param term Term to fill the context.
		 *
		 * @return The original term with the matched subterm replaced by the given term.
		 */
		EasyTerm* fillContext(EasyTerm* term) const {
			return new EasyTerm($self->rebuildDag(term->getDag()).first);
		}
	}

	%unprotectDestructor(MatchSearchState);
};

/**
 * An iterator through the solutions of a search.
 */
class RewriteSequenceSearch {
public:
	StrategicSearch() = delete;

	%newobject getSubstitution;
	%newobject getStateTerm;
	%newobject __next;

	%extend {
		/**
		 * Get the number of rewrites until this term has been found.
		 */
		int getRewriteCount() {
			return $self->getContext()->getTotalCount();
		}

		/**
		 * Get the matching substitution of the solution into the pattern.
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

	%unprotectDestructor(RewriteSequenceSearch);
};

/**
 * An iterator through the solutions of a strategy-controlled search.
 */
class StrategySequenceSearch {
public:
	StrategicSearch() = delete;

	%newobject getSubstitution;
	%newobject getStateTerm;
	%newobject __next;

	%extend {
		/**
		 * Get the number of rewrites until this term has been found.
		 */
		int getRewriteCount() {
			return $self->getContext()->getTotalCount();
		}

		/**
		 * Get the matching substitution of the solution into the pattern.
		 */
		EasySubstitution* getSubstitution() {
			return new EasySubstitution($self->getSubstitution(),
						    $self->getGoal(),
						    nullptr);
		}

		/**
		 * Get the transition leading to the given state.
		 * 
		 * @param stateNr The number of a state in the search graph
		 * or -1 for the current one.
		 *
		 * @return The transition between the parent of the given state and the
		 * state itself.
		 */
		const StrategyTransitionGraph::Transition& getTransition(int stateNr = -1) {
			return $self->getStateTransition(stateNr == -1
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
		 * Get the next strategy to be executed from the given state.
		 *
		 * @param stateNr The number of a state in the search graph
		 * or -1 for the current one.
		 */
		StrategyExpression* getStrategyContinuation(int stateNr = -1) {
			return $self->getStrategyContinuation(stateNr == -1
					? $self->getStateNr() : stateNr);
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

	%unprotectDestructor(StrategySequenceSearch);
};

/**
 * An iterator through narrowing solutions.
 */
class NarrowingSequenceSearch3 {
public:
	NarrowingSequenceSearch3() = delete;

	%newobject __next;
	%newobject getSubstitution;
	%newobject getUnifier;

	/**
	 * Whether some solutions may have been missed due to incomplete unification algorithms.
	 */
	bool isIncomplete() const;

	/**
	 * Get the parent state.
	 *
	 * @param stateNr The number of state in the search graph.
	 *
	 * @return The number of the parent or -1 for the root.
	 */
	int getStateParent(int stateNr);

	%extend {
		/**
		 * Get the next solution of the narrowing search.
		 */
		EasyTerm* __next() {
			if (!$self->findNextUnifier())
				return nullptr;

			DagNode *stateDag, *dummy;
			int variableFamily;
			Substitution* substitution;

			$self->getStateInfo(stateDag, variableFamily, dummy, substitution);
			return new EasyTerm(stateDag);
		}

		/**
		 * Get the accumulated substitution.
		 */
		EasySubstitution* getSubstitution() const {
			DagNode *stateDag, *dummy;
			int variableFamily;
			Substitution* substitution;

			$self->getStateInfo(stateDag, variableFamily, dummy, substitution);
			return new EasySubstitution(substitution, &$self->getInitialVariableInfo());
		}

		/**
		 * Get the variant unifier.
		 */
		EasySubstitution* getUnifier() const {
			const Vector<DagNode*>* unifier = $self->getUnifier();
			size_t nrVariables = unifier->size();

			Substitution subs(nrVariables);

			for (size_t i = 0; i < nrVariables; i++)
				subs.bind(i, (*unifier)[i]);

			return new EasySubstitution(&subs, &$self->getUnifierVariableInfo());
		}

		/**
		 * Get the frontier states.
		 */
		std::vector<EasyTerm*> getFrontierStates() {
			std::vector<EasyTerm*> frontier;

			bool partiallyExpanded; // this information is not returned

			for (DagNode* d : $self->getUnexpandedStates(partiallyExpanded))
				frontier.push_back(new EasyTerm(d));

			for (DagNode* d : $self->getUnvisitedStates())
				frontier.push_back(new EasyTerm(d));

			return frontier;
		}

		/**
		 * Get the most general states.
		 */
		std::vector<EasyTerm*> getMostGeneralStates() const {
			std::vector<EasyTerm*> states;

			for (DagNode* d : $self->getMostGeneralStates())
				states.push_back(new EasyTerm(d));

			return states;
		}
	}

	%unprotectDestructor(NarrowingSequenceSearch3);
};

/**
 * An iterator through variants.
 */
class VariantSearch {
public:
	VariantSearch() = delete;

	%newobject __next;

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
			Substitution subs(nrVariables);

			for (int i = 0; i < nrVariables; i++)
				subs.bind(i, variant[i]);

			return new std::pair<EasyTerm*, EasySubstitution*>(new EasyTerm(d),
			          new EasySubstitution(&subs, &$self->getVariableInfo()));
		}
	};

	%unprotectDestructor(VariantSearch);
};

/**
 * An iterator through rewriting solutions.
 */
class RewriteSearchState {
public:
	RewriteSearchState() = delete;

	%newobject __next;
	%newobject getSubstitution;
	%newobject fillContext;

	/**
	 * Get the applied rule.
	 */
	Rule* getRule() const;

	%extend {
		/**
		 * Get the next solution of the rewriting search.
		 */
		EasyTerm* __next() {
			if (!$self->findNextRewrite())
				return nullptr;

			return new EasyTerm($self->rebuildDag($self->getReplacement()).first);
		}

		/**
		 * Get the matching substitution.
		 */
		EasySubstitution* getSubstitution() const {
			return new EasySubstitution($self->getContext(), $self->getRule());
		}

		/**
		 * Get the context of the match filled with the given term.
		 *
		 * @param term Term to fill the context.
		 *
		 * @return The original term with the matched subterm replaced by the given term.
		 */
		EasyTerm* fillContext(EasyTerm* term) const {
			return new EasyTerm($self->rebuildDag(term->getDag()).first);
		}
	};

	%unprotectDestructor(RewriteSearchState);
};

/**
 * An iterator through the arguments of a term.
 */
class EasyArgumentIterator {
public:
	EasyArgumentIterator() = delete;

	%newobject argument;
	%rename(__next) next;

	/**
	 * Is this iterator pointing to a valid argument?
	 */
	bool valid() const;

	/**
	 * Advance the iterator to the next argument.
	 */
	void next();

	/**
	 * Get the argument pointed by this iterator.
	 */
	EasyTerm* argument() const;
};
