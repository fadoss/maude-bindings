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

// To retrieve the module path (dladdr, non-standard)
#if defined(_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <dlfcn.h>
#else
#include <link.h>
#endif

#include "maude_wrappers.hh"

#include <vector>
#include <map>

using namespace std;

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
init(bool readPrelude, int randomSeed, bool advise)
{
	bool includeFile(const string& directory, const string& fileName, bool silent, int lineNr);
	void createRootBuffer(FILE* fp, bool forceInteractive);
	void checkForPending();

	// The root buffer is the null file
	FILE* fp = fopen("/dev/null", "r");

	// Set the random seed and the advisory flag
	RandomOpSymbol::setGlobalSeed(randomSeed);
	globalAdvisoryFlag = advise;

	createRootBuffer(fp, false);
	directoryManager.initialize();

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
	// The top buffer we should come back to
	extern YY_BUFFER_STATE inStack[];

	// Parse from the give string
	YY_BUFFER_STATE new_state = yy_scan_string(name);

	UserLevelRewritingContext::ParseResult parseResult = UserLevelRewritingContext::NORMAL;
	while (parseResult == UserLevelRewritingContext::NORMAL) {
		if (yyparse(&parseResult))
			return false;
	}

	yy_delete_buffer(new_state);
	yy_switch_to_buffer(inStack[0]);

	return true;
}

VisibleModule* getCurrentModule() {
	SyntacticPreModule* premodule = interpreter.getCurrentModule();

	if (premodule == nullptr || premodule->getFlatSignature()->isBad())
		return nullptr;

	VisibleModule* module = premodule->getFlatModule();

	if (module->isBad())
		return nullptr;

	module->protect();
	return module;
}

VisibleModule* getModule(const char* name) {
	PreModule* premodule = interpreter.getModule(Token::encode(name));

	if (premodule == nullptr || premodule->getFlatSignature()->isBad())
		return nullptr;

	VisibleModule* module = premodule->getFlatModule();

	if (module->isBad())
		return nullptr;

	module->protect();
	return module;
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

MetaLevel*
getMetaLevel(VisibleModule* mod) {
	// Finds an operator of type MetaLevelOpSymbol for which to obtain
	// the MetaLevel instance. Finding a specific function would be more
	// efficient, but would fail in case or renaming.

	const Vector<Symbol*> &symbols = mod->getSymbols();
	int symbolIndex = mod->getNrUserSymbols() - 1;

	MetaLevelOpSymbol* metaSymbol = nullptr;

	while (metaSymbol == nullptr && symbolIndex >= 0)
		metaSymbol = dynamic_cast<MetaLevelOpSymbol*>(symbols[symbolIndex--]);

	if (metaSymbol == nullptr) {
		IssueWarning("the module does not include the META-LEVEL module.");
		return nullptr;
	}

	return metaSymbol->getMetaLevel();
}
