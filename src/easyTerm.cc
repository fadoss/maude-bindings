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
#include "strategySequenceSearch.hh"
#include "rewriteSearchState.hh"
#include "freshVariableSource.hh"
#include "pattern.hh"
#include "extensionInfo.hh"
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
#include "S_Theory.hh"
#include "S_DagNode.hh"
#include "S_Term.hh"

#include <sstream>

using namespace std;

const Vector<ConditionFragment*> EasyTerm::NO_CONDITION;

EasyTerm::EasyTerm(Term* term, bool owned)
 : is_dag(false), is_own(owned), term(term)
{
	protect();
}

EasyTerm::EasyTerm(DagNode* dagNode)
 : is_dag(true), is_own(false), dagNode(dagNode)
{
	protect();
	link();
}

EasyTerm::~EasyTerm() {
	// Unprotect the module this object belongs to
	dynamic_cast<ImportModule*>(symbol()->getModule())->unprotect();

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
	uint_fast32_t oldFlags = 0;
	// Set the selected print flags
	for (uint_fast32_t mask = 0x1; mask <= Interpreter::PRINT_COMBINE_VARS; mask <<= 1) {
		if (interpreter.getPrintFlag(Interpreter::PrintFlags(mask)))
			oldFlags |= mask;
		if ((flags & mask) != (oldFlags & mask))
			interpreter.setPrintFlag(Interpreter::PrintFlags(mask), flags & mask);
	}
	is_dag ? (out << dagNode) : (out << term);
	// Recover the old print flags
	for (uint_fast32_t mask = 0x1; mask <= Interpreter::PRINT_COMBINE_VARS; mask <<= 1)
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

bool
EasyTerm::isVariable() const {
	return (is_dag && dynamic_cast<VariableDagNode*>(dagNode) != nullptr)
	       || dynamic_cast<VariableTerm*>(term) != nullptr;
}

const char*
EasyTerm::getVarName() const {
	if (is_dag) {
		if (auto vard = dynamic_cast<VariableDagNode*>(dagNode))
			return Token::name(vard->id());
	}
	else {
		if (auto vart = dynamic_cast<VariableTerm*>(term))
			return Token::name(vart->id());
	}

	return nullptr;
}

unsigned long int
EasyTerm::getIterExponent() const {
	if (is_dag) {
		if (S_DagNode* sdag = dynamic_cast<S_DagNode*>(dagNode))
			return sdag->getNumber().get_ui();
	}
	else {
		if (S_Term* sterm = dynamic_cast<S_Term*>(term))
			return sterm->getNumber().get_ui();
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

inline void
EasyTerm::protect() {
	// Since its module must stay alive during the lifetime of term,
	// we protect it so that it is not garbage collected by Maude
	dynamic_cast<ImportModule*>(symbol()->getModule())->protect();
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

void
EasyTerm::normalize(bool full) {
	if (!is_dag)
		term->normalize(full);
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
EasyTerm::match(EasyTerm* target, const Vector<ConditionFragment*>& condition,
                bool withExtension, int minDepth, int maxDepth)
{
	// Protect the module to avoid its deletion while the search is active
	dynamic_cast<VisibleModule*>(symbol()->getModule())->protect();

	if (!is_dag)
		dagify();

	// Patterns take ownership of the condition, so we need to pass them a copy.
	// For efficiency, Pattern may be modified to optionally borrow conditions,
	// if we prevent their destruction at the user side during the search.
	Vector<ConditionFragment*> conditionCopy;
	ImportModule::deepCopyCondition(nullptr, condition, conditionCopy);

	Pattern* pattern = new Pattern(target->termCopy(), withExtension || maxDepth != -1, conditionCopy);
	UserLevelRewritingContext* context = new UserLevelRewritingContext(dagNode);
	dagNode->computeTrueSort(*context);

	MatchSearchState* state = new MatchSearchState(context,
			 pattern,
			 MatchSearchState::GC_PATTERN | MatchSearchState::GC_CONTEXT,
			 minDepth,
			 (withExtension && maxDepth == -1) ? 0 : maxDepth);

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

	// Protect the module to avoid its deletion while the search is active
	dynamic_cast<VisibleModule*>(symbol()->getModule())->protect();

	if (target->is_dag)
		target->termify();

	// Patterns take ownership of the condition, so we need to pass them a copy.
	Vector<ConditionFragment*> conditionCopy;
	ImportModule::deepCopyCondition(nullptr, condition, conditionCopy);

	Pattern* pattern = new Pattern(target->termCopy(), false, conditionCopy);

	RewriteSequenceSearch* state =
		new RewriteSequenceSearch(new UserLevelRewritingContext(getDag()),
				  static_cast<RewriteSequenceSearch::SearchType>(type),
				  pattern,
				  depth);

	return state;
}

StrategySequenceSearch*
EasyTerm::search(SearchType type,
		 EasyTerm* target,
		 StrategyExpression* strategy,
		 const Vector<ConditionFragment*> &condition,
		 int depth)
{
	if (this == target) {
		IssueWarning("the target of the search cannot be the initial term itself.");
		return nullptr;
	}

	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());
	startUsingModule(vmod);

	if (target->is_dag)
		target->termify();

	// Patterns take ownership of the condition, so we need to pass them a copy.
	Vector<ConditionFragment*> conditionCopy;
	ImportModule::deepCopyCondition(nullptr, condition, conditionCopy);

	// Copy the given strategy, since it will be deleted with this structure
	ImportTranslation translation(dynamic_cast<ImportModule*>(getDag()->symbol()->getModule()));
	StrategyExpression* stratCopy = ImportModule::deepCopyStrategyExpression(&translation, strategy);

	Pattern* pattern = new Pattern(target->termCopy(), false, conditionCopy);

	StrategySequenceSearch* state =
		new StrategySequenceSearch(new UserLevelRewritingContext(getDag()),
				  static_cast<RewriteSequenceSearch::SearchType>(type),
				  pattern,
				  stratCopy,
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
		    int variantFlags)
{
	if (this == target) {
		IssueWarning("the target of the search cannot be the initial term itself.");
		return nullptr;
	}

	// Delegates on the general method
	return EasyTerm::vu_narrow({this}, type, target, depth, variantFlags);
}

NarrowingSequenceSearch3*
EasyTerm::vu_narrow(const vector<EasyTerm*>& subject,
                    SearchType type,
		    EasyTerm* target,
		    int depth,
		    int variantFlags)
{
	if ((variantFlags & NarrowingSequenceSearch3::FOLD) &&
            (variantFlags & NarrowingSequenceSearch3::VFOLD)) {
		IssueWarning("fold and vfold option cannot be used together");
		return nullptr;
	}

	if (subject.empty()) {
		IssueWarning("empty list of initial states");
		return nullptr;
	}

	VisibleModule* vmod = dynamic_cast<VisibleModule*>(subject[0]->symbol()->getModule());
	startUsingModule(vmod);

        Vector<DagNode*> subjectDags(subject.size());

	for (size_t i = 0; i < subject.size(); ++i)
		subjectDags[i] = subject[i]->getDag();

	return new NarrowingSequenceSearch3(new UserLevelRewritingContext(subjectDags[0]),
	                subjectDags,
			static_cast<NarrowingSequenceSearch::SearchType>(type),
			target->getDag(),
			depth,
			new FreshVariableSource(vmod),
			variantFlags);
}

RewriteSearchState*
EasyTerm::apply(const char* label, EasySubstitution* substitution,
	        int minDepth, int maxDepth)
{
	VisibleModule* vmod = dynamic_cast<VisibleModule*>(symbol()->getModule());

	if (!is_dag)
		dagify();

	UserLevelRewritingContext* context = new UserLevelRewritingContext(dagNode);
	startUsingModule(vmod);
	context->reduce();

	// If no label is provided, any executable rule can be applied
	int label_id = label != nullptr ? Token::encode(label) : UNDEFINED;

	RewriteSearchState* state =
		new RewriteSearchState(context,
		                       label_id,
			               RewriteSearchState::GC_CONTEXT |
      			               RewriteSearchState::GC_SUBSTITUTION |
			               (label != nullptr ? RewriteSearchState::ALLOW_NONEXEC : 0),
			               minDepth,
			               maxDepth);

	// Set the initial substitution
	if (substitution != nullptr && substitution->size() > 0) {
		Vector<Term*> variables;
		Vector<DagRoot*> values;
		substitution->getSubstitution(variables, values);
		state->setInitialSubstitution(variables, values);
	}

	return state;
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

EasyArgumentIterator*
EasyTerm::arguments(bool normalize) {
	// Converting the EasyTerm to DAG while iterating over
	// a term will cause memory errors
	if (!is_dag && normalize)
		dagify();

	return is_dag ? new EasyArgumentIterator(dagNode)
	              : new EasyArgumentIterator(*term);
}

void
EasyTerm::markReachableNodes() {
	if (is_dag)
		dagNode->mark();
}

string
EasyTerm::toLatex() const {
	ostringstream stream;

	if (is_dag)
		MixfixModule::latexPrintDagNode(stream, dagNode);
	else
		MixfixModule::latexPrettyPrint(stream, term);

	return stream.str();
}

//
//	EasySubstitution
//

EasySubstitution::EasySubstitution(const Substitution* subs,
				   const VariableInfo* vinfo,
				   const ExtensionInfo* extension)
 : extension(extension) {
	for (int i = 0; i < vinfo->getNrRealVariables(); ++i) {
		VariableTerm* var = dynamic_cast<VariableTerm*>(vinfo->index2Variable(i));
		mapping[{var->id(), var->symbol()->getRangeSort()}] = subs->value(i);
	}

	link();
}

EasySubstitution::EasySubstitution(const Substitution* subs,
				   const NarrowingVariableInfo* nvinfo)
 : extension(nullptr) {
	for (int i = 0; i < subs->nrFragileBindings(); ++i) {
		VariableDagNode* var = nvinfo->index2Variable(i);
		mapping[{var->id(), var->symbol()->getRangeSort()}] = subs->value(i);
	}

	link();
}

EasySubstitution::EasySubstitution(const vector<EasyTerm*> &variables,
				   const vector<EasyTerm*> &values)
 : extension(nullptr) {
 	int nrVariables = variables.size();

	for (int i = 0; i < nrVariables; ++i) {
		VariableDagNode* var = dynamic_cast<VariableDagNode*>(variables[i]->getDag());
		if (var != nullptr)
			mapping[{var->id(), var->symbol()->getRangeSort()}] = values[i]->getDag();
	}

	link();
}

EasySubstitution::~EasySubstitution() {
	mapping.clear();
	unlink();
}

int
EasySubstitution::size() const {
	return mapping.size();
}

EasyTerm*
EasySubstitution::value(EasyTerm* variable) const {

	VariableDagNode* var = dynamic_cast<VariableDagNode*>(variable->getDag());

	if (var != nullptr) {
		auto it = mapping.find({var->id(), var->symbol()->getRangeSort()});

		if (it != mapping.end())
			return new EasyTerm(it->second);
	}

	return nullptr;
}

EasyTerm*
EasySubstitution::matchedPortion() const {
	return (extension != nullptr && !extension->matchedWhole())
		? new EasyTerm(extension->buildMatchedPortion())
		: nullptr;
}

EasyTerm*
EasySubstitution::find(const char* name, Sort* sort) const {

	decltype(mapping)::const_iterator it;
	int code = Token::encode(name);

	if (sort != nullptr) {
		if ((it = mapping.find({code, sort})) == mapping.end())
			return nullptr;
	}
	// When no sort is provided, an arbitrary variable with that name is returned
	else if ((it = mapping.upper_bound({code, nullptr})) == mapping.end() || it->first.first != code)
		return nullptr;

	return new EasyTerm(it->second);
}

EasyTerm*
EasySubstitution::instantiate(EasyTerm* term) const {
	EasyTerm* result = new EasyTerm(term->getDag());
	NarrowingVariableInfo vinfo;

	DagNode* dag = result->getDag();

	dag->computeBaseSortForGroundSubterms(false);
	dag->indexVariables(vinfo, 0);

	// Construct the substitution
	// (DagNode::instantiate requires that all variables in the term are defined
	// in the substitution, so identity mappings are added for them)
	int nrVariables = vinfo.getNrVariables();

	Substitution subs(nrVariables);

	for (int i = 0; i < nrVariables; ++i) {
		VariableDagNode* var = vinfo.index2Variable(i);
		auto it = mapping.find({var->id(), var->symbol()->getRangeSort()});

		subs.bind(i, it != mapping.end() ? it->second : var);
	}

	DagNode* instantiated = dag->instantiate(subs, true);

	if (instantiated != nullptr)
		result->setDag(instantiated);

	return result;
}

void
EasySubstitution::markReachableNodes() {
	for (auto &pair : mapping)
		pair.second->mark();
}

Term*
EasySubstitution::makeVariable(const Mapping::const_iterator &it) const {
	MixfixModule* mxmod = dynamic_cast<MixfixModule*>(it->second->symbol()->getModule());
	VariableSymbol* varSymbol = static_cast<VariableSymbol*>(mxmod->instantiateVariable(it->first.second));

	return new VariableTerm(varSymbol, it->first.first);
}

void
EasySubstitution::getSubstitution(Vector<Term*> &variables, Vector<DagRoot*> &values) {
	size_t nrVars = mapping.size();

	variables.resize(nrVars);
	values.resize(nrVars);

	auto it = mapping.begin();

	for (size_t i = 0; i < nrVars; ++i) {
		variables[i] = makeVariable(it);
		values[i] = new DagRoot(it->second);
		++it;
	}
}

EasySubstitution::Iterator::Iterator(const EasySubstitution* subs)
 : subs(subs), it(subs->mapping.cbegin()) {

}

void
EasySubstitution::Iterator::nextAssignment() {
	++it;
}

EasyTerm*
EasySubstitution::Iterator::getVariable() const {
	if (it != subs->mapping.end())
		return new EasyTerm(subs->makeVariable(it), true);

	return nullptr;
}

EasyTerm*
EasySubstitution::Iterator::getValue() const {
	if (it != subs->mapping.end())
		return new EasyTerm(it->second);

	return nullptr;
}

//
//	EasyArgumentIterator
//

EasyArgumentIterator::EasyArgumentIterator(Term& term)
 : variant(term) {
}

EasyArgumentIterator::EasyArgumentIterator(DagNode* dagNode)
 : variant(dagNode) {
}

// For compatibility with macOS <10.16
#ifdef __APPLE__
#define getFromVariant(T, obj) (*get_if<T>(obj))
#else
#define getFromVariant(T, obj) get<T>(*obj)
#endif

bool
EasyArgumentIterator::valid() const {
	return holds_alternative<DagArgumentIterator>(*this)
		? getFromVariant(DagArgumentIterator, this).valid()
		: getFromVariant(ArgumentIterator, this).valid();
}

EasyTerm*
EasyArgumentIterator::argument() const {
	return holds_alternative<DagArgumentIterator>(*this)
		? new EasyTerm(getFromVariant(DagArgumentIterator, this).argument())
		: new EasyTerm(getFromVariant(ArgumentIterator, this).argument(), false);
}

void
EasyArgumentIterator::next() {
	if (holds_alternative<DagArgumentIterator>(*this))
		getFromVariant(DagArgumentIterator, this).next();
	else
		getFromVariant(ArgumentIterator, this).next();
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
