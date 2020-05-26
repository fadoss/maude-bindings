Experimental language bindings for Maude
========================================

Experimental bindings for the [Maude](http://maude.cs.illinois.edu) specification language using [SWIG](http://www.swig.org). They make use of a [modified version](https://github.com/fadoss/maudesmc) of Maude extended with a model checker for system controlled by strategies, which is also accessible through the bindings.

The Python package is available at [PyPI](https://pypi.org/project/maude). After installing it using `pip install maude`, it can be directly used since Maude is embedded in the package:

```python
import maude
maude.init()
nat = maude.getModule('NAT')
t = nat.parseTerm('1 + 2')
t.reduce()
print(t)
```

Bindings for other languages supported by SWIG can be built from this repository, but they have not been given specific support and testing.


Building
--------

This repository includes the extended version of Maude as a submodule, which has to be cloned first with  `git submodule update --init` or an equivalent Git command. To build the Python package, [scikit-build](https://scikit-build.org) is used:

```
python setup.py bdist_wheel
```

This will cause Maude to be built in the `subprojects` directory, for which the [Meson](https://mesonbuild.com/) build system, [Ninja](https://ninja-build.org/), and various external libraries and tools are required, as described in [its repository](https://github.com/fadoss/maudesmc). Alternatively, compiled versions of Maude as a library can be downloaded from its [releases section](https://github.com/fadoss/maudesmc/releases) and placed in their expected locations:
* `subprojects/maudesmc/installdir/lib` for the libraries, and
* `subprojects/maudesmc/build` for the `config.h` header file.

In this case or when building Maude directly from its subdirectory, `-- -DBUILD_LIBMAUDE=OFF` should be added to the previous command.

Bindings for other languages can also be build using CMake directly, where `srcdir` is the directory where the repository has been cloned, and `language` is one of the languages supported by SWIG:

```
cmake <srcdir> -DLANGUAGE=<language>
cmake --build .
```

For some of them this will be enough, but additional steps could be expected for others.


Documentation
-------------

Documentation for the Python package is available [here](https://fadoss.github.io/maude-bindings), which can be largely extrapolated to other target languages. Javadoc-generated documentation is also [available](https://fadoss.github.io/maude-bindings/javadoc). In addition to these, the examples in the repository can be used as a reference for various topics:

* Loading files, parsing terms, reducing, rewriting, rewriting with strategies, and searching in `test.py`.
* Matching in `match.py`.
* Unification in `unify.py`.
* Manipulating the rewrite graph in `graph.py`.
* Model checking in `modelcheck.py`.
* Narrowing in `vunarrow.py`.
* Variant generation in `variants.py`.
* Iterating over the arguments of a term in `gui.py`.
* Building terms from symbols in `buildTerm.py`.
* Inspecting modules in `maudedoc.py`.
* Loading files and input raw text in `loading.py`.
