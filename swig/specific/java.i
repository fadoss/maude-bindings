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
%makeIterable(RewriteSearchState, Term);
%makeIterable(MatchSearchState, Substitution);
%makeIterable(RewriteSequenceSearch, Term);
%makeIterable(StrategySequenceSearch, Term);
%makeIterable(VariantSearch, TermSubstitutionPair);
%makeIterable(NarrowingSequenceSearch3, Term);

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
%substitutionPrint;


//
// Defined in misc.i

// Trim the strings returned by all function named getMetadata
// to get rid of the quotes in the internal Maude strings
%typemap(out) const char* getMetadata {
	// The JNI does not support creating a string with a length,
	// so we have to make a temporary copy
	if ($1 == nullptr)
		$result = nullptr;
	else {
		std::string tmp($1 + 1, strlen($1) - 2);
		$result = jenv->NewStringUTF(tmp.c_str());
	}
}


//
// Signal handlers (does nothing special)

%{
void install_target_signal_handlers(bool) {}
%}

