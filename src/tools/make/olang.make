# Oberon compiler and library makefile.
#
# To build and install the Oberon compiler and library on a Unix based 
# OS (Linux/Mac/BSD etc.) or on cygwin, run:
#
#   make full
#
# To override your OSs default C compiler, first run
#
#   export CC=compiler
#
# Where compiler is one of:
#  
#   clang                     
#   gcc
#   i686-w64-mingw32-gcc        (32 bit cygwin only)
#   x86_64-w64-mingw32-gcc      (64 bit cygwin only)
#
# (To build on native Windows use make.cmd, not this makefile. Make.cmd automatically 
# assumes use of the Microsoft compiler cl.)



# C compiler data models and sizes and alignments of Oberon types.
#
# There are just three distinct data models that we build for:
#
#    44  -  32 bit pointers, 32 bit alignment
#    48  -  32 bit pointers, 64 bit alignment
#    88  -  64 bit pointers, 64 bit alignment
#
# Meaning of n bit alignment:
#
#    Individual variables of up to n bits are aligned in memory to 
#    whole multiples of their own size, rounded up to a power of two.
#    Variables larger than n bits are aligned to n bits.
#
#    (n will always be a power of 2).
#
# Thus:
#
#                  Size     32 bit alignment   64 bit alignment
#                --------   ----------------   ----------------
# CHAR            1 byte         1 byte             1 byte 
# INTEGER         4 bytes        4 bytes            4 bytes
# LONGINT         8 bytes        4 bytes            8 bytes
#
# Note that in practice for 32 and 64 bit systems, this only affects
# LONGINT.
#
# C data model names:
#
# name           32 bit types            64 bit types         alignment
# ---------   ------------------   ------------------------   ---------
# ILP32       int, long, pointer   long long                  32 or 64
# LP64        int                  long, long long, pointer      64
# LLP64       int, long            long long                     64


# Gnu make has the make initiel directory in CURDIR, BSD make has it in .CURDIR.
OLANGDIR = $(CURDIR)$(.CURDIR)

include ./Configuration.Make

FLAVOUR    = $(OS).$(DATAMODEL).$(COMPILER)
BUILDDIR   = build/$(FLAVOUR)
# SAVEDOLANG = bin/olang.$(FLAVOUR)$(BINEXT)
SOURCE     = $(OLANGDIR)/src
OLANG      = olang$(BINEXT)





usage:
	@echo ""
	@echo Usage:
	@echo ""
	@echo "  make clean         - Remove made files"
	@echo "  make compiler      - Build the compiler but not the library"
	@echo "  make library       - Build all library files and make libolang"
	@echo "  make full          - Runs all the above"
	@echo "  make install       - Install built compiler and library in /opt"
	@echo "                       (May need root access)"
	@echo "  make preparecommit - Uddate bootstrap C source directories."
	@echo "  make revertcsource - Use git checkout to restore the bootstrap C source directories"




# full: Full build of compiler and libarary.
full:
	@make -s clean
	@make -s compiler
	@make -s browsercmd
	@make -s library
	@echo "Compiler and library built in $(BUILDDIR)"




# compiler: Builds the compiler, but not the library
compiler:
	@make -s translate
	@make -s assemble




library: v4 v4compat ooc2 ooc ulm pow32 misc s3 libolang




