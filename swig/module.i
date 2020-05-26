//
//	Interface to Maude modules
//

%{
#include "metaLevel.hh"
#include "metaModule.hh"
#include "unificationProblem.hh"
#include "freshVariableSource.hh"
%}

%rename (Module) VisibleModule;

/**
 * A Maude module.
 */
class VisibleModule {
public:
	VisibleModule() = delete;

	%extend {
		~VisibleModule() {
			// Modules are protected so that they are not deleted
			// by Maude while they are still accesible by an object
			// in the target language (if another module with the
			// same name is introduced)
			$self->unprotect();
		}
	}

	/**
	 * Module or theory type (function, system or strategy).
	 */
	enum ModuleType
	{
		FUNCTIONAL_MODULE = 0,				///< Functional module (<code>fmod</code>)
		SYSTEM_MODULE = SYSTEM,				///< System module (<code>mod</code>)
		STRATEGY_MODULE = SYSTEM | STRATEGY,		///< Strategy module (<code>smod</code>)
		FUNCTIONAL_THEORY = THEORY,			///< Functional theory (<code>fth</code>)
		SYSTEM_THEORY = SYSTEM | THEORY,		///< System module (<code>th</code>)
		STRATEGY_THEORY = SYSTEM | STRATEGY | THEORY	///< Strategy module (<code>sth</code>)
	};

	%rename (getKinds) getConnectedComponents;
	%rename (getMembershipAxioms) getSortConstraints;

	/**
	 * Get the module type.
	 *
	 * This allows distinguishing modules from theories, and the
	 * functional, system and strategy variants within them.
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
	const Vector<ConnectedComponent*>& getConnectedComponents() const;
	/**
	 * Get the membership axioms defined in the module.
	 */
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
	 * Is this a parameterized module with free parameters?
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

