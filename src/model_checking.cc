/**
 * @file model_checking.cc
 *
 * Wraps model-checking functions.
 */

#include "macros.hh"
#include "core.hh"
#include "interface.hh"
#include "mixfix.hh"
#include "higher.hh"
#include "strategyLanguage.hh"
#include "temporal.hh"

#include "vector.hh"
#include "stateTransitionGraph.hh"
#include "strategyTransitionGraph.hh"
#include "visibleModule.hh"
#include "modelChecker2.hh"
#include "logicFormula.hh"
#include "temporalSymbol.hh"

#include "maude_wrappers.hh"

//
// TemporalSymbol is subclassed to give access to its protected methods
// negate and build which are neccesary to process formulae.
//
class FormulaeBuilder : public TemporalSymbol {
public:
	FormulaeBuilder() : TemporalSymbol(0, 0) {}

	bool loadSymbols(VisibleModule* mod, ConnectedComponent* stateKind);

	using TemporalSymbol::negate;
	using TemporalSymbol::build;
};

bool
FormulaeBuilder::loadSymbols(VisibleModule* vmod, ConnectedComponent* stateKind) {
	Vector<ConnectedComponent*> domain(2);

	// Finds any of the modelCheck symbols to import its attachments

	Sort* modelCheckSort = vmod->findSort(Token::encode("ModelCheckResult"));
	Sort* ltlSort = vmod->findSort(Token::encode("Formula"));

	// First, we try to find them by name and domain
	if (modelCheckSort != nullptr && ltlSort != nullptr) {

		ConnectedComponent* ltlKind = ltlSort->component();

		// Tries the original model checker first

		domain[0] = stateKind;
		domain[1] = ltlKind;

		Symbol* modelCheckSymb = vmod->findSymbol(Token::encode("modelCheck"),
							 domain, modelCheckSort->component());

		if (modelCheckSymb != nullptr) {
			copyAttachments(modelCheckSymb, nullptr);
			return true;
		}

		// Otherwise, tries the strategy-aware model checker

		domain.expandBy(3);

		Sort* qidSort = vmod->findSort(Token::encode("Qid"));
		Sort* boolSort = vmod->findSort(Token::encode("Bool"));

		domain[2] = qidSort->component();
		domain[3] = qidSort->component();
		domain[4] = boolSort->component();

		modelCheckSymb = vmod->findSymbol(Token::encode("modelCheck"),
						 domain, modelCheckSort->component());

		if (modelCheckSymb != nullptr) {
			copyAttachments(modelCheckSymb, nullptr);
			return true;
		}
	}

	// As a second chance, we try to find the symbol by dynamic-casting all
	// of them in the module (in case modelCheck has been renamed)

	const Vector<Symbol*> &symbols = vmod->getSymbols();
	int symbolIndex = vmod->getNrUserSymbols() - 1;

	TemporalSymbol* modelCheckSymb = nullptr;

	while (modelCheckSymb == nullptr && symbolIndex >= 0)
		modelCheckSymb = dynamic_cast<TemporalSymbol*>(symbols[symbolIndex--]);

	if (modelCheckSymb != nullptr) {
		copyAttachments(modelCheckSymb, nullptr);
		return true;
	}

	return false;
}

//
// System automaton structures exhibited to the model-checker.
// They are copies of those in modelCheckSymbol.hh and
// strategyModelCheckSymbol.hh
//

struct BaseSystemAutomaton : public ModelChecker2::System
{
	DagNodeSet propositions;
	Symbol* satisfiesSymbol;
	RewritingContext* parentContext;
	DagRoot trueTerm;

	inline bool checkProposition(DagNode* stateDag, int propositionIndex) const;
};

inline bool
BaseSystemAutomaton::checkProposition(DagNode* stateDag, int propositionIndex) const { 
	Vector<DagNode*> args(2);
	args[0] = stateDag;
	args[1] = propositions.index2DagNode(propositionIndex);
	RewritingContext* testContext =
	parentContext->makeSubcontext(satisfiesSymbol->makeDagNode(args));
	testContext->reduce();
	bool result = trueTerm.getNode()->equal(testContext->root());
	parentContext->addInCount(*testContext);
	delete testContext;

	return result;
}

struct SystemAutomaton : public BaseSystemAutomaton
{
	int getNextState(int stateNr, int transitionNr);
	bool checkProposition(int stateNr, int propositionIndex) const;

	StateTransitionGraph* systemStates;
};

struct StrategySystemAutomaton : public BaseSystemAutomaton
{
	int getNextState(int stateNr, int transitionNr);
	bool checkProposition(int stateNr, int propositionIndex) const;

	StrategyTransitionGraph* systemStates;

	typedef std::map<std::pair<DagNode*,int>, bool> PropositionCache;
	mutable PropositionCache propositionCache;
};

int
SystemAutomaton::getNextState(int stateNr, int transitionNr) {
	int n = systemStates->getNextState(stateNr, transitionNr);
	if (n == NONE && transitionNr == 0)
		return stateNr; // fake a self loop for deadlocked state
	return n;
}

int
StrategySystemAutomaton::getNextState(int stateNr, int transitionNr)
{
	return systemStates->getNextState(stateNr, transitionNr);
}

