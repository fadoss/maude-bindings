//
//	Interface to almost opaque objects
//

%{
#include "equation.hh"
#include "sortConstraint.hh"
#include "rule.hh"
#include "strategyExpression.hh"
#include "strategyDefinition.hh"
#include "equalityConditionFragment.hh"
#include "assignmentConditionFragment.hh"
#include "rewriteConditionFragment.hh"
#include "sortTestConditionFragment.hh"
#include "stateTransitionGraph.hh"
#include "strategyTransitionGraph.hh"
#include "userLevelRewritingContext.hh"
#include "importTranslation.hh"

#include "helper_funcs.hh"
%}

//
//	Module items
//

%rename (RewriteGraph) StateTransitionGraph;
%rename (StrategyRewriteGraph) StrategyTransitionGraph;

/**
 * An item that belongs to a module.
 */
class ModuleItem {
public:
	ModuleItem() = delete;

	%extend {
		/**
		 * Get the module where this item is defined.
		 */
		VisibleModule* getModule() const {
			VisibleModule* mod = safeCast(VisibleModule*, $self->getModule());
			mod->protect();
			return mod;
		}
	}
};

/**
 * A Maude equation.
 */
class Equation : public ModuleItem {
public:
	Equation() = delete;

	%twoSidedObject;
	%labeledObject;

	/**
	 * Whether the equation has the @c nonexec attribute.
	 */
	bool isNonexec() const;
	/**
	 * Whether the equation has a condition.
	 */
	bool hasCondition() const;
	/**
	 * Get the condition of the equation.
	 */
	const Vector<ConditionFragment*>& getCondition() const;

	%streamBasedPrint;
	%getMetadataItem(EQUATION);
	%getLineNumber;
};

/**
 * A Maude sort.
 */
class Sort : public ModuleItem {
public:
	Sort() = delete;

	%rename (kind) component;

	/**
	 * Get the kind this sort belongs to.
	 */
	ConnectedComponent* component() const;
	/**
	 * Get the subsorts of this sort.
	 */
	const Vector<Sort*>& getSubsorts() const;
	/**
	 * Get the supersorts of this sort.
	 */
	const Vector<Sort*>& getSupersorts() const;

	%extend {
		/**
		 * Check whether two sorts are the same.
		 */
		bool equal(Sort* other) {
			return $self == other;
		}

		/**
		 * Check if this sort is a subsort of the given sort.
		 *
		 * @param rhs The right-hand side of the comparison.
		 */
		bool leq(Sort* rhs) const {
			return $self->component() == rhs->component() && leq($self, rhs);
		}

		/**
		 * Get the hash value of the sort.
		 */
		unsigned int hash() const {
			return (unsigned int) (uintptr_t) $self;
		}
	}

	%streamBasedPrint;
	%getLineNumber;
};

%rename (Kind) ConnectedComponent;

/**
 * A Maude kind (connected component of sorts).
 */
class ConnectedComponent {
public:
	ConnectedComponent() = delete;

	/**
	 * Get the number of sorts in this kind.
	 */
	int nrSorts() const;

	/**
	 * Get the sort with a given index in this kind.
	 *
	 * @param index Sort index.
	 */
	Sort* sort(int index) const;

	%extend {
		/**
		 * Check whether two kinds are the same.
		 */
		bool equal(ConnectedComponent* other) {
			return $self == other;
		}

		/**
		 * Get the hash value of the kind.
		 */
		unsigned int hash() const {
			return (unsigned int) (uintptr_t) $self;
		}
	}

	%streamBasedPrint;
};

%rename (MembershipAxiom) SortConstraint;

/**
 * A sort membership axiom.
 */
class SortConstraint {
public:
	SortConstraint() = delete;

	%newobject getLhs;

	%extend {
		/**
		 * Get the term of the membership axiom.
		 */
		EasyTerm* getLhs() const {
			return new EasyTerm($self->getLhs(), false);
		}
	}

