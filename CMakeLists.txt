cmake_minimum_required(VERSION 3.12)
project(maude)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/build;${CMAKE_MODULE_PATH}")
set(MAUDESMC_PATH "${CMAKE_SOURCE_DIR}/subprojects/maudesmc")

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
set(CMAKE_INSTALL_RPATH @loader_path)
else()
set(CMAKE_INSTALL_RPATH $ORIGIN)
endif()

if (POLICY CMP0078)
cmake_policy(SET CMP0078 NEW)
endif()
if (POLICY CMP0086)
cmake_policy(SET CMP0086 NEW)
endif()

find_package(PythonExtensions REQUIRED)
find_package(SWIG REQUIRED)
include(ExternalProject)
include(UseSWIG)

#
## Build script options

option(BUILD_LIBMAUDE "build libmaude before building the extension")
set(EXTRA_INCLUDE_DIRS "" CACHE PATH "Additional include paths")
set(EXTRA_INSTALL_FILES "" CACHE PATH "Additional files to be installed")

#
## Build libmaude.so using Meson

if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
add_library(libmaude STATIC IMPORTED)
set_property(TARGET libmaude PROPERTY IMPORTED_LOCATION
	"${MAUDESMC_PATH}/installdir/lib/libmaude.dll.a")
else()
add_library(libmaude SHARED IMPORTED)
set_property(TARGET libmaude PROPERTY IMPORTED_LOCATION
	"${MAUDESMC_PATH}/installdir/lib/libmaude${CMAKE_SHARED_LIBRARY_SUFFIX}")
endif()

if (BUILD_LIBMAUDE)

ExternalProject_Add(maudesmc
	SOURCE_DIR "${MAUDESMC_PATH}"
	BINARY_DIR "${MAUDESMC_PATH}/build"
	CONFIGURE_COMMAND meson . .. --buildtype=custom
		"-Dcpp_args=-O2 -fno-stack-protector -fstrict-aliasing"
		-Db_lto=true
		-Dwith-ltsmin=disabled
		-Dwith-smt=no
		-Dstrip=true
		-Dlibdir=lib
		-Dprefix=/
	BUILD_COMMAND ninja
	BUILD_BYPRODUCTS "${MAUDESMC_PATH}/installdir/lib/libmaude${CMAKE_SHARED_LIBRARY_SUFFIX}"
	INSTALL_COMMAND "DESTDIR=${MAUDESMC_PATH}/installdir" ninja install
	INSTALL_DIR "${MAUDESMC_PATH}/installdir"
)

add_dependencies(_maude maudesmc)

endif()

#
## Build the SWIG extension module and wrappers

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -s")

include_directories(
	"${CMAKE_SOURCE_DIR}/src"
	"${MAUDESMC_PATH}/build"
	"${MAUDESMC_PATH}/src/Core"
	"${MAUDESMC_PATH}/src/StrategyLanguage"
	"${MAUDESMC_PATH}/src/Higher"
	"${MAUDESMC_PATH}/src/Interface"
	"${MAUDESMC_PATH}/src/Utility"
	"${MAUDESMC_PATH}/src/FullCompiler"
	"${MAUDESMC_PATH}/src/Meta"
	"${MAUDESMC_PATH}/src/Mixfix"
	"${MAUDESMC_PATH}/src/Variable"
	"${MAUDESMC_PATH}/src/IO_Stuff"
	"${MAUDESMC_PATH}/src/FreeTheory"
	"${MAUDESMC_PATH}/src/BuiltIn"
	"${MAUDESMC_PATH}/src/SMT"
	"${MAUDESMC_PATH}/src/NA_Theory"
	"${MAUDESMC_PATH}/src/Parser"
	"${MAUDESMC_PATH}/src/ObjectSystem"
	"${MAUDESMC_PATH}/src/S_Theory"
	${EXTRA_INCLUDE_DIRS}
)

set_property(SOURCE swig/maude.i PROPERTY CPLUSPLUS ON)

swig_add_library(_maude
	TYPE MODULE
	LANGUAGE python
	SOURCES swig/maude.i src/easyTerm.cc src/maude_wrappers.cc
)

set_property(TARGET _maude PROPERTY SWIG_COMPILE_OPTIONS -doxygen)
set_property(TARGET _maude PROPERTY COMPILE_DEFINITIONS HAVE_CONFIG_H)
set_property(TARGET _maude PROPERTY SWIG_COMPILE_DEFINITIONS HAVE_CONFIG_H)
set_property(TARGET _maude PROPERTY SWIG_GENERATED_COMPILE_DEFINITIONS HAVE_CONFIG_H)
python_extension_module(_maude)

swig_link_libraries(_maude libmaude)

#
## Install all the components

install(TARGETS _maude LIBRARY DESTINATION maude)
install(FILES
	"${MAUDESMC_PATH}/installdir/lib/libmaude${CMAKE_SHARED_LIBRARY_SUFFIX}"
	"${MAUDESMC_PATH}/src/Main/prelude.maude"
	"${MAUDESMC_PATH}/src/Main/file.maude"
	"${MAUDESMC_PATH}/src/Main/linear.maude"
	"${MAUDESMC_PATH}/src/Main/machine-int.maude"
	"${MAUDESMC_PATH}/src/Main/metaInterpreter.maude"
	"${MAUDESMC_PATH}/src/Main/model-checker.maude"
	"${MAUDESMC_PATH}/src/Main/smt.maude"
	"${MAUDESMC_PATH}/src/Main/socket.maude"
	"${MAUDESMC_PATH}/src/Main/term-order.maude"
	${EXTRA_INSTALL_FILES}
	DESTINATION maude
)
get_property(wrapper_file TARGET _maude PROPERTY SWIG_SUPPORT_FILES)
install(FILES "${wrapper_file}" RENAME __init__.py DESTINATION maude)
