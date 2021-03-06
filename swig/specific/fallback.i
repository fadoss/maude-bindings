//
//	Generic code for languages without specific adaptations
//

%vectorPrint;
%substitutionPrint;

//
// Signal handlers (does nothing special)

%{
void install_target_signal_handlers(bool) {}
%}
