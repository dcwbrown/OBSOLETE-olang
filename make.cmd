@echo off

:: mscmake.cmd - Build Oberon with Microsoft C compiler.

:: Expects the path to include cl.exe.

:: As of 10th Feb 2016 the miscrosoft c compiler and build tools
:: can be downloaded independently of  the full Visual Studio IDE
:: as the 'Visual C++ Build Tools 2015'.

:: See: https://blogs.msdn.microsoft.com/vcblog/2015/11/02/announcing-visual-c-build-tools-2015-standalone-c-tools-for-build-environments/

:: With this installed, from the start button select:
::   All Apps / Visual C++ Build Tools / Visual C++ x86 Native Build Tools Command Prompt


:: Create configuration and parameter files.

cl -nologo -Isrc\system src\tools\make\configure.c >nul
setlocal
configure.exe >nul
del configure.obj configure.exe 2>nul

:: Extract make variables into local environment

for /F "delims='=' tokens=1,2" %%a in (Configuration.make) do set %%a=%%b

set FLAVOUR=%OS%.%DATAMODEL%.%COMPILER%
set BUILDDIR=build\%FLAVOUR%
set VISHAP=%ONAME%%BINEXT%

for /F %%d in ('cd');do set ROOTDIR=%%d



:: Process target parameter

if "%1" equ "" (
  call :usage
) else (
  call :%1
)
endlocal
goto :eof




:usage
@echo.
@echo Usage:
@echo.
@echo.  make full          - Make and install compiler (from administrator prompt)
@echo.
@echo.  make clean         - Remove made files
@echo.  make compiler      - Build the compiler but not the library
@echo.  make library       - Build all library files and make library
@echo.  make install       - Install built compiler and library (from administrator prompt)
goto :eof




:full
call :clean
call :compiler
call :browsercmd
call :library
call :install
goto :eof




:compiler
call :translate
call :assemble
goto :eof




:library
call :v4
call :ooc2
call :ooc
call :ulm
call :pow32
call :misc
call :s3
call :librarybinary
goto :eof




:clean
rd /s /q %BUILDDIR% 2>nul
del /q %VISHAP% 2>nul
goto :eof




:assemble
echo.
echo.make assemble - compiling Oberon compiler c source::
echo.  VERSION:   %VERSION%
echo.  Target characeristics:
echo.    PLATFORM:  %PLATFORM%
echo.    OS:        %OS%
echo.    BUILDDIR:  %BUILDDIR%
echo.  Oberon characteristics:
echo.    INTSIZE:   %INTSIZE%
echo.    ADRSIZE:   %ADRSIZE%
echo.    ALIGNMENT: %ALIGNMENT%
echo.  C compiler:
echo.    COMPILER:  %COMPILER%
echo.    COMPILE:   %COMPILE%
echo.    DATAMODEL: %DATAMODEL%

cd %BUILDDIR%

cl -nologo /Zi -c SYSTEM.c  Configuration.c Platform.c Heap.c
cl -nologo /Zi -c Console.c Strings.c       Modules.c  Files.c
cl -nologo /Zi -c Reals.c   Texts.c         vt100.c    errors.c
cl -nologo /Zi -c OPM.c     extTools.c      OPS.c      OPT.c
cl -nologo /Zi -c OPC.c     OPV.c           OPB.c      OPP.c

cl -nologo /Zi Vishap.c /Fe%ROOTDIR%\%VISHAP% ^
SYSTEM.obj Configuration.obj Platform.obj Heap.obj ^
Console.obj Strings.obj Modules.obj Files.obj ^
Reals.obj Texts.obj vt100.obj errors.obj ^
OPM.obj extTools.obj OPS.obj OPT.obj ^
OPC.obj OPV.obj OPB.obj OPP.obj

echo.%VISHAP% created.
cd %ROOTDIR%
goto :eof




:compilefromsavedsource
echo.Populating clean build directory from bootstrap C sources.
mkdir %BUILDDIR% >nul 2>nul
copy bootstrap\%PLATFORM%-%ADRSIZE%%ALIGNMENT%\*.* %BUILDDIR% >nul
call :assemble
goto :eof




:translate
:: Make sure we have an oberon compiler binary: if we built one earlier we'll use it,
:: otherwise use one of the saved sets of C sources in the bootstrap directory.
if not exist %VISHAP% call :compilefromsavedsource

echo.
echo.make translate - translating compiler source:
echo.  PLATFORM:  %PLATFORM%
echo.  INTSIZE:   %INTSIZE%
echo.  ADRSIZE:   %ADRSIZE%
echo.  ALIGNMENT: %ALIGNMENT%

md %BUILDDIR% 2>nul
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../Configuration.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/system/Platform%PLATFORM%.Mod
%ROOTDIR%\%VISHAP% -SFsapx -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/system/Heap.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/system/Console.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/library/v4/Strings.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/library/v4/Modules.Mod
%ROOTDIR%\%VISHAP% -SFsx   -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/system/Files.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/library/v4/Reals.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/library/v4/Texts.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/system/vt100.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/errors.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPM.cmdln.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/extTools.Mod
%ROOTDIR%\%VISHAP% -SFsx   -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPS.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPT.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPC.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPV.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPB.Mod
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPP.Mod
%ROOTDIR%\%VISHAP% -Ssm    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/Vishap.Mod
cd %ROOTDIR%
copy src\system\*.c %BUILDDIR% >nul
copy src\system\*.h %BUILDDIR% >nul
echo.%BUILDDIR% filled with compiler C source.
goto :eof




