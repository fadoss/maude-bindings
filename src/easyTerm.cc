/**
 * @file easyTerm.cc
 *
 * Simplified interface to the Maude terms.
 */

#include "easyTerm.hh"

#include "mixfix.hh"
#include "term.hh"
#include "dagNode.hh"
#include "userLevelRewritingContext.hh"
#include "visibleModule.hh"
#include "interpreter.hh"
#include "global.hh"
#include "strategyExpression.hh"
#include "depthFirstStrategicSearch.hh"
#include "fairStrategicSearch.hh"
#include "importTranslation.hh"
#include "rewriteSequenceSearch.hh"
#include "pattern.hh"
#include "extensionInfo.hh"

using namespace std;

const Vector<ConditionFragment*> EasyTerm::NO_CONDITION;

EasyTerm::EasyTerm(Term* term, bool owned)
 : is_dag(false), is_own(owned), term(term)
{
}

EasyTerm::EasyTerm(DagNode* dagNode)
 : is_dag(true), is_own(false), dagNode(dagNode)
{
	link();
}

EasyTerm::~EasyTerm() {
	if (is_dag)
		unlink();
	else if (is_own)
		term->deepSelfDestruct();
}

Symbol*
EasyTerm::symbol() const {
	return is_dag ? dagNode->symbol() : term->symbol();
}

bool
EasyTerm::ground() const {
	return is_dag ? dagNode->isGround() : term->ground();
}

bool
EasyTerm::equal(const EasyTerm* other) const {
	return is_dag ? (other->is_dag ? dagNode->equal(other->dagNode) : other->term->equal(dagNode)) :
		(other->is_dag ? term->equal(other->dagNode) : term->equal(other->term));
}

bool
EasyTerm::leq(const Sort* sort) const {
	return is_dag ? dagNode->leq(sort) : term->leq(sort);
}

Sort*
EasyTerm::getSort() const {
	return is_dag ? dagNode->getSort() : term->getSort();
}

void
EasyTerm::print(std::ostream &out) const {
	is_dag ? (out << dagNode) : (out << term);
}

void
EasyTerm::dagify() {
	term = term->normalize(false);
	NatSet eagerVariables;
	Vector<int> problemVariables;
	term->markEager(0, eagerVariables, problemVariables);
	DagNode* d = term->term2Dag();
	if (is_own) term->deepSelfDestruct();
	dagNode = d;
	is_dag = true;
	link();
}

void
EasyTerm::termify() {
	Term* termified = dagNode->symbol()->termify(dagNode);
	is_dag = false;
	is_own = true;
	term = termified;
	unlink();
}

EasyTerm*
EasyTerm::copy() const {
	return new EasyTerm(termCopy());
}

Term*
EasyTerm::termCopy() const {
	if (is_dag)
		return dagNode->symbol()->termify(dagNode);
	else
		return term->deepCopy();
}

DagNode*
EasyTerm::getDag() {
	if (!is_dag)
		dagify();

	return dagNode;
}

void
EasyTerm::startUsingModule(VisibleModule* module) {
	UserLevelRewritingContext::clearTrialCount();
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_MEMO))
		module->clearMemo();
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_PROFILE))
		module->clearProfile();
	module->protect();
}

int
EasyTerm::reduce() {
	VisibleModule* module = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	RewritingContext* context = new RewritingContext(dagNode);
	startUsingModule(module);
	context->reduce();

	int rewrites = context->getTotalCount();

	delete context;
	(void) module->unprotect();

	return rewrites;
}

int
EasyTerm::rewrite(int limit) {
	VisibleModule* module = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	ObjectSystemRewritingContext* context = new ObjectSystemRewritingContext(dagNode);

	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_RULES))
		module->resetRules();
	startUsingModule(module);

	context->ruleRewrite(limit);

	int rewrites = context->getTotalCount();
	dagNode = context->root();

	delete context;
	(void) module->unprotect();

	return rewrites;
}

