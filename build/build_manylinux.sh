#!/bin/sh
#
# Build script for the maude extension module and package (manylinux)

set -xe

AUXFILES_PKG="https://github.com/fadoss/maude-bindings/releases/download/0.1/manylinux$1-auxfiles.tar.xz"
LIBMAUDE_PKG="https://github.com/fadoss/maudesmc/releases/download/latest/libmaude-manylinux$1.tar.xz"

#
## Install required libraries

sudo yum install -y xz libsigsegv-devel gmp-devel

# A prebuilt package that includes Swig 4 and Buddy and Yices2 headers
curl -L "$AUXFILES_PKG" -O
xz -cd $(basename "$AUXFILES_PKG") | sudo tar -xC /

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

/opt/python/cp38-cp38/bin/python -m pip install --upgrade pip
/opt/python/cp38-cp38/bin/python -m pip install --upgrade ninja cmake scikit-build wheel auditwheel

sudo ln -sf /opt/python/cp38-cp38/bin/ninja /usr/bin/ninja
sudo ln -sf /opt/python/cp38-cp38/bin/cmake /usr/bin/cmake

#
## Build for each Python version

if [ "$1" = "1" ]; then
	versions=(cp27-cp27m cp36-cp36m cp37-cp37m cp38-cp38 cp39-cp39)
else
	versions=(cp36-cp36m cp37-cp37m cp38-cp38 cp39-cp39)
fi

for version in "${versions[@]}"; do
	/opt/python/${version}/bin/python setup.py bdist_wheel -- -DBUILD_LIBMAUDE=OFF
done

for whl in dist/*linux_*.whl; do
	/opt/python/cp38-cp38/bin/auditwheel repair $whl -w /work/dist/
	rm -f $whl
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
