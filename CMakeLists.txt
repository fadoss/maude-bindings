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

#
## Build script options

option(BUILD_LIBMAUDE "build libmaude before building the extension" YES)
set(EXTRA_INCLUDE_DIRS "" CACHE PATH "Additional include paths")
set(EXTRA_INSTALL_FILES "" CACHE PATH "Additional files to be installed")
set(EXTRA_SWIG_OPTIONS "" CACHE STRING "Additional options passed to swig")
set(LANGUAGE "python" CACHE STRING "Generate wrappers for that language")
set(JAVA_PACKAGE_NAME "es.ucm.maude.bindings" CACHE STRING "Name of the Java package for the bindings")

find_package(SWIG REQUIRED)
include(ExternalProject)
include(UseSWIG)

#
## Language-specific actions

if (${LANGUAGE} STREQUAL python)
	find_package(PythonExtensions REQUIRED)
	list(APPEND EXTRA_SWIG_OPTIONS -doxygen)
elseif (${LANGUAGE} STREQUAL java)
	find_package(Java REQUIRED)
	find_package(JNI REQUIRED)
	include_directories(${JNI_INCLUDE_DIRS})
	list(APPEND EXTRA_SWIG_OPTIONS "-doxygen;-package;${JAVA_PACKAGE_NAME}" )
elseif (${LANGUAGE} STREQUAL go)
	math(EXPR GOINTSIZE "8 * ${CMAKE_SIZEOF_VOID_P}")
	list(APPEND EXTRA_SWIG_OPTIONS -intgosize ${GOINTSIZE})
elseif (${LANGUAGE} STREQUAL guile)
	find_package(Guile)
	include_directories(${GUILE_INCLUDE_DIRS})
	list(APPEND EXTRA_SWIG_OPTIONS -doxygen)
elseif (${LANGUAGE} STREQUAL lua)
	find_package(Lua REQUIRED)
	include_directories(${LUA_INCLUDE_DIR})
elseif (${LANGUAGE} STREQUAL node)
	find_package(Node REQUIRED)
	include_directories(${NODEJS_INCLUDE_DIRS})
	set(EXTRA_SWIG_OPTIONS "${EXTRA_SWIG_OPTIONS};-node")
	set(LANGUAGE javascript)
	add_definitions(-DBUILDING_NODE_EXTENSION)
elseif (${LANGUAGE} STREQUAL php)
	find_package(PHP4 REQUIRED)
	include_directories(${PHP4_INCLUDE_PATH})
elseif (${LANGUAGE} STREQUAL r)
	find_package(R REQUIRED)
	include_directories(${R_INCLUDEDIR})
elseif (${LANGUAGE} STREQUAL ruby)
	find_package(Ruby REQUIRED)
	include_directories(${RUBY_INCLUDE_DIRS})
elseif (${LANGUAGE} STREQUAL tcl)
	find_package(TCL REQUIRED)
	include_directories(${TCL_INCLUDE_DIRS})
endif()

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
		-Dwith-smt=yices2
		-Dstrip=true
		-Dlibdir=lib
		-Dprefix=/
	BUILD_COMMAND ninja
	BUILD_BYPRODUCTS "${MAUDESMC_PATH}/installdir/lib/libmaude${CMAKE_SHARED_LIBRARY_SUFFIX}"
	INSTALL_COMMAND "DESTDIR=${MAUDESMC_PATH}/installdir" ninja install
	INSTALL_DIR "${MAUDESMC_PATH}/installdir"
)

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
	"${MAUDESMC_PATH}/src/Temporal"
	"${MAUDESMC_PATH}/src/3rdParty"
	${EXTRA_INCLUDE_DIRS}
)

set_property(SOURCE swig/maude.i PROPERTY CPLUSPLUS ON)

swig_add_library(_maude
	TYPE MODULE
	LANGUAGE ${LANGUAGE}
	SOURCES swig/maude.i src/easyTerm.cc src/maude_wrappers.cc
	        src/model_checking.cc src/narrowing.cc src/hooks.cc
)

set_property(TARGET _maude PROPERTY SWIG_COMPILE_OPTIONS ${EXTRA_SWIG_OPTIONS})
set_property(TARGET _maude PROPERTY COMPILE_DEFINITIONS HAVE_CONFIG_H)
set_property(TARGET _maude PROPERTY SWIG_COMPILE_DEFINITIONS HAVE_CONFIG_H)
set_property(TARGET _maude PROPERTY SWIG_GENERATED_COMPILE_DEFINITIONS HAVE_CONFIG_H)

if (BUILD_LIBMAUDE)
	add_dependencies(_maude maudesmc)
endif()

if (${LANGUAGE} STREQUAL python)
	python_extension_module(_maude)
endif()

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

if (${LANGUAGE} STREQUAL python)
	# The SWIG_SUPPORT_FILES property is only accurate for Python
	get_property(wrapper_file TARGET _maude PROPERTY SWIG_SUPPORT_FILES)
	install(FILES "${wrapper_file}" RENAME __init__.py DESTINATION maude)
endif()
