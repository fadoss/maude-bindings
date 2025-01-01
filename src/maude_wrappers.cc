/**
 * @file maude_wrappers.cc
 *
 * Wraps some Maude high-level functions.
 */

#include <climits>
#include <iostream>

#include "macros.hh"
#include "core.hh"
#include "strategyLanguage.hh"
#include "interface.hh"
#include "mixfix.hh"
#include "higher.hh"
#include "meta.hh"
#include "module.hh"
#include "interpreter.hh"
#include "global.hh"
#include "syntacticPreModule.hh"
#include "visibleModule.hh"
#include "userLevelRewritingContext.hh"
#include "directoryManager.hh"
#include "metaLevel.hh"
#include "metaLevelOpSymbol.hh"
#include "randomOpSymbol.hh"
#include "pigPug.hh"

// To retrieve the module path (dladdr, non-standard)
#if defined(_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <dlfcn.h>
#else
#include <link.h>
#endif

// Platform-dependent null file
#if defined(_WIN32)
#define NULL_FILE "nul"
#else
#define NULL_FILE "/dev/null"
#endif

#include "maude_wrappers.hh"

#include <vector>
#include <map>

using namespace std;

// Signal handlers installer that may depend on the target language
extern void install_target_signal_handlers(bool handledByMaude);

// Exported Maude and Flex functions
extern const Vector<int>* tokenizeRope(const Rope& argumentRope);
extern int yyparse(UserLevelRewritingContext::ParseResult*);
struct yy_buffer_state {};

void
tokenize(const char* str, Vector<Token> &tokens)
{
	Rope rope(str);
	const Vector<int>* tokenCodes = tokenizeRope(rope);

	size_t nrTokens = tokenCodes->size();
	tokens.resize(nrTokens);
	for (size_t i = 0; i < nrTokens; i++)
		tokens[i].tokenize((*tokenCodes)[i], 0);
}

vector<Token>
tokenize(const char* str)
{
	Rope rope(str);
	const Vector<int>* tokenCodes = tokenizeRope(rope);

	size_t nrTokens = tokenCodes->size();
	vector<Token> tokens(nrTokens);
	for (size_t i = 0; i < nrTokens; i++)
		tokens[i].tokenize((*tokenCodes)[i], 0);

	return tokens;
}

bool
containsSpecialChars(const char* str)
{
	if (str != nullptr)
		for (char last = 0; *str != '\0'; last = *str, str++)
			if (Token::specialChar(*str) && last != '`')
				return true;

	return false;
}

string
escapeWithBackquotes(const char* str)
{
	string escaped;

	// Add backquotes before special characters if not already there
	for (char last = 0; *str != '\0'; last = *str, str++) {
		if (Token::specialChar(*str) && last != '`')
			escaped.push_back('`');
		escaped.push_back(*str);
	}

	return escaped;
}

int
encodeEscapedToken(const char* str)
{
	// Escape the string only if it is needed
	if (!containsSpecialChars(str))
		return Token::encode(str);

	string escaped = escapeWithBackquotes(str);
	return Token::encode(escaped.c_str());
}

bool
init(bool readPrelude, int randomSeed, bool advise, bool handleInterrupts)
{
	bool includeFile(const string& directory, const string& fileName, bool silent, int lineNr);
	void createRootBuffer(FILE* fp, bool forceInteractive);
	void checkForPending();

	// init should only be executed once
	static bool alreadyInitialized = false;

	if (alreadyInitialized)
		return false;
	else
		alreadyInitialized = true;

	// The root buffer is the null file
	FILE* fp = fopen(NULL_FILE, "r");

	// Set the random seed and the advisory flag
	RandomOpSymbol::setGlobalSeed(randomSeed);
	globalAdvisoryFlag = advise;

	// Signal handling can be tricky and language-dependent (for example,
	// Python-defined signals will not be executed until the interpreter
	// gets the control back). The option handleInterrups sets the Maude
	// signal handlers, but this may print misleading messages attributing
	// to Maude errors that may have been originated by a misuse of the
	// library or to foreign code.

	if (handleInterrupts)
		UserLevelRewritingContext::setHandlers(true);

	// Set up the language-specific actions for signals
	install_target_signal_handlers(handleInterrupts);

	createRootBuffer(fp, false);
	directoryManager.initialize();
	ioManager.setAutoWrap(false);

	// Take the path of the binary as a search directory
	#ifdef _WIN32
	char buffer[FILENAME_MAX];
	GetModuleFileName(GetModuleHandle("libmaude.dll"), buffer, FILENAME_MAX);
	string executable(buffer);
	#else
	Dl_info dlinfo;
	dladdr((void*) &tokenizeRope, &dlinfo);
	string executable(dlinfo.dli_fname);
	#endif

	findExecutableDirectory(executableDirectory, executable);

	if (readPrelude) {
		string directory;
		string fileName(PRELUDE_NAME);
		if (findPrelude(directory, fileName))
			includeFile(directory, fileName, true, FileTable::AUTOMATIC);
		else {
			cerr << "Cannot find Maude prelude (setting MAUDE_LIB environment variable could help)" << endl;
			fclose(fp);
			return false;
		}
	}
	else
		checkForPending();  // because we won't hit an EOF

	ioManager.startCommand();
	UserLevelRewritingContext::ParseResult parseResult = UserLevelRewritingContext::NORMAL;
	while (parseResult == UserLevelRewritingContext::NORMAL) {
		if (yyparse(&parseResult)) {
			fclose(fp);
			return false;
		}
	}

	return true;
}

