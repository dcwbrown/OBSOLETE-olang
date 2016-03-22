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
set SOURCE=%OLANGDIR%\src
set OLANG=olang%BINEXT%





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
@echo.  make clean         - Remove made files
@echo.  make compiler      - Build the compiler but not the library
@echo.  make library       - Build all library files and make libolang
@echo.  make full          - Runs all the above
@echo.  make install       - Install built compiler and library in /opt
@echo.                       (May need root access)
goto :eof




:full
call :clean
call :compiler
call :browsercmd
call :library
echo.Compiler and library built in %BUILDDIR%
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
call :libolang
goto :eof




:clean
rd /s /q %BUILDDIR% 2>nul
del /q %OLANG% 2>nul
goto :eof




:assemble
echo.
echo.make assemble - compiling Oberon compiler c source::
echo.  PLATFORM:  %PLATFORM%
echo.  OS:        %OS%
echo.  DATAMODEL: %DATAMODEL%
echo.  SIZEALIGN: %SIZEALIGN%
echo.  COMPILER:  %COMPILER%
echo.  VERSION:   %VERSION%
echo.  COMPILE:   %COMPILE%
echo.  BUILDDIR:  %BUILDDIR%

cd %BUILDDIR%

cl -nologo -c SYSTEM.c  Configuration.c Platform.c Heap.c 
cl -nologo -c Console.c Strings.c       Modules.c  Files.c 
cl -nologo -c Reals.c   Texts.c         vt100.c    errors.c 
cl -nologo -c OPM.c     extTools.c      OPS.c      OPT.c 
cl -nologo -c OPC.c     OPV.c           OPB.c      OPP.c

cl -nologo olang.c /Fe%OLANGDIR%\%OLANG% ^
SYSTEM.obj Configuration.obj Platform.obj Heap.obj ^
Console.obj Strings.obj Modules.obj Files.obj ^
Reals.obj Texts.obj vt100.obj errors.obj ^
OPM.obj extTools.obj OPS.obj OPT.obj ^
OPC.obj OPV.obj OPB.obj OPP.obj

echo.%OLANG% created.
cd %OLANGDIR%
goto :eof




:compilefromsavedsource
echo.Populating clean build directory from bootstrap C sources.
mkdir %BUILDDIR% >nul 2>nul
copy bootstrap\%PLATFORM%-%SIZEALIGN%\*.* %BUILDDIR% >nul
call :assemble
goto :eof




:translate
:: Make sure we have an oberon compiler binary: if we built one earlier we'll use it,
:: otherwise use one of the saved sets of C sources in the bootstrap directory.
if not exist %OLANG% call :compilefromsavedsource

echo.
echo.make translate - translating compiler source:
echo.  PLATFORM:  %PLATFORM%
echo.  SIZEALIGN: %SIZEALIGN%

md %BUILDDIR% 2>nul
cd %BUILDDIR%
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../Configuration.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/system/Platform%PLATFORM%.Mod
%OLANGDIR%\%OLANG% -SFsapx -T%SIZEALIGN% -I%INTSIZE% ../../src/system/Heap.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/system/Console.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/library/v4/Strings.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/library/v4/Modules.Mod
%OLANGDIR%\%OLANG% -SFsx   -T%SIZEALIGN% -I%INTSIZE% ../../src/system/Files.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/library/v4/Reals.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/library/v4/Texts.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/system/vt100.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/errors.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/OPM.cmdln.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/extTools.Mod
%OLANGDIR%\%OLANG% -SFsx   -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/OPS.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/OPT.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/OPC.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/OPV.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/OPB.Mod
%OLANGDIR%\%OLANG% -SFs    -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/OPP.Mod
%OLANGDIR%\%OLANG% -Ssm    -T%SIZEALIGN% -I%INTSIZE% ../../src/compiler/olang.Mod
cd %OLANGDIR%
copy src\system\*.c %BUILDDIR% >nul
copy src\system\*.h %BUILDDIR% >nul
echo.%BUILDDIR% filled with compiler C source.
goto :eof




:browsercmd
echo.
echo.Making symbol browser
cd %BUILDDIR%
%OLANGDIR%/%OLANG% -Sm ../../src/tools/browser/BrowserCmd.Mod
cl -nologo BrowserCmd.c /Feshowdef.exe ^
  Platform.obj Texts.obj OPT.obj Heap.obj Console.obj SYSTEM.obj OPM.obj OPS.obj OPV.obj ^
  Files.obj Reals.obj Modules.obj vt100.obj errors.obj Configuration.obj Strings.obj ^
  OPC.obj
cd %OLANGDIR%
goto :eof




:install
whoami /groups | find "12288" >nul
if errorlevel 1 (
echo make install - administrator rights required. Please run under an administrator command prompt.
goto :eof
)
mkdir "%INSTALLDIR%\bin"                            >nul 2>&1 
mkdir "%INSTALLDIR%\include"                        >nul 2>&1     
mkdir "%INSTALLDIR%\sym"                            >nul 2>&1 
mkdir "%INSTALLDIR%\lib"                            >nul 2>&1 
copy %BUILDDIR%\*.h          "%INSTALLDIR%\include" >nul       
copy %BUILDDIR%\*.sym        "%INSTALLDIR%\sym"     >nul   
copy %OLANG%                 "%INSTALLDIR%\bin"     >nul   
copy %BUILDDIR%\showdef.exe  "%INSTALLDIR%\bin"     >nul   
copy %BUILDDIR%\libolang.lib "%INSTALLDIR%\lib"     >nul   
:: Optional: Link c:\windows\olang.exe to the new binary
::del /q c:\windows\olang.exe >nul 2>&1
::mklink c:\windows\olang.exe "%INSTALLDIR%\bin\olang%BINEXT%"
goto :eof




