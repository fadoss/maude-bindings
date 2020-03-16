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
%}


//
//	Module items
//

/**
 * An item that belongs to a module.
 */
class ModuleItem {
public:
	ModuleItem() = delete;
	/**
	 * Get the module where this item is defined.
	 */
	VisibleModule* getModule() const;
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
};

/**
 * A Maude sort.
 */
class Sort : public ModuleItem {
public:
	Sort() = delete;

	/**
	 * Get the kind this sort belongs to.
	 */
	%rename (kind) component;
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
		 * Check if this sort is a subsort of the given sort.
		 *
		 * @param rhs The right-hand side of the comparison.
		 */
		bool leq(Sort* rhs) const {
			return leq($self, rhs);
		}
	}

	%namedEntityPrint;
};

%rename (Kind) ConnectedComponent;

/**
 * A Maude kind (connected component of sorts).
 */
class ConnectedComponent {
public:
	ConnectedComponent() = delete;

	%streamBasedPrint;
};

%rename (MembershipAxiom) SortConstraint;

/**
 * A sort membership axiom.
 */
class SortConstraint {
public:
	SortConstraint() = delete;

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

	%newobject getLhs;

	%labeledObject;
	%streamBasedPrint;
};

/**
 * A Maude system (operator at the kind level).
 */
class Symbol : public ModuleItem {
public:
	Symbol() = delete;

	/**
	 * Get the number of arguments.
	 */
	int arity() const;

	/**
	 * Get the kind for the given argument.
	 *
	 * @param argNr The argument number.
	 */
	const ConnectedComponent* domainComponent(int argNr) const;

	/**
	 * Get the range sort of the symbol.
	 */
	Sort* getRangeSort() const;

	%namedEntityPrint;
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
	 * Whether the rule has a condition.
	 */
	bool hasCondition() const;
	/**
	 * Get the condition of the rule.
	 */
	const Vector<ConditionFragment*>& getCondition() const;

	%streamBasedPrint;
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
};

/**
 * A Maude strategy definition.
 */
class StrategyDefinition : public ModuleItem {
public:
	StrategyDefinition() = delete;

	%extend {
		/**
		 * Get the left-hand side of the strategy definition as a Maude term.
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

	%newobject getLhs;

	%labeledObject;
	%streamBasedPrint;
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

%template(Condition) Vector<ConditionFragment*>;

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

	%newobject getLhs;

	%streamBasedPrint;
};

/**
 * Complete rewriting graph from an initial state.
 */
class StateTransitionGraph {
public:
	StateTransitionGraph() = delete;

	%extend {
		/**
		 * Construct a state transition graph.
		 *
		 * @param term Initial state.
		 */
		StateTransitionGraph(EasyTerm* term) {
			RewritingContext* context = new RewritingContext(term->getDag());
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
		 * Get a rule that connectes two states.
		 *
		 * @param origin Origin state number.
		 * @param dest Destination state number.
		 *
		 * @return A rule that connects the two states.
		 */
		Rule* getRule(int origin, int dest) const {
			auto it = $self->getStateFwdArcs(origin).find(dest);
			if (it == $self->getStateFwdArcs(origin).end())
				return nullptr;
			return it->second.empty() ? nullptr : *it->second.begin();
		}
	}

	%newobject getStateTerm;

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

namespace std { %template (StringVector) vector<const char*>; }

/**
 * Complete rewriting graph under the control of a strategy from an initial state.
 */
class StrategyTransitionGraph {
public:
	StrategyTransitionGraph() = delete;

	%extend {
		/**
		 * Construct a strategy transition graph.
		 *
		 * @param initial Initial state.
		 * @param strat A strategy expression.
		 * @param opaques A list of strategy names to be considered opaque.
		 * @param biased Whether the matchrews should be biased.
		 */
		StrategyTransitionGraph(EasyTerm* initial, StrategyExpression* strat,
					const std::vector<const char*> &opaques = {}, bool biased=false) {
			RewritingContext* context = new RewritingContext(initial->getDag());
			set<int> opaqueIds;
			for (const char* name : opaques)
				opaqueIds.insert(Token::encode(name));
			return new StrategyTransitionGraph(context, strat, opaqueIds, biased);
		}

		/**
		 * Get the term of the given state.
		 *
		 * @param stateNr A state number.
		 */
		EasyTerm* getStateTerm(int stateNr) const {
			return new EasyTerm($self->getStateDag(stateNr));
		}
	}

	%newobject getStateTerm;

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
	 * Whether the state is a solution for the strategy.
	 *
	 * @param stateNr A state number.
	 */
	bool isSolutionState(int stateNr) const;
};
