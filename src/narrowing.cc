/**
 * @file narrowing.cc
 *
 * Wrap Maude stuff related to narrowing and unification.
 */
 
#include "narrowing.hh"

#include "variable.hh"
#include "variantSearch.hh"
#include "substitution.hh"

VariantUnifierSearch::VariantUnifierSearch(VariantSearch * search)
 : search(search)  {
}

bool
VariantUnifierSearch::isIncomplete() const {
	return search->isIncomplete();
}

EasySubstitution*
VariantUnifierSearch::__next() {
	int nrFreeVariables; int dummy;
	const Vector<DagNode*>* unifier = search->getNextUnifier(nrFreeVariables, dummy);

	if (unifier == nullptr)
		return nullptr;

	int nrVariables = unifier->size();

	// Create a substitution
	Substitution* subs = new Substitution(nrVariables);

	for (int i = 0; i < nrVariables; i++)
		subs->bind(i, (*unifier)[i]);

	return new EasySubstitution(subs, &search->getVariableInfo());
}