	/**
	 * Get the sort of the membership axiom.
	 */
	Sort* getSort() const;

	%labeledObject;
	%streamBasedPrint;
	%getMetadataItem(MEMB_AX);
	%getLineNumber;
};

/**
 * A Maude symbol (operator at the kind level).
 */
class Symbol : public ModuleItem {
public:
	Symbol() = delete;

	%rename (domainKind) domainComponent;
	%rename (hash) getHashValue;

	/**
	 * Get the number of arguments.
	 */
	int arity() const;

	/**
	 * Get the kind for the given argument.
	 *
	 * @param argNr The argument index.
	 */
	const ConnectedComponent* domainComponent(int argNr) const;

	/**
	 * Get the range sort of the symbol.
	 */
	Sort* getRangeSort() const;

	/**
	 * Get the hash value of the symbol.
	 */
	unsigned int getHashValue() const;

	%extend {
		/**
		 * Check whether two symbols are the same.
		 */
		bool equal(Symbol* other) const {
			return $self == other;
		}

		/**
		 * Get the declarations of the symbol.
		 */
		Vector<const OpDeclaration*> getOpDeclarations() const {
			const Vector<OpDeclaration> &decls = $self->getOpDeclarations();
			Vector<const OpDeclaration*> declsp(decls.size());
			for (size_t i = 0; i < decls.size(); ++i)
				declsp[i] = &decls[i];
			return declsp;
		}

		/**
		 * Build a term with this symbol and the given terms as arguments.
		 */
		EasyTerm* makeTerm(const std::vector<EasyTerm*> &args) {
			Vector<DagNode*> dargs(args.size());
			for (size_t i = 0; i < args.size(); ++i)
				dargs[i] = args[i]->getDag();
			return new EasyTerm($self->makeDagNode(dargs));
		}

		/**
		 * Get the metadata attribute of the given declaration of this symbol.
		 *
		 * @param index Index of the operator declaration.
		 */
		const char* getMetadata(int index) {
			int metadata_code = safeCast(VisibleModule*,
				$self->getModule())->getMetadata($self, index);

			return metadata_code == NONE ? nullptr : Token::name(metadata_code);
		}

		/**
		 * Whether the symbol is associative.
		 */
		bool isAssoc() const {
			return dynamic_cast<const AssociativeSymbol*>($self) != 0;
		}
	}

	%namedEntityPrint;
	%getLineNumber;
};

/**
 * Syntactical operator declaration.
 */
class OpDeclaration {
public:
	/**
	 * Get domain and range sorts (range is last).
	 */
	const Vector<Sort*>& getDomainAndRange() const;

	/**
	 * Is the declared operator marked as a data constructor?
	 */
	 bool isConstructor() const;
};

/**
 * A Maude rewrite rule.
 */
class Rule : public ModuleItem {
public:
	Rule() = delete;

	%twoSidedObject;
	%labeledObject;

	/**
	 * Whether the rule has the @c narrowing attribute.
	 */
	bool isNarrowing() const;
	/**
	 * Whether the rule has the @c nonexec attribute.
	 */
	bool isNonexec() const;
	/**
	 * Whether the rule has a condition.
	 */
	bool hasCondition() const;
	/**
	 * Get the condition of the rule.
	 */
	const Vector<ConditionFragment*>& getCondition() const;

	%streamBasedPrint;
	%getMetadataItem(RULE);
	%getLineNumber;
};

/**
 * An expression of the Maude strategy language.
 */
class StrategyExpression {
public:
	StrategyExpression() = delete;
	~StrategyExpression();

	/**
	 * Check whether two strategy expression are the same.
	 *
	 * @note Not accurate (false negatives).
	 */
	bool equal(const StrategyExpression& other) const;

	%streamBasedPrint;
};

/**
 * A named rewriting strategy.
 */
class RewriteStrategy : public ModuleItem {
public:
	RewriteStrategy() = delete;

