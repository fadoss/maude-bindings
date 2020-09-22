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

EasyTerm*
HookData::getTerm(const char* name) const {
	auto it = terms.find(name);
	return it != terms.end() ? new EasyTerm(it->second.getDag()) : nullptr;
}

DagNode*
hookDispacher(DagNode* dag,
              const vector<string>& data,
              const SpecialHubSymbol::SymbolHooks& symbols,
              SpecialHubSymbol::TermHooks& terms,
              void* rawHook) {

	EasyTerm tmp(dag);
	HookData hdata(data, symbols, terms);

	Hook* hook = reinterpret_cast<Hook*>(rawHook);

	EasyTerm* result = hook->run(&tmp, &hdata);

	return result == nullptr ? nullptr : result->getDag();
}

bool
connectEqHook(const char* name, Hook* callback) {
	if (callback != nullptr)
		return SpecialHubSymbol::connectReduce(name, &hookDispacher, callback);
	else
		return SpecialHubSymbol::connectReduce(name, nullptr, nullptr);
}

bool
connectRlHook(const char* name, Hook* callback) {
	if (callback != nullptr)
		return SpecialHubSymbol::connectRewrite(name, &hookDispacher, callback);
	else
		return SpecialHubSymbol::connectRewrite(name, nullptr, nullptr);
}