:browsercmd
echo.
echo.Making symbol browser
cd %BUILDDIR%
%ROOTDIR%/%VISHAP% -Sm ../../src/tools/browser/BrowserCmd.Mod
cl -nologo BrowserCmd.c /Feshowdef.exe ^
  Platform.obj Texts.obj OPT.obj Heap.obj Console.obj SYSTEM.obj OPM.obj OPS.obj OPV.obj ^
  Files.obj Reals.obj Modules.obj vt100.obj errors.obj Configuration.obj Strings.obj ^
  OPC.obj
cd %ROOTDIR%
goto :eof




:install
whoami /groups | find "12288" >nul
if errorlevel 1 (
echo make install - administrator rights required. Please run under an administrator command prompt.
goto :eof
)
rmdir /s /q "%INSTALLDIR%"                          >nul 2>&1
mkdir "%INSTALLDIR%"                                >nul 2>&1
mkdir "%INSTALLDIR%\bin"                            >nul 2>&1
mkdir "%INSTALLDIR%\include"                        >nul 2>&1
mkdir "%INSTALLDIR%\sym"                            >nul 2>&1
mkdir "%INSTALLDIR%\lib"                            >nul 2>&1
copy %BUILDDIR%\*.h          "%INSTALLDIR%\include" >nul
copy %BUILDDIR%\*.sym        "%INSTALLDIR%\sym"     >nul
copy %VISHAP%                 "%INSTALLDIR%\bin"     >nul
copy %BUILDDIR%\showdef.exe  "%INSTALLDIR%\bin"     >nul
copy %BUILDDIR%\lib%ONAME%.lib "%INSTALLDIR%\lib"     >nul
echo.
echo.Now add %INSTALLDIR%\bin to your path.
goto :eof


:uninstall
whoami /groups | find "12288" >nul
if errorlevel 1 (
echo make uninstall - administrator rights required. Please run under an administrator command prompt.
goto :eof
)
rmdir /s /q "%INSTALLDIR%" >nul 2>&1
goto :eof




:v4
echo.
echo.Making V4 library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/v4/Args.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/v4/Printer.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/v4/Sets.Mod
cd %ROOTDIR%
goto :eof

:ooc2
echo.Making ooc2 library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2Strings.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2Ascii.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2CharClass.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2ConvTypes.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2IntConv.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2IntStr.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2Real0.Mod
cd %ROOTDIR%
goto :eof

:ooc
echo.Making ooc library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLowReal.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLowLReal.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocRealMath.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocOakMath.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLRealMath.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLongInts.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocComplexMath.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLComplexMath.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocAscii.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocCharClass.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocStrings.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocConvTypes.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLRealConv.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLRealStr.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocRealConv.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocRealStr.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocIntConv.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocIntStr.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocMsg.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocSysClock.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocTime.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocChannel.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocStrings2.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocRts.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocFilenames.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocTextRider.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocBinaryRider.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocJulianDay.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocFilenames.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocwrapperlibc.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocC%DATAMODEL%.Mod
cd %ROOTDIR%
goto :eof

:oocX
echo No X11 support on plain Windows - use cygwin and build with cygwin make.
goto :eof

:ulm
echo.Making ulm library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmObjects.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPriorities.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmDisciplines.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmServices.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSys.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSYSTEM.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmEvents.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmProcess.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmResources.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmForwarders.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmRelatedEvents.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTypes.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmStreams.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmStrings.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysTypes.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTexts.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysConversions.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmErrors.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysErrors.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysStat.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmASCII.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSets.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmIO.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmAssertions.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmIndirectDisciplines.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmStreamDisciplines.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmIEEE.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmMC68881.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmReals.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPrint.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmWrite.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmConstStrings.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPlotters.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysIO.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmLoader.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmNetIO.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPersistentObjects.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPersistentDisciplines.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmOperations.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmScales.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTimes.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmClocks.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTimers.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmConditions.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmStreamConditions.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTimeConditions.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmCiphers.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmCipherOps.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmBlockCiphers.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmAsymmetricCiphers.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmConclusions.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmRandomGenerators.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTCrypt.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmIntOperations.Mod
cd %ROOTDIR%
goto :eof

:pow32
echo.Making pow32 library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/pow/powStrings.Mod
cd %ROOTDIR%
goto :eof

:misc
echo.Making misc library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/crt.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/Listen.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/MersenneTwister.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/MultiArrays.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/MultiArrayRiders.Mod
cd %ROOTDIR%
goto :eof

:s3
echo.Making s3 library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethBTrees.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethMD5.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethSets.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlib.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibBuffers.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibInflate.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibDeflate.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibReaders.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibWriters.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZip.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethRandomNumbers.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethGZReaders.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethGZWriters.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethUnicode.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethDates.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethReals.Mod
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethStrings.Mod
cd %ROOTDIR%
goto :eof




:librarybinary
echo.
echo.Making lib%ONAME%
:: Remove objects that should not be part of the library
del /q %BUILDDIR%\Vishap.obj
:: Make static library
lib -nologo %BUILDDIR%\*.obj -out:%BUILDDIR%\lib%ONAME%.lib
goto :eof