	/**
	 * Get the argument domain.
	 */
	const Vector<Sort*>& getDomain() const;
	/**
	 * Get the sort to which the strategy is intended to be applied.
	 */
	Sort* getSubjectSort() const;
	/**
	 * Get the definitions for this strategy.
	 */
	const Vector<StrategyDefinition*>& getDefinitions() const;
	/**
	 * Get the number of arguments of the strategy.
	 */
	int arity() const;

	%namedEntityGetName;
	%streamBasedPrint;
	%getMetadataItem(STRAT_DECL);
	%getLineNumber;
};

/**
 * A Maude strategy definition.
 */
class StrategyDefinition : public ModuleItem {
public:
	StrategyDefinition() = delete;

	%newobject getLhs;

	%extend {
		/**
		 * Get the left-hand side of the strategy definition as a term.
		 */
		EasyTerm* getLhs() const {
			return new EasyTerm($self->getLhs(), false);
		}
	}

	/**
	 * Get the strategy definition.
	 */
	StrategyExpression* getRhs() const;

	/**
	 * Get the named strategy being defined.
	 */
	RewriteStrategy* getStrategy() const;

	/**
	 * Whether the strategy definition has the @c nonexec attribute.
	 */
	bool isNonexec() const;
	/**
	 * Whether the strategy definition has a condition.
	 */
	bool hasCondition() const;
	/**
	 * Get the condition of the strategy definition.
	 */
	const Vector<ConditionFragment*>& getCondition() const;

	%labeledObject;
	%streamBasedPrint;
	%getMetadataItem(STRAT_DEF);
	%getLineNumber;
};

/**
 * A syntactical unit.
 */
class Token {
public:
	/**
	 * Get the name of the token.
	 */
	const char* name() const;

	%extend {
		Token(const char* name) {
			Token* token = new Token();
			token->tokenize(name, FileTable::AUTOMATIC);
			return token;
		}

		const char * REPR_METHOD() {
			return $self->name();
		}
	}
};


//
//	Conditions
//

%rename (EqualityCondition) EqualityConditionFragment;
%rename (AssignmentCondition) AssignmentConditionFragment;
%rename (SortTestCondition) SortTestConditionFragment;
%rename (RewriteCondition) RewriteConditionFragment;

/**
 * A generic condition fragment.
 */
class ConditionFragment {
public:
	ConditionFragment() = delete;

	%streamBasedPrint;
};

/**
 * An equality <code>t = t'</code> condition.
 */
class EqualityConditionFragment : public ConditionFragment {
public:
	%extend {
		EqualityConditionFragment(EasyTerm* lhs, EasyTerm* rhs)
		{
			return new EqualityConditionFragment(lhs->termCopy(), rhs->termCopy());
		}
	}

	%twoSidedObject;
	%streamBasedPrint;
};

/**
 * An assignment <code>t := t'</code> condition.
 */
class AssignmentConditionFragment : public ConditionFragment {
public:
	%extend {
		AssignmentConditionFragment(EasyTerm* lhs, EasyTerm* rhs)
		{
			return new AssignmentConditionFragment(lhs->termCopy(), rhs->termCopy());
		}
	}

	%twoSidedObject;
	%streamBasedPrint;
};

/**
 * A rewrite <code>t => t'</code> condition.
 */
class RewriteConditionFragment : public ConditionFragment {
public:
	%extend {
		RewriteConditionFragment(EasyTerm* lhs, EasyTerm* rhs)
		{
			return new RewriteConditionFragment(lhs->termCopy(), rhs->termCopy());
		}
	}

	%twoSidedObject;
	%streamBasedPrint;
};

/**
 * A sort test <code>t : s</code> condition.
 */
class SortTestConditionFragment : public ConditionFragment {
public:

	%newobject getLhs;

	%extend {
		SortTestConditionFragment(EasyTerm* lhs, Sort* rhs)
		{
			return new SortTestConditionFragment(lhs->termCopy(), rhs);
		}

		/**
		 * Get the term of the sort test.
		 */
		EasyTerm* getLhs() const {
			return new EasyTerm($self->getLhs(), false);
		}
	}