preparecommit:	
	@rm -rf bootstrap/*
	@for SA in 44 48 88; do for PL in unix windows; do make -s translate SIZEALIGN=$$SA BUILDDIR=bootstrap/$$PL-$$SA PLATFORM=$$PL; done; done




revertcsource:
	@for SA in 44 48 88; do for PL in unix windows; do git checkout bootstrap/$$PL-$$SA PLATFORM=$$PL; done; done



clean:
	rm -rf $(BUILDDIR)
	rm -f $(OLANG)




# Assemble: Generate the olang compiler binary by compiling the C sources in the build directory

assemble:
	@printf "\nmake assemble - compiling Oberon compiler c source:\n"
	@printf "  PLATFORM:  %s\n" "$(PLATFORM)"
	@printf "  OS:        %s\n" "$(OS)"
	@printf "  DATAMODEL: %s\n" "$(DATAMODEL)"
	@printf "  SIZEALIGN: %s\n" "$(SIZEALIGN)"
	@printf "  COMPILER:  %s\n" "$(COMPILER)"
	@printf "  VERSION:   %s\n" "$(VERSION)"
	@printf "  COMPILE:   %s\n" "$(COMPILE)"
	@printf "  BUILDDIR:  %s\n" "$(BUILDDIR)"

	cd $(BUILDDIR) && $(COMPILE) -c SYSTEM.c  Configuration.c Platform.c Heap.c 
	cd $(BUILDDIR) && $(COMPILE) -c Console.c Strings.c       Modules.c  Files.c 
	cd $(BUILDDIR) && $(COMPILE) -c Reals.c   Texts.c         vt100.c    errors.c 
	cd $(BUILDDIR) && $(COMPILE) -c OPM.c     extTools.c      OPS.c      OPT.c 
	cd $(BUILDDIR) && $(COMPILE) -c OPC.c     OPV.c           OPB.c      OPP.c

	cd $(BUILDDIR) && $(COMPILE) $(STATICLINK) olang.c -o $(OLANGDIR)/$(OLANG) \
	SYSTEM.o  Configuration.o Platform.o Heap.o    Console.o Strings.o       Modules.o  Files.o \
	Reals.o   Texts.o         vt100.o    errors.o  OPM.o     extTools.o      OPS.o      OPT.o \
	OPC.o     OPV.o           OPB.o      OPP.o
	@printf "$(OLANG) created.\n"




compilerfromsavedsource:
	@echo Populating clean build directory from bootstrap C sources.
	@mkdir -p $(BUILDDIR)
	@cp bootstrap/$(PLATFORM)-$(SIZEALIGN)/* $(BUILDDIR)
	@make -s assemble




translate:
# Make sure we have an oberon compiler binary: if we built one earlier we'll use it,
# otherwise use one of the pre-prepared sets of C sources in the bootstrap directory.
#	if [ \( ! -e $(OLANG) \) -a -e $(SAVEDOLANG) ]; then cp $(SAVEDOLANG) $(OLANG); fi
	if [ ! -e $(OLANG) ]; then make -s compilerfromsavedsource; fi

	@printf "\nmake translate - translating compiler source:\n"
	@printf "  PLATFORM:  %s\n" $(PLATFORM)
	@printf "  SIZEALIGN: %s\n" $(SIZEALIGN)
	@mkdir -p $(BUILDDIR)

	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../Configuration.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/system/Platform$(PLATFORM).Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFsapx -T$(SIZEALIGN) ../../src/system/Heap.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/system/Console.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/library/v4/Strings.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/library/v4/Modules.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFsx   -T$(SIZEALIGN) ../../src/system/Files.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/library/v4/Reals.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/library/v4/Texts.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/system/vt100.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/compiler/errors.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/compiler/OPM.cmdln.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/compiler/extTools.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFsx   -T$(SIZEALIGN) ../../src/compiler/OPS.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/compiler/OPT.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/compiler/OPC.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/compiler/OPV.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/compiler/OPB.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -SFs    -T$(SIZEALIGN) ../../src/compiler/OPP.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Ssm    -T$(SIZEALIGN) ../../src/compiler/olang.Mod

	cp src/system/*.[ch] $(BUILDDIR)

	@printf "$(BUILDDIR) filled with compiler C source.\n"




browsercmd:
	@printf "\nMaking symbol browser\n"
	@cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Sm ../../src/tools/browser/BrowserCmd.Mod
	@cd $(BUILDDIR) && $(COMPILE) $(STATICLINK) BrowserCmd.c -o showdef \
	  Platform.o Texts.o OPT.o Heap.o Console.o SYSTEM.o OPM.o OPS.o OPV.o \
	  Files.o Reals.o Modules.o vt100.o errors.o Configuration.o Strings.o \
	  OPC.o





# install: Use only after a successful full build. Installs the compiler 
#          and libraries in /opt/olang.
#          May require root access.
install:
	@printf "\nInstalling into $(INSTALLDIR)\n"
	@rm -rf $(INSTALLDIR)
	@mkdir -p "$(INSTALLDIR)/bin"       "$(INSTALLDIR)/include" "$(INSTALLDIR)/sym" "$(INSTALLDIR)/lib"
	@cp -p $(BUILDDIR)/*.h              "$(INSTALLDIR)/include/"
	@cp -p $(BUILDDIR)/*.sym            "$(INSTALLDIR)/sym/"
	@cp -p $(OLANG)                     "$(INSTALLDIR)/bin/olang$(BINEXT)"
	@cp -p $(BUILDDIR)/showdef$(BINEXT) "$(INSTALLDIR)/bin"
	@cp -p $(BUILDDIR)/libolang.a       "$(INSTALLDIR)/lib/"
#	Optional: Link /usr/bin/olang to the new binary
#	ln -fs "$(INSTALLDIR)/bin/$(OLANGDIR)/$(OLANG)" /usr/bin/$(OLANGDIR)/$(OLANG)
	@printf "\nNow add $(INSTALLDIR)/bin to your path, for example with the command:\n"
	@printf "export PATH=$(INSTALLDIR)/bin:$$PATH\n"


uninstall:
	rm -rf $(INSTALLDIR)



# Optional shared library for Linux systems.
sharedlibrary:
	cd $(BUILDDIR) && $(COMPILE) -shared -o "$(INSTALLDIR)/lib/libolang.so" *.o
	echo "$(INSTALLDIR)/lib" >/etc/ld.so.conf.d
	ldconfig




v4:
	@printf "\nMaking v4 library\n"
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/v4/Args.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/v4/Printer.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/v4/Sets.Mod

v4compat:
	@printf "Making v4_compat library\n"
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/v4_compat/Oberon.Mod

ooc2:
	@printf "Making ooc2 library\n"
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc2/ooc2Strings.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc2/ooc2Ascii.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc2/ooc2CharClass.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc2/ooc2ConvTypes.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc2/ooc2IntConv.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc2/ooc2IntStr.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc2/ooc2Real0.Mod

ooc:
	@printf "Making ooc library\n"
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocLowReal.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocLowLReal.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocRealMath.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocOakMath.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocLRealMath.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocLongInts.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocComplexMath.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocLComplexMath.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocAscii.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocCharClass.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocStrings.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocConvTypes.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocLRealConv.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocLRealStr.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocRealConv.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocRealStr.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocIntConv.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocIntStr.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocMsg.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocSysClock.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocTime.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocChannel.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocStrings2.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocRts.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocFilenames.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocTextRider.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocBinaryRider.Mod 
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocJulianDay.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocFilenames.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocwrapperlibc.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ooc/oocC$(DATAMODEL).Mod

oocX:
	@printf "Making oocX11 library\n"
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/oocX/oocX11.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/oocX/oocXutil.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/oocX/oocXYplane.Mod

ulm:
	@printf "Making ulm library\n"
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmObjects.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmPriorities.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmDisciplines.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmServices.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmSys.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmSYSTEM.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmEvents.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmProcess.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmResources.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmForwarders.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmRelatedEvents.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmTypes.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmStreams.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmStrings.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmSysTypes.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmTexts.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmSysConversions.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmErrors.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmSysErrors.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmSysStat.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmASCII.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmSets.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmIO.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmAssertions.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmIndirectDisciplines.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmStreamDisciplines.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmIEEE.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmMC68881.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmReals.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmPrint.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmWrite.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmConstStrings.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmPlotters.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmSysIO.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmLoader.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmNetIO.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmPersistentObjects.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmPersistentDisciplines.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmOperations.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmScales.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmTimes.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmClocks.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmTimers.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmConditions.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmStreamConditions.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmTimeConditions.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmCiphers.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmCipherOps.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmBlockCiphers.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmAsymmetricCiphers.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmConclusions.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmRandomGenerators.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmTCrypt.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/ulm/ulmIntOperations.Mod

pow32:
	@printf "Making pow library\n"
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/pow/powStrings.Mod

misc:
	@printf "Making misc library\n"
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/misc/crt.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/misc/Listen.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/misc/MersenneTwister.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/misc/MultiArrays.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/misc/MultiArrayRiders.Mod

s3:
	@printf "Making s3 library\n"
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethBTrees.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethMD5.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethSets.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethZlib.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethZlibBuffers.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethZlibInflate.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethZlibDeflate.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethZlibReaders.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethZlibWriters.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethZip.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethRandomNumbers.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethGZReaders.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethGZWriters.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethUnicode.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethDates.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethReals.Mod
	cd $(BUILDDIR); $(OLANGDIR)/$(OLANG) -Fs ../../src/library/s3/ethStrings.Mod

libolang:
	@printf "\nMaking libolang\n"
#	Remove objects that should not be part of the library
	rm -f $(BUILDDIR)/olang.o 
#	rm -f $(BUILDDIR)/errors.o $(BUILDDIR)/extTools.o
#	rm -f $(BUILDDIR)/OPM.o   $(BUILDDIR)/OPS.o    $(BUILDDIR)/OPT.o      $(BUILDDIR)/OPP.o 
#	rm -f $(BUILDDIR)/OPC.o   $(BUILDDIR)/OPV.o    $(BUILDDIR)/OPB.o
#	Make static library
	ar rcs "$(BUILDDIR)/libolang.a" $(BUILDDIR)/*.o

