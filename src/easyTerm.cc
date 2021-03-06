/**
 * @file easyTerm.cc
 *
 * Simplified interface to the Maude terms.
 */

#include "easyTerm.hh"
#include "helper_funcs.hh"

#include "mixfix.hh"
#include "meta.hh"

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
#include "narrowingSequenceSearch.hh"
#include "narrowingSequenceSearch3.hh"
#include "freshVariableSource.hh"
#include "pattern.hh"
#include "extensionInfo.hh"
#include "dagArgumentIterator.hh"
#include "variableDagNode.hh"
#include "metaLevel.hh"
#include "userLevelRewritingContext.hh"
#include "visibleModule.hh"
#include "metaModule.hh"
#include "variableGenerator.hh"

// for theory-specific functions
#include "NA_Theory.hh"
#include "floatTerm.hh"
#include "floatDagNode.hh"
#include "succSymbol.hh"
#include "minusSymbol.hh"
#include "SMT_NumberDagNode.hh"
#include "SMT_NumberTerm.hh"

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
	if (!is_dag)
		return term->ground();

	dagNode->computeBaseSortForGroundSubterms(false);
	return dagNode->isGround();
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

	if (is_dag) {
		if (dagNode->getSort() == nullptr) {
			RewritingContext* context = new UserLevelRewritingContext(dagNode);
			dagNode->computeTrueSort(*context);
			delete context;
		}
		return dagNode->getSort();
	}

	if (term->getSort() == nullptr)
		term->symbol()->fillInSortInfo(term);
	return term->getSort();
}

void
EasyTerm::print(std::ostream &out) const {
	is_dag ? (out << dagNode) : (out << term);
}

void
EasyTerm::print(std::ostream &out, Interpreter::PrintFlags flags) const {
	//
	// Temporarily set the print flags (a variable of the interpreter)
	//
	int oldFlags = interpreter.getPrintFlags();
	// Set the selected print flags
	for (int mask = 0x1; mask <= Interpreter::PRINT_RAT; mask <<= 1)
		if ((flags & mask) != (oldFlags & mask))
			interpreter.setPrintFlag(Interpreter::PrintFlags(mask), flags & mask);
	is_dag ? (out << dagNode) : (out << term);
	// Recover the old print flags
	for (int mask = 0x1; mask <= Interpreter::PRINT_RAT; mask <<= 1)
		if ((flags & mask) != (oldFlags & mask))
			interpreter.setPrintFlag(Interpreter::PrintFlags(mask), oldFlags & mask);
}

double
EasyTerm::toFloat() const {
	if (is_dag) {
		if (auto fdag = dynamic_cast<FloatDagNode*>(dagNode))
			return fdag->getValue();
		else if (auto fsym = dynamic_cast<SuccSymbol*>(dagNode->symbol()))
			return fsym->isNat(dagNode) ? fsym->getNat(dagNode).get_d() : 0.0;
		else if (auto fsym = dynamic_cast<MinusSymbol*>(dagNode->symbol())) {
			mpz_class result;
			return fsym->isNeg(dagNode) ? fsym->getNeg(dagNode, result).get_d() : 0.0;
		}
		else if (auto fdag = dynamic_cast<SMT_NumberDagNode*>(dagNode))
			return fdag->getValue().get_d();
	}
	else {
		if (auto fterm = dynamic_cast<FloatTerm*>(term))
			return fterm->getValue();
		else if (auto fsym = dynamic_cast<SuccSymbol*>(term->symbol()))
			return fsym->isNat(term) ? fsym->getNat(term).get_d() : 0.0;
		else if (auto fsym = dynamic_cast<MinusSymbol*>(term->symbol())) {
			mpz_class result;
			return fsym->isNeg(term) ? fsym->getNeg(term, result).get_d() : 0.0;
		}
		else if (auto fterm = dynamic_cast<SMT_NumberTerm*>(term))
			return fterm->getValue().get_d();
	}

	return 0.0;
}

long int
EasyTerm::toInt() const {
	if (is_dag) {
		if (auto fsym = dynamic_cast<SuccSymbol*>(dagNode->symbol()))
			return fsym->isNat(dagNode) ? fsym->getNat(dagNode).get_si() : 0;
		else if (auto fsym = dynamic_cast<MinusSymbol*>(dagNode->symbol())) {
			mpz_class result;
			return fsym->isNeg(dagNode) ? fsym->getNeg(dagNode, result).get_si() : 0;
		}
		else if (auto fdag = dynamic_cast<FloatDagNode*>(dagNode))
			return fdag->getValue();
		else if (auto fdag = dynamic_cast<SMT_NumberDagNode*>(dagNode))
			return fdag->getValue().get_d();
	}
	else {
		if (auto fsym = dynamic_cast<SuccSymbol*>(term->symbol()))
			return fsym->isNat(term) ? fsym->getNat(term).get_si() : 0;
		else if (auto fsym = dynamic_cast<MinusSymbol*>(term->symbol())) {
			mpz_class result;
			return fsym->isNeg(term) ? fsym->getNeg(term, result).get_si() : 0;
		}
		else if (auto fterm = dynamic_cast<FloatTerm*>(term))
			return fterm->getValue();
		else if (auto fterm = dynamic_cast<SMT_NumberTerm*>(term))
			return fterm->getValue().get_d();
	}

	return 0;
}

