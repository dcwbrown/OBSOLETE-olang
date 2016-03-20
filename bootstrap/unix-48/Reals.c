/* voc  1.2 [2016/03/20] for cygwin LP64 using gcc xtspkaSF */
#include "SYSTEM.h"




export void Reals_Convert (REAL x, INTEGER n, CHAR *d, LONGINT d__len);
export void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len);
export void Reals_ConvertHL (LONGREAL x, CHAR *d, LONGINT d__len);
export void Reals_ConvertL (LONGREAL x, INTEGER n, CHAR *d, LONGINT d__len);
export INTEGER Reals_Expo (REAL x);
export INTEGER Reals_ExpoL (LONGREAL x);
export REAL Reals_Ten (INTEGER e);
export LONGREAL Reals_TenL (INTEGER e);
static void Reals_Unpack (SYSTEM_BYTE *b, LONGINT b__len, SYSTEM_BYTE *d, LONGINT d__len);


REAL Reals_Ten (INTEGER e)
{
	REAL _o_result;
	LONGREAL r, power;
	r = (LONGREAL)1;
	power = (LONGREAL)10;
	while (e > 0) {
		if (__ODD(e)) {
			r = r * power;
		}
		power = power * power;
		e = __ASHR(e, 1);
	}
	_o_result = r;
	return _o_result;
}

LONGREAL Reals_TenL (INTEGER e)
{
	LONGREAL _o_result;
	LONGREAL r, power;
	r = (LONGREAL)1;
	power = (LONGREAL)10;
	for (;;) {
		if (__ODD(e)) {
			r = r * power;
		}
		e = __ASHR(e, 1);
		if (e <= 0) {
			_o_result = r;
			return _o_result;
		}
		power = power * power;
	}
	__RETCHK;
}

INTEGER Reals_Expo (REAL x)
{
	INTEGER _o_result;
	_o_result = (int)__MASK(__ASHR((LONGINT)(__VAL(INTEGER, x)), 23), -256);
	return _o_result;
}

INTEGER Reals_ExpoL (LONGREAL x)
{
	INTEGER _o_result;
	INTEGER h;
	__GET((LONGINT)(uintptr_t)&x + 4, h, INTEGER);
	_o_result = (int)__MASK(__ASHR((LONGINT)h, 20), -2048);
	return _o_result;
}

void Reals_ConvertL (LONGREAL x, INTEGER n, CHAR *d, LONGINT d__len)
{
	LONGINT i, j, k;
	if (x < (LONGREAL)0) {
		x = -x;
	}
	k = 0;
	if (n > 9) {
		i = __ENTIER(x / (LONGREAL)(LONGREAL)1000000000);
		j = __ENTIER(x - i * (LONGREAL)1000000000);
		if (j < 0) {
			j = 0;
		}
		while (k < 9) {
			d[__X(k, d__len)] = (CHAR)(__MOD(j, 10) + 48);
			j = __DIV(j, 10);
			k += 1;
		}
	} else {
		i = __ENTIER(x);
	}
	while (k < (LONGINT)n) {
		d[__X(k, d__len)] = (CHAR)(__MOD(i, 10) + 48);
		i = __DIV(i, 10);
		k += 1;
	}
}

void Reals_Convert (REAL x, INTEGER n, CHAR *d, LONGINT d__len)
{
	Reals_ConvertL(x, n, (void*)d, d__len);
}

static void Reals_Unpack (SYSTEM_BYTE *b, LONGINT b__len, SYSTEM_BYTE *d, LONGINT d__len)
{
	SHORTINT i, k;
	LONGINT len;
	i = 0;
	len = b__len;
	while ((LONGINT)i < len) {
		k = (int)__ASHR((int)(__VAL(CHAR, b[__X(i, b__len)])), 4);
		if (k > 9) {
			d[__X(__ASHL(i, 1), d__len)] = k + 55;
		} else {
			d[__X(__ASHL(i, 1), d__len)] = k + 48;
		}
		k = (int)__MASK((int)(__VAL(CHAR, b[__X(i, b__len)])), -16);
		if (k > 9) {
			d[__X(__ASHL(i, 1) + 1, d__len)] = k + 55;
		} else {
			d[__X(__ASHL(i, 1) + 1, d__len)] = k + 48;
		}
		i += 1;
	}
}

void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len)
{
	Reals_Unpack((void*)&y, ((LONGINT)(4)), (void*)d, d__len * ((LONGINT)(1)));
}

void Reals_ConvertHL (LONGREAL x, CHAR *d, LONGINT d__len)
{
	Reals_Unpack((void*)&x, ((LONGINT)(8)), (void*)d, d__len * ((LONGINT)(1)));
}


export void *Reals__init(void)
{
	__DEFMOD;
	__REGMOD("Reals", 0);
/* BEGIN */
	__ENDMOD;
}
