/* voc  1.2 [2016/03/25] for cygwin LP64 using gcc xtspkaSF */

#ifndef extTools__h
#define extTools__h

#define LARGE
#include "SYSTEM.h"




import void extTools_Assemble (CHAR *moduleName, LONGINT moduleName__len);
import void extTools_LinkMain (CHAR *moduleName, LONGINT moduleName__len, BOOLEAN statically, CHAR *additionalopts, LONGINT additionalopts__len);
import void *extTools__init(void);


#endif
