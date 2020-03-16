Experimental language bindings for Maude
========================================

Experimental language bindings for Maude using SWIG.

The following sequence builds the Python library:

```
git submodule update --init
meson build --buildtype=custom -Dcpp_args='-O2 -fno-stack-protector -fstrict-aliasing' -Db_lto=true
cd build
ninja
```

It can later be used by writing `import maude` in Python.

Documentation
-------------

In addition to the documentation of functions and classes included in the SWIG and C++ files (copied to the generated Python file by SWIG), the included examples can be used as a reference for:

* Loading files, parsing terms, reducing, rewriting, rewriting with strategies, and searching in `test.py`.
* Matching in `match.py`.
* Manipulating the rewrite graph in `graph.py`.
* Iterating over the arguments of a term in `gui.py`.
* Inspecting modules in `maudedoc.py`.
* Loading files and input raw text in `loading.py`.
