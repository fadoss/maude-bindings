//
//	C#-specific adaptations
//

#ifndef SWIGCSHARP
#error C#-specific bindings
#endif

// Make ToString methods override Object.ToString
%csmethodmodifiers ToString "public override"

// Swig does not expand the non-exported enum Bits in the definition
// of Module, causing compilation errors, so we replace it by hand
%ignore VisibleModule::ModuleType;

%typemap(cscode) VisibleModule %{
  public enum ModuleType {
    FUNCTIONAL_MODULE = 0,
    SYSTEM_MODULE = 1,
    STRATEGY_MODULE = 5,
    FUNCTIONAL_THEORY = 2,
    SYSTEM_THEORY = 3,
    STRATEGY_THEORY = 7
  }
%}

//
// The same adaptations of fallback.i

%vectorPrint;
%substitutionPrint;

//
// Signal handlers (does nothing special)

%{
void install_target_signal_handlers(bool) {}
%}
