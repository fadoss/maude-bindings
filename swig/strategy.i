//
//	Interface to strategy expressions
//

%{
#include "applicationStrategy.hh"
#include "branchStrategy.hh"
#include "callStrategy.hh"
#include "concatenationStrategy.hh"
#include "trivialStrategy.hh"
#include "iterationStrategy.hh"
#include "oneStrategy.hh"
#include "subtermStrategy.hh"
#include "unionStrategy.hh"
#include "testStrategy.hh"

#include "choiceStrategy.hh"
#include "sampleStrategy.hh"
#include "weightedSubtermStrategy.hh"
%}

// General procedure to obtain vectors of EasyTerm from vectors of CachedDags
%define %getCachedTermVector(methodName)
	std::vector<EasyTerm*> methodName() const {
		const Vector<CachedDag>& terms = $self->methodName();
		std::vector<EasyTerm*> easyTerms(terms.size());

		for (size_t i = 0; i < terms.size(); ++i)
			easyTerms[i] = new EasyTerm(terms[i].getTerm(), false);

		return easyTerms;
	}
%enddef

/**
 * Trivial strategy (either <code>idle</code> or <code>fail</code>).
 */
class TrivialStrategy : public StrategyExpression {
public:
	TrivialStrategy() = delete;

	/**
	 * Whether the strategy succeeds or not, i.e., whether it is <code>idle</code>.
	 */
	bool getResult() const;

	%streamBasedPrint;
};

%define %matchStratOps
	%newobject getPattern;

	/**
	 * Get the matching depth limit.
	 */
	int getDepth() const;
	/**
	 * Get the condition of the test.
	 */
	const Vector<ConditionFragment*>& getCondition() const;

	%extend {
		/**
		 * Matching pattern of the test.
		 */
		 EasyTerm* getPattern() const {
		 	return new EasyTerm($self->getPatternTerm(), false);
		 }
	}
%enddef

/**
 * Test strategy (either <code>match</code>, <code>xmatch</code>, or <code>amatch</code>).
 */
class TestStrategy : public StrategyExpression {
public:
	TestStrategy() = delete;

	%matchStratOps;
	%streamBasedPrint;
};

/**
 * Rule application strategy
 */
class ApplicationStrategy : public StrategyExpression
{
public:
	ApplicationStrategy() = delete;

	%newobject getSubstitution;

	/**
	 * Whether the rule is applied only on top.
	 */
	bool getTop() const;

	%extend {
		/**
		 * Get the rule label (may be none).
		 */
		const char* getLabel() const {
			return $self->getLabel() != NONE ? Token::name($self->getLabel())
			                                 : nullptr;
		}

		/**
		 * Get the initial substitution
		 */
		EasySubstitution* getSubstitution() const {
			const Vector<Term*>& variables = $self->getVariables();
			const Vector<CachedDag>& values = $self->getValues();

			std::vector<EasyTerm*> easyVariables(variables.size());
			std::vector<EasyTerm*> terms(values.size());

			for (size_t i = 0; i < values.size(); ++i) {
				easyVariables[i] = new EasyTerm(variables[i], false);
				terms[i] = new EasyTerm(values[i].getTerm(), false);
			}

			return new EasySubstitution(easyVariables, terms);
		}
	}

	/**
	 * Strategies to control the rewriting conditions of the rule
	 */
	const Vector<StrategyExpression*>& getStrategies() const;

	%streamBasedPrint;
};

/**
 * Union or disjunction of several strategies.
 */
class UnionStrategy : public StrategyExpression {
public:
	UnionStrategy() = delete;

	/**
	 * Get the alternative strategies
	 */
	const Vector<StrategyExpression*>& getStrategies() const;

	%streamBasedPrint;
};

/**
 * Concatenation, i.e. sequential execution, of several strategies.
 */
class ConcatenationStrategy : public StrategyExpression {
public:
	ConcatenationStrategy() = delete;

	/**
	 * Get the sequence of strategies
	 */
	const Vector<StrategyExpression*>& getStrategies() const;

	%streamBasedPrint;
};

/**
 * Strategy for rewriting of subterms.
 */
class SubtermStrategy : public StrategyExpression {
public:
	SubtermStrategy() = delete;

	/**
	 * Get the strategies to be applied on each matched subterm
	 */
	const Vector<StrategyExpression*>& getStrategies() const;

	%extend {
		/**
		 * Get the variables that match the subterms to be written
		 */
		std::vector<EasyTerm*> getSubterms() const {
			const Vector<Term*>& terms = $self->getSubterms();
			std::vector<EasyTerm*> easyTerms(terms.size());

			for (size_t i = 0; i < terms.size(); ++i)
				easyTerms[i] = new EasyTerm(terms[i], false);

			return easyTerms;
		}
	}

