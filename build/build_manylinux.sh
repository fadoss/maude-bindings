#!/bin/sh
#
# Build script for the maude extension module and package (manylinux)

set -xe

AUXFILES_PKG="https://github.com/fadoss/maude-bindings/releases/download/0.1/manylinux_2_28-auxfiles.tar.xz"
LIBMAUDE_PKG="https://github.com/fadoss/maudesmc/releases/download/latest/libmaude-manylinux_2_28.tar.xz"

#
## Install required libraries

yum install -y xz swig
# already installed: swig cmake ninja

# A prebuilt package with the headers of the libraries (GMP, Buddy, Yices2, libsigsegv)
curl -L "$AUXFILES_PKG" -O
xz -cd $(basename "$AUXFILES_PKG") | tar -xC /

# Get the extended version of Maude from its repository
# and copies Maude's config.h and libmaude.so to the
# locations expected by the cmake script

curl -L "$LIBMAUDE_PKG" -O
mkdir libmaude-pkg
xz -cd $(basename "$LIBMAUDE_PKG")  | tar -xC libmaude-pkg

mkdir -p subprojects/maudesmc/build
mkdir -p subprojects/maudesmc/installdir/lib

mv libmaude-pkg/config.h subprojects/maudesmc/build
mv libmaude-pkg/libmaude.so subprojects/maudesmc/installdir/lib

#
## Install required build tools and overwrite defaults

refversion=cp311-cp311

/opt/python/${refversion}/bin/python -m pip install --upgrade pip
/opt/python/${refversion}/bin/python -m pip install --upgrade wheel auditwheel

#
## Build for each Python version

versions=(cp39-cp39 cp310-cp310 cp311-cp311 cp312-cp312 cp313-cp313)

for version in "${versions[@]}"; do
	/opt/python/${version}/bin/python -m pip install --upgrade scikit-build-core
	CMAKE_ARGS="-DBUILD_LIBMAUDE=OFF" /opt/python/${version}/bin/python -m build
done

for whl in dist/*linux_*.whl; do
	/opt/python/${refversion}/bin/auditwheel repair $whl -w /work/dist/
done

#
## Test the generated packages

cd /tmp

cat > test.py <<TestFileHERE
import maude
maude.init()
print(maude.getCurrentModule())
TestFileHERE

cat > test.expected <<ExpectedFileHERE
CONVERSION
ExpectedFileHERE

for version in "${versions[@]}"; do
	/opt/python/${version}/bin/python -m pip install /work/dist/maude*${version}*manylinux*.whl
	/opt/python/${version}/bin/python test.py > test.out
	cmp test.out test.expected
done
