#
# Build script for the maude extension module and package (Windows)

function Invoke-NativeCommand {
	$command = $args[0]
	$arguments = $args[1..($args.Length)]
	& $command @arguments
	if (!$?) {
		Write-Error "Exit code $LastExitCode while running $command $arguments"
	}
}

function Download-File {
	$webclient = $args[0]
	$url = $args[1]
	$webclient.DownloadFile($url, "$(Get-Location)/$(Split-Path -Leaf $url)")
}

function Extract-Archive {
	$filename = $args[0]
	$basename = (Split-Path -LeafBase $filename)
	$moreargs = $args[1..($args.Length)]

	7z x -y $filename

	if ((Split-Path -Extension $basename) -eq ".tar") {
		7z x -y $basename @moreargs
		Remove-Item $basename
	}
}

Set-PSDebug -Trace 1
$ErrorActionPreference = "Stop"

$LIBMAUDE_PKG = "https://github.com/fadoss/maudesmc/releases/download/latest/libmaude-windows.tar.xz"
$AUXFILES_PKG = "https://github.com/fadoss/maude-bindings/releases/download/0.1/windows-auxfiles.tar.xz"

# Install swig and ninja with Chocolatey
choco install swig ninja

# Get the extended version of Maude from its repository
# and copies Maude's config.h and libmaude.dll* to the
# locations expected by the cmake script

$webclient = New-Object System.Net.WebClient

Download-File $webclient $LIBMAUDE_PKG
Extract-Archive (Split-Path -Leaf $LIBMAUDE_PKG) "-olibmaude-pkg"

New-Item subprojects\maudesmc\build -ItemType Directory -ErrorAction SilentlyContinue
New-Item subprojects\maudesmc\installdir\lib -ItemType Directory -ErrorAction SilentlyContinue

# config.h, gmp.h and sigsegv.h are included in the libmaude package
# because they are generated by the corresponding configure scripts and
# to make their parameters coincide with those used when building Maude

Move-Item libmaude-pkg\config.h subprojects\maudesmc\build
Move-Item libmaude-pkg\gmp.h subprojects\maudesmc\build
Move-Item libmaude-pkg\sigsegv.h subprojects\maudesmc\build
Move-Item libmaude-pkg\libmaude.dll subprojects\maudesmc\installdir\lib
Move-Item libmaude-pkg\libmaude.dll.a subprojects\maudesmc\installdir\lib

# Download Buddy, Yices2 and GMP C++ headers
# (only yices_types.h is modified to avoid a name conflict)

Download-File $webclient $AUXFILES_PKG
Extract-Archive (Split-Path -Leaf $AUXFILES_PKG) "-osubprojects\maudesmc\build"

# Remove some Unix-specific code

$pseudoThreadPath = "subprojects\maudesmc\src\ObjectSystem\pseudoThread.hh"
(Get-Content $pseudoThreadPath).replace('POLLIN', '0').replace('POLLOUT', '1') | Set-Content $pseudoThreadPath

#
## Install required build tools

Invoke-NativeCommand python -m pip install --upgrade pip
Invoke-NativeCommand python -m pip install --upgrade scikit-build-core

#
## Build the extension

# Include the required Mingw dlls
$mingwDllPath = (Get-Item "libmaude-pkg").FullName
$mingwDlls = "$mingwDllPath\libstdc++-6.dll;$mingwDllPath\libwinpthread-1.dll;$mingwDllPath\libgcc_s_seh-1.dll"

$Env:CMAKE_ARGS = "-DBUILD_LIBMAUDE=OFF -DEXTRA_INSTALL_FILES=$mingwDlls -G Ninja"
Invoke-NativeCommand python -m pip wheel -w dist .

#
## Test the generated packages

$builddir = (Get-Location)
Push-Location $env:TEMP

"import maude
maude.init()
print(maude.getCurrentModule())
" > test.py

"CONVERSION" > test.expected

Invoke-NativeCommand python -m pip install (Get-Item $builddir\dist\*.whl).FullName
Invoke-NativeCommand python test.py > test.out

if (Compare-Object (Get-Content test.out) (Get-Content test.expected)) {
	Write-Error "Unexpected program output"
}

Pop-Location
