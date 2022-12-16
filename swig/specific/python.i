//
//	Python-specific adaptations
//

#ifndef SWIGPYTHON
#error Python-specific bindings
#endif

// Include the version number in the package
%pythoncode %{
__version__ = '1.2.1'
%}

%define %makeIterable(CLASS)
%extend CLASS {
%pythoncode %{
	def __iter__(self):
		return self

	def __next__(self):
		nxt = self.__next()
		if nxt is None:
			raise StopIteration
		return nxt
%}
}
%enddef

//
// Defined in module.i

%makeIterable(UnificationProblem);
%makeIterable(VariantUnifierSearch);

//
// Defined in term.i

%extend EasyTerm {

	%define %searchSignature(with_strat)
		search(SearchType type, EasyTerm* target,
		       #if with_strat
		       StrategyExpression* strategy,
		       #endif
	               const Vector<ConditionFragment*> &condition = NO_CONDITION,
		       int depth = -1)
	%enddef

	%rename (_search) %searchSignature(1);
	%feature("shadow") %searchSignature(1) %{ %}

	%feature("shadow") %searchSignature(0) %{
		def search(self, type, target, strategy=None, condition=None, depth=-1):
			r"""
			Search states that match into a given pattern and satisfy a given condition
			by rewriting from this term.

			:type type: int
			:param type: Type of search (number of steps).
			:type target: :py:class:`Term`
			:param target: Pattern term.
			:type strategy: :py:class:`StrategyExpression`, optional
			:param strategy: Strategy to control the search.
			:type condition: :py:class:`Condition` or sequence of condition fragments, optional
			:param condition: Condition that solutions must satisfy.
			:type depth: int, optional
			:param depth: Depth bound

			:rtype: either :py:class:`StrategySequenceSearch` if a strategy is provided or :py:class:`RewriteSequenceSearch`
			:return: An object to iterate through matches.
			"""
			# Fix the case where a condition and not a strategy has been specified
			if strategy is not None and not isinstance(strategy, StrategyExpression):
				if condition is not None:
					depth = condition
				condition, strategy = strategy, None

			if condition is None:
				condition = _maude.cvar.Term_NO_CONDITION

			if strategy is not None:
				return _maude.Term__search(self, type, target, strategy, condition, depth)
			else:
				return _maude.Term_search(self, type, target, condition, depth)
	%}

	%pythoncode %{
		def __eq__(self, other):
			return other is not None and self.equal(other)

		__float__ = toFloat
		__int__ = toInt
		__hash__ = hash
	%}
}

%extend StrategicSearch {
%pythoncode %{
	def __iter__(self):
		return self

	def __next__(self):
		v = self.__next()
		if v is None:
			raise StopIteration
		return v, self.getRewriteCount()
%}
}

%extend MatchSearchState {
%pythoncode %{
	def __iter__(self):
		return self

	def __next__(self):
		nxt = self.__next()
		if nxt is None:
			raise StopIteration
		return nxt, lambda t: self.fillContext(t)
%}
}

%extend RewriteSequenceSearch {
%pythoncode %{
	def __iter__(self):
		return self

	def pathTo(self, stateNr):
		r"""
		Get the path from the initial to the given state.

		:type stateNr: int
		:param stateNr: State index.

		:rtype: list of :py:class:`Term` and :py:class:`Rule`
		:return: A list interleaving terms and rules that connect
		  them from the initial to the given state.
		"""
		parent = self.getStateParent(stateNr)

		if parent < 0:
			path = [self.getStateTerm(stateNr)]
		else:
			path = self.pathTo(parent)

			path.append(self.getRule(stateNr))
			path.append(self.getStateTerm(stateNr))

		return path

	def __next__(self):
		term = self.__next()
		if term is None:
			raise StopIteration
		return term, self.getSubstitution(), lambda: self.pathTo(self.getStateNr()), self.getRewriteCount()
%}
}

%extend StrategySequenceSearch {
%pythoncode %{
	def __iter__(self):
		return self

	def pathTo(self, stateNr):
		r"""
		Get the path from the initial to the given state.

		:type stateNr: int
		:param stateNr: State index.

		:rtype: list of :py:class:`Term` and :py:class:`StrategyGraphTransition`
		:return: A list interleaving terms and transitions that connect
		  them from the initial to the given state.
		"""
		parent = self.getStateParent(stateNr)

		if parent < 0:
			path = [self.getStateTerm(stateNr)]
		else:
			path = self.pathTo(parent)

			path.append(self.getTransition(stateNr))
			path.append(self.getStateTerm(stateNr))

		return path

	def __next__(self):
		term = self.__next()
		if term is None:
			raise StopIteration
		return (term, self.getSubstitution(), lambda: self.pathTo(self.getStateNr()),
		        self.getStrategyContinuation(), self.getRewriteCount())
%}
}

