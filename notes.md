####Changes relative to Vishap Oberon

The biggest changes relative to current (March 2016) Vishap Oberon are in the build system and platform specific behaviour. Where possible platform differences have been automated or removed.

 - The same make commands are used for all platforms, Linux, BSD, Darwin and Windows:
   - 'make full' builds the compiler and library
   - 'make install' then installs the build into /opt/olang (or %ProgramFiles%\oloang or %ProgramFiles(x86)%\olang on Windows).

 - Oberon type sizes are platform independent:
   - CHAR, SHORTINT: 8 bit
   - INTEGER, REAL: 32 bit
   - SET, LONGINT, LONGREAL: 64 bit

 - The C program 'configure.c', a much expanded version of vocparam.c, generates all the platform specific make variables, and the configuration constants compiled into the compiler. Configure.c is compiled and executed at the start of every make command.

 - The vast majority of the makefile (olang.make) is platform independent (even across BSD make/GNU make) - just a stub makefile/GNUmakefile exists to run configure.c and start the platform independent makefile. (For native windows a separate make.cmd contains the equivalent functionality expressed as a Windows .cmd file.)

 - All duplicate files required to build Linux/BSD/Darwin variants have been removed by making them platform independent:
   - Rather than access Linux structures through Oberon RECORDs intended to match their memory layout, reference the
     fields or constants that we actually need to use from within code procedures.
   - Size dependent code is abstracted into simple definitions in SYSTEM.h and referenced from code procedures.
   - Add file search path feature to standard Files.Mod (with new Files.SetSearchPath procedure) and remove compiler
     specific Files0.Mod. SetSearchPath is now called from OPM.cmdln init removing the need for a compiler sepecific versions of Texts.Mod and Kernel.Mod.
   - Refactor Kernel.Mod, Unix.Mod and SYSTEM.Mod into Heap.Mod and PlatformUnix.Mod. Provide a separate PlatformWindows.Mod that uses the Win32 API directly.
   - Lots of places freely mixed 'long' and 'LONGINT' assuming they are the same thing. All have been changed to 'LONGINT' partly for consistency, but mostly as for some platforms LONGINT is 'long long', not 'long'.

 - The enlistment no longer includes compiled binaries. Instead it includes pre-prepared sets of C source covering the three datamodel types on the two operating system platforms. 

 - The bootstrap build required on a new platform is automatic, using one of the pre-prepared sets of C source. Indeed the initial build of a new enlistment on all platfroms uses these bootstrap C sources.

The result is that there is now a single version of earch Oberon source file, with the exceptions only of PlatformUnix.Mod/PlatformWindows.Mod in the compiler, and oocCILP32.Mod/oocCLP64.Mod/oocCLLP64.Mod in the ooc library.

All Oberon compilation warnings have been fixed. Most of these by the addition of ELSE parts to CASE statements.

All C compilation warnings have been fixed:
 - Conversion between integer and pointer of different size solved by casting with with uintptr_t as an intermediate type.
 - Conversion between signed and unsigned char types solved by explicitly casting 'CHAR's passed to system APIs in code procedures to 'char'.

HALT/exit code has been simplified. Exit now just calls the system exit API rather than calling the kill API and passing our own process ID. For runtime errors it now displayes the appropriate error message (e.g. Index out of range).

The jump buffer was not used by any code and has been removed. (It seems from a comment to have been intended for use during some termination code, but the termination code does not use it.)

Compilation errors now include the line number at the start of the displayed source line. The pos (character offset) is still displayed on the error message line. The error handling code was already doing some walking of the source file to find start and end of line - I changed this to walk through the source file from the start identifying line end positions, counting lines and caching the position at the start of the last error line. The resultant code is much simpler in my opinion, and displays the line number without losing the pos. The performance cost of walking the source file is not an issue.

######A few fix details:

 - Problem with size of literal parameters, specifically for NEW of dynamic arrays: In theory it is not necessary to specify literal numeric sizes on parameters to ANSI C functions as the compiler should know the size from the declaration of the called function. 
The Oberon compiler includes a procedure (OPM.PromoteIntConstToLInt) to generate 'l' at the end of long literal parameters on K&R C, but intentionally omits the 'l' when the compiler is known to be ANSI. (All currently supported compilers are ANSI). 
I can only imagine the reason to omit the 'l' is as a perceived optimization, but arguably there's no harm adding the 'l', and this test is an unnecessary complication.
**But** actually it is not safe to omit the 'l' where the parameter is being passed to a vararg. In this case the compiler cannot tell what size the code will fetch at run time and does not extend a literal integer to long. 
Why does this matter, surely Oberon does not use varargs? 
Unfortunately it does - for each of the individual dimension size parameters to NEW. On a 64 bit systems, each dimension size literal must be specified as 64 bit or the compiler will only pass 32 bits. (Which generates intermittent out of memory failures when the subsequent stack word is non-zero.)  
Removing the test for ANSI and thus always generating the trailing 'l' for LONGINTs is a sufficient fix for the data models supported by current Vishap Oberon. 
However there is a further complication - this is not sufficient for the LLP64 C data model favoured by Windows. In LLP64, 'long' is only 32 bit. The 64 bit integer type is  'long long' and literal numerics of this type would require an 'll' suffix. 
Rather than create more complex 'l' suffix code I chose to fix this by by generating a (LONGINT)(n) typecast, which forces n to the correct size in all cases.

 - Fix SYSTEM.H __VAL(t, x) originally defined as (\*(t\*)&(x)) - the original definition maps the new type onto the memory of the old and so produces the wrong result if the new type is larger than the old type. Corrected to the simpler ((t)(x)).

 - Problem with access to free'd memory in RETURN expressions: Oberon generates code to create local copies of dynamic strings passed by value (so that code is free to change the value parameter without affecting the original string). 
