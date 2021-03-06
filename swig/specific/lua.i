//
//	Lua-specific adaptations
//

#ifndef SWIGLUA
#error Lua-specific bindings
#endif

//
// Convert some iterable objects to Lua iterators

%luacode {
	-- Get an iterator from a StrategySearch, MatchSearchState, and less
	-- conveniently from a RewriteSequenceSearch
	function maude.iter(it)
		return function ()
			return it:__next()
		end
	end

	-- Calculate the path to a state in a RewriteSequence
	function maude.pathTo(search, stateNr)
		parent = search:getStateParent(stateNr)

		if parent < 0 then
			path = {search:getStateTerm(stateNr)}
		else
			path = maude.pathTo(search, parent)
			table.insert(path, search:getRule(stateNr))
			table.insert(path, search:getStateTerm(stateNr))
		end

		return path
	end

	-- Get an iterator from a RewriteSequenceSearch
	function maude.siter(it)
		return function ()
			term = it:__next()
			if term then
				return term, it:getSubstitution(),
					(function () return maude.pathTo(it, it:getStateNr()) end),
					it:getRewriteCount()
			end
		end
	end


	-- Get the arguments of a given term as an iterator
	function maude.arguments(t)
		local argiter = t:arguments()
		return function ()
			if argiter:valid() then
				term = argiter:argument()
				argiter:__next()
				return term
			end
		end
	end
}

//
// Pairs should be returned as pairs

%typemap (out) std::pair<EasyTerm*, int> {
	SWIG_NewPointerObj(L, $result.first, SWIGTYPE_p_EasyTerm, 0);
	lua_pushinteger(L, $result.second);
	SWIG_arg += 2;
}

// Trim the strings returned by all function named getMetadata
// to efficiently get rid of the quotes in the internal Maude strings

%typemap(out) const char* getMetadata {
	lua_pushlstring(L, ($1 ? $1 + 1 : 0), ($1 ? strlen($1) - 2 : 0));
	SWIG_arg++;
}

//
// Classes could also be extended (see Stack Overflow question 16360012)

%vectorPrint;
%substitutionPrint;

//
// Signal handlers (does nothing special)

%{
void install_target_signal_handlers(bool) {}
%}
