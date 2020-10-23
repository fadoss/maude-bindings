/**
 * @file narrowing.cc
 *
 * Wrap Maude stuff related to narrowing and unification.
 */
 
#include "narrowing.hh"

#include "variable.hh"
#include "variantSearch.hh"
#include "substitution.hh"
#include "filteredVariantUnifierSearch.cc"

VariantUnifierSearch::VariantUnifierSearch(VariantSearch * search, Command cmd)
 : search(search), command(cmd)  {
}

bool
VariantUnifierSearch::isIncomplete() const {
	return search->isIncomplete();
}

bool
VariantUnifierSearch::filteringIncomplete() const {
	if (command == FILTERED_UNIFY) {
		auto fstate = dynamic_cast<FilteredVariantUnifierSearch*>(search);
		return fstate->filteringIncomplete();
	}

	return false;
}

EasySubstitution*
VariantUnifierSearch::__next() {
	VariantMatchingProblem* problem;
	bool moreResults;

	// The results of both the matching and the unification problem is a
	// substitution, which can be handled uniformly but they are obtained
	// differently

	if (command == MATCH) {
		problem = search->getLastVariantMatchingProblem();
		moreResults = problem->findNextMatcher();
	}
	else {
		moreResults = search->findNextUnifier();
	}

	if (!moreResults)
		return nullptr;

	int nrFreeVariables; int dummy;
	const Vector<DagNode*> &unifier = command == MATCH ? problem->getCurrentMatcher()
							   : search->getCurrentUnifier(nrFreeVariables, dummy);

	int nrVariables = unifier.size();

	// Create a substitution
	Substitution* subs = new Substitution(nrVariables);

	for (int i = 0; i < nrVariables; i++)
		subs->bind(i, unifier[i]);

	return new EasySubstitution(subs, &search->getVariableInfo());
}
