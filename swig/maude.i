//
//	Experimental language bindings for Maude
//

%module maude

%{
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "macros.hh"
#include "core.hh"
#include "strategyLanguage.hh"
#include "interface.hh"
#include "mixfix.hh"
#include "higher.hh"

#include "visibleModule.hh"

#include "maude_wrappers.hh"
#include "easyTerm.hh"
%}

%include std_vector.i
%include vector.i
%include common.i

namespace std { %template(TokenVector) vector<Token>; }

//
//	High-level functions
//	(defined and documented in maude_wrappers)
//

bool init(bool loadPrelude=true);
bool load(const char* name);
bool input(const char* text);
VisibleModule* getCurrentModule();
VisibleModule* getModule(const char* name);
std::vector<Token> tokenize(const char* str);

%include misc.i
%include term.i
%include module.i
