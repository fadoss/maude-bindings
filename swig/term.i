//
//	Interface to Maude terms and operations
//

%{
#include "strategicSearch.hh"
#include "rewriteSequenceSearch.hh"
#include "pattern.hh"
#include "dagArgumentIterator.hh"
%}

//
//	Simplified interface to Maude terms
//	(defined and documented in easyTerm.cc/hh)
//

%include std_pair.i
namespace std { %template (TermIntPair) pair<EasyTerm*, int>; }

enum SearchType { ONE_STEP, AT_LEAST_ONE_STEP, ANY_STEPS, NORMAL_FORM };

%rename(Term) EasyTerm;
class EasyTerm {
public:
	EasyTerm() = delete;
	~EasyTerm();

	// Information about the term

	Symbol* symbol() const;
	bool ground() const;
	bool equal(const EasyTerm* other) const;
	bool leq(const Sort* sort) const;
	Sort* getSort() const;

	// Maude operations following Maude commands

	int reduce();
	int rewrite(int limit = -1);
	int frewrite(int limit = -1, int gas = -1);
	std::pair<EasyTerm*, int> erewrite(int limit = -1, int gas = -1);

	MatchSearchState* match(EasyTerm* right,
				const Vector<ConditionFragment*> &condition = NO_CONDITION,
				bool withExtension = false);
	StrategicSearch* srewrite(StrategyExpression* expr, bool depth = false);
	RewriteSequenceSearch* search(SearchType type, EasyTerm* target,
				      const Vector<ConditionFragment*> &condition = NO_CONDITION,
				      int depth = -1);

	DagArgumentIterator* arguments();

	EasyTerm* copy() const;
	static const Vector<ConditionFragment*> NO_CONDITION;

	%newobject match;
	%newobject srewrite;
	%newobject search;
	%newobject arguments;
	%newobject copy;

	%streamBasedPrint;
};

//
//	Iterators for the operations that return more than one solution
//

/**
 * An iterator through the solutions of a strategy search
 */
class StrategicSearch {
public:
	StrategicSearch() = delete;

	%extend {
		/**
		 * Get the number of rewrites until the solution has been found.
		 */
		int getRewriteCount() {
			return $self->getContext()->getTotalCount();
		}

		EasyTerm* __next() {
			DagNode* d = $self->findNextSolution();
			return d == nullptr ? nullptr : new EasyTerm(d);
		}
	}

	%newobject __next;

	#if defined(SWIGPYTHON)
	%pythoncode %{
		def __iter__(self):
			return self

		def __next__(self):
			v = self.__next()
			if v is None:
				raise StopIteration

			return v, self.getRewriteCount()

	%}
	#endif
};

%rename (Substitution) EasySubstitution;
class EasySubstitution {
public:
	EasySubstitution() = delete;

	int size() const;
	EasyTerm* variable(int index) const;
	EasyTerm* value(int index) const;
	EasyTerm* matchedPortion() const;

	#if defined(SWIGPYTHON)
	%pythoncode %{
		def __getitem__(self, index):
			return self.variable(index), self.value(index)

		def __len__(self):
			return self.size()

		def __iter__(self):
			return VectorIterator(self, self.size())

		def __repr__(self):
			return 'Subtitution with {} variables'.format(self.size())

		def __str__(self):
			if len(self) == 0:
				return 'empty'

			vector_str = str(self.variable(0)) + '=' + str(self.value(0))
			for i in range(1, len(self)):
				vector_str = vector_str + ', ' + str(self.variable(i)) + '=' + str(self.value(i))

			return vector_str
	%}
	#endif
};

/**
 * An iterator through the matching a term into a pattern
 */
class MatchSearchState {
public:
	MatchSearchState() = delete;

	%extend {
		EasySubstitution* __next() {
			bool nextMatch = $self->findNextMatch();
			return nextMatch ? new EasySubstitution($self->getContext(),
								$self->getPattern(),
								$self->getExtensionInfo())
					 : nullptr;
		}
	}

	%newobject __next;

	#if defined(SWIGPYTHON)
	%pythoncode %{
		def __iter__(self):
			return self

		def __next__(self):
			nxt = self.__next()
			if nxt is None:
				raise StopIteration
			return nxt
	%}
	#endif
};

/**
 * An iterator through the solutions of a search
 */
class RewriteSequenceSearch {
public:
	StrategicSearch() = delete;

	%extend {
		/**
		 * Get the number of rewrites until this term has been found.
		 */
		int getRewriteCount() {
			return $self->getContext()->getTotalCount();
		}

		/**
		 * Get the substitution that make the found term match
		 * into the pattern.
		 */
		EasySubstitution* getSubstitution() {
			return new EasySubstitution($self->getSubstitution(),
						    $self->getGoal(),
						    nullptr);
		}

		/**
		 * Get the rule leading to this term.
		 */
		Rule* getRule() {
			return $self->getStateRule($self->getStateNr());
		}

		/**
		 * Get the rule leading to the given state.
		 * 
		 * @param stateNr The number of a state in the search graph.
		 */
		Rule* getRule(int stateNr) {
			return $self->getStateRule(stateNr);
		}

		/**
		 * Get the term of a given state.
		 * 
		 * @param stateNr The number of a state in the search graph.
		 */
		EasyTerm* getStateTerm(int stateNr) {
			return new EasyTerm($self->getStateDag(stateNr));
		}

		EasyTerm* __next() {
			bool hasNext = $self->findNextMatch();
			return hasNext ? new EasyTerm($self->getStateDag($self->getStateNr())) : nullptr;
		}
	}

	%newobject getSubstitution;
	%newobject getStateTerm;
	%newobject __next;

	/**
	 * Get an internal state number that allows reconstructing 
	 * the path to this term.
	 */
	int getStateNr() const;

	/**
	 * Get the parent state.
	 *
	 * @param stateNr The number of a state in the search graph.
	 *
	 * @return The number of the parent or -1 for the root.
	 */
	int getStateParent(int stateNr) const;

	#if defined(SWIGPYTHON)
	%pythoncode %{
		def __iter__(self):
			return self

		def pathTo(self, stateNr):
			parent = self.getStateParent(stateNr)

			if parent < 0:
				path = [self.getStateTerm(stateNr)]
			else:
				path = self.pathTo(parent)

				path.append(self.getRule(stateNr))
				path.append(self.getStateTerm(stateNr))

			return path

		def __next__(self):
			"""Get term found, the substitution, a function to retrieve"""
			"""the rewriting path to the term, and the rewrite count"""
			term = self.__next()
			if term is None:
				raise StopIteration
			return term, self.getSubstitution(), lambda: self.pathTo(self.getStateNr()), self.getRewriteCount()
	%}
	#endif
};

%rename (ArgumentIterator) DagArgumentIterator;

/**
 * An iterator through the arguments of a term
 */
class DagArgumentIterator {
public:
	DagArgumentIterator() = delete;

	/**
	 * Is this iterator pointing to a valid argument?
	 */
	bool valid() const;

	/**
	 * Advance the iterator to the next argument.
	 */
	void next();

	%extend {
		/**
		 * Get the argument pointed by this iterator
		 */
		EasyTerm* argument() {
			return new EasyTerm($self->argument());
		}
	}

	#if defined(SWIGPYTHON)
	%pythoncode %{
		def __iter__(self):
			return self

		def __next__(self):
			if not self.valid():
				raise StopIteration
			term = self.argument()
			self.next()
			return term
	%}
	#endif
};
