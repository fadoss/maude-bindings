/**
 * @file easyTerm.hh
 *
 * Simplified interface to the Maude terms.
 */

#ifndef EASY_TERM_H
#define EASY_TERM_H

#include <climits>

#include "macros.hh"
#include "interface.hh"
#include "core.hh"
#include "strategyLanguage.hh"
#include "higher.hh"
#include "mixfix.hh"
#include "rootContainer.hh"
#include "vector.hh"
#include "interpreter.hh"

#include <iostream>
#include <vector>

/**
 * Search types (number of steps).
 */
enum SearchType {
	ONE_STEP,		///< ->1
	AT_LEAST_ONE_STEP,	///< ->+
	ANY_STEPS,		///< ->*
	NORMAL_FORM		///< ->!
};

/**
 * Maude term with its associated operations.
 */
class EasyTerm : public RootContainer {
public:
	/**
	 * Create a simplified term from an internal tree representation.
	 *
	 * @param term The internal term representation.
	 * @param owned Whether the internal representation is owned and should be deleted by this class.
	 */
	EasyTerm(Term* term, bool owned = true);

	/**
	 * Creates a simplified term from an internal DAG representation.
	 *
	 * @param dagNode The internal term representation.
	 */
	EasyTerm(DagNode* dagNode);

	~EasyTerm();

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
	 * Rewrite a term following a strategy.
	 *
	 * @param expr A strategy expression.
	 * @param depth Whether to perform a depth-first search. By default, a fair search is used.
	 *
	 * @return An object to iterate among strategy solution.
	 */
	StrategicSearch* srewrite(StrategyExpression* expr,
				  bool depth = false);

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
	 * @param target Term that found states must unify with.
	 * @param depth Depth bound (@c -1 for unbounded)
	 * @param fold Whether to activate folding (@c fvu-narrow command).
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
	 * Pretty prints this term.
	 *
	 * @param out The stream where to print.
	 */
	void print(std::ostream &out) const;

	/**
	 * Pretty prints this term.
	 *
	 * @param out The stream where to print.
	 * @param flags Flags that affect the term output.
	 */
	void print(std::ostream &out, Interpreter::PrintFlags flags) const;

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
	 * Get a copy of the internal term.
	 */
	Term* termCopy() const;

	/**
	 * Get the internal DAG node.
	 */
	DagNode* getDag();

	/*
	 * Set the internal DAG node.
	 */
	void setDag(DagNode* node);

	/**
	 * An empty condition to be used as a placeholder.
	 */
	static const Vector<ConditionFragment*> NO_CONDITION;

	void markReachableNodes();

	static void startUsingModule(VisibleModule* vmod);

private:
	void dagify();
	void termify();

	bool is_dag;
	bool is_own;
	union {
		DagNode* dagNode;
		Term* term;
	};
};

/**
 * Substitution (mapping from variables to terms).
 */
class EasySubstitution {
public:
	EasySubstitution(const Substitution* subs,
			 const VariableInfo* vinfo,
			 const ExtensionInfo* extension = nullptr);

	EasySubstitution(const Substitution* subs,
			 const NarrowingVariableInfo* vinfo,
			 bool ownsSubstitution = true);


	~EasySubstitution();

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
	 * Get the value at the given index.
	 *
	 * @param index The index of the value.
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

private:
	const Substitution* subs;
	union {
		const VariableInfo* vinfo;
		const NarrowingVariableInfo* nvinfo;
	};
	const ExtensionInfo* extension;

	enum Flags {
		OWNS_SUBSTITUTION = 0x1,
		NARROWING = 0x2
	};
	int flags;
};

inline
ostream& operator<<(ostream& s, const EasyTerm* term) {
	term->print(s);
	return s;
}

/**
 * Get a module object from its metarepresentation in this
 * module, which must include the @c META-LEVEL module.
 *
 * @param term The metarepresentation of a module, that is,
 * a valid element of the @c Module sort in @c META-MODULE.
 * The term will be reduced.
 *
 * @return The module object or null if the given term was not
 * a valid module metarepresentation.
 */
VisibleModule* downModule(EasyTerm* term);

#endif // EASY_TERM_H
