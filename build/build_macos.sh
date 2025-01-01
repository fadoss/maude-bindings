#!/bin/sh
#
# Build script for the maude extension module and package (Mac)

set -xe

LIBMAUDE_PKG="https://github.com/fadoss/maudesmc/releases/download/latest/libmaude-osx.tar.xz"
LIBMAUDE_ARM_PKG="https://github.com/fadoss/maudesmc/releases/download/latest/libmaude-osx_arm64.tar.xz"
YICES_HEADERS_URL="https://raw.githubusercontent.com/SRI-CSL/yices2/Yices-2.6.1/src/include"

#
## Install required libraries

brew install libsigsegv ninja swig

# Get the extended version of Maude from its repository
# and copies Maude's config.h and libmaude.dylib to the
# locations expected by the cmake script

wget "$LIBMAUDE_PKG"
mkdir libmaude-pkg
tar -xf $(basename "$LIBMAUDE_PKG") -C libmaude-pkg

mkdir -p subprojects/maudesmc/build
mkdir -p subprojects/maudesmc/installdir/lib

mv libmaude-pkg/config.h subprojects/maudesmc/build
mv libmaude-pkg/libmaude.dylib subprojects/maudesmc/installdir/lib

# Download Buddy headers
wget https://sourceforge.net/projects/buddy/files/latest/download -O buddy.tar.gz
tar xzvf buddy.tar.gz

cd buddy-*
mv src/bdd.h ../subprojects/maudesmc/build
cd ..

# Download Yices2 headers
pushd subprojects/maudesmc/build
wget 	"$YICES_HEADERS_URL/yices.h" \
	"$YICES_HEADERS_URL/yices_exit_codes.h" \
	"$YICES_HEADERS_URL/yices_limits.h" \
	"$YICES_HEADERS_URL/yices_types.h"
popd


#
## Install required build tools

python -m pip install --upgrade pip
python -m pip install --upgrade scikit-build-core

#
## Build the extension for x86_64 (without testing)

CMAKE_ARGS="-DBUILD_LIBMAUDE=OFF -DEXTRA_INCLUDE_DIRS=/opt/homebrew/include" \
ARCHFLAGS="-arch x86_64" \
	python -m pip wheel -w dist .


#
## Build the extension for ARM

wget "$LIBMAUDE_ARM_PKG"
mkdir libmaude-arm-pkg
tar -xf $(basename "$LIBMAUDE_ARM_PKG") -C libmaude-arm-pkg

mv libmaude-arm-pkg/config.h subprojects/maudesmc/build
mv libmaude-arm-pkg/libmaude.dylib subprojects/maudesmc/installdir/lib

CMAKE_ARGS="-DBUILD_LIBMAUDE=OFF -DEXTRA_INCLUDE_DIRS=/opt/homebrew/include" \
ARCHFLAGS="-arch arm64" \
	python -m pip wheel -w dist .

#
## Test the generated packages

builddir="$(pwd)"

pushd /tmp

cat > test.py <<TestFileHERE
import maude
maude.init()
print(maude.getCurrentModule())
TestFileHERE

cat > test.expected <<ExpectedFileHERE
CONVERSION
ExpectedFileHERE

python -m pip install "$builddir"/dist/*arm*.whl
python test.py > test.out
cmp test.out test.expected

popd
