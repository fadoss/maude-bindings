/**
 * @file hooks.cc
 *
 * Allows defining special operators in the target language.
 */

#include "macros.hh"
#include "core.hh"
#include "interface.hh"
#include "mixfix.hh"
#include "higher.hh"
#include "strategyLanguage.hh"

#include "vector.hh"
#include "specialHubSymbol.hh"

#include "maude_wrappers.hh"
#include "easyTerm.hh"

#include "trivialStrategy.hh"
#include "oneStrategy.hh"
#include "applicationStrategy.hh"
#include "concatenationStrategy.hh"
#include "unionStrategy.hh"
#include "iterationStrategy.hh"
#include "branchStrategy.hh"
#include "testStrategy.hh"
#include "subtermStrategy.hh"
#include "callStrategy.hh"

Module* getModule(StrategyExpression* expr) {

	if (dynamic_cast<TrivialStrategy*>(expr) != nullptr)
		return nullptr;

	else if (TestStrategy* t = dynamic_cast<TestStrategy*>(expr))
		return t->getPatternTerm()->symbol()->getModule();

	else if (SubtermStrategy* s = dynamic_cast<SubtermStrategy*>(expr))
		return s->getPatternTerm()->symbol()->getModule();

	else if (CallStrategy* c = dynamic_cast<CallStrategy*>(expr))
		return c->getStrategy()->getModule();

	else if (ApplicationStrategy* a = dynamic_cast<ApplicationStrategy*>(expr)) {
		if (!a->getVariables().empty())
			return a->getVariables()[0]->symbol()->getModule();

		Module* md = nullptr;

		for (StrategyExpression* e : a->getStrategies())
			if ((md = getModule(e)) != nullptr)
				break;
		return md;
	}
	else if (OneStrategy* o = dynamic_cast<OneStrategy*>(expr))
		return getModule(o->getStrategy());

	else if (ConcatenationStrategy* c = dynamic_cast<ConcatenationStrategy*>(expr)) {
		Module* md = nullptr;

		for (StrategyExpression* e : c->getStrategies())
			if ((md = getModule(e)) != nullptr)
				break;
		return md;
	}
	else if (UnionStrategy* u = dynamic_cast<UnionStrategy*>(expr)) {
		Module* md = nullptr;

		for (StrategyExpression* e : u->getStrategies())
			if ((md = getModule(e)) != nullptr)
				break;
		return md;
	}
	else if (IterationStrategy* i = dynamic_cast<IterationStrategy*>(expr))
		return getModule(i->getStrategy());

	else if (BranchStrategy* b = dynamic_cast<BranchStrategy*>(expr)) {
		if (b->getInitialStrategy() != nullptr)
			return getModule(b->getInitialStrategy());
		if (b->getSuccessStrategy() != nullptr)
			return getModule(b->getSuccessStrategy());
		if (b->getFailureStrategy() != nullptr)
			return getModule(b->getFailureStrategy());
	}

    	// Should not happen
	return nullptr;
}
