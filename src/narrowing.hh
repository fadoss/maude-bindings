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

class VariantUnifierSearch {
public:
	VariantUnifierSearch(VariantSearch* search);

	/**
	 * Whether some unifiers may have been missed due to incomplete unification algorithms.
	 */
	bool isIncomplete() const;

	/**
	 * Get the next unifier.
	 *
	 * @return The next unifier or null if there is no more.
	 */
	EasySubstitution* __next();
private:
	VariantSearch* search;
};

#endif // NARROWING_H