	/**
	 * Get the sort of the sort test.
	 */
	Sort* getSort() const;

	%streamBasedPrint;
};

/**
 * Result of LTL model checking.
 */
struct ModelCheckResult {
	%immutable;
	bool holds;			///< Whether the property holds.
	std::vector<int> leadIn;	///< The counterexample path to the cycle.
	std::vector<int> cycle;		///< The counterexample cycle.
	int nrBuchiStates;		///< Number of states in the Büchi automaton.
};

/**
 * Complete rewriting graph from an initial state.
 */
class StateTransitionGraph {
public:
	StateTransitionGraph() = delete;

	%newobject getStateTerm;
	%newobject modelCheck;

	%extend {
		/**
		 * Construct a state transition graph.
		 *
		 * @param term Initial state term (it will be reduced).
		 */
		StateTransitionGraph(EasyTerm* term) {
			RewritingContext* context = new UserLevelRewritingContext(term->getDag());
			context->reduce();
			return new StateTransitionGraph(context);
		}

		/**
		 * Get the term of the given state.
		 *
		 * @param stateNr A state number.
		 */
		EasyTerm* getStateTerm(int stateNr) const {
			return new EasyTerm($self->getStateDag(stateNr));
		}

		/**
		 * Get a rule that connects two states.
		 *
		 * @param origin Origin state number.
		 * @param dest Destination state number.
		 *
		 * @return A rule that connects the two states or null if none.
		 */
		Rule* getRule(int origin, int dest) const {
			auto it = $self->getStateFwdArcs(origin).find(dest);
			if (it == $self->getStateFwdArcs(origin).end())
				return nullptr;
			return it->second.empty() ? nullptr : *it->second.begin();
		}

		/**
		 * Get the number of rewrites used to generate this graph,
		 * including the evaluation of atomic propositions.
		 */
		int getNrRewrites() {
			return $self->getContext()->getTotalCount();
		}

		/**
		 * Model check a given LTL formula.
		 *
		 * @param formula Term of the @c Formula sort.
		 *
		 * @return The result of model checking.
		 */
		ModelCheckResult* modelCheck(EasyTerm* formula) {
			return modelCheck(*$self, formula->getDag());
		}
	}

	/**
	 * Get the number of states in the graph.
	 */
	int getNrStates() const;
	/**
	 * List the successors of a state in the graph.
	 *
	 * @param stateNr A state number.
	 * @param index A child index (from zero).
	 *
	 * @return The state number of a successor or -1.
	 */
	int getNextState(int stateNr, int index);
	/**
	 * Get the (one) parent of a given state.
	 *
	 * @param stateNr A state number.
	 *
	 * @return The state number of the parent or -1.
	 */
	int getStateParent(int stateNr) const;
};

/**
 * Complete rewriting graph under the control of a strategy from an initial state.
 */
class StrategyTransitionGraph {
public:
	StrategyTransitionGraph() = delete;

	%newobject getStateTerm;
	%newobject modelCheck;

	/**
	 * Cause of the transition in the graph.
	 */
	enum TransitionType {
		RULE_APPLICATION,	///< rule application
		OPAQUE_STRATEGY,	///< opaque strategy
		SOLUTION		///< self-loops for solutions
	};

	%rename (StrategyGraphTransition) Transition;

	/**
	 * Structure describing a transition in the graph.
	 */
	struct Transition {
		Transition() = delete;

		/**
		 * Get the transition type (rule application, opaque strategy,
		 * or solution).
		 */
		TransitionType getType() const;
		/**
		 * Get the rule applied, in case the transition is a rule application.
		 *
		 * @return That rule or a null pointer if the transition is not
		 * a rule application.
		 */
		Rule* getRule() const;
		/**
		 * Get the strategy executed, in case of an opaque transition.
		 *
		 * @return That strategy or a null pointer if the transition
		 * is not an opaque strategy.
		 */
		RewriteStrategy* getStrategy() const;

