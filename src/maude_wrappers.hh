/**
 * @file maude_wrappers.hh
 *
 * Wraps some Maude high-level functions.
 */

#include "macros.hh"
#include "vector.hh"
#include "core.hh"
#include "meta.hh"

#include <vector>

/**
 * Tokenize a string according to Maude lexer rules.
 *
 * @param str The string to be tokenized.
 *
 * @note For internal use.
 */
void tokenize(const char* str, Vector<Token> &token);

/**
 * Tokenize a string according to Maude lexer rules.
 *
 * @param tokenize The string to be tokenized.
 *
 * @returns A vector of tokens.
 */
std::vector<Token> tokenize(const char* str);

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
 * Init Maude.
 *
 * This function must be called before anything else.
 *
 * @param loadPrelude Whether the Maude prelude should be loaded.
 * @param randomSeed Seed for the pseudorandom number generator in
 * the @c RANDOM module.
 * @param advise Whether debug messages should be printed.
 */
bool init(bool loadPrelude=true, int randomSeed=0, bool advise=false);

/**
 * Get a module or theory by name.
 *
 * @param name Name of the module or theory (module expressions are not allowed).
 */
VisibleModule* getModule(const char* name);

/**
 * Get the current module (the last module inserted or explicitly selected,
 * like in the Maude interpreter).
 */
VisibleModule* getCurrentModule();

/**
 * Module header information.
 */
struct ModuleHeader {
	VisibleModule::ModuleType type;		///< Type of the module
	const char * name;			///< Name of the module
};

std::ostream &operator<<(std::ostream &out, ModuleHeader* mh);

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
 * Result of LTL model checking.
 */
struct ModelCheckResult {
	bool holds;
	std::vector<int> leadIn;
	std::vector<int> cycle;
};

/**
 * Model check.
 *
 * @param graph State-transition graph of the model to be checked.
 * @param formula Term of sort @c Formula in the module of the state graph.
 */
ModelCheckResult* modelCheck(StateTransitionGraph& graph, DagNode* formula);

/**
 * Model check.
 *
 * @param graph State-transition graph of the strategy-controlled
 * model to be checked.
 * @param formula Term of sort @c Formula in the module of the state graph.
 */
ModelCheckResult* modelCheck(StrategyTransitionGraph& graph, DagNode* formula);

/**
 * Get the meta level of a given module.
 */
MetaLevel* getMetaLevel(VisibleModule* mod);
