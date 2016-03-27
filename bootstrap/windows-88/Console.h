/* voc  1.2 [2016/03/25] for cygwin LP64 using gcc xtspkaSF */

#ifndef Console__h
#define Console__h

#define LARGE
#include "SYSTEM.h"




import void Console_Bool (BOOLEAN b);
import void Console_Char (CHAR ch);
import void Console_Flush (void);
import void Console_Hex (LONGINT i);
import void Console_Int (LONGINT i, LONGINT n);
import void Console_Ln (void);
import void Console_Read (CHAR *ch);
import void Console_ReadLine (CHAR *line, LONGINT line__len);
import void Console_String (CHAR *s, LONGINT s__len);
import void *Console__init(void);


#endif