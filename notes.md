####Changes relative to March 2016 Vishap Oberon


The biggest changes relative to current (March 2016) Vishap Oberon are in the build system and platform specific behaviour. Where possible platform differences have been automated or removed.

 - The same make commands are used for all platforms, Linux, BSD, Darwin and Windows. In particular 'make full'
builds the compiler, library and tools, installs the compler and tools, and runs a couple of confidence tests.

 - The C program 'configure.c', a much expanded version of vocparam.c, generates all the platform specific make variables, and the configuration constants compiled into the compiler. Configure.c is compiled and executed at the start of every make command.

 - The vast majority of the makefile (olang.make) is platform independent (even across BSD make/GNU make) - just a stub makefile/GNUmakefile exists to run configure.c and start the platform independent makefile. (For native windows a separate make.cmd contains the equivalent functionality expressed as a Windows .cmd file.)

 - All duplicate files required to build Linux/BSD/Darwin variants have been removed by recoding them to be platform independent:
   - Rather than accessing Linux structures through Oberon RECORDs intended to match their memory layout, code procedures are used to reference C constants and struct fields directly. (This reolves a number of complexities with structure field order and layout variations across operating systems.)
   - Size dependent code is abstracted into simple definitions in SYSTEM.h and referenced from code procedures.
   - Files.Mod is extended with a file search path feature removing the need for Files0.Mod, Text0.Mod and Kernel0.Mod. Instead OPM.cmdln.Mod calls the new Files.SetSearchPath.
   - Kernel.Mod, Unix.Mod and SYSTEM.Mod are refactored into Heap.Mod and PlatformUnix.Mod. An alternate Platform module implementation PlatformWindows.Mod that uses the Win32 API directly.
   - All references to the LONGINT type in C source, including in code procedures new explicitly specify 'LONGINT'. Previously the code assumed that 'long' was intercgangeable with 'LONGINT', but for some platforms LONGINT is 'long long', not 'long'.

 - The enlistment no longer includes compiled binaries. Instead it includes pre-prepared sets of C source covering all 5 C data model variants. (See directory 'bootstrap'.)

 - The bootstrap sources are used on any fresh enlistment or clean build ('make full' is always a clean build). These sources, combined with the platform independence improvements outlined above, have built crrectly from a fresh enlistment on all Linux, BSD and cygwin platforms that I have tried, including the raspberry pi under raspbian, and in the termux terminal emulator on android.

The result is that there is now a single version of earch Oberon source file, with the exceptions only of PlatformUnix.Mod/PlatformWindows.Mod in the compiler, and oocCILP32.Mod/oocCLP64.Mod/oocCLLP64.Mod in the ooc library.

The full build is now free of warnings:

 - Missing ELSE warnings solved by adding ELSE.

 - C code conversion between integer and pointer of different size solved by casting with with uintptr_t as an intermediate type.

 - C code conversion between signed and unsigned char types solved by explicitly casting 'CHAR's passed to system APIs in code procedures to 'char'.

HALT/exit code has been simplified. Exit now just calls the system exit API rather than calling the kill API and passing our own process ID. For runtime errors it now displayes the appropriate error message (e.g. Index out of range).

The jump buffer was not used by any code and has been removed. (It seems from a comment to have been intended for use during some termination code, but the termination code does not use it.)

Compilation errors now include the line number at the start of the displayed source line. The pos (character offset) is still displayed on the error message line. The error handling code was already doing some walking of the source file to find start and end of line - I changed this to walk through the source file from the start identifying line end positions, counting lines and caching the position at the start of the last error line. The resultant code is much simpler in my opinion, and displays the line number without losing the pos. The performance cost of walking the source file is not an issue.