%extend DagArgumentIterator {
%pythoncode %{
	def __iter__(self):
		return self

	def __next__(self):
		if not self.valid():
			raise StopIteration
		term = self.argument()
		self.__next()
		return term
%}
}

%extend EasySubstitution {

	%rename (__iter__) iterator;
	%rename (SubstitutionIterator) Iterator;

%pythoncode %{
	_raw_init = __init__

	def __init__(self, *args):
		if len(args) == 2:
			self._raw_init(*args)
		elif len(args) == 1 and isinstance(args[0], dict):
			self._raw_init(list(args[0].keys()), list(args[0].values()))
		else:
			raise TypeError('__init__() takes either a dictionary or two sequences of Term.')

	def __getitem__(self, variable):
		if isinstance(variable, str):
			return self.find(variable)
		else:
			return self.value(variable)

	__len__ = size

	def __repr__(self):
		return 'Subtitution with {} variables'.format(self.size())

	def __str__(self):
		if len(self) == 0:
			return 'empty'

		return ', '.join(['{}={}'.format(variable, value) for variable, value in self])
%}
}

%extend EasySubstitution::Iterator {
%pythoncode %{
	def __next__(self):
		variable, value = self.getVariable(), self.getValue()

		if variable is None:
			raise StopIteration

		self.nextAssignment()

		return variable, value
%}
}

%extend VariantSearch {
%pythoncode %{
	def __iter__(self):
		return self

	def __next__(self):
		nxt = self.__next()
		if nxt is None:
			raise StopIteration
		return nxt.first, nxt.second
%}
}

%extend NarrowingSequenceSearch3 {
%pythoncode %{
	def __iter__(self):
		return self

	def __next__(self):
		nxt = self.__next()
		if nxt is None:
			raise StopIteration
		return nxt, self.getSubstitution(), self.getUnifier()
%}
}

%extend RewriteSearchState {
%pythoncode %{
	def __iter__(self):
		return self

	def __next__(self):
		nxt = self.__next()
		if nxt is None:
			raise StopIteration
		return nxt, self.getSubstitution(), lambda t: self.fillContext(t), self.getRule()
%}
}

//
// Defined in misc.i

%extend ConnectedComponent {
%pythoncode %{
	def __iter__(self):
		return VectorIterator(self, len(self))

	__getitem__ = sort
	__len__ = nrSorts
	__hash__ = hash

	def __eq__(self, other):
		return other is not None and self.equal(other)
%}
}

%extend Sort {
%pythoncode %{
	def __eq__(self, other):
		return other is not None and self.equal(other)

	__le__ = leq
	__hash__ = hash
%}
}

%extend Symbol {
%pythoncode %{
	def __call__(self, *args):
		return self.makeTerm(args)

	def __eq__(self, other):
		return other is not None and self.equal(other)

	__hash__ = hash
%}
}

%extend SortConstraint {
%pythoncode %{
	__hash__ = hash

	def __eq__(self, other):
		return other is not None and self.equal(other)
%}
}

%extend Equation {
%pythoncode %{
	__hash__ = hash

	def __eq__(self, other):
		return other is not None and self.equal(other)
%}
}

%extend Rule {
%pythoncode %{
	__hash__ = hash

	def __eq__(self, other):
		return other is not None and self.equal(other)
%}
}

%extend StrategyDefinition {
%pythoncode %{
	__hash__ = hash

	def __eq__(self, other):
		return other is not None and self.equal(other)
%}
}

%extend RewriteStrategy {
%pythoncode %{
	__hash__ = hash

	def __eq__(self, other):
		return other is not None and self.equal(other)
%}
}

// Trim the strings returned by all function named getMetadata
// to efficiently get rid of the quotes in the internal Maude strings
%typemap(out) const char* getMetadata {
	$result = SWIG_FromCharPtrAndSize(($1 ? $1 + 1 : 0), ($1 ? strlen($1) - 2 : 0));
}


//
// Defined in vector.i

// Since the iterator defined by Python in the presence of __getitem__
// and __len__ does not stop, VectorIterator is defined to substitute it
%pythoncode %{
class VectorIterator:
	def __init__(self, vect, length):
		self.vect = vect
		self.i = 0
		self.length = length

	def __iter__(self):
		return self

	def __next__(self):
		if self.i >= self.length:
			raise StopIteration
		self.i = self.i + 1
		return self.vect[self.i - 1]
%}

%extend Vector {
%pythoncode %{
	def __iter__(self):
		return VectorIterator(self, len(self))

	def __repr__(self):
		return '{} with {} elements'.format(type(self).__name__, len(self))

	def __str__(self):
		return 'empty' if self.empty() else (
			', '.join([str(self[i]) for i in range(0, len(self))]))

	__len__ = size
%}
}

