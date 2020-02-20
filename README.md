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
