// Generate platform specific files:
//   BasicTypeParameters - Oberon compiler type sizes and alignments
//   Configuration.Mod   - version and directory information to build into the compiler
//   make.include        - make variable settings for this configuration
// Also tests validity of SYSTEM.h macros on this platform.
// from vocparam.c originally by J. Templ 23.6.95

#include "SYSTEM.h"  

#ifdef _WIN32
  #define strncasecmp _strnicmp
#else
  #include <sys/types.h>
  #include <sys/stat.h>
  #include <fcntl.h>
  #include <sys/utsname.h>
  #include <unistd.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <time.h>



#define O_VER 1.2



#define macrotostringhelper(s) #s
#define macrotostring(s) macrotostringhelper(s)



void fail(char *msg) {printf("Error: %s\n", msg); exit(1);}
void assert(int truth, char *complaint) {if (!truth) fail(complaint);}



char builddate[256];
char installdir[256];
char versionstring[256];
char osrelease[1024];
char cwd[1024];

char* version = macrotostring(O_VER);

char* dataModel   = NULL;
char* sizeAlign   = NULL;
char* compiler    = NULL;
char* cc          = NULL;
char* os          = NULL;
char* platform    = NULL;
char* binext      = NULL;
char* staticlink  = NULL;  // Static compilation option - none on darwin / windows.
int   alignment   = 0;
int   addressSize = 0;




void determineLinuxVariant() {
  os = "linux";
  FILE *fd = fopen("/etc/os-release", "r");
  if (fd == NULL) return;
  while (fgets(osrelease, sizeof(osrelease), fd) != NULL) {
    if (strncasecmp(osrelease, "id=", 3) == 0) {
      int i=3;
      while (osrelease[i] == '"') {i++;}
      int j=i;
      while (osrelease[j] > '"') {j++;}
      if (j>i) {
        osrelease[j] = 0;
        os = osrelease + i;
      }
      break;
    }
  }
  fclose(fd);
}



void determineOS() {
  #ifdef _WIN32
    os = "windows";  platform = "windows";  binext = ".exe"; staticlink = "";
  #else
    os = "unknown";  platform = "unix";     binext = "";     staticlink = "-static";

    struct utsname sys;
    if (uname(&sys)<0) fail("Couldn't get sys name - uname() failed.");
  
    if      (strncasecmp(sys.sysname, "cygwin",  6) == 0) {os = "cygwin";  binext = ".exe";}
    else if (strncasecmp(sys.sysname, "linux",   5) == 0) {determineLinuxVariant();}
    else if (strncasecmp(sys.sysname, "freebsd", 5) == 0) {os = "freebsd";}
    else if (strncasecmp(sys.sysname, "openbsd", 5) == 0) {os = "openbsd";}
    else if (strncasecmp(sys.sysname, "darwin",  5) == 0) {os = "darwin";  staticlink = "";}
    else {
      fprintf(stderr, "\n\n** Unrecognised utsname.sysname '%s' returned by uname().\n", sys.sysname);
      fprintf(stderr, "** Please add a test for this OS in src/buildtools/configure.c\n");
      fprintf(stderr, "** in function determineOS() near line %d.\n\n", __LINE__-3);
      fail("Unrecognised OS architecture name (sysname) returned by uname.");
    }
  #endif
}


void determineCCompiler() {
  #if defined(__MINGW32__)
    compiler = "mingw";
    if (sizeof (void*) == 4) {
      cc = "i686-w64-mingw32-gcc -g"; 
    } else {
      cc = "x86_64-w64-mingw32-gcc -g";
    }
  #elif defined(__clang__)
    compiler = "clang";
    cc       = "clang -fPIC -g";
  #elif defined(__GNUC__)
    compiler = "gcc";
    cc       = "gcc -g";
  #elif defined(_MSC_VER)
    compiler = "msc";
    cc       = "cl /nologo";
  #else
    fail("Unrecognised C compiler.");
  #endif
}



void determineInstallDirectory() {
  #if defined(_MSC_VER)  
    #ifdef _WIN64
      sprintf(installdir, "%s\\olang", getenv("ProgramFiles"));
    #else
      sprintf(installdir, "%s\\olang", getenv("ProgramFiles(x86)"));
    #endif
  #else
    strncpy(installdir, "/opt/olang", sizeof(installdir));
  #endif
}