######A few fix details:

 - There was aproblem with the dynamic array size parameter passed to NEW when expressed as a literal on 64 bit builds. This happens a number of times in the compiler and library. In theory it is not necessary to specify the size of numeric literals on parameters to ANSI C functions as the compiler should know the size from the declaration of the called function. (i.e. it shouldn't matter whether one passes '1', '1l', or '1ll'.)
Therefore while OPM.PromoteIntConstToLInt was coded to generate 'l' at the end of long literal parameters on K&R C, it intentionally omits the 'l' when the compiler is known to be ANSI. (All currently supported compilers are ANSI.)
**But** it is not safe to omit the 'l' in literal parameters to C vararg functions: the C compiler cannot get vararg parameter size from the declaration, and so uses the literal size. Thus only 32 bits are pushed to the stack where 64 bits are required. The implementation of SYSTEM\_NEWARR reads the full 64 bits. Often the uninitialised 32 bits are zero, and everything works correctly. Rarely they are a very small integer and the system thrashes a while to allocate page tables and then continues normally. Other times a segmentation fault or out of memery error is generated.
Removing the test for ANSI and thus always generating the trailing 'l' for LONGINTs is a sufficient fix for the data models supported by current Vishap Oberon.
However there is a further complication - this is not sufficient for the LLP64 C data model used by 64 bit Windows. In LLP64, 'long' is only 32 bit. The 64 bit integer type is  'long long' and literal numerics of this type would require an 'll' suffix.
Rather than create more complex 'l' suffix code I chose to fix this by by generating a (LONGINT)(n) typecast, which forces n to the correct size in all cases.

 - SYSTEM.H __VAL(t, x) was defined as (\*(t\*)&(x)) which maps the new type onto the memory of the old. This produces the wrong result if the new type is larger than the old type, because it includes memory that does not belong to the variable into the result. This has been corrected to the simpler ((t)(x)) which will do the appropriate signed or unsigned extension.

 - There was a serious issue with accessing free'd memory in RETURN expressions. Oberon generates code to create local copies of dynamic strings passed by value (so that code is free to change the value parameter without affecting the original string).
The copy is not allocated from the Oberon Heap, but direct from the OS (e.g. via malloc on Linux/Unix). At function return the compiler inserts a call to C's free before the return statement.
The problem comes when the expression on the Oberon RETURN statement references the local string copy. This gets compiled to a C 'return' statement that references the free'd memory. Sometimes the C free will not have modified the string copy, and no error is seen. However all bets are off - the OS or C runtime could have done anything to this memory as part of heap management (e.g. used it for free chain linkage), and with pre-emptive multitasking it may have been reallocated and used for another purpose before the return expression refers to it.
This is one of that category of frustrating bug that may hit rarely but is very difficult to diagnose when it does.
The solution I have implemented is to generate a return value variable at the entry of every function, and generate code to evaluate the return expression into the variable *before* generating the code to free the local string copy.
In theory the Oberon compiler could inspect the return value for reference to a local copy and only generate the result variable when necessary, however this is a lot of complicated code at function entry and I'm not sure it is necessary, really the C compiler should be able to optimize code with a result variable much the same as code without it.

 - Texts.WriteInt corrected to work with both 4 and 8 byte LONGINTs. Previously values with more than 11 digits caused an index out of range error.

 - Between voc.Translate and extTools.Mod, the main program was being compiled twice by the C compiler. It is now compiled just once.

######Other changes:

 - In his latest specs (around 2013) Wirth removed the 'COPY(a, b)' character array copy procedure, replacing it with 'b := a'. I have accordingly enabled 'b := a' in voc as an alternative to 'COPY(a, b)'.

 - Oberon code often writes to Oberon.Log expecting the text to appear on the screen. While voc has an Oberon.DumpLog procedure, I looked into making the behaviour automatic. Interestingly voc declares the Text notifier constants replace, insert and delete, but omits the notifier calls. The implementation turned out to be very little code, and I have used it to echo all text written to Oberon.Log to the console. This has the advantage over DumpLog that text is written immediately rather than only when DumpLog is called, and allows existing program source to work unchanged.

 - While working on this I have been using the name 'olang' rather than 'voc', partly to avoid confusing binary files, and partly because I had not (re)reached compatability with voc. Since I reckon I'm close to complete, I have now parameterised the code to allow any file name for the compiler and install dir, and switched it back to 'voc' by default. src/tools/make/configure.c line 12 specifies the name that will be built.

 - Oberon TYPE sizes are the same as voc, that is
  - CHAR - always 8 bit
  - SHORTINT - always 8 bit
  - INTEGER - 16 bit on 32 bit systems, 32 bit on 64 bit systems.
  - LONGINT - 32 bit on 32 bit systems, 64 bit on 64 bit systems.

 I did experiment with making INTEGER always 32 bit and LONGINT always 64 bit (i.e. even on 32 bit platfroms), but soon found that the libraries assume 16 bit INTEGER and 32 bit LONGINT all over the place. Uncomment the '#define LARGE' on src/tools/make/configure.c line 14 to force 32 bit INTEGER and 64 bit LONGINT on all platforms.

#####Machine size

I don't see any really good solutions to different machine sizes. Existing code, such as the libraries, assumes that INTEGER is 16 bit and LONGINT is 32 bit and so is broken on 64 bit builds of voc. Looking at the voc source there is the remnants of an unfinished implementaton of built-in types INT8, INT16, INT32 and INT64. This code has not been completed or tested and I have not retained it where it added complexity.

So maybe completing the implementation of INTxx could help, but it does not solve (for example) the need for a type that always matches address size. Nor does it provide unsigned types. Implementation of low level memory management ideally needs both.

Wirth's latest spec includes a BYTE type (not SYSTEM.BYTE, just BYTE) that behaves as an unsigned 8 bit integer, for use in low level code. BYTE thus avoids the need for SYSTEM.VAL when manipulating 8 bit unsigned numeric values, making code easier to write and, more importantly, easier to read. I believe it makes sense to add Wirths's BYTE to voc.

Linux/Unix specifies many API datatypes and structure fields in terms of named C numeric types, with the result that they vary in size between implementations. This is perhaps the most driving force for adding support for various numeric types to voc - but they would better match the C types than be of fixed size.

So maybe one could provide Platform.int, Platform.long, Platform.longlong, Platform.unsignedint, Platform.unsignedlong, Platform.unsignedlonglong and, importantly for memory management, Platform.address (being unsigned).

Personally I miss Pascal and Modula's subrange variables. As well as being great for error detection (assuming value checking code is generated), they can also be used to imply variables of arbitrary sizes (e.g. 'VAR mybyte = 0..255;'). With these one could remove the Platform.int* types and replace them with constants Platform.MaxInt, Platform.MaxLong etc. I think this would be a cleaner more generalised option - but maybe, probably, it is a step too far. Always beware of over-generalising. Wirth found that most programmers did not use, or very rarely used, subrange types.

#####A possible TODO

When exiting abnormally, e.g. due to index out of range, report .Mod file name and line number at fault. Preferably include a stack trace. Wirth's original Pascal (Pascal 6000 on the CDC mainframe at ETHZ) had this in 1975. This could be achieved by including a table of line number (in .Mod file) vs code address, and having the runtime seach this table for the failure address. It would be quite a lot of work!

#####Norayr/voc issues addressed

######Issue 7 - 'silence ccomp warnings'.
This has been done.

######Issue 9 - 'oberon.par arguments'.
I analysed parameters for all platforms covered, including Ubuntu, FreeBSD, OpenBSD, Raspbian, Darwin, Cygwin and MS C, on a mixture of 32 and 64 bit architectures. The vast majority of info in the .par file is redundant. For example the size and alignment of char, unsigned char, int and float is independent of platform.

A single value is sufficient to specify alignment: above this size this value is the alignment, below this size, the alignment is the same as the type size. (Actually the latter is the type size rounded up to the enclosing power of two, but as all the Oberon type sizes are powers of two this step is unecessary.)

The only platform differences come around the meaning of 'long' vs 'long long', pointer size and alignment of 64 bit values. These are just 3 possible combinations:

| Pointer size | Alignment |
| ------------ | --------- |
|    32 bit    |   32 bit  |
|    32 bit    |   64 bit  |
|    64 bit    |   64 bit  |

######Issue 13 - 'prepare Linux/x86asm target'.
Linux is currently compiled using PlatfromUnix.Mod, but the integration of Windows support has made the Platform interface reasonably OS independent, so implementing a PlatformLinux.Mod using Linux kernel calls directly should be straightforward.

######Issue 14 - 'separate rtl from SYSTEM?'.
OS specific code is now all in Platformxxx.Mod. Memory management (including the loaded module list) is now in Heap.Mod. SYSTEM.h is platform independent, with minimal ifdefs to allow compiling on all platforms. For example, when SYSTEM.h/SYSTEM.c need to allocate memory, or to halt, they call into Platform.Mod.