The copy is not allocated from the Oberon Heap, but direct from the OS (e.g. via malloc on Linux/Unix). At function return the copy is free'd by generating C code to call free before the return statement. 
There is a problem here when the expression on the return statement references the local string copy as the reference is now to free'd memory. 
All bets are off - the OS or C runtime could have done anything to this memory as part of heap management (e.g. used it for free chain linkage), and with pre-emptive multitasking it may have been reallocated and used for another purpose before the return expression refers to it. 
This is one of that category of frustrating bug that may hit rarely but is very difficult to diagnose when it does. 
The solution I have implemented is to generate a return value variable at the entry of every function, and generate code to evaluate the return expression into the variable *before* generating the code to free the local string copy. 
In theory the Oberon compiler could inspect the return value for reference to a local copy and only generate the result variable when necessary, however this is a lot of complicated code at function entry and I'm not sure it is necessary, really the C compiler should be able to optimize code with a result variable much the same as code without it.

 - Texts.WriteInt corrected to work with both 4 and 8 byte LONGINTs. Previously values with more than 11 digits caused an index out of range error.

 - olang.Translate no longer C compiles the main program twice.

#####A couple of potential TODOs.

 - When exiting abnormally, e.g. due to index out of range, report .Mod file name and line number at fault. Preferably include a stack trace. Wirth's original Pascal (Pascal 6000 on the CDC mainframe at ETHZ) had this in 1975. This could be achieved by including a table of line number (in .Mod file) vs code address, and having the runtime seach this table for the failure address. 
 
 - Go through the libraries and add support for 32 bit INTEGER and 64 bit LONGINT. I keep finding places which assume 16 bit INTEGER and 32 bit LONGINT.

 - Provide a compiler option to generate code where INTEGER and REAL are 16 bit and SET, LONGINT anf LONGREAL are 32 bit. While this is no significant performance benefit for modern Linux and Windows systems, it may make it easier to port old code that assumes these type sizes (as do some of the library files). 
Further, maybe implement INT8, INT16, INT32 and INT64. 
Maybe even UINT8, UINT16, UINT32 and UINT64. 
And also INTADDR / UINTADDR (same size as an address.) 
Indeed I miss Pascal and Modula's subrange variables (e.g. 'TYPE byte = 0..255;'). Implementing these would remove the need for most of the explicit integer type names.
i.e. it is unclear how far to go. 
 
#####Norayr/voc issues addressed by olang

######Issue 7 - 'silence ccomp warnings'. 
This has been done.

######Issue 9 - 'oberon.par arguments'. 
I analysed parameters for all platforms covered, including Ubuntu, FreeBSD, OpenBSD, Raspbian, Darwin, Cygwin and MS C, on a mixture of 32 and 64 bit architectures. The vast majority of info in the .par file is redundant. For example on all platforms, char, unsigned char, int and float have the same size and same alignment. The only differences come around the meaning of 'long' vs 'long long', pointer size and alignment of 64 bit values. By fixing LONGINT, LONGREAL and SET at 64 bits, there are only 3 possible PAR variants: 
  a) 32 bit pointers, with 64 bit vars aligned on 32 bit boundaries.
  b) 32 bit pointers, with 64 bit vars aligned on 64 bit boundaries.
  c) 64 bit pointers, with 64 bit vars aligned on 64 bit boundaries.
(All types smaller than 64 bits align on their own size on all combinations of platform and compiler).

######Issue 13 - 'prepare Linux/x86asm target'. 
Linux is currently compiled using PlatfromUnix.Mod, but the integration of Windows support has made the Platform interface reasonably OS independent, so implementing a PlatformLinux.Mod using Linux kernel calls directly should be straightforward.

######Issue 14 - 'separate rtl from SYSTEM?'. 
OS specific code is now all in Platformxxx.Mod. Memory management (including the loaded module list) is now in Heap.Mod. SYSTEM.h is platform independent, with minimal ifdefs to allow compiling on all platforms. For example, when SYSTEM.h/SYSTEM.c need to allocate memory, or to halt, they call into Platform.Mod.