void determineBuildDate() {
  time_t t = time(0);
  strftime(builddate, sizeof(builddate), "%Y/%m/%d", localtime(&t));
}



struct {CHAR ch; CHAR     x;}    c;
struct {CHAR ch; BOOLEAN  x;}    b;
struct {CHAR ch; SHORTINT x;}    si;
struct {CHAR ch; INTEGER  x;}    i;
struct {CHAR ch; LONGINT  x;}    li;
struct {CHAR ch; SET      x;}    s;
struct {CHAR ch; REAL     x;}    r;
struct {CHAR ch; LONGREAL x;}    lr;
struct {CHAR ch; void*    x;}    p;
struct {CHAR ch; void   (*x)();} f;

struct {CHAR ch;}    rec0;
struct {CHAR x[65];} rec2;


void determineCDataModel() {
  addressSize = sizeof(void*);
  alignment = (char*)&li.x - (char*)&li; 

  // Check the sizes of the Oberon basic types as defined in SYSTEM.h.
  // By design these are fixed across all supported platfroms.

  assert(sizeof(CHAR)     == 1, "Size of CHAR not 1.");
  assert(sizeof(BOOLEAN)  == 1, "Size of BOOLEAN not 1.");
  assert(sizeof(SHORTINT) == 1, "Size of SHORTINT not 1.");
  assert(sizeof(INTEGER)  == 4, "Size of INTEGER not 4 bytes.");
  assert(sizeof(LONGINT)  == 8, "Size of LONGINT not 8 bytes.");
  assert(sizeof(SET)      == 8, "Size of SET not 8 bytes.");
  assert(sizeof(REAL)     == 4, "Size of REAL not 4 bytes.");
  assert(sizeof(LONGREAL) == 8, "Size of LONGREAL not 8 bytes.");
  assert(sizeof(f.x) == sizeof(p.x), "Size of function pointer differs from size of data pointer.");

  assert((alignment == 4) || (alignment == 8), "Alignment of LONGINT neither 4 nor 8 bytes.");

  assert(((char*)&c.x  - (char*)&c) == 1, "Alignment of CHAR not 1.");
  assert(((char*)&b.x  - (char*)&b) == 1, "Alignment of BOOLEAN not 1.");
  assert(((char*)&si.x - (char*)&si) == 1, "Alignment of SHORTINT not 1.");
  assert(((char*)&i.x  - (char*)&i) == 4, "Alignment of INTEGER not 4 bytes.");
  assert(((char*)&r.x  - (char*)&r) == 4, "Alignment of REAL not 4 bytes.");
  assert(((char*)&lr.x - (char*)&lr) == alignment, "Alignment of LONGREAL differs from alignment of LONGINT.");
  assert(((char*)&s.x  - (char*)&s) == alignment, "Alignment of SET differs from alignmnet of LONGINT.");
  assert(((char*)&p.x  - (char*)&p) == addressSize, "Alignment of data pointer differs from address size.");
  assert(((char*)&f.x  - (char*)&f) == addressSize, "Alignment of data pointer differs from address size.");

  assert(sizeof(rec0) ==  1, "CHAR wrapped in record aligns differently to CHAR alone.");
  assert(sizeof(rec2) == 65, "CHAR array wrapped in record aligns differently to CHAR array alone.");

  assert(sizeof(LONGINT) >= sizeof p.x, "LONGINT should have at least the same size as data pointers.");
  assert(sizeof(LONGINT) >= sizeof f.x, "LONGINT should have at least the same size as function pointers.");

  if (((sizeof(rec2)==65) == (sizeof(rec0)==1)) && ((sizeof(rec2)-64) != sizeof(rec0)))
    printf("error: unsupported record layout  sizeof(rec0) = %lu  sizeof(rec2) = %lu\n", (long)sizeof(rec0), (long)sizeof(rec2));

  long x = 1;
  assert(*(char*)&x == 1, "C compiler does not store multibyte numeric values in little-endian order.");

  // Now we know type sizes are as expected, generate C memory model parameters

  if      (addressSize == 4  &&  sizeof(int)  == 4) dataModel = "ILP32";  // Unix/Linux and modern Windows
  else if (addressSize == 8  &&  sizeof(long) == 4) dataModel = "LLP64";  // Windows/mingw 64 bit
  else if (addressSize == 8  &&  sizeof(long) == 8) dataModel = "LP64";   // Unix/Linux 64 bit
  else fail("Unsupported combination of address size and int/long size.");

  if      (addressSize == 4  &&  alignment == 4) sizeAlign = "44";
  else if (addressSize == 4  &&  alignment == 8) sizeAlign = "48";
  else if (addressSize == 8  &&  alignment == 8) sizeAlign = "88";
  else fail("Unsupported combination of address size and LONGINT alignment.");
}





