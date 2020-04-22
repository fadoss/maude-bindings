.. Maude bindings documentation master file, created by
   sphinx-quickstart on Fri Apr  3 19:22:46 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Maude bindings documentation
============================

.. currentmodule:: maude

The experimental :mod:`maude` package allows manipulating terms, modules, and other entities of the Maude_ specification language as Python objects, whose methods expose the operations available as commands in the Maude interpreter. This documentation describes the Python bindings, but most of the API is available for other languages supported by SWIG_. These bindings are based on the latest Maude release extended with a `model checker`_ for systems controlled by the Maude `strategy language`_, which is accessible via the :py:meth:`StrategyTransitionGraph.modelCheck` method.

.. seealso:: `Maude 3.0 manual <http://maude.lcc.uma.es/maude30-manual-html/maude-manual.html>`_ · `Source code <https://github.com/fadoss/maude-bindings>`_ ·  `Package at PyPI <https://pypi.org/project/maude>`_

.. toctree::
   :maxdepth: 2
   :caption: Contents:

First steps
-----------

After loading the :py:mod:`maude` module, the first step should be calling the :py:func:`init` function to initialize Maude and load its prelude. Other modules can be loaded from file with the :py:func:`load` function or inserted verbatim with :py:func:`input`. Any loaded module can be obtained as a :py:class:`Module` object with :py:func:`getModule` or :py:func:`getCurrentModule`, which allow parsing terms with their :py:meth:`~Module.parseTerm` method. The usual Maude commands are represented as homonym methods of the :py:class:`Term` class.


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
   :members: init, load, input, getCurrentModule, getModule, getModules, getViews
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
   :exclude-members: ground

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

   It iterates over matching substitutions of type :py:class:`Substitution`.

.. autoclass:: RewriteSequenceSearch
   :members:
   :undoc-members:

   It iterates over (:py:class:`Term`, :py:class:`Substitution`, function, :py:class:`int`)
   tuples consisting of the solution term, the matching substitution, and the
   number of rewrites until it has been found. The third coordinate is a
   function that returns, when called without arguments, a path to the
   solution, as described in :py:meth:`pathTo`.

.. autoclass:: ArgumentIterator
   :undoc-members:

   It iterates over subterms of type :py:class:`Term`.


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

.. autoclass:: Kind
   :members:
   :undoc-members:

   This is an iterable object over its sorts.

.. autoclass:: MembershipAxiom
   :members:
   :undoc-members:

.. autoclass:: Equation
   :members:
   :undoc-members:

.. autoclass:: Rule
   :members:
   :undoc-members:

.. autoclass:: RewriteStrategy
   :members:
   :undoc-members:

.. autoclass:: StrategyDefinition
   :members:
   :undoc-members:


Rewriting graphs and model checking
-----------------------------------

These two classes give access to the reachable rewriting graphs from an initial
term. Their nodes are terms indexed by integers and their edges are essentially
rule applications. In :py:class:`StrategyTransitionGraph`, rewriting is
controlled by a strategy expression. LTL formulae can be model checked on these
graphs using their ``modelCheck`` methods, obtaining the state indices of the
counterexample in case the property is not satisfied.

.. autoclass:: StateTransitionGraph
   :members:
   :undoc-members:

.. autoclass:: StrategyTransitionGraph
   :members:
   :undoc-members:

.. autoclass:: StrategyGraphTransition
   :members:
   :undoc-members:

.. autoclass:: ModelCheckResult
   :members:
   :undoc-members:


Indices and tables
==================

* :ref:`genindex`
* :ref:`search`

.. :ref:`modindex`

.. _SWIG: http://www.swig.org/
.. _PyPI: https://pypi.org/project/maude/
.. _Maude: http://maude.cs.illinois.edu/
.. _`model checker`: https://github.com/fadoss/maudesmc
.. _`strategy language`: http://maude.ucm.es/strategies
