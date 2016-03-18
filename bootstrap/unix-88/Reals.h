/* voc  1.2 [2016/03/18] for cygwin LP64 using gcc xtspkaSF */

#ifndef Reals__h
#define Reals__h

#define LONGINT64
#include "SYSTEM.h"




import void Reals_Convert (REAL x, INTEGER n, CHAR *d, LONGINT d__len);
import void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len);
import void Reals_ConvertHL (LONGREAL x, CHAR *d, LONGINT d__len);
import void Reals_ConvertL (LONGREAL x, INTEGER n, CHAR *d, LONGINT d__len);
import INTEGER Reals_Expo (REAL x);
import INTEGER Reals_ExpoL (LONGREAL x);
import REAL Reals_Ten (INTEGER e);
import LONGREAL Reals_TenL (INTEGER e);
import void *Reals__init(void);


#endif
