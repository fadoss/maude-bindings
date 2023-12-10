/**
 * @file helper_funcs.hh
 *
 * Useful functions not directly accesible from the SWIG interface.
 */

#ifndef HELPER_FUNCS_HH
#define HELPER_FUNCS_HH

#include "meta.hh"

// Forward declaration
class ModelCheckResult;

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

/**
 * Get the module a strategy expression belongs to or null
 * if it is module-independent.
 */
Module* getModule(const StrategyExpression* expr);

#endif // HELPER_FUNCS_HH