// Typemap to convert Python sequences into Maude internal vectors
// in input arguments. Hence, internal vectors can be read-only and
// modifiers methods of Vector are removed.

%{
template<typename T>
bool convertVector(PyObject* input, Vector<T*>* &vect, swig_type_info* swig_elem_type) {
	if (!PySequence_Check(input))
		return false;

	size_t size = PySequence_Size(input);
	vect = new Vector<T*>(size);
	for (size_t i = 0; i < size; i++) {
		PyObject *o = PySequence_GetItem(input, i);

		T* f;
		if (!SWIG_IsOK(SWIG_ConvertPtr(o, (void **) &f, swig_elem_type, 0))) {
			delete vect;
			Py_XDECREF(o);
			return false;
		}

		(*vect)[i] = f;
		Py_XDECREF(o);
	}

	return true;
}
%}

%extend Vector {
	// Suppress all modifiers to make internal vectors read-only
	%ignore append;
	%ignore swap;
	%ignore clear;
	%ignore resize;
	%ignore capacity;
	%ignore __setitem__;
	%ignore Vector;

	%typemap(in) const Vector<_Tp> & {
		if (!convertVector($input, $1, $descriptor(_Tp))) {
			PyErr_SetString(PyExc_TypeError, "in method '$symname', argument $argnum of type '$type'");
			SWIG_fail;
		}
	}

	%typemap(typecheck) const Vector<_Tp> & {
		$1 = PySequence_Check($input) ? 1 : 0;
	}

	%typemap(freearg) const Vector<_Tp> & {
		delete $1;
	}

	%typemap(freearg) const Vector<ConditionFragment*> & {
		// The NO_CONDITION constant must not be freed
		if ($1 != &EasyTerm::NO_CONDITION)
			delete $1;
	}
}

// Instruction so that ConditionFragments returned by functions are
// automatically casted to the corresponding subtype

%include factory.i

%factory(ConditionFragment*, EqualityConditionFragment, AssignmentConditionFragment,
         SortTestConditionFragment, RewriteConditionFragment);


//
// Module protection for vectors

%vectorProtections;

//
// Signal handlers

%{
#ifdef _WIN32

void install_target_signal_handlers(bool handledByMaude) { }

#else

#include <signal.h>
#include "userLevelRewritingContext.hh"

//
// Hack to make Ctrl+C abort the current calculation without necessarily
// terminating the program and without entering in an unusable debugger.
// This implies setting the abortFlag of UserLevelRewritingContext, which
// is a private static attribute. The correct way would be subclassing
// UserLevelRewritingContext and redefining its virtual methods.
//

void setMaudeAbortFlags();

template<bool* N>
struct SetAbortFlagsHack {
	friend void setMaudeAbortFlags() {
		*N = true;
	}
};

template struct SetAbortFlagsHack<&UserLevelRewritingContext::abortFlag>;

// Signal handler for SIGINT (Ctrl+C)

void (*user_pysigint)(int);

void pysigint_handler(int sig) {
	// Call the user signal handler
	(*user_pysigint)(sig);

	setMaudeAbortFlags();
	UserLevelRewritingContext::setTraceStatus(true);
}

// Signal handler for other signals

typedef void(*PyUserSignalHandler)(int);
std::map<int, PyUserSignalHandler> user_pysigothers;

void pysigother_handler(int sig) {
	// Call the user signal handler (if using the Python's
	// signal package, this will only mark the signal)
	(*user_pysigothers[sig])(sig);

	// Make Python execute the actual handler and terminate
	// if an exception occurs during its execution
	if (PyErr_CheckSignals() == -1)
		_exit(0);
}

// Install the signal handlers

inline void wrap_pysignal(int signal) {
	struct sigaction sigact;

	sigaction(signal, nullptr, &sigact);

	if (sigact.sa_handler != SIG_IGN && sigact.sa_handler != SIG_DFL) {
		user_pysigothers[signal] = sigact.sa_handler;
		sigact.sa_handler = pysigother_handler;
		sigaction(signal, &sigact, nullptr);
	}
}

void install_target_signal_handlers(bool handledByMaude) {

	if (handledByMaude)
		return;

	// Set up SIGINT (Ctrl+C)
	struct sigaction sigact;
	sigaction(SIGINT, nullptr, &sigact);

	user_pysigint = sigact.sa_handler;
	sigact.sa_handler = pysigint_handler;

	sigaction(SIGINT, &sigact, nullptr);

	// Install wrappers for other signals
	wrap_pysignal(SIGILL);
	wrap_pysignal(SIGSEGV);
	wrap_pysignal(SIGBUS);
	#ifdef SIGINFO
	wrap_pysignal(SIGINFO);
	#endif
	wrap_pysignal(SIGUSR1);
	wrap_pysignal(SIGUSR2);
}
#endif
%}
