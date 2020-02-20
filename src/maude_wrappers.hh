/**
 * @file maude_wrappers.hh
 *
 * Wraps some Maude high-level functions.
 */

#include "macros.hh"
#include "vector.hh"
#include "core.hh"

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
 * @param name The name of the file (absolute or relative to the current working directory or MAUDE_LIB).
 */
bool load(const char* name);

/**
 * Process the given text as direct Maude input.
 *
 * @param text Maude modules and/or commands.
 */
bool input(const char* text);

/**
 * Init Maude.
 *
 * @param loadPrelude Whether the Maude prelude should be loaded.
 */
bool init(bool loadPrelude=true);

/**
 * Get a module or theory by name.
 *
 * @param name Name of the module or theory (module expressions are not allowed).
 */
VisibleModule* getModule(const char* name);

/**
 * Get the current module, like in the Maude interpreter.
 */
VisibleModule* getCurrentModule();
