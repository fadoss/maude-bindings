.. Maude bindings documentation master file
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

:tocdepth: 3

Maude bindings documentation
============================

.. _main:

.. currentmodule:: maude

The :mod:`maude` package allows manipulating terms, modules, and other entities of the Maude_ specification language as Python objects, whose methods expose the operations available as commands in the Maude interpreter. This documentation describes the Python bindings, but most of the API is available for other languages supported by SWIG_. These bindings are based on the latest Maude release extended with a `model checker`_ for systems controlled by the Maude `strategy language`_, which is accessible via the :py:meth:`StrategyRewriteGraph.modelCheck` method.

.. seealso:: `Maude 3.5 manual <https://maude.lcc.uma.es/maude-manual/>`_ · `Source code <https://github.com/fadoss/maude-bindings>`_ ·  `Package at PyPI <https://pypi.org/project/maude>`_ · :ref:`Bindings for other languages <other-languages>`

.. toctree::
   :maxdepth: 2
   :caption: Contents:
   :hidden:

   babel

First steps
-----------

After loading the :py:mod:`maude` module, the first step should be calling the :py:func:`init` function to initialize Maude and load its prelude. Other modules can be loaded from file with the :py:func:`load` function or inserted verbatim with :py:func:`input`. Any loaded module can be obtained as a :py:class:`Module` object with :py:func:`getModule` or :py:func:`getCurrentModule`, which allow parsing terms with their :py:meth:`~Module.parseTerm` method. The usual Maude commands are represented as homonym methods of the :py:class:`Term` class, except :py:meth:`~Module.unify`, :py:meth:`~Module.variant_unify` and :py:meth:`~Module.variant_match` that belong to the :py:class:`Module` class.


::

   import maude
   maude.init()
   m = maude.getModule('NAT')
   t = m.parseTerm('2 * 3')
   t.reduce()
   print(t)

For example, the snippet above parses the term ``2 * 3`` in the ``NAT`` module (defined in the Maude prelude) and reduces it equationally. The result ``6`` is printed to the standard output.

.. note::
    Loading the package attaches a single session of Maude to the Python process that cannot be refreshed or unloaded. Finer control on the session lifetime and multiple simultaneous instances can be achieved using the :mod:`multiprocessing` module.


.. automodule:: maude
   :members: init, load, input, getCurrentModule, getModule, downModule, getModules, getView, getViews, setAllowFiles, setAllowProcesses, setAllowDir, setRandomSeed, setAssocUnifDepth
   :undoc-members:

.. autoclass:: ModuleHeader
   :members:
   :undoc-members:

Terms
-----

:py:class:`Term` objects represent Maude terms in the context of a module. Their methods include observers (:py:meth:`~Term.arguments`, :py:meth:`~Term.equal`, ...) and command-like operations (:py:meth:`~Term.reduce`, :py:meth:`~Term.rewrite`, ...). Some of the latter are applied destructively, replacing the original term by the result, so a previous :py:meth:`~Term.copy` may be required to preserve the original term if desired. Operations with multiple potential results return iterable objects over them.

.. warning::
   Modules should be understood as closed compartments. In operations involving different terms, symbols or other module items, they must all belong to the same module. Mixing terms from different modules, even if related by inclusion, will not work.

.. autoclass:: Term
   :members:
   :undoc-members:
   :exclude-members: ground, thisown

.. autoclass:: Symbol
   :members:
   :undoc-members:

.. autoclass:: OpDeclaration
   :members:
   :undoc-members:

.. autoclass:: Substitution
   :members:
   :undoc-members:

   Substitution are iterable, and the iterator returns pairs with each variable and value of the mapping.


Search iterators
................

The following classes can be used as usual Python iterators, albeit some offer additional methods.

.. autoclass:: StrategicSearch
   :undoc-members:

   It iterates over (:py:class:`Term`, :py:class:`int`) pairs including the solution term and the
   number of rewrites until it has been reached.

.. autoclass:: MatchSearchState
   :members:
   :undoc-members:

   It iterates over (:py:class:`Substitution`, function) pairs including the matching
   substitution and a function from :py:class:`Term` to :py:class:`Term` that returns the
   matching context filled with the given term.

.. autoclass:: RewriteSearchState
   :members:
   :undoc-members:
   

   It iterates over (:py:class:`Term`, :py:class:`Substitution`, function, :py:class:`Rule`)
   tuples including the resulting term, the matching substitution, a :py:class:`Term`
   to :py:class:`Term` function that provides the matching context filled with the given term,
   and the rule that has been applied.

