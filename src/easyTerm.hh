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

#include <iostream>

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
	 * Get the top symbol of the term.
	 */
	Symbol* symbol() const;

	/**
	 * Is the term ground?
	 *
	 * @note This function is not accurate (false negatives).
	 */
	bool ground() const;

	/**
	 * Compare two terms for equality.
	 *
 	 * @param other The second term to be compared.
	 */
	bool equal(const EasyTerm* other) const;

	/**
	 * Check whether the sort of the term is a subtype of the given sort.
	 *
	 * @param sort The pretended supertype.
	 */
	bool leq(const Sort* sort) const;

	/**
	 * Get the sort of the term.
	 */
	Sort* getSort() const;

	/**
	 * Reduce this term.
	 *
	 * @return The total number of rewrites.
	 */
	int reduce();

	/**
	 * Rewrite a term following the semantics of the @c srewrite command.
	 *
	 * @param bound A bound to the number of rule rewrites.
	 *
	 * @return The total number of rewrites.
	 */
	int rewrite(int bound = -1);

	/**
	 * Rewrite a term following the semantics of the @c frewrite command.
	 *
	 * @param bound A bound to the number of rule rewrites.
	 * @param gas A bound to the number of rule rewrites per position.
	 *
	 * @return The total number of rewrites.
	 */
	int frewrite(int limit = -1, int gas = -1);

	/**
	 * Rewrite a term following the semantics of the @c erewrite command.
	 *
	 * @param bound A bound to the number of rule rewrites.
	 * @param gas A bound to the number of rule rewrites by position.
	 *
	 * @return The result of the rewriting and the total number of rewrites.
	 * The original term is not modified.
	 */
	std::pair<EasyTerm*, int> erewrite(int limit = -1, int gas = -1);

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
	 * @param pattern Pattern term where to match this term.
	 * @param condition Equational condition to be checked.
	 * @param withExtension Whether the matching should be done with extension modulo axioms.
	 *
	 * @returns An object to iterate among matchings.
	 */
	MatchSearchState* match(EasyTerm* pattern,
			        const Vector<ConditionFragment*> &condition = NO_CONDITION,
				bool withExtension = false);

	/**
	 * Search states matching in target and satisfying condition by rewriting from this term.
	 *
	 * @param type Type of search (number of steps).
	 * @param target Term that found states must match.
	 * @param cond Condition that found states must satisfy.
	 * @param limit Limit to the number of solution.
	 * @param depth Depth bound.
	 */
	RewriteSequenceSearch* search(SearchType type, EasyTerm* target,
				      const Vector<ConditionFragment*> &condition = NO_CONDITION,
				      int depth = -1);

	/**
	 * Iterates through the arguments of this term.
	 */
	DagArgumentIterator* arguments();

	/**
	 * Pretty prints the term.
	 *
	 * @param out The stream where to print.
	 */
	void print(std::ostream &out) const;

	/**
	 * Get a copy of the term
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

	/**
	 * An empty condition to be used as a placeholder.
	 */
	static const Vector<ConditionFragment*> NO_CONDITION;

	void markReachableNodes();

private:
	void dagify();
	void termify();
	void startUsingModule(VisibleModule* module);

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
	EasySubstitution(const Substitution* subs, const VariableInfo* vinfo,
			 const ExtensionInfo* extension = nullptr);

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

private:
	const Substitution* subs;
	const VariableInfo* vinfo;
	const ExtensionInfo* extension;
};

inline
ostream& operator<<(ostream& s, const EasyTerm* term) {
	term->print(s);
	return s;
}

#endif // EASY_TERM_H
