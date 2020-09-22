//
//	Python-specific adaptations
//

#ifndef SWIGPYTHON
#error Python-specific bindings
#endif

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
%pythoncode %{
	def __float__(self):
		return self.toFloat()

	def __int__(self):
		return self.toInt()

	def __eq__(self, other):
		return self.equal(other)
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

%makeIterable(MatchSearchState);

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

		return ', '.join(['{}={}'.format(self.variable(i), self.value(i))
				for i in range(0, len(self))])
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

//
// Defined in misc.i

%extend ConnectedComponent {
%pythoncode %{
	def __iter__(self):
		return VectorIterator(self, len(self))

	def __getitem__(self, n):
		return self.sort(n)

	def __len__(self):
		return self.nrSorts()

	def __eq__(self, other):
		return self.equal(other)
%}
}

%extend Sort {
%pythoncode %{
	def __le__(self, other):
		return self.leq(other)

	def __eq__(self, other):
		return self.equal(other)
%}
}

%extend Symbol {
%pythoncode %{
	def __call__(self, *args):
		return self.makeTerm(args)

	def __eq__(self, other):
		return self.equal(other)
%}
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

	def __len__(self):
		return self.size()
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
			return false;
		}

		(*vect)[i] = f;
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
}
