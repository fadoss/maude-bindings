//
//	Java-specific adaptations
//

#ifndef SWIGJAVA
#error Java-specific bindings
#endif

%define %makeIterable(CLASS, TELEM)
	%typemap(javaimports) CLASS %{
		import java.util.Iterator;
		import java.util.NoSuchElementException;
	%}
	%typemap(javainterfaces) CLASS "Iterable<TELEM>, Iterator<TELEM>";
	%typemap(javacode) CLASS %{
		private transient TELEM last = null;
		private transient boolean advanced = false;

		public Iterator<TELEM> iterator() {
			return this;
		}

		public boolean hasNext() {
			if (!advanced) {
				last = __next();
				advanced = true;
			}
			return last != null;
		}

		public TELEM next() {
			if (!advanced)
				hasNext();
			if (last == null)
				throw new NoSuchElementException("no more solutions");
			advanced = false;
			return last;
		}
	%}
%enddef

//
// Defined in module.i

%makeIterable(UnificationProblem, Substitution);
%makeIterable(VariantUnifierSearch, Substitution);

//
// Defined in term.i

%makeIterable(StrategicSearch, Term);
%makeIterable(MatchSearchState, Substitution);
%makeIterable(RewriteSequenceSearch, Term);

// DagArgumentIterator

%typemap(javaimports) DagArgumentIterator %{
	import java.util.Iterator;
	import java.util.NoSuchElementException;
%}
%typemap(javainterfaces) DagArgumentIterator "Iterable<Term>, Iterator<Term>";
%typemap(javacode) DagArgumentIterator %{
	public Iterator<Term> iterator() {
		return this;
	}

	public boolean hasNext() {
		return valid();
	}

	public Term next() {
		if (!valid())
			throw new NoSuchElementException("no more solutions");
		Term elem = argument();
		__next();
		return elem;
	}
%}

// Substitution

%typemap(javacode) EasySubstitution %{
	public String toString() {
		int length = size();

		if (length == 0)
			return "empty";

		StringBuilder repr = new StringBuilder();

		repr.append(variable(0) + "=" + value(0));

		for (int i = 1; i < length; i++)
			repr.append(", " + variable(i) + "=" + value(i));

		return repr.toString();
	}
%}

%makeIterable(VariantSearch, TermSubstitutionPair);
%makeIterable(NarrowingSequenceSearch3, Term);