int
EasyTerm::frewrite(int limit, int gas) {
	VisibleModule* module = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	ObjectSystemRewritingContext* context = new ObjectSystemRewritingContext(dagNode);
	context->setObjectMode(ObjectSystemRewritingContext::FAIR);
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_RULES))
		module->resetRules();
	startUsingModule(module);
	context->fairRewrite(limit, (gas == NONE) ? 1 : gas);

	int rewrites = context->getTotalCount();
	dagNode = context->root();

	delete context;
	(void) module->unprotect();

	return rewrites;
}

pair<EasyTerm*, int>
EasyTerm::erewrite(int limit, int gas) {
	VisibleModule* module = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	ObjectSystemRewritingContext* context = new ObjectSystemRewritingContext(dagNode);
	context->setObjectMode(ObjectSystemRewritingContext::EXTERNAL);
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_RULES))
		module->resetRules();
	startUsingModule(module);
	context->fairStart(limit, (gas == NONE) ? 1 : gas);
	context->externalRewrite();

	int rewrites = context->getTotalCount();
	EasyTerm* result = new EasyTerm(context->root());

	delete context;
	(void) module->unprotect();

	return {result, rewrites};
}

StrategicSearch*
EasyTerm::srewrite(StrategyExpression* expr, bool depthSearch) {
	ImportModule* module = dynamic_cast<ImportModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	ImportTranslation dummy(module);
	StrategyExpression* strategy = ImportModule::deepCopyStrategyExpression(&dummy, expr);

	TermSet nothing;
	VariableInfo vinfo;
	if (!strategy->check(vinfo, nothing)) {
		return 0;
	}

	strategy->process();

	ObjectSystemRewritingContext* context = new ObjectSystemRewritingContext(dagNode);
	context->setObjectMode(ObjectSystemRewritingContext::EXTERNAL);
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_RULES))
		module->resetRules();
	// startUsingModule(module);
	context->reduce();

	StrategicSearch* state = depthSearch ? new DepthFirstStrategicSearch(context, strategy)
		: static_cast<StrategicSearch*>(new
		  FairStrategicSearch(context, strategy));

	return state;
}

MatchSearchState*
EasyTerm::match(EasyTerm* target, const Vector<ConditionFragment*>& condition, bool withExtension)
{
	if (!is_dag)
		dagify();

	Pattern* pattern = new Pattern(target->termCopy(), withExtension, condition);
	RewritingContext* context = new RewritingContext(dagNode);
	dagNode->computeTrueSort(*context);

	MatchSearchState* state = new MatchSearchState(context,
			 pattern,
			 MatchSearchState::GC_PATTERN | MatchSearchState::GC_CONTEXT,
			 0,
			 withExtension ? 0 : NONE);

	return state;
}

RewriteSequenceSearch*
EasyTerm::search(SearchType type,
		 EasyTerm* target,
		 const Vector<ConditionFragment*> &condition,
		 int depth)
{
	if (this == target) {
		cerr << "The term of the search cannot be the initial term itself." << endl;
		return nullptr;
	}

	if (!is_dag)
		dagify();
	if (target->is_dag)
		target->termify();

	Pattern* pattern = new Pattern(target->term, false, condition);

	RewriteSequenceSearch* state =
		new RewriteSequenceSearch(new UserLevelRewritingContext(dagNode),
				  static_cast<RewriteSequenceSearch::SearchType>(type),
				  pattern,
				  depth);

	return state;
}

void
EasyTerm::markReachableNodes() {
	if (is_dag)
		dagNode->mark();
}

//
//	EasySubstitution
//

EasySubstitution::EasySubstitution(const Substitution* subs, const VariableInfo* vinfo,
				   const ExtensionInfo* extension)
 : subs(subs), vinfo(vinfo), extension(extension) {

}

int
EasySubstitution::size() const {
	return vinfo->getNrRealVariables();
}

EasyTerm*
EasySubstitution::variable(int index) const {
	return new EasyTerm(vinfo->index2Variable(index), false);
}

EasyTerm*
EasySubstitution::value(int index) const {
	return new EasyTerm(subs->value(index));
}

EasyTerm*
EasySubstitution::matchedPortion() const {
	return (extension != nullptr && !extension->matchedWhole())
		? new EasyTerm(extension->buildMatchedPortion())
		: nullptr;
}