.. autoclass:: RewriteSequenceSearch
   :members:
   :undoc-members:

   It iterates over (:py:class:`Term`, :py:class:`Substitution`, function, :py:class:`int`)
   tuples consisting of the solution term, the matching substitution, and the
   number of rewrites until it has been found. The third coordinate is a
   function that returns, when called without arguments, a path to the
   solution, as described in :py:meth:`pathTo`.

.. autoclass:: StrategySequenceSearch
   :members:
   :undoc-members:

   It iterates over (:py:class:`Term`, :py:class:`Substitution`, function,
   :py:class:`StrategyExpression`, :py:class:`int`) tuples consisting of the solution term,
   the matching substitution, the next strategy to be executed from the current term, and the
   number of rewrites until it has been found. The third coordinate is a
   function that returns, when called without arguments, a path to the
   solution, as described in :py:meth:`pathTo`.

.. autoclass:: NarrowingSequenceSearch
   :members:
   :undoc-members:

   It iterates over (:py:class:`Term`, :py:class:`Substitution`, :py:class:`Substitution`)
   tuples, consisting of the solution, the accumulated substitution, and the variant unifer.

.. autoclass:: VariantSearch
   :members:
   :undoc-members:

   It iterates over (:py:class:`Term`, :py:class:`Substitution`) pairs
   describing the variants.

.. autoclass:: UnificationProblem
   :members:
   :undoc-members:

   It iterates over unifiers of type :py:class:`Substitution`.

.. autoclass:: VariantUnifierSearch
   :members:
   :undoc-members:

   It iterates over unifiers of type :py:class:`Substitution`.

.. autoclass:: ArgumentIterator
   :undoc-members:

   It iterates over subterms of type :py:class:`Term`.


Search types
............

.. autodata:: ANY_STEPS
   :annotation:

.. autodata:: AT_LEAST_ONE_STEP
   :annotation:

.. autodata:: ONE_STEP
   :annotation:

.. autodata:: NORMAL_FORM
   :annotation:

.. autodata:: BRANCH
   :annotation:


Print flags
...........

.. autodata:: PRINT_CONCEAL
   :annotation:

.. autodata:: PRINT_FORMAT
   :annotation:

.. autodata:: PRINT_MIXFIX
   :annotation:

.. autodata:: PRINT_WITH_PARENS
   :annotation:

.. autodata:: PRINT_COLOR
   :annotation:

.. autodata:: PRINT_DISAMBIG_CONST
   :annotation:

.. autodata:: PRINT_FLAT
   :annotation:

.. autodata:: PRINT_NUMBER
   :annotation:

.. autodata:: PRINT_RAT
   :annotation:


Narrowing flags
...............

.. autodata:: FOLD
   :annotation:

.. autodata:: VFOLD
   :annotation:

.. autodata:: PATH
   :annotation:

.. autodata:: DELAY
   :annotation:

.. autodata:: FILTER
   :annotation:


Conditions
..........

Conditions are sequences of condition fragments of any of the four types described below. They should be provided as Python lists to methods like :py:meth:`Term.search`, and they are returned as Maude internal vectors in other methods like :py:meth:`Rule.getCondition`. Maude internal vectors are read-only iterable objects, whose elements can also be accessed by index.

.. autoclass:: Condition
   :members:
   :undoc-members:

.. autoclass:: EqualityCondition
   :members:
   :undoc-members:
   :show-inheritance:

.. autoclass:: AssignmentCondition
   :members:
   :undoc-members:
   :show-inheritance:

.. autoclass:: SortTestCondition
   :members:
   :undoc-members:
   :show-inheritance:

.. autoclass:: RewriteCondition
   :members:
   :undoc-members:
   :show-inheritance:

Modules
-------

The :py:class:`Module` class gives access to module information including its components: :py:class:`Sort`, :py:class:`Kind`, :py:class:`Equation`, :py:class:`MembershipAxiom`, :py:class:`Rule`, :py:class:`RewriteStrategy` (strategy declarations) and :py:class:`StrategyDefinition`.
Terms and strategy expressions can be parsed by means of the :py:meth:`~Module.parseTerm` and :py:meth:`~Maude.parseStrategy` functions.
Modules can be obtained with :py:func:`getCurrentModule`, :py:func:`getModule`, :py:func:`~Module.downModule`, and some other specific functions.

.. autoclass:: Module
   :members:
   :undoc-members:

Module items
............

.. autoclass:: Sort
   :members:
   :undoc-members:
   :exclude-members: hash, equal, thisown