		%extend {
			std::string REPR_METHOD() {
				ostringstream stream;
				switch ($self->getType()) {
					case StrategyTransitionGraph::RULE_APPLICATION:
						stream << $self->getRule();
						return stream.str();
					case StrategyTransitionGraph::OPAQUE_STRATEGY:
						stream << $self->getStrategy();
						return stream.str();
					case StrategyTransitionGraph::SOLUTION:
					default:
						return "solution";
				}
			}
		}
	};

	%extend {
		/**
		 * Construct a strategy transition graph.
		 *
		 * @param initial Initial state term (it will be reduced).
		 * @param strat A strategy expression.
		 * @param opaques A list of strategy names to be considered opaque.
		 * @param biased Whether the matchrews should be biased.
		 */
		StrategyTransitionGraph(EasyTerm* initial, StrategyExpression* strat,
					const std::vector<std::string> &opaques = {}, bool biased=false) {
			RewritingContext* context = new UserLevelRewritingContext(initial->getDag());
			context->reduce();
			set<int> opaqueIds;
			for (auto &name : opaques)
				opaqueIds.insert(Token::encode(name.c_str()));
			// Copy the given strategy, since it will be deleted with this structure
			ImportTranslation translation(dynamic_cast<ImportModule*>(initial->getDag()->symbol()->getModule()));
			StrategyExpression* stratCopy = ImportModule::deepCopyStrategyExpression(&translation, strat);
			TermSet nothing;
			VariableInfo vinfo;
			stratCopy->check(vinfo, nothing);
			stratCopy->process();
			return new StrategyTransitionGraph(context, stratCopy, opaqueIds, biased);
		}

		/**
		 * Get the term of the given state.
		 *
		 * @param stateNr A state number.
		 */
		EasyTerm* getStateTerm(int stateNr) const {
			return new EasyTerm($self->getStateDag(stateNr));
		}

		/**
		 * Get the strategy that will be executed next
		 * from the given state.
		 *
		 * @param stateNr A state number.
		 *
		 * @return That strategy expression or null if there is
		 * no pending strategy in the current call or subsearch frame.
		 */
		StrategyExpression* getStateStrategy(int stateNr) const {
			return $self->getStrategyContinuation(stateNr);
		}

		/**
		 * Get the transition that connects two states (if any).
		 *
		 * @param origin Origin state number.
		 * @param dest Destination state number.
		 *
		 * @return That transition if exists or a null pointer.
		 */
		const Transition* getTransition(int origin, int dest) const {
			auto it = $self->getStateFwdArcs(origin).find(dest);
			if (it == $self->getStateFwdArcs(origin).end())
				return nullptr;
			return it->second.empty() ? nullptr : &*it->second.begin();
		}

		/**
		 * Get the number of rewrites used to generate this graph,
		 * including the evaluation of atomic propositions.
		 */
		int getNrRewrites() {
			return $self->getContext()->getTotalCount();
		}

		/**
		 * Model check a given LTL formula.
		 *
		 * @param formula Term of the @c Formula sort.
		 *
		 * @return The result of model checking.
		 */
		ModelCheckResult* modelCheck(EasyTerm* formula) {
			return modelCheck(*$self, formula->getDag());
		}
	}

	/**
	 * Get the number of states in the graph.
	 */
	int getNrStates() const;
	/**
	 * Get the number of real (not merged) states in the graph (in linear time).
	 */
	int getNrRealStates() const;
	/**
	 * List the successors of a state in the graph.
	 *
	 * @param stateNr A state number.
	 * @param index A child index (from zero).
	 *
	 * @return The state number of a successor or -1.
	 */
	int getNextState(int stateNr, int index);
	/**
	 * Whether the state is a solution for the strategy.
	 *
	 * @param stateNr A state number.
	 */
	bool isSolutionState(int stateNr) const;
};