bool load(const char * name)
{
	bool includeFile(const string& directory, const string& fileName, bool silent, int lineNr);

	int lineNr = lineNumber;
	string directory, fileName;
	if (findFile(name, directory, fileName, lineNr) &&
		includeFile(directory, fileName, true, lineNr))
	{
		UserLevelRewritingContext::ParseResult parseResult = UserLevelRewritingContext::NORMAL;
		while (parseResult == UserLevelRewritingContext::NORMAL) {
			if (yyparse(&parseResult))
				return false;
		}

		return true;
	}

	return false;
}

bool input(const char * name)
{
	// Exported functions from the Flex lexer
	typedef yy_buffer_state* YY_BUFFER_STATE;
	YY_BUFFER_STATE yy_scan_string(const char*);
	void yy_delete_buffer(YY_BUFFER_STATE);
	void yy_switch_to_buffer(YY_BUFFER_STATE);
	void cleanUpParser();
	// The top buffer we should come back to
	extern YY_BUFFER_STATE inStack[];

	// Parse from the give string
	YY_BUFFER_STATE new_state = yy_scan_string(name);

	UserLevelRewritingContext::ParseResult parseResult = UserLevelRewritingContext::NORMAL;
	while (parseResult == UserLevelRewritingContext::NORMAL) {
		if (yyparse(&parseResult)) {
			cleanUpParser();
			return false;
		}
	}

	yy_delete_buffer(new_state);
	yy_switch_to_buffer(inStack[0]);

	return true;
}

VisibleModule* getCurrentModule() {
	SyntacticPreModule* premodule = interpreter.getCurrentModule();

	if (premodule == nullptr || premodule->getFlatSignature()->isBad())
		return nullptr;

	VisibleModule* vmod = premodule->getFlatModule();

	if (vmod->isBad())
		return nullptr;

	vmod->protect();
	return vmod;
}

VisibleModule* getModule(const char* name) {
	PreModule* premodule = interpreter.getModule(Token::encode(name));

	if (premodule == nullptr || premodule->getFlatSignature()->isBad())
		return nullptr;

	VisibleModule* vmod = premodule->getFlatModule();

	if (vmod->isBad())
		return nullptr;

	vmod->protect();
	return vmod;
}

// Dirty hacks to access some private members
// (not to modify Maude for the moment)

template<typename Tag, typename Tag::type M>
struct PrivateHack {
	friend typename Tag::type get(Tag) {
		return M;
	}
};

struct HackModuleMap {
	typedef std::map<int, PreModule*> ModuleDatabase::* type;
	friend type get(HackModuleMap);
};

template struct PrivateHack<HackModuleMap, &ModuleDatabase::moduleMap>;

struct HackViewMap {
	typedef std::map<int, View*> ViewDatabase::* type;
	friend type get(HackViewMap);
};

template struct PrivateHack<HackViewMap, &ViewDatabase::viewMap>;

vector<ModuleHeader>
getModules() {
	const auto &moduleMap = interpreter.*get(HackModuleMap());

	auto it = moduleMap.begin();
	size_t nrModules = moduleMap.size();

	vector<ModuleHeader> modules(nrModules);

	for (size_t i = 0; i < nrModules; i++, it++)
		modules[i] = {it->second->getModuleType(), Token::name(it->second->id())};

	return modules;
}

ostream &operator<<(ostream &out, ModuleHeader* mh) {
	return out << MixfixModule::moduleTypeString(mh->type) << " " << mh->name;
}

View*
getView(const char * name) {
	View* view = interpreter.getView(Token::encode(name));
	return view;
}

vector<View*>
getViews() {
	const auto &viewMap = interpreter.*get(HackViewMap());

	auto it = viewMap.begin();
	size_t nrViews = viewMap.size();

	vector<View*> views(nrViews);

	for (size_t i = 0; i < nrViews; i++, it++)
		views[i] = it->second;

	return views;
}

void setRandomSeed(int seed) {
	RandomOpSymbol::setGlobalSeed(seed);
	#ifdef WITH_PROBABILISTIC_SLANG
	setChoiceSeed(seed);
	#endif
}

bool setAssocUnifDepth(float m) {
	if (isfinite(m) && m >= 0.0 && m <= 1e6) {
		PigPug::setDepthBoundMultiplier(m);
		return true;
	}

	return false;
}

MetaLevel*
getMetaLevel(VisibleModule* vmod) {
	// Finds an operator of type MetaLevelOpSymbol for which to obtain
	// the MetaLevel instance. Finding a specific function would be more
	// efficient, but would fail in case or renaming.

	const Vector<Symbol*> &symbols = vmod->getSymbols();
	int symbolIndex = vmod->getNrUserSymbols() - 1;

	MetaLevelOpSymbol* metaSymbol = nullptr;

	while (metaSymbol == nullptr && symbolIndex >= 0)
		metaSymbol = dynamic_cast<MetaLevelOpSymbol*>(symbols[symbolIndex--]);

	if (metaSymbol == nullptr) {
		IssueWarning("the module does not include the META-LEVEL module.");
		return nullptr;
	}

	return metaSymbol->getMetaLevel();
}