bool
SystemAutomaton::checkProposition(int stateNr, int propositionIndex) const {
	return BaseSystemAutomaton::checkProposition(systemStates->getStateDag(stateNr),
						     propositionIndex);
}

bool
StrategySystemAutomaton::checkProposition(int stateNr, int propositionIndex) const
{
  DagNode* stateDag = systemStates->getStateDag(stateNr);

  //
  // System automaton states represent a term and a point in the strategy
  // execution. Hence multiple distinct states share a common State term.
  // To reduce properties only once per term instead of once per automaton
  // state, we introduce a(nother) proposition cache.
  //
  PropositionCache::const_iterator cached = propositionCache.find(make_pair(stateDag, propositionIndex));
  if (cached != propositionCache.end())
    return cached->second;

  bool result = BaseSystemAutomaton::checkProposition(stateDag, propositionIndex);
  propositionCache[make_pair(stateDag, propositionIndex)] = result;
  return result;
}

bool
prepareModelChecker(BaseSystemAutomaton &system, RewritingContext* context, DagNode* termFormula, LogicFormula &formula, int &top) {
	VisibleModule* mod = dynamic_cast<VisibleModule*>(context->root()->symbol()->getModule());
	FormulaeBuilder builder;

	// Find some required sorts
	Sort* stateSort = mod->findSort(Token::encode("State"));
	Sort* propSort = mod->findSort(Token::encode("Prop"));
	Sort* boolSort = mod->findSort(Token::encode("Bool"));

	if (stateSort == nullptr || propSort == nullptr || boolSort == nullptr)
		return false;

	// Try to load the LTL symbols into the fake TemporalSymbol
	if (!builder.loadSymbols(mod, stateSort->component()))
		return false;

	// Reduce negated formula
	RewritingContext* newContext = context->makeSubcontext(builder.negate(termFormula));
	newContext->reduce();

	// Build the LTL formula with the fake TemporalSymbol
	top = builder.build(formula, system.propositions, newContext->root());
	if (top == NONE) {
		IssueAdvisory("negated LTL formula " << QUOTE(newContext->root()) <<
		    " did not reduce to a valid negative normal form.");
		return false;
	}
	context->addInCount(*newContext);

	// Set system automaton fields
	system.parentContext = context;

	// Find the satisfies-relation symbol and the Boolean true term
	Vector<ConnectedComponent*> domain(2);

	domain[0] = stateSort->component();
	domain[1] = propSort->component();

	if (Symbol* symbol = mod->findSymbol(Token::encode("_|=_"), domain, boolSort->component()))
		system.satisfiesSymbol = symbol;
	else
		return false;

	domain.resize(0);

	if (Symbol* symbol = mod->findSymbol(Token::encode("true"), domain, boolSort->component()))
		system.trueTerm.setNode(symbol->makeDagNode());
	else
		return false;

	return true;
}

// Dirty hacks to access some private members
// (not to modify Maude for the moment, as already
// done in maude_wrappers.cc)

template<typename Tag, typename Tag::type M>
struct PrivateHack {
	friend typename Tag::type get(Tag) {
		return M;
	}
};

struct HackBuchiAutomaton {
	typedef BuchiAutomaton2 ModelChecker2::* type;
	friend type get(HackBuchiAutomaton);
};

template struct PrivateHack<HackBuchiAutomaton, &ModelChecker2::propertyAutomaton>;


ModelCheckResult*
modelCheck(StateTransitionGraph &graph, DagNode* termFormula) {
	SystemAutomaton system;
	LogicFormula formula;
	int top;

	if (!prepareModelChecker(system, graph.getContext(), termFormula, formula, top)) {
		IssueWarning("module is not prepared for model checking (the model checker module is not included).");
		return nullptr;
	}

	system.systemStates = &graph;

	ModelChecker2 mc(system, formula, top);
	bool result = mc.findCounterexample();

	const auto &buchiAut = mc.*get(HackBuchiAutomaton());
	int nrBuchiStates = buchiAut.getNrStates();

	if (result)
		return new ModelCheckResult{false,
			{mc.getLeadIn().begin(), mc.getLeadIn().end()},
			{mc.getCycle().begin(), mc.getCycle().end()},
			nrBuchiStates
		};
	else
		return new ModelCheckResult{true, {}, {}, nrBuchiStates};
}

ModelCheckResult*
modelCheck(StrategyTransitionGraph &graph, DagNode* termFormula) {
	StrategySystemAutomaton system;
	LogicFormula formula;
	int top;

	if (!prepareModelChecker(system, graph.getContext(), termFormula, formula, top)) {
		IssueWarning("module is not prepared for model checking (the model checker module is not included).");
		return nullptr;
	}

	system.systemStates = &graph;

	ModelChecker2 mc(system, formula, top);
	bool result = mc.findCounterexample();

	const auto &buchiAut = mc.*get(HackBuchiAutomaton());
	int nrBuchiStates = buchiAut.getNrStates();

	if (result)
		return new ModelCheckResult{false,
			{mc.getLeadIn().begin(), mc.getLeadIn().end()},
			{mc.getCycle().begin(), mc.getCycle().end()},
			nrBuchiStates
		};
	else
		return new ModelCheckResult{true, {}, {}, nrBuchiStates};
}
