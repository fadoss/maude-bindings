//
//	Interface to Maude modules
//

%template(SortVector) Vector<Sort*>;
%template(SymbolVector) Vector<Symbol*>;
%template(KindVector) Vector<ConnectedComponent*>;
%template(SubsortVector) Vector<SortConstraint*>;
%template(EquationVector) Vector<Equation*>;
%template(RuleVector) Vector<Rule*>;
%template(StratVector) Vector<RewriteStrategy*>;
%template(StratDefVector) Vector<StrategyDefinition*>;

%rename (Module) VisibleModule;

/**
 * A Maude module.
 */
class VisibleModule {
public:
	Module() = delete;

	/**
	 * Module or theory type (function, system or strategy).
	 */
	enum ModuleType
	{
		FUNCTIONAL_MODULE = 0,				///< Functional module (fmod)
		SYSTEM_MODULE = SYSTEM,				///< System module (mod)
		STRATEGY_MODULE = SYSTEM | STRATEGY,		///< Strategy module (smod)
		FUNCTIONAL_THEORY = THEORY,			///< Functional theory (fth)
		SYSTEM_THEORY = SYSTEM | THEORY,		///< System module (th)
		STRATEGY_THEORY = SYSTEM | STRATEGY | THEORY	///< Strategy module (sth)
	};

	/**
	 * Get the module type.
	 */
	ModuleType getModuleType();
	/**
	 * Get the sorts declared in the module.
	 */
	const Vector<Sort*>& getSorts() const;
	/**
	 * Get the symbols declared in the module.
	 */
	const Vector<Symbol*>& getSymbols() const;
	/**
	 * Get the kinds defined in the module.
	 */
	%rename (getKinds) getConnectedComponents;
	const Vector<ConnectedComponent*>& getConnectedComponents() const;
	/**
	 * Get the membership axioms defined in the module.
	 */
	%rename (getMembershipAxioms) getSortConstraints;
	const Vector<SortConstraint*>& getSortConstraints() const;
	/**
	 * Get the equations defined in the module.
	 */
	const Vector<Equation*>& getEquations() const;
	/**
	 * Get the rules defined in the module.
	 */
	const Vector<Rule*>& getRules() const;
	/**
	 * Get the strategies declared in the module.
	 */
	const Vector<RewriteStrategy*>& getStrategies() const;
	/**
	 * Get the strategy definitions defined in the module.
	 */
	const Vector<StrategyDefinition*>& getStrategyDefinitions() const;

	/**
	 * Number of parameters of the parameterized module.
	 */
	int getNrParameters() const;
	/**
	 * Does the module have free parameters?
	 */
	bool hasFreeParameters() const;
	/**
	 * Number of sorts imported from other modules or parameters.
	 */
	int getNrImportedSorts() const;
	/**
	 * Number of symbols imported from other modules or parameters.
	 */
	int getNrImportedSymbols() const;
	/**
	 * Number of strategies imported from other modules or parameters.
	 */
	int getNrImportedStrategies() const;
	/**
	 * Number of equations from this module.
	 */
	int getNrOriginalEquations() const;
	/**
	 * Number of rules from this module.
	 */
	int getNrOriginalRules() const;
	/**
	 * Number of strategy definitions from this module.
	 */
	int getNrOriginalStrategyDefinitions() const;
	/**
	 * Get the theory of the given parameter.
	 */
	VisibleModule* getParameterTheory(int index) const;

	%extend {
		/**
		 * Get the name of a module parameter.
		 *
		 * @param index Index of the parameter.
		 */
		const char* getParameterName(int index) const {
			return Token::name($self->getParameterName(index));
		}
	}

	//
	//	Methods for parsing terms and strategies
	//

	%extend {
		/**
		 * Parse a term.
		 *
		 * @param bubble Tokenized term.
		 * @param component Kind.
		 */
		EasyTerm* parseTerm(std::vector<Token> &bubble, ConnectedComponent* component = nullptr) {
			Vector<Token> bubbleV(bubble.size());

			for (size_t i = 0; i < bubble.size(); i++)
				bubbleV[i] = bubble[i];

			return new EasyTerm($self->parseTerm(bubbleV, component));

		}

		/**
		 * Parse a term.
		 *
		 * @param term_str A term represented as a string.
		 * @param component Kind.
		 */
		EasyTerm* parseTerm(const char* term_str, ConnectedComponent* component = nullptr) {
			Vector<Token> tokens;
			tokenize(term_str, tokens);
			Term* term = $self->parseTerm(tokens, component);
			return term != nullptr ? new EasyTerm(term) : nullptr;
		}

		/**
		 * Parse a strategy expression.
		 *
		 * @param term_str A strategy represented as a string.
		 */
		StrategyExpression* parseStrategy(const char* strat_str) {
			Vector<Token> tokens;
			tokenize(strat_str, tokens);
			return $self->parseStrategyExpr(tokens);
		}
	}

	%newobject parseTerm;
	%newobject parseStrategy;

	%namedEntityPrint;
};
