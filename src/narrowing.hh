/**
 * @file narrowing.hh
 *
 * Wrap Maude stuff related to narrowing and unification.
 */
 
#ifndef NARROWING_H
#define NARROWING_H

#include "macros.hh"
#include "higher.hh"

#include "easyTerm.hh"

/**
 * Search iterator for multiple problems using variants.
 */
class VariantUnifierSearch {
public:
	/**
	 * Command that generated this search problem.
	 */
	enum Command {
		UNIFY,
		FILTERED_UNIFY,
		MATCH
	};

	VariantUnifierSearch(VariantSearch* search, Command cmd);

	/**
	 * Whether some unifiers may have been missed due to incomplete unification algorithms.
	 */
	bool isIncomplete() const;

	/**
	 * Whether filetering was incomplete due to incomplete unification algorithms.
	 */
	bool filteringIncomplete() const;

	/**
	 * Get the next unifier.
	 *
	 * @return The next unifier or null if there is no more.
	 */
	EasySubstitution* __next();

	/**
	 * Rewriting context of the search.
	 */
	RewritingContext* getContext() const;
private:
	VariantSearch* search;
	Command command;
};

/**
 * Get the module of a unification problem.
 */
VisibleModule* getModule(UnificationProblem* problem);

#endif // NARROWING_H
