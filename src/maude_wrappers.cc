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
#include "module.hh"
#include "interpreter.hh"
#include "global.hh"
#include "syntacticPreModule.hh"
#include "visibleModule.hh"
#include "userLevelRewritingContext.hh"
#include "directoryManager.hh"

// To retrieve the module path (dladdr, non-standard)
#ifdef __APPLE__
#include <dlfcn.h>
#else
#include <link.h>
#endif

#include "maude_wrappers.hh"

#include <vector>

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
init(bool readPrelude)
{
	bool includeFile(const string& directory, const string& fileName, bool silent, int lineNr);
	void createRootBuffer(FILE* fp, bool forceInteractive);
	void checkForPending();

	// The root buffer is the null file
	FILE* fp = fopen("/dev/null", "r");

	createRootBuffer(fp, false);
	directoryManager.initialize();

	// Take the path of the binary as a search directory
	Dl_info dlinfo;
	dladdr((void*) &tokenizeRope, &dlinfo);

	string executable(dlinfo.dli_fname);
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
	return module->isBad() ? nullptr : module;
}

VisibleModule* getModule(const char* name) {
	PreModule* premodule = interpreter.getModule(Token::encode(name));

	if (premodule == nullptr || premodule->getFlatSignature()->isBad())
		return nullptr;

	VisibleModule* module = premodule->getFlatModule();
	return module->isBad() ? nullptr : module;
}