void testSystemH() {
  /* test the __ASHR macro */
  assert(__ASHR(-1, 1) == -1, "ASH(-1, -1) # -1.");
  assert(__ASHR(-2, 1) == -1, "ASH(-2, -1) # -1.");
  assert(__ASHR(0, 1)  ==  0, "ASH(0, 1) #  0.");
  assert(__ASHR(1, 1)  ==  0, "ASH(1, 1) #  0.");
  assert(__ASHR(2, 1)  ==  1, "ASH(2, 1) #  1.");

  /* test the __SETRNG macro */
  long x = 0;
  long y = sizeof(SET)*8 - 1;
  assert(__SETRNG(x, y) == -1, "SETRNG(0, MAX(SET)) != -1.");

  /* test string comparison for extended ascii */
  {char a[10], b[10];
    a[0] = (CHAR)128; a[1] = 0;
    b[0] = 0;
    assert(__STRCMP(a, b) >= 0, "__STRCMP(a, b) with extended ascii charcters; should be unsigned.");
  }
}




void writeMakeParameters() {
  FILE *fd = fopen("Configuration.Make", "w");
  if (fd == NULL) fail("Couldn't create Configuration.make.");
  fprintf(fd, "OLANGDIR=%s\n",   cwd);
  fprintf(fd, "COMPILER=%s\n",   compiler);
  fprintf(fd, "OS=%s\n",         os);
  fprintf(fd, "VERSION=%s\n",    version);
  fprintf(fd, "DATAMODEL=%s\n",  dataModel);
  fprintf(fd, "SIZEALIGN=%s\n",  sizeAlign);
  fprintf(fd, "INSTALLDIR=%s\n", installdir);
  fprintf(fd, "PLATFORM=%s\n",   platform);
  fprintf(fd, "BINEXT=%s\n",     binext);
  fprintf(fd, "COMPILE=%s\n",    cc);
  fprintf(fd, "STATICLINK=%s\n", staticlink);
  fclose(fd);
}




void writeConfigurationMod() {
  FILE *fd = fopen("Configuration.Mod", "w");
  if (fd == NULL) fail("Couldn't create Configuration.Mod.");

  fprintf(fd, "MODULE Configuration;\n");
  fprintf(fd, "CONST\n");
  fprintf(fd, "  versionLong* = '%s';\n", versionstring);
  fprintf(fd, "  addressSize* = %d;\n",   addressSize);
  fprintf(fd, "  alignment*   = %d;\n",   alignment);
  fprintf(fd, "  compiler*    = '%s';\n", compiler);
  fprintf(fd, "  compile*     = '%s';\n", cc);
  fprintf(fd, "  dataModel*   = '%s';\n", dataModel);
  fprintf(fd, "  installdir*  = '%s';\n", installdir);
  fprintf(fd, "  staticLink*  = '%s';\n", staticlink); 
  fprintf(fd, "END Configuration.\n");

  fclose(fd);
}




int main()
{
  getcwd(cwd, sizeof(cwd));

  determineOS();
  determineCCompiler();
  determineCDataModel();
  determineBuildDate();
  determineInstallDirectory();

  testSystemH();

  snprintf(versionstring, sizeof(versionstring), 
           "%s [%s] for %s %s using %s",
           version, builddate, os, dataModel, compiler);

  writeConfigurationMod();
  writeMakeParameters();

  printf("%s\n", versionstring);
}
