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
#include "visibleModule.hh"
#include "unificationProblem.hh"

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
	Substitution subs(nrVariables);

	for (int i = 0; i < nrVariables; i++)
		subs.bind(i, unifier[i]);

	return new EasySubstitution(&subs, &search->getVariableInfo());
}

RewritingContext*
VariantUnifierSearch::getContext() const {
	return search->getContext();
}

// Dirty hacks to access some private members
// (not to modify Maude for the moment)

template<typename Tag, typename Tag::type M>
struct PrivateHack {
	friend typename Tag::type get(Tag) {
		return M;
	}
};

struct HackUnificationProblem {
	typedef Vector<Term*> UnificationProblem::* type;
	friend type get(HackUnificationProblem);
};

template struct PrivateHack<HackUnificationProblem, &UnificationProblem::leftHandSides>;

VisibleModule*
getModule(UnificationProblem* problem) {
	const auto &leftHandSides = problem->*get(HackUnificationProblem());

	if (leftHandSides.empty())
		return nullptr;

	return dynamic_cast<VisibleModule*>(leftHandSides[0]->symbol()->getModule());
}