size_t
EasyTerm::hash() const {
	if (is_dag) {
		return dagNode->getHashValue();
	}
	else {
		// We should avoid normalizing if not necessary
		term->normalize(true);
		return term->getHashValue();
	}
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
EasyTerm::setDag(DagNode* other) {
	if (!is_dag && is_own) {
		term->deepSelfDestruct();
		term = nullptr;
		is_dag = true;
	}
	dagNode = other;
}

void
EasyTerm::startUsingModule(VisibleModule* vmod) {
	UserLevelRewritingContext::clearTrialCount();
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_MEMO))
		vmod->clearMemo();
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_PROFILE))
		vmod->clearProfile();
	vmod->protect();
}

int
EasyTerm::reduce() {
	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	UserLevelRewritingContext* context = new UserLevelRewritingContext(dagNode);
	startUsingModule(vmod);
	context->reduce();

	int rewrites = context->getTotalCount();

	delete context;
	(void) vmod->unprotect();

	return rewrites;
}

int
EasyTerm::rewrite(int limit) {
	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	RewritingContext* context = new UserLevelRewritingContext(dagNode);

	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_RULES))
		vmod->resetRules();
	startUsingModule(vmod);

	context->ruleRewrite(limit);

	int rewrites = context->getTotalCount();
	dagNode = context->root();

	delete context;
	(void) vmod->unprotect();

	return rewrites;
}

int
EasyTerm::frewrite(int limit, int gas) {
	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	UserLevelRewritingContext* context = new UserLevelRewritingContext(dagNode);
	context->setObjectMode(ObjectSystemRewritingContext::FAIR);
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_RULES))
		vmod->resetRules();
	startUsingModule(vmod);
	context->fairRewrite(limit, (gas == NONE) ? 1 : gas);

	int rewrites = context->getTotalCount();
	dagNode = context->root();

	delete context;
	(void) vmod->unprotect();

	return rewrites;
}

pair<EasyTerm*, int>
EasyTerm::erewrite(int limit, int gas) {
	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	UserLevelRewritingContext* context = new UserLevelRewritingContext(dagNode);
	context->setObjectMode(ObjectSystemRewritingContext::EXTERNAL);
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_RULES))
		vmod->resetRules();
	startUsingModule(vmod);
	context->fairStart(limit, (gas == NONE) ? 1 : gas);
	context->externalRewrite();

	int rewrites = context->getTotalCount();
	EasyTerm* result = new EasyTerm(context->root());

	delete context;
	(void) vmod->unprotect();

	return {result, rewrites};
}

StrategicSearch*
EasyTerm::srewrite(StrategyExpression* expr, bool depthSearch) {
	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	ImportTranslation dummy(vmod);
	StrategyExpression* strategy = ImportModule::deepCopyStrategyExpression(&dummy, expr);

	TermSet nothing;
	VariableInfo vinfo;
	if (!strategy->check(vinfo, nothing))
		return nullptr;

	strategy->process();

	UserLevelRewritingContext* context = new UserLevelRewritingContext(dagNode);
	context->setObjectMode(ObjectSystemRewritingContext::EXTERNAL);
	if (interpreter.getFlag(Interpreter::AUTO_CLEAR_RULES))
		vmod->resetRules();
	startUsingModule(vmod);
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
	UserLevelRewritingContext* context = new UserLevelRewritingContext(dagNode);
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
		IssueWarning("the target of the search cannot be the initial term itself.");
		return nullptr;
	}

	if (target->is_dag)
		target->termify();

	Pattern* pattern = new Pattern(target->termCopy(), false, condition);

	RewriteSequenceSearch* state =
		new RewriteSequenceSearch(new UserLevelRewritingContext(getDag()),
				  static_cast<RewriteSequenceSearch::SearchType>(type),
				  pattern,
				  depth);

	return state;
}

VariantSearch*
EasyTerm::get_variants(bool irredundant, const std::vector<EasyTerm*> &irreducible) {
	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());

	size_t nrIrredTerm = irreducible.size();
	Vector<DagNode*> blockerDags(nrIrredTerm);

	for (size_t i = 0; i < nrIrredTerm; i++)
		blockerDags[i] = irreducible[i]->getDag();

	startUsingModule(vmod);

	VariantSearch* search = new VariantSearch(new UserLevelRewritingContext(getDag()),
						  blockerDags,
						  new FreshVariableSource(vmod),
						  VariantSearch::DELETE_FRESH_VARIABLE_GENERATOR |
						  VariantSearch::CHECK_VARIABLE_NAMES |
						  (irredundant ? VariantSearch::IRREDUNDANT_MODE : 0));

	if (!search->problemOK()) {
		delete search;
		return nullptr;
	}

	return search;
}

