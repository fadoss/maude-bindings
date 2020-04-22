//
//	Experimental language bindings for Maude
//

%module maude
%feature("flatnested", "1");

%{
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <list>

#include "macros.hh"
#include "core.hh"
#include "strategyLanguage.hh"
#include "interface.hh"
#include "mixfix.hh"
#include "higher.hh"

#include "visibleModule.hh"
#include "view.hh"

#include "maude_wrappers.hh"
#include "easyTerm.hh"
%}

%include std_vector.i
%include std_pair.i
%include std_string.i
%include common.i
%include vector.i

namespace std {
	%template (TokenVector) vector<Token>;
	%template (ModuleHeaderVector) vector<ModuleHeader>;
	%template (ViewVector) vector<View*>;
	%template (IntVector) vector<int>;
	%template (TermIntPair) pair<EasyTerm*, int>;
	%template (TermVector) vector<EasyTerm*>;
	%template (StringVector) vector<std::string>;
}

//
// Language-specific additions
//

#if defined(SWIGPYTHON)
%include specific/python.i
#elif defined(SWIGLUA)
%include specific/lua.i
#else
%vectorPrint;
%substitutionPrint;
#endif

//
// Maude internal vector instantiation
//
// These vectors are only used as return types of some observer
// functions in module and other Maude entities, to avoid copying.

%template (OpDeclVector) Vector<const OpDeclaration*>;
%template (SortVector) Vector<Sort*>;
%template (SymbolVector) Vector<Symbol*>;
%template (KindVector) Vector<ConnectedComponent*>;
%template (SubsortVector) Vector<SortConstraint*>;
%template (EquationVector) Vector<Equation*>;
%template (RuleVector) Vector<Rule*>;
%template (StratVector) Vector<RewriteStrategy*>;
%template (StratDefVector) Vector<StrategyDefinition*>;
%template (Condition) Vector<ConditionFragment*>;

//
//	High-level functions
//	(defined in maude_wrappers)
//

/**
 * Init Maude.
 *
 * This function must be called before anything else.
 *
 * @param loadPrelude Whether the Maude prelude should be loaded.
 * @param randomSeed Seed for the pseudorandom number generator in
 * the @c RANDOM module.
 * @param advise Whether debug messages should be printed.
 */
bool init(bool loadPrelude=true, int randomSeed = 0, bool advise = true);

/**
 * Load the file with the given name.
 *
 * @param name The name of the file (absolute or relative to the current
 * working directory or @c MAUDE_LIB).
 */
bool load(const char* name);

/**
 * Process the given text as direct input to Maude.
 *
 * @param text Maude modules or commands.
 */
bool input(const char* text);

/**
 * Get the current module (the last module inserted or explicitly selected,
 * like in the Maude interpreter).
 */
VisibleModule* getCurrentModule();

/**
 * Get a module or theory by name.
 *
 * @param name Name of the module or theory (module expressions are not allowed).
 */
VisibleModule* getModule(const char* name);

/**
 * Tokenize a string according to Maude lexer rules.
 *
 * @param tokenize The string to be tokenized.
 *
 * @returns A vector of tokens.
 */
std::vector<Token> tokenize(const char* str);

/**
 * Get the list of loaded modules.
 *
 * @return A list of module headers (this may change).
 */
std::vector<ModuleHeader> getModules();

/**
 * Get the list of loaded views.
 */
std::vector<View*> getViews();

/**
 * Module header information.
 */
struct ModuleHeader {
	%immutable;

	VisibleModule::ModuleType type;		///< Type of the module (see Module class)
	const char* name;			///< Name of the module

	%streamBasedPrint;
};

%include misc.i
%include term.i
%include module.i
%include view.i
