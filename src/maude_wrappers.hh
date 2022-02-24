/**
 * @file maude_wrappers.hh
 *
 * Wraps some Maude high-level functions.
 */

#ifndef MAUDE_WRAPPERS_HH
#define MAUDE_WRAPPERS_HH

#include "macros.hh"
#include "vector.hh"
#include "core.hh"
#include "meta.hh"
#include "objectSystem.hh"

#include "visibleModule.hh"
#include "fileManagerSymbol.hh"
#include "processManagerSymbol.hh"
#include "directoryManagerSymbol.hh"
#include "specialHubSymbol.hh"

#include <vector>

// Forward declaration
class EasyTerm;

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
 * Check whether a string contains unescaped special characters.
 *
 * @param str That string.
 */
bool containsSpecialChars(const char* str);

/**
 * Escape the special characters of a string with backquotes.
 *
 * @param str The string to be escaped (must not be null).
 */
std::string escapeWithBackquotes(const char* str);

/**
 * Get the token code of the given string once special characters are escaped.
 *
 * @param str That string.
 */
int encodeEscapedToken(const char* str);

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
 * @param handleInterrupts Whether interrupts are handled by Maude.
 */
bool init(bool loadPrelude=true, int randomSeed=0, bool advise=false,
          bool handleInterrupts=false);

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
 * Result of LTL model checking.
 */
struct ModelCheckResult {
	bool holds;
	std::vector<int> leadIn;
	std::vector<int> cycle;
	int nrBuchiStates;
};

/**
 * Allow or disallow running arbitrary executables from Maude code.
 *
 * @param flag Whether processes should be allowed.
 */
inline void setAllowProcesses(bool flag) {
	ProcessManagerSymbol::setAllowProcesses(flag);
}

/**
 * Allow or disallow operations on files from Maude code.
 *
 * @param flag Whether file access should be allowed.
 */
inline void setAllowFiles(bool flag) {
	FileManagerSymbol::setAllowFiles(flag);
}

/**
 * Allow or disallow operations on directories from Maude code.
 *
 * @param flag Whether directory access should be allowed.
 */
inline void setAllowDir(bool flag) {
	DirectoryManagerSymbol::setAllowDir(flag);
}

/**
 * Set the pseudorandom number generator seed.
 *
 * @param seed New pseudorandom number generator seed.
 */
void setRandomSeed(int seed);

/**
 * Set depth multiplier for associative unification.
 *
 * @param seed New depth multiplier (between 0 and 1e6).
 */
bool setAssocUnifDepth(float m);

/**
 * Data associated to a hook and passed to its callback.
 */
class HookData {
	const std::vector<std::string>& data;
	const SpecialHubSymbol::SymbolHooks& symbols;
	SpecialHubSymbol::TermHooks& terms;

public:
	HookData(const std::vector<std::string>& data,
	         const SpecialHubSymbol::SymbolHooks& symbols,
	         SpecialHubSymbol::TermHooks& terms)
	: data(data), symbols(symbols), terms(terms) {}

	/**
	 * Get the data associated to the hook.
	 */
	const std::vector<std::string>& getData() const;
	/**
	 * Get the symbol associated to the hook with the given name.
	 */
	Symbol* getSymbol(const char* name) const;
	/**
	 * Get the term associated to the hook with the given name.
	 */
	EasyTerm* getTerm(const char* name) const;
};

/**
 * Hooks defined on the external language.
 */
struct Hook {
	/**
	 * Method called by the hook.
	 */
	virtual EasyTerm* run(EasyTerm* term, const HookData* data) = 0;
	virtual ~Hook() {};
};

/**
 * Connect a callback for the reduction of a special operator declared with
 * the @c SpecialHubSymbol id-hook.
 *
 * @param name The name of the operator to be bound to this callback.
 *   In case the id-hook contains arguments, the name is instead the first
 *   of these. A null value may be passed to assign a default callback for
 *   those operators without an explicitly associated one.
 * @param hook An instance of a subclass of Hook defining its run method.
 *   The object must be alive as long as the binding is active. A null value
 *   can be passed to disconnect the current one.
 *
 * @return Whether this call overwrites a previous binding.
 */
bool connectEqHook(const char* name, Hook* hook);

/**
 * Connect a callback for rule rewriting a special operator declared with
 * the @c SpecialHubSymbol id-hook.
 *
 * @param name The name of the operator to be bound to this callback.
 *   In case the id-hook contains arguments, the name is instead the first
 *   of these. A null value may be passed to assign a default callback for
 *   those operators without an explicitly associated one.
 * @param hook An instance of a subclass of Hook defining its run method.
 *   The object must be alive as long as the binding is active. A null value
 *   can be passed to disconnect the current one.
 *
 * @return Whether this call overwrites a previous binding.
 */
bool connectRlHook(const char* name, Hook* hook);


inline const std::vector<std::string>&
HookData::getData() const {
	return data;
}

inline Symbol*
HookData::getSymbol(const char* name) const {
	auto it = symbols.find(name);
	return it != symbols.end() ? it->second : nullptr;
}

#endif // MAUDE_WRAPPERS_HH