NarrowingSequenceSearch3*
EasyTerm::vu_narrow(SearchType type,
		    EasyTerm* target,
		    int depth,
		    bool fold)
{
	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (this == target) {
		IssueWarning("the target of the search cannot be the initial term itself.");
		return nullptr;
	}

	return new NarrowingSequenceSearch3(new UserLevelRewritingContext(getDag()),
			static_cast<NarrowingSequenceSearch::SearchType>(type),
			target->getDag(),
			depth,
			new FreshVariableSource(vmod),
			fold ? NarrowingSequenceSearch3::FOLD : 0);
}

#if defined(USE_CVC4) || defined(USE_YICES2)
const char*
EasyTerm::check()
{
	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());
	startUsingModule(vmod);

	const SMT_Info& smtInfo = vmod->getSMT_Info();
	VariableGenerator vg(smtInfo);
	VariableGenerator::Result result = vg.checkDag(getDag());
	vmod->unprotect();

	if (result == VariableGenerator::BAD_DAG)
		return nullptr;

	else
		return (result == VariableGenerator::SAT) ? "sat" :
			((result == VariableGenerator::UNSAT) ? "unsat" : "undecided");
}
#endif

DagArgumentIterator*
EasyTerm::arguments() {
	if (!is_dag)
		dagify();

	return new DagArgumentIterator(dagNode);
}

void
EasyTerm::markReachableNodes() {
	if (is_dag)
		dagNode->mark();
}

//
//	EasySubstitution
//

EasySubstitution::EasySubstitution(const Substitution* subs,
				   const VariableInfo* vinfo,
				   const ExtensionInfo* extension)
 : subs(subs), vinfo(vinfo), extension(extension), flags(0) {

}

EasySubstitution::EasySubstitution(const Substitution* subs,
				   const NarrowingVariableInfo* nvinfo,
				   bool ownsSubstitution)
 : subs(subs), nvinfo(nvinfo), extension(nullptr), flags(NARROWING) {
	if (ownsSubstitution)
		flags |= OWNS_SUBSTITUTION;
}

EasySubstitution::~EasySubstitution() {
	if (flags & OWNS_SUBSTITUTION)
		delete subs;
}

int
EasySubstitution::size() const {
	return (flags & NARROWING)
			? subs->nrFragileBindings()
			: vinfo->getNrRealVariables();
}

EasyTerm*
EasySubstitution::variable(int index) const {
	return (flags & NARROWING)
			? new EasyTerm(nvinfo->index2Variable(index))
			: new EasyTerm(vinfo->index2Variable(index), false);
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

EasyTerm*
EasySubstitution::find(const char* name, Sort* sort) const {
	int code = Token::encode(name);
	int nrRealVariables = size();

	for (int i = 0; i < nrRealVariables; i++) {
		int varId;
		Sort* varSort;

		if (flags & NARROWING) {
			VariableDagNode* var = nvinfo->index2Variable(i);
			varId = var->id();
			varSort = var->getSort();
		}
		else {
			VariableTerm* var = dynamic_cast<VariableTerm*>(vinfo->index2Variable(i));
			varId = var->id();
			varSort = var->getSort();
		}

		if (varId == code && (sort == nullptr || varSort == sort))
			return new EasyTerm(subs->value(i));
	}

	return nullptr;
}

EasyTerm*
EasySubstitution::instantiate(EasyTerm* term) const {
	// This implementation could be more efficient

	EasyTerm* result;

	// Index variables
	if (flags & NARROWING) {
		DagNode* dagNode = term->getDag();
		NarrowingVariableInfo vinfoCopy;
		vinfoCopy.copy(*nvinfo);
		dagNode->indexVariables(vinfoCopy, 0);
		result = new EasyTerm(dagNode);
	}
	else {
		Term* termCopy = term->termCopy();
		VariableInfo vinfoCopy = *vinfo;
		termCopy->indexVariables(vinfoCopy);
		result = new EasyTerm(termCopy);
		termCopy->dagify();
	}

	// Set ground flags
	result->getDag()->computeBaseSortForGroundSubterms(false);

	DagNode* instantiated = result->getDag()->instantiate(*subs, true);
	if (instantiated != nullptr)
		result->setDag(instantiated);

	return result;
}

VisibleModule* downModule(EasyTerm* term) {
	MetaLevel* metaLevel = getMetaLevel(safeCast(VisibleModule*, term->symbol()->getModule()));

	if (metaLevel == nullptr)
		return nullptr;

	UserLevelRewritingContext context(term->getDag());
	context.reduce();

	VisibleModule* mod = metaLevel->downModule(context.root());

	if (mod == nullptr)
		return nullptr;

	mod->protect();
	return mod;
}
