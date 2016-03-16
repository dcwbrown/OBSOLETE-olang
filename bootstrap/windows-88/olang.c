/* voc  Oberon compiler olang 0.5 [2016/03/14] for cygwin ILP32 using gcc xtspkamS */
#include "SYSTEM.h"
#include "Configuration.h"
#include "Heap.h"
#include "OPB.h"
#include "OPC.h"
#include "OPM.h"
#include "OPP.h"
#include "OPT.h"
#include "OPV.h"
#include "Platform.h"
#include "Strings.h"
#include "extTools.h"
#include "vt100.h"


static CHAR olang_mname[256];


export void olang_Module (BOOLEAN *done);
static void olang_PropagateElementaryTypeSizes (void);
export void olang_Translate (void);
static void olang_Trap (INTEGER sig);


void olang_Module (BOOLEAN *done)
{
	BOOLEAN ext, new;
	OPT_Node p = NIL;
	OPP_Module(&p, OPM_opt);
	if (OPM_noerr) {
		OPV_Init();
		OPV_AdrAndSize(OPT_topScope);
		OPT_Export(&ext, &new);
		if (OPM_noerr) {
			OPM_OpenFiles((void*)OPT_SelfName, ((LONGINT)(256)));
			OPC_Init();
			OPV_Module(p);
			if (OPM_noerr) {
				if (((OPM_mainProg || OPM_mainLinkStat) && __STRCMP(OPM_modName, "SYSTEM") != 0)) {
					OPM_DeleteNewSym();
				} else {
					if (new) {
						OPM_RegisterNewSym();
					} else if (ext) {
						OPM_RegisterNewSym();
					}
				}
			} else {
				OPM_DeleteNewSym();
			}
		}
	}
	OPM_CloseFiles();
	OPT_Close();
	*done = OPM_noerr;
}

static void olang_PropagateElementaryTypeSizes (void)
{
	OPT_bytetyp->size = OPM_ByteSize;
	OPT_sysptrtyp->size = OPM_PointerSize;
	OPT_chartyp->size = OPM_CharSize;
	OPT_settyp->size = OPM_SetSize;
	OPT_realtyp->size = OPM_RealSize;
	OPT_inttyp->size = OPM_IntSize;
	OPT_linttyp->size = OPM_LIntSize;
	OPT_lrltyp->size = OPM_LRealSize;
	OPT_sinttyp->size = OPM_SIntSize;
	OPT_booltyp->size = OPM_BoolSize;
}

void olang_Translate (void)
{
	BOOLEAN done;
	CHAR modulesobj[2048];
	CHAR objext[32];
	modulesobj[0] = 0x00;
	__MOVE(".o ", objext, 4);
	if (OPM_OpenPar()) {
		for (;;) {
			OPM_Init(&done, (void*)olang_mname, ((LONGINT)(256)));
			if (!done) {
				return;
			}
			OPM_InitOptions();
			olang_PropagateElementaryTypeSizes();
			Heap_GC(0);
			olang_Module(&done);
			if (!done) {
				OPM_LogLn();
				OPM_LogWStr((CHAR*)"Module compilation failed.", (LONGINT)27);
				OPM_LogLn();
				Platform_Exit(1);
			}
			if (!OPM_dontAsm) {
				if (OPM_dontLink) {
					extTools_Assemble(OPM_modName, ((LONGINT)(32)));
				} else {
					if (!(OPM_mainProg || OPM_mainLinkStat)) {
						extTools_Assemble(OPM_modName, ((LONGINT)(32)));
						Strings_Append((CHAR*)" ", (LONGINT)2, (void*)modulesobj, ((LONGINT)(2048)));
						Strings_Append(OPM_modName, ((LONGINT)(32)), (void*)modulesobj, ((LONGINT)(2048)));
						Strings_Append(objext, ((LONGINT)(32)), (void*)modulesobj, ((LONGINT)(2048)));
					} else {
						extTools_LinkMain((void*)OPM_modName, ((LONGINT)(32)), OPM_mainLinkStat, modulesobj, ((LONGINT)(2048)));
					}
				}
			}
		}
	}
}

static void olang_Trap (INTEGER sig)
{
	Heap_FINALL();
	if (sig == 3) {
		Platform_Exit(0);
	} else {
		if ((sig == 4 && Platform_HaltCode == -15)) {
			OPM_LogWStr((CHAR*)" --- olang: internal error", (LONGINT)27);
			OPM_LogLn();
		}
		Platform_Exit(2);
	}
}


export int main(int argc, char **argv)
{
	__INIT(argc, argv);
	__MODULE_IMPORT(Configuration);
	__MODULE_IMPORT(Heap);
	__MODULE_IMPORT(OPB);
	__MODULE_IMPORT(OPC);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPP);
	__MODULE_IMPORT(OPT);
	__MODULE_IMPORT(OPV);
	__MODULE_IMPORT(Platform);
	__MODULE_IMPORT(Strings);
	__MODULE_IMPORT(extTools);
	__MODULE_IMPORT(vt100);
	__REGMAIN("olang", 0);
	__REGCMD("Translate", olang_Translate);
/* BEGIN */
	Platform_SetInterruptHandler(olang_Trap);
	Platform_SetQuitHandler(olang_Trap);
	Platform_SetBadInstructionHandler(olang_Trap);
	OPB_typSize = OPV_TypSize;
	OPT_typSize = OPV_TypSize;
	olang_Translate();
	__FINI;
}
