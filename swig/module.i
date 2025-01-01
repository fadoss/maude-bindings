//
//	Interface to Maude modules
//

%{
#include "metaLevel.hh"
#include "metaModule.hh"
#include "unificationProblem.hh"
#include "freshVariableSource.hh"
#include "filteredVariantUnifierSearch.hh"
#include "irredundantUnificationProblem.hh"
#include "pointerMap.hh"
%}

%rename (Module) VisibleModule;

/**
 * A Maude module.
 */
class VisibleModule {
public:
	VisibleModule() = delete;

	%newobject parseTerm;
	%newobject parseStrategy;
	%newobject downTerm;
	%newobject downStrategy;
	%newobject upTerm;
	%newobject upStrategy;
	%newobject unify;
	%newobject variant_unify;
	%newobject variant_match;
	%newobject vu_narrow;
	%newobject getParameterTheory;

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
		SYSTEM_THEORY = SYSTEM | THEORY,		///< System theory (<code>th</code>)
		STRATEGY_THEORY = SYSTEM | STRATEGY | THEORY,	///< Strategy theory (<code>sth</code>)

		OBJECT_ORIENTED_MODULE = SYSTEM | OBJECT_ORIENTED,		///< Object-oriented module (<code>omod</code>)
		OBJECT_ORIENTED_THEORY = SYSTEM | OBJECT_ORIENTED | THEORY	///< Object-oriented theory (<code>oth</code>)
	};

	%rename (getKinds) getConnectedComponents;
	%rename (getMembershipAxioms) getSortConstraints;

	// Keyword arguments are used when available for some of the
	// methods of this class to avoid writing unnecessary arguments

	%feature("kwargs") variant_unify;
	%feature("kwargs") parseStrategy;
	%feature("kwargs") vu_narrow;

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
			return $self->findSort(encodeEscapedToken(name));
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
			return $self->findSymbol(encodeEscapedToken(name), domainKinds, rangeKind);
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
		 * @param vars Variables that may appear without explicit type
		 * annotation in the strategy.
		 */
		EasyTerm* parseTerm(const char* term_str, ConnectedComponent* kind = nullptr, const std::vector<EasyTerm*> &vars = {}) {
			Vector<Token> tokens;
			tokenize(term_str, tokens);

			MixfixModule::AliasMap aliasMap;
			MixfixParser* parser = nullptr;

			if (!vars.empty()) {
				for (EasyTerm* term : vars) {
					if (VariableDagNode* var = dynamic_cast<VariableDagNode*>(term->getDag()))
						aliasMap.insert({var->id(), var->symbol()->getRangeSort()});
					else {
						IssueWarning("the given list of variables contains terms that are not variables.");
						return nullptr;
					}
				}
				$self->swapVariableAliasMap(aliasMap, parser);
			}

			Term* term = $self->parseTerm(tokens, kind);

			if (!vars.empty())
				$self->swapVariableAliasMap(aliasMap, parser);

			return term != nullptr ? new EasyTerm(term) : nullptr;
		}

		/**
		 * Parse a strategy expression.
		 *
		 * @param term_str A strategy represented as a string.
		 * @param vars Variables that may appear without explicit type
		 * annotation in the strategy.
		 */
		StrategyExpression* parseStrategy(const char* strat_str, const std::vector<EasyTerm*> &vars = {}) {
			Vector<Token> tokens;
			tokenize(strat_str, tokens);

			MixfixModule::AliasMap aliasMap;
			MixfixParser* parser = nullptr;

			if (!vars.empty()) {
				for (EasyTerm* term : vars) {
					if (VariableDagNode* var = dynamic_cast<VariableDagNode*>(term->getDag()))
						aliasMap.insert({var->id(), var->symbol()->getRangeSort()});
					else {
						IssueWarning("the given list of variables contains terms that are not variables.");
						return nullptr;
					}
				}
				$self->swapVariableAliasMap(aliasMap, parser);
			}

			StrategyExpression* expr = $self->parseStrategyExpr(tokens);

			if (!vars.empty())
				$self->swapVariableAliasMap(aliasMap, parser);

			return expr;
		}

		/**
		 * Get a term in this module from its metarepresentation
		 * in (possibly) another module.
		 *
		 * @param term The metarepresentation of a term, that is,
		 * a valid element of the @c Term sort in @c META-TERM.
		 * This term must belong to a module where the @c META-LEVEL
		 * module is included. The term will be reduced.
		 *
		 * @return The term or null if the metarepresentation was
		 * not valid.
		 */
		EasyTerm* downTerm(EasyTerm* term) {
			VisibleModule* otherModule = safeCast(VisibleModule*, term->symbol()->getModule());
			MetaLevel* metaLevel = getMetaLevel(otherModule);

			if (metaLevel == nullptr)
				return nullptr;

			UserLevelRewritingContext context(term->getDag());
			context.reduce();

			Term* result = metaLevel->downTerm(context.root(), $self);
			return result == nullptr ? nullptr : new EasyTerm(result);
		}

		/**
		 * Get a strategy expression in this module from its
		 * metarepresentation in (possibly) another module.
		 *
		 * @param term The metarepresentation of a strategy, that is,
		 * a valid element of the @c Strategy sort in @c META-STRATEGY.
		 * This term must belong to a module where the @c META-LEVEL
		 * module is included. The term will be reduced.
		 *
		 * @return The strategy expression or null if the
		 * metarepresentation was not valid.
		 */
		StrategyExpression* downStrategy(EasyTerm* term) {
			VisibleModule* otherModule = safeCast(VisibleModule*, term->symbol()->getModule());
			MetaLevel* metaLevel = getMetaLevel(otherModule);

			if (metaLevel == nullptr)
				return nullptr;

			UserLevelRewritingContext context(term->getDag());
			context.reduce();
			return metaLevel->downStratExpr(context.root(), $self);
		}

		/**
		 * Get the metarepresentation in this module of a term
		 * in (possibly) another module. This module must contain
		 * @c META-LEVEL.
		 *
		 * @param term Any term.
		 *
		 * @return The metarepresentation term or null.
		 */
		EasyTerm* upTerm(EasyTerm* term) {
			VisibleModule* otherModule = safeCast(VisibleModule*, term->symbol()->getModule());
			MetaLevel* metaLevel = getMetaLevel($self);

			if (metaLevel == nullptr)
				return nullptr;

			Term* copy = term->termCopy();
			PointerMap qidMap;
			DagNode* result = metaLevel->upTerm(copy, otherModule, qidMap);
			copy->deepSelfDestruct();
			return result == nullptr ? nullptr : new EasyTerm(result);
		}

		/**
		 * Get the metarepresentation in this module of a strategy
		 * expression in (possibly) another module. This module must
		 * contain @c META-LEVEL.
		 *
		 * @param expr Any strategy expression.
		 *
		 * @return The metarepresented strategy or null.
		 */
		EasyTerm* upStrategy(StrategyExpression* expr) {
			VisibleModule* otherModule = dynamic_cast<VisibleModule*>(getModule(expr));
			MetaLevel* metaLevel = getMetaLevel($self);

			if (metaLevel == nullptr)
				return nullptr;

			// If the strategy is module-independent, the current module is used
			if (otherModule == nullptr)
				otherModule = $self;

			DagNode* result = metaLevel->upStratExpr(expr, otherModule);
			return result == nullptr ? nullptr : new EasyTerm(result);
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
		 * @param irredundant Whether to compute a minimal set of unifiers.
		 *
		 * @returns An object to iterate through unifiers.
		 */
		UnificationProblem* unify(const std::vector<std::pair<EasyTerm*, EasyTerm*>> &problem,
					  bool irredundant = false) {
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
			FreshVariableSource* freshVariableSource = new FreshVariableSource($self);

			UnificationProblem* unifProblem = irredundant ?
				new IrredundantUnificationProblem(lhs, rhs, freshVariableSource) :
				new UnificationProblem(lhs, rhs, freshVariableSource);

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
		 * @param filtered Whether to compute a minimal set of unifiers.
		 *
		 * @returns An object to iterate through unifiers.
		 */
		VariantUnifierSearch* variant_unify(const std::vector<std::pair<EasyTerm*, EasyTerm*>> &problem,
					            const std::vector<EasyTerm*> &irreducible = {},
					            bool filtered = false) {
			size_t nrPairs = problem.size();

			if (nrPairs == 0) {
				IssueWarning("the given unification problem is empty.");
				return nullptr;
			}

			EasyTerm::startUsingModule($self);

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

			UserLevelRewritingContext* context = new UserLevelRewritingContext(d);
			FreshVariableGenerator* freshVariableGenerator = new FreshVariableSource($self);

			VariantSearch* unifProblem = filtered ?
				new FilteredVariantUnifierSearch(context,
								 blockerDags,
								 freshVariableGenerator,
								 VariantSearch::IRREDUNDANT_MODE |
								 VariantSearch::DELETE_FRESH_VARIABLE_GENERATOR |
								 VariantSearch::CHECK_VARIABLE_NAMES) :
				new VariantSearch(context,
						  blockerDags,
						  freshVariableGenerator,
						  VariantSearch::UNIFICATION_MODE |
						  VariantSearch::DELETE_FRESH_VARIABLE_GENERATOR |
						  VariantSearch::CHECK_VARIABLE_NAMES);

			return new VariantUnifierSearch(unifProblem, filtered ? VariantUnifierSearch::FILTERED_UNIFY
									      : VariantUnifierSearch::UNIFY);
		}

		/**
		 * Computes a complete set of order-sorted matches modulo the equations
		 * declared with the variant attribute (which must satisfy the finite
		 * variant property) plus the (supported) equational axioms in the
		 * given module.
		 *
		 * @param problem A list of pairs of terms to be matched.
		 * @param irreducible Irreducible terms.
		 *
		 * @returns An object to iterate through unifiers.
		 */
		VariantUnifierSearch* variant_match(const std::vector<std::pair<EasyTerm*, EasyTerm*>> &problem,
					            const std::vector<EasyTerm*> &irreducible = {}) {
			size_t nrPairs = problem.size();

			if (nrPairs == 0) {
				IssueWarning("the given matching problem is empty.");
				return nullptr;
			}

			EasyTerm::startUsingModule($self);

			Vector<Term*> lhs(nrPairs);
			Vector<Term*> rhs(nrPairs);

			for (size_t i = 0; i < nrPairs; i++) {
				// Terms are deleted by makeMatchProblemDags
				lhs[i] = problem[i].first->termCopy();
				rhs[i] = problem[i].second->termCopy();
			}

			auto mp = $self->makeMatchProblemDags(lhs, rhs);

			UserLevelRewritingContext* patternContext = new UserLevelRewritingContext(mp.first);
			UserLevelRewritingContext* subjectContext = new UserLevelRewritingContext(mp.second);

			size_t nrIrredTerm = irreducible.size();
			Vector<DagNode*> blockerDags(nrIrredTerm);

			for (size_t i = 0; i < nrIrredTerm; i++)
				blockerDags[i] = irreducible[i]->getDag();

			VariantSearch* vs = new VariantSearch(patternContext,
							      blockerDags,
							      new FreshVariableSource($self),
							      VariantSearch::MATCH_MODE |
							      VariantSearch::DELETE_FRESH_VARIABLE_GENERATOR |
							      VariantSearch::DELETE_LAST_VARIANT_MATCHING_PROBLEM |
							      VariantSearch::CHECK_VARIABLE_NAMES);

			if (vs->problemOK()) {
				patternContext->addInCount(*subjectContext);
				(void) vs->makeVariantMatchingProblem(subjectContext);
			}
			else {
				delete vs;
				$self->unprotect();
				return nullptr;
			}

			return new VariantUnifierSearch(vs, VariantUnifierSearch::MATCH);
		}

		/**
		 * Narrowing-based search of terms that unify with the given target
		 * with multiple initial states.
		 *
		 * @param subject Subject terms where to start the search.
		 * @param type Type of the search (number of steps).
		 * @param target Term that found states must unify with.
		 * @param depth Depth bound (@c -1 for unbounded)
		 * @param flags Narrowing search flags (@c fold, @c vfold, @c path, @c delay, or @c filter flag).
		 */
		NarrowingSequenceSearch3* vu_narrow(const std::vector<EasyTerm*>& subject, SearchType type,
							   EasyTerm* target, int depth = -1, int flags = 0) {

			return EasyTerm::vu_narrow(subject, type, target, depth, flags);
		}
	}

	%extend {
		/**
	 	 * Obtain the LaTeX representation of this module.
		 *
		 * @param all Whether to show all statements by transitivity.
		 */
		std::string toLatex(bool all = false) {
			std::ostringstream stream;
			$self->latexShowModule(stream, all);
			return stream.str();
		}
	}

	%namedEntityPrint;
};

/**
 * An iterator through unifiers.
 */
class UnificationProblem {
public:
	UnificationProblem() = delete;

	%newobject __next;

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

		~UnificationProblem() {
			getModule($self)->unprotect();
		}
	}
};

/**
 * An iterator through unifiers or matchers for variant unification or matching.
 */
class VariantUnifierSearch {
public:
	VariantUnifierSearch() = delete;

	%newobject __next;

	/**
	 * Whether some unifiers may have been missed due to incomplete unification algorithms.
	 */
	bool isIncomplete() const;

	/**
	 * Whether filetering was incomplete due to incomplete unification algorithms.
	 */
	bool filteringIncomplete() const;

	/**
	 * Get the next unifier.
	 *
	 * @return The next unifier or null if there is no more.
	 */
	EasySubstitution* __next();

	%unprotectDestructor(VariantUnifierSearch);
};