:v4
echo.
echo.Making V4 library
cd %BUILDDIR%
%OLANGDIR%\%OLANG% -Fs ../../src/library/v4/Args.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/v4/Printer.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/v4/Sets.Mod
cd %OLANGDIR%
goto :eof

:ooc2
echo.Making ooc2 library
cd %BUILDDIR%
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc2/ooc2Strings.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc2/ooc2Ascii.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc2/ooc2CharClass.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc2/ooc2ConvTypes.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc2/ooc2IntConv.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc2/ooc2IntStr.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc2/ooc2Real0.Mod
cd %OLANGDIR%
goto :eof

:ooc
echo.Making ooc library
cd %BUILDDIR%
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocLowReal.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocLowLReal.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocRealMath.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocOakMath.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocLRealMath.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocLongInts.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocComplexMath.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocLComplexMath.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocAscii.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocCharClass.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocStrings.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocConvTypes.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocLRealConv.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocLRealStr.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocRealConv.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocRealStr.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocIntConv.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocIntStr.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocMsg.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocSysClock.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocTime.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocChannel.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocStrings2.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocRts.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocFilenames.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocTextRider.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocBinaryRider.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocJulianDay.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocFilenames.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocwrapperlibc.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ooc/oocC%DATAMODEL%.Mod
cd %OLANGDIR%
goto :eof

:oocX
echo No X11 support on plain Windows - use cygwin and build with cygwin make.
goto :eof

:ulm
echo.Making ulm library
cd %BUILDDIR%
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmObjects.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmPriorities.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmDisciplines.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmServices.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmSys.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmSYSTEM.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmEvents.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmProcess.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmResources.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmForwarders.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmRelatedEvents.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmTypes.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmStreams.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmStrings.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmSysTypes.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmTexts.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmSysConversions.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmErrors.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmSysErrors.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmSysStat.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmASCII.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmSets.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmIO.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmAssertions.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmIndirectDisciplines.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmStreamDisciplines.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmIEEE.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmMC68881.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmReals.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmPrint.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmWrite.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmConstStrings.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmPlotters.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmSysIO.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmLoader.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmNetIO.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmPersistentObjects.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmPersistentDisciplines.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmOperations.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmScales.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmTimes.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmClocks.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmTimers.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmConditions.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmStreamConditions.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmTimeConditions.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmCiphers.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmCipherOps.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmBlockCiphers.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmAsymmetricCiphers.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmConclusions.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmRandomGenerators.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmTCrypt.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/ulm/ulmIntOperations.Mod
cd %OLANGDIR%
goto :eof

:pow32
echo.Making pow32 library
cd %BUILDDIR%
%OLANGDIR%\%OLANG% -Fs ../../src/library/pow/powStrings.Mod
cd %OLANGDIR%
goto :eof

:misc
echo.Making misc library
cd %BUILDDIR%
%OLANGDIR%\%OLANG% -Fs ../../src/library/misc/crt.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/misc/Listen.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/misc/MersenneTwister.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/misc/MultiArrays.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/misc/MultiArrayRiders.Mod
cd %OLANGDIR%
goto :eof

:s3
echo.Making s3 library
cd %BUILDDIR%
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethBTrees.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethMD5.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethSets.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethZlib.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethZlibBuffers.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethZlibInflate.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethZlibDeflate.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethZlibReaders.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethZlibWriters.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethZip.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethRandomNumbers.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethGZReaders.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethGZWriters.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethUnicode.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethDates.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethReals.Mod
%OLANGDIR%\%OLANG% -Fs ../../src/library/s3/ethStrings.Mod
cd %OLANGDIR%
goto :eof




:libolang
echo.
echo.Making libolang
:: Remove objects that should not be part of the library
del /q %BUILDDIR%\olang.obj 
:: del /q %BUILDDIR%\errors.obj %BUILDDIR%\extTools.obj %BUILDDIR%\OPM.obj   
:: del /q %BUILDDIR%\OPS.obj    %BUILDDIR%\OPT.obj      %BUILDDIR%\OPP.obj 
:: del /q %BUILDDIR%\OPC.obj    %BUILDDIR%\OPV.obj      %BUILDDIR%\OPB.obj
:: Make static library
lib -nologo %BUILDDIR%\*.obj -out:%BUILDDIR%\libolang.lib
goto :eof







:uninstall

whoami /groups | find "12288" >nul
if errorlevel 1 (
echo make uninstall - administrator rights required. Please run under an administrator command prompt.
goto :eof
)

rmdir /s /q "%PREFIX%"         >nul 2>&1 
rmdir "%PREFIXLN%"             >nul 2>&1
del /q c:\windows\olang.exe    >nul 2>&1
goto :eof

