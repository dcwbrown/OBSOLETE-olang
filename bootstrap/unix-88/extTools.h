/* voc  Oberon compiler olang 0.5 [2016/03/14] for cygwin ILP32 using gcc xtspkaSF */

#ifndef extTools__h
#define extTools__h

#include "SYSTEM.h"




import void extTools_Assemble (CHAR *moduleName, LONGINT moduleName__len);
import void extTools_LinkMain (CHAR *moduleName, LONGINT moduleName__len, BOOLEAN statically, CHAR *additionalopts, LONGINT additionalopts__len);
import void *extTools__init(void);


#endif
