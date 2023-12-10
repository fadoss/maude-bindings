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
#include "choiceStrategy.hh"
#include "sampleStrategy.hh"

Module* getModule(const StrategyExpression* expr) {

	if (dynamic_cast<const TrivialStrategy*>(expr) != nullptr)
		return nullptr;

	else if (const TestStrategy* t = dynamic_cast<const TestStrategy*>(expr))
		return t->getPatternTerm()->symbol()->getModule();

	else if (const SubtermStrategy* s = dynamic_cast<const SubtermStrategy*>(expr))
		return s->getPatternTerm()->symbol()->getModule();

	else if (const CallStrategy* c = dynamic_cast<const CallStrategy*>(expr))
		return c->getStrategy()->getModule();

	else if (const ApplicationStrategy* a = dynamic_cast<const ApplicationStrategy*>(expr)) {
		if (!a->getVariables().empty())
			return a->getVariables()[0]->symbol()->getModule();

		Module* md = nullptr;

		for (StrategyExpression* e : a->getStrategies())
			if ((md = getModule(e)) != nullptr)
				break;
		return md;
	}
	else if (const OneStrategy* o = dynamic_cast<const OneStrategy*>(expr))
		return getModule(o->getStrategy());

	else if (const ConcatenationStrategy* c = dynamic_cast<const ConcatenationStrategy*>(expr)) {
		Module* md = nullptr;

		for (StrategyExpression* e : c->getStrategies())
			if ((md = getModule(e)) != nullptr)
				break;
		return md;
	}
	else if (const UnionStrategy* u = dynamic_cast<const UnionStrategy*>(expr)) {
		Module* md = nullptr;

		for (StrategyExpression* e : u->getStrategies())
			if ((md = getModule(e)) != nullptr)
				break;
		return md;
	}
	else if (const IterationStrategy* i = dynamic_cast<const IterationStrategy*>(expr))
		return getModule(i->getStrategy());

	else if (const BranchStrategy* b = dynamic_cast<const BranchStrategy*>(expr)) {
		Module* md = nullptr;

		if (b->getInitialStrategy() != nullptr)
			md = getModule(b->getInitialStrategy());
		if (md == nullptr && b->getSuccessStrategy() != nullptr)
			md = getModule(b->getSuccessStrategy());
		if (md == nullptr && b->getFailureStrategy() != nullptr)
			md = getModule(b->getFailureStrategy());

		return md;
	}
#if WITH_PROBABILISTIC_SLANG
	else if (const ChoiceStrategy* c = dynamic_cast<const ChoiceStrategy*>(expr))
		return c->getWeights()[0].getTerm()->symbol()->getModule();

	else if (const SampleStrategy* s = dynamic_cast<const SampleStrategy*>(expr))
		return s->getVariable()->symbol()->getModule();
#endif

    	// Should not happen
	return nullptr;
}