.. autoclass:: Kind
   :members:
   :undoc-members:
   :exclude-members: hash, equal, thisown

   This is an iterable object over its sorts.

.. autoclass:: MembershipAxiom
   :members:
   :undoc-members:
   :exclude-members: hash, equal, thisown

.. autoclass:: Equation
   :members:
   :undoc-members:
   :exclude-members: hash, equal, thisown

.. autoclass:: Rule
   :members:
   :undoc-members:
   :exclude-members: hash, equal, thisown

.. autoclass:: RewriteStrategy
   :members:
   :undoc-members:
   :exclude-members: hash, equal, thisown

.. autoclass:: StrategyDefinition
   :members:
   :undoc-members:
   :exclude-members: hash, equal, thisown

Operator attributes
...................

.. autodata:: OP_ASSOC
   :annotation:

.. autodata:: OP_COMM
   :annotation:

.. autodata:: OP_ITER
   :annotation:

.. autodata:: OP_IDEM
   :annotation:

.. autodata:: OP_LEFT_ID
   :annotation:

.. autodata:: OP_RIGHT_ID
   :annotation:

.. autodata:: OP_MEMO
   :annotation:

.. autodata:: OP_SPECIAL
   :annotation:


Rewriting graphs and model checking
-----------------------------------

These two classes give access to the reachable rewriting graphs from an initial
term. Their nodes are terms indexed by integers and their edges are essentially
rule applications. In :py:class:`StrategyRewriteGraph`, rewriting is
controlled by a strategy expression. LTL formulae can be model checked on these
graphs using their ``modelCheck`` methods, obtaining the state indices of the
counterexample in case the property is not satisfied.

.. autoclass:: RewriteGraph
   :members:
   :undoc-members:

.. autoclass:: StrategyRewriteGraph
   :members:
   :undoc-members:

.. autoclass:: StrategyGraphTransition
   :members:
   :undoc-members:

.. autoclass:: ModelCheckResult
   :members:
   :undoc-members:


Custom special operators
------------------------

Special operators in Maude are those whose semantics are given in the C++ code of its interpreter, as opposed to the usual ones	 that are defined by means of equations and rules. Using the elements described below, new special operators can be declared whose behavior is implemented in Python. The process involves three steps:

1. Declaring in Maude the desired operator with a ``special`` attribute containing the fragment ``id-hook SpecialHubSymbol``. Additionally, ``op-hook`` and ``term-hook`` bindings can be included in the attribute to let the Python implementation access some given symbols and terms through the :py:class:`HookData` class.
2. Defining in Python the behavior of the special operator whenever it is reduced equationally or rewritten. A subclass of :py:class:`Hook` must define its :py:meth:`~Hook.run` method that produces the reduced or rewritten term.
3. Associating a :py:class:`Hook` instance with an special operator using the functions :py:func:`connectEqHook` for equational rewriting or :py:func:`connectRlHook` for rule rewriting.


For example, the following is the declaration in Maude of a function ``getenv`` to obtain the value of an environment variable:

.. code-block:: maude

   op getenv : String ~> String [special (
       id-hook SpecialHubSymbol
   )] .

This declaration alone makes ``getenv`` behave as a standard operator, and its special meaning should be given within Python:

::

   class EnvironmentHook(maude.Hook):
       def run(self, term, data):
           module = term.symbol().getModule()
           term.reduce()
           envar = str(term)[1:-1]
           enval = os.getenv(envar)
           return module.parseTerm(f'"{enval}"') if enval is not None else None

   envhook = EnvironmentHook()
   maude.connectEqHook('getenv', envhook)

The terms passed to the Python implementation do not have their subterms reduced, but these arguments must be reduced if included in the resulting term. ``None`` is an admitted return value that is interpreted as the absence of rewrite at that symbol. In this case, ``getenv`` is a partial function that does not yield a string when the given environment variable does not exist.

.. warning::
   This feature is experimental and may be subject to changes. Do not forget that Maude programs including these special operators will not be executable in the official Maude interpreter.

.. autoclass:: Hook
   :members:
   :undoc-members:

.. autoclass:: HookData
   :members:
   :undoc-members:

.. autofunction:: connectEqHook

.. autofunction:: connectRlHook


Indices and tables
==================

* :ref:`genindex`
* :ref:`search`

.. :ref:`modindex`

.. _SWIG: https://www.swig.org/
.. _PyPI: https://pypi.org/project/maude/
.. _Maude: https://maude.cs.illinois.edu/
.. _`model checker`: https://github.com/fadoss/maudesmc
.. _`strategy language`: https://maude.ucm.es/strategies