	%matchStratOps;
	%streamBasedPrint;
};

/**
 * Strategy <code>one</code>.
 */
class OneStrategy : public StrategyExpression {
public:
	OneStrategy() = delete;

	/**
	 * Get the strategy for which only one solution is required
	 */
	StrategyExpression* getStrategy() const;

	%streamBasedPrint;
};

/**
 * Iteration strategy.
 */
class IterationStrategy : public StrategyExpression
{
public:
	IterationStrategy() = delete;

	/**
	 * Get the iteration body.
	 */
	StrategyExpression* getStrategy() const;

	/**
	 * Get whether iterating zero times is allowed
	 */
	bool getZeroAllowed() const;

	%streamBasedPrint;
};


/**
 * Strategy call expression.
 */
class CallStrategy : public StrategyExpression
{
public:
	CallStrategy() = delete;

	%newobject getTerm;

	RewriteStrategy* getStrategy() const;

	%extend {
		/**
		 * Get the strategy call arguments as a fake term.
		 */
		EasyTerm* getTerm() {
			return new EasyTerm($self->getTerm(), false);
		}
	}

	%streamBasedPrint;
};

%rename (ConditionalStrategy) BranchStrategy;

%{
enum ConditionalStratType {
	CONDITIONAL,
	OR_ELSE,
	NORMALIZATION,
	TEST,
	TRY,
	NOT,
};
%}

/**
 * Type of a conditional strategy.
 */
enum ConditionalStratType {
	CONDITIONAL,       ///< full conditional strategy
	OR_ELSE,           ///< @c or-else strategy (only failure strategy is non-empty)
	NORMALIZATION,     ///< normalization operator (@c !)
	TEST,              ///< @c test operator
	TRY,               ///< @c try operator
	NOT,               ///< @c not operator
};

/**
 * Conditional strategy (and other related strategy constructs that are reduced to it).
 *
 * Except for the full conditional strategy and for the @c or-else, the success and failure
 * strategies are empty. For the @c or-else, the success strategy is empty too.
 */
class BranchStrategy : public StrategyExpression
{
public:
	BranchStrategy() = delete;

	/**
	 * Get the strategy expression for the condition
	 */
	StrategyExpression* getInitialStrategy() const;
	/**
	 * Get the strategy expression for the success branch
	 */
	StrategyExpression* getSuccessStrategy() const;
	/**
	 * Get the strategy expression for the failure branch
	 */
	StrategyExpression* getFailureStrategy() const;

	%extend {
		/**
		 * Get the type of conditional strategy.
		 */
		ConditionalStratType getType() const {
			using CST = ConditionalStratType;
			using BS = BranchStrategy;

			switch ($self->getSuccessAction()) {
				case BS::NEW_STRATEGY:
					return CST::CONDITIONAL;
				case BS::PASS_THRU:
					return ($self->getFailureAction() == BS::NEW_STRATEGY)
						? CST::OR_ELSE : CST::TRY;
				case BS::ITERATE:
					return CST::NORMALIZATION;
				case BS::IDLE:
					return CST::TEST;
				default: // BS::FAIL
					return CST::NOT;
			}
		}
	}
};

/**
 * Quantified choice strategy
 */
class ChoiceStrategy : public StrategyExpression
{
public:
	ChoiceStrategy() = delete;

	/**
	 * Get the alternative strategies
	 */
	const Vector<StrategyExpression*>& getStrategies() const;

	%extend {
		/**
		 * Get the weights associated to each strategy
		 */
		%getCachedTermVector(getWeights);
	}

	%streamBasedPrint;
};

/**
 * Random sample strategy
 */
class SampleStrategy : public StrategyExpression
{
public:
	SampleStrategy() = delete;

	%newobject getVariable;
	%newobject getArguments;

	/**
	 * Get the strategy expression depending on the sampled value
	 */
	StrategyExpression* getStrategy() const;

	%extend {
		/**
		 * Get the variable to hold the sampled value
		 */
		EasyTerm* getVariable() const {
			return new EasyTerm($self->getVariable(), false);
		}

		/**
		 * Get the name of the probabilistic distribution
		 */
		const char* getDistributionName() const {
			return SampleStrategy::getName($self->getDistribution());
		}

		/**
		 * Get the arguments of the probabilistic distribution
		 */
		%getCachedTermVector(getArguments);
	}

	%streamBasedPrint;
};

/**
 * Subterm rewriting strategy that asssociates a weight to every match
 */
class WeightedSubtermStrategy : public SubtermStrategy
{
public:
	WeightedSubtermStrategy() = delete;

	%newobject getWeight;

	%extend {
		/**
		 * Get the weight term
		 */
		EasyTerm* getWeight() const {
			return new EasyTerm($self->getWeight(), false);
		}
	}

	%streamBasedPrint;
};