	%extend {
		/**
		 * Get the theory of the given parameter.
		 */
		VisibleModule* getParameterTheory(int index) const {
			VisibleModule* mod = safeCast(VisibleModule*, $self->getParameterTheory(index));
			mod->protect();
			return mod;
		}

		/**
		 * Get the name of a module parameter.
		 *
		 * @param index Index of the parameter.
		 */
		const char* getParameterName(int index) const {
			return Token::name($self->getParameterName(index));
		}

		/**
		 * Finds a sort by its name in the module.
		 *
		 * @param name The name of the sort.
		 *
		 * @return The sort or null if it does not exist.
		 */
		Sort* findSort(const char* name) const {
			return $self->findSort(Token::encode(name));
		}

		/**
		 * Find a symbol by its name and signature in the module.
		 *
		 * @param name The name of the sort.
		 * @param domainKinds Kinds of the symbol domain.
		 * @param rangeKind Range kind of the symbol.
		 *
		 * @return The symbol or null if it does not exist.
		 */
		Symbol* findSymbol(const char* name,
				 const Vector<ConnectedComponent*>& domainKinds,
				 ConnectedComponent* rangeKind) {
			return $self->findSymbol(Token::encode(name), domainKinds, rangeKind);
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
		 * @param kind Restrict parsing to terms of the given kind.
		 */
		EasyTerm* parseTerm(std::vector<Token> &bubble, ConnectedComponent* kind = nullptr) {
			Vector<Token> bubbleV(bubble.size());

			for (size_t i = 0; i < bubble.size(); i++)
				bubbleV[i] = bubble[i];

			return new EasyTerm($self->parseTerm(bubbleV, kind));

		}

		/**
		 * Parse a term.
		 *
		 * @param term_str A term represented as a string.
		 * @param kind Restrict parsing to terms of the given kind.
		 */
		EasyTerm* parseTerm(const char* term_str, ConnectedComponent* kind = nullptr) {
			Vector<Token> tokens;
			tokenize(term_str, tokens);
			Term* term = $self->parseTerm(tokens, kind);
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

		/**
		 * Get a strategy expression from its metarepresentation in
		 * this module, which must include the @c META-LEVEL module.
		 *
		 * @param term The metarepresentation of a strategy, that is,
		 * a valid element of the @c Strategy sort in @c META-STRATEGY.
		 * The term will be reduced.
		 */
		StrategyExpression* downStrategy(EasyTerm* term) {
			MetaLevel* metaLevel = getMetaLevel($self);

			if (metaLevel == nullptr)
				return nullptr;

			UserLevelRewritingContext context(term->getDag());
			context.reduce();
			return metaLevel->downStratExpr(context.root(), $self);
		}

		/**
		 * Get a module object from its metarepresentation in this
		 * module, which must include the @c META-LEVEL module.
		 *
		 * @param term The metarepresentation of a module, that is,
		 * a valid element of the @c Module sort in @c META-MODULE.
		 * The term will be reduced.
		 */
		VisibleModule* downModule(EasyTerm* term) {
			MetaLevel* metaLevel = getMetaLevel($self);

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
	}

	//
	//	Methods for operations
	//

	%extend {
		/**
		 * Solves the given unification problem.
		 *
		 * @param problem A list of pairs of terms to be unified.
		 *
		 * @returns An object to iterate through unifiers.
		 */
		UnificationProblem* unify(const std::vector<std::pair<EasyTerm*, EasyTerm*>> &problem) {
			size_t nrPairs = problem.size();

			if (nrPairs == 0) {
				IssueWarning("the given unification problem is empty.");
				return nullptr;
			}

			Vector<Term*> lhs(nrPairs);
			Vector<Term*> rhs(nrPairs);

			for (size_t i = 0; i < nrPairs; i++) {
				// Terms are deleted by ~UnificationProblem
				lhs[i] = problem[i].first->termCopy();
				rhs[i] = problem[i].second->termCopy();
			}

			EasyTerm::startUsingModule($self);
			UnificationProblem* unifProblem = new UnificationProblem(lhs, rhs, new FreshVariableSource($self));
			if (unifProblem->problemOK())
				return unifProblem;

			delete unifProblem;
			$self->unprotect();
			return nullptr;
		}

		/**
		 * Solves the given unification problem using variants.
		 *
		 * @param problem A list of pairs of terms to be unified.
		 * @param irreducible Irreducible terms.
		 *
		 * @returns An object to iterate through unifiers.
		 */
		VariantUnifierSearch* variant_unify(const std::vector<std::pair<EasyTerm*, EasyTerm*>> &problem,
					            const std::vector<EasyTerm*> &irreducible = {}) {
			size_t nrPairs = problem.size();

			if (nrPairs == 0) {
				IssueWarning("the given unification problem is empty.");
				return nullptr;
			}

			Vector<Term*> lhs(nrPairs);
			Vector<Term*> rhs(nrPairs);

			for (size_t i = 0; i < nrPairs; i++) {
				// Terms are deleted by makeUnificationProblemDag
				lhs[i] = problem[i].first->termCopy();
				rhs[i] = problem[i].second->termCopy();
			}

			DagNode* d = $self->makeUnificationProblemDag(lhs, rhs);

			size_t nrIrredTerm = irreducible.size();
			Vector<DagNode*> blockerDags(nrIrredTerm);

			for (size_t i = 0; i < nrIrredTerm; i++)
				blockerDags[i] = irreducible[i]->getDag();

			EasyTerm::startUsingModule($self);
			VariantSearch* unifProblem = new VariantSearch(new UserLevelRewritingContext(d),
								       blockerDags,
								       new FreshVariableSource($self),
								       true,
								       false);
			return new VariantUnifierSearch(unifProblem);
		}
	}

	%newobject parseTerm;
	%newobject parseStrategy;
	%newobject downStrategy;
	%newobject downModule;
	%newobject unify;
	%newobject variant_unify;

	%namedEntityPrint;
};

/**
 * An iterator through unifiers.
 */
class UnificationProblem {
public:
	UnificationProblem() = delete;

	%extend {
		/**
		 * Get the next unifier.
		 *
		 * @return That unifier or null pointer if there is no more.
		 */
		EasySubstitution* __next() {
			bool nextMatch = $self->findNextUnifier();
			return nextMatch ? new EasySubstitution(&$self->getSolution(),
								&$self->getVariableInfo())
					 : nullptr;
		}
	}

	%newobject __next;
};

/**
 * An iterator through unifiers for variant unification.
 */
class VariantUnifierSearch {
public:
	VariantUnifierSearch() = delete;

	/**
	 * Whether some unifiers may have been missed due to incomplete unification algorithms.
	 */
	bool isIncomplete() const;

	/**
	 * Get the next unifier.
	 *
	 * @return The next unifier or null if there is no more.
	 */
	EasySubstitution* __next();

	%newobject __next;
};
