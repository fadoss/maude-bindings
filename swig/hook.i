//
//	Interface to Maude special operators
//

%immutable HookData;

/**
 * Data associated to a hook and passed to its callback.
 */
struct HookData {
	HookData() = delete;

	%newobject getTerm;

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

%feature("director") Hook;

/**
 * Special operators defined on the external language.
 */
struct Hook {
	/**
	 * Method called by the hook.
	 *
	 * @param term The term being reduced or rewritten.
	 * @param data Data associated to the hook.
	 *
	 * @return The reduced or rewritten term, or a null value in case
	 * no rewrite is possible.
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
