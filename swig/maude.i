//
//	Experimental language bindings for Maude
//

%module(directors="1") maude
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
#include "narrowing.hh"
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
	%template (TermPair) pair<EasyTerm*, EasyTerm*>;
	%template (TermSubstitutionPair) pair<EasyTerm*, EasySubstitution*>;
	%template (TermPairVector) vector<pair<EasyTerm*, EasyTerm*>>;
}

//
// Language-specific additions
//

#if defined(SWIGPYTHON)
%include specific/python.i
#elif defined(SWIGLUA)
%include specific/lua.i
#elif defined(SWIGJAVA)
%include specific/java.i
#else
%include specific/fallback.i
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
 * @param handleInterrupts Whether interrupts are handled by Maude.
 */
bool init(bool loadPrelude=true, int randomSeed = 0, bool advise = true,
          bool handleInterrupts=false);

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
 * Get a module object from its metarepresentation in this
 * module, which must include the @c META-LEVEL module.
 *
 * @param term The metarepresentation of a module, that is,
 * a valid element of the @c Module sort in @c META-MODULE.
 * The term will be reduced.
 *
 * @return The module object or null if the given term was not
 * a valid module metarepresentation.
 */
VisibleModule* downModule(EasyTerm* term);

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
 * Get a view by name.
 *
 * @param name Name of the view (view expressions are not allowed).
 */
View* getView(const char* name);

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

/**
 * Allow or disallow running arbitrary executables from Maude code.
 *
 * @param flag Whether file access should be allowed.
 */
void setAllowProcesses(bool flag);

/**
 * Allow or disallow operations on files from Maude code.
 *
 * @param flag Whether processes should be allowed.
 */
void setAllowFiles(bool flag);

/**
 * Set the pseudorandom number generator seed.
 *
 * @param seed New pseudorandom number generator seed.
 */
void setRandomSeed(int randomSeed);

// Global constants
constexpr int UNBOUNDED = INT_MAX;

%include misc.i
%include term.i
%include module.i
%include view.i
%include hook.i
