/* voc  1.2 [2016/03/17] for cygwin ILP32 using gcc xtspkaSF */
#include "SYSTEM.h"




export void Reals_Convert (REAL x, INTEGER n, CHAR *d, LONGINT d__len);
export void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len);
export void Reals_ConvertHL (LONGREAL x, CHAR *d, LONGINT d__len);
export void Reals_ConvertL (LONGREAL x, INTEGER n, CHAR *d, LONGINT d__len);
export INTEGER Reals_Expo (REAL x);
export INTEGER Reals_ExpoL (LONGREAL x);
export void Reals_IntToStr (LONGINT int_, CHAR *str, LONGINT str__len);
static void Reals_Reverse0 (CHAR *str, LONGINT str__len, INTEGER start, INTEGER end);
export void Reals_SetExpo (INTEGER e, REAL *x);
export void Reals_SetExpoL (INTEGER e, LONGREAL *x);
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
	_o_result = (int)__MASK(__ASHR(__VAL(LONGINT, x), 23), -256);
	return _o_result;
}

INTEGER Reals_ExpoL (LONGREAL x)
{
	INTEGER _o_result;
	LONGINT h;
	__GET((LONGINT)(uintptr_t)&x + 4, h, LONGINT);
	_o_result = (int)__MASK(__ASHR(h, 20), -2048);
	return _o_result;
}

void Reals_SetExpo (INTEGER e, REAL *x)
{
	*x = (REAL)((__VAL(SET, *x) & ~0x01fe) | (SET)__ASHL((LONGINT)e, 23));
}

void Reals_SetExpoL (INTEGER e, LONGREAL *x)
{
	SET h;
	__GET((LONGINT)(uintptr_t)x + 4, h, SET);
	h = (h & ~0x0ffe) | (SET)__ASHL((LONGINT)e, 20);
	__PUT((LONGINT)(uintptr_t)x + 4, h, SET);
}

static void Reals_Reverse0 (CHAR *str, LONGINT str__len, INTEGER start, INTEGER end)
{
	CHAR h;
	while (start < end) {
		h = str[__X(start, str__len)];
		str[__X(start, str__len)] = str[__X(end, str__len)];
		str[__X(end, str__len)] = h;
		start += 1;
		end -= 1;
	}
}

void Reals_IntToStr (LONGINT int_, CHAR *str, LONGINT str__len)
{
	CHAR b[21];
	INTEGER s, e;
	SHORTINT maxLength;
	maxLength = 20;
	if (int_ == (-9223372036854775807-1)) {
		__MOVE("-9223372036854775808", b, 21);
		e = 20;
	} else {
		if (int_ < 0) {
			b[0] = '-';
			int_ = -int_;
			s = 1;
		} else {
			s = 0;
		}
		e = s;
		do {
			b[__X(e, ((LONGINT)(21)))] = (CHAR)(__MOD(int_, 10) + 48);
			int_ = __DIV(int_, 10);
			e += 1;
		} while (!(int_ == 0));
		b[__X(e, ((LONGINT)(21)))] = 0x00;
		Reals_Reverse0((void*)b, ((LONGINT)(21)), s, e - 1);
	}
	__COPY(b, str, str__len);
}

void Reals_Convert (REAL x, INTEGER n, CHAR *d, LONGINT d__len)
{
	LONGINT i, k;
	if (x < (REAL)0) {
		x = -x;
	}
	i = __ENTIER(x);
	k = 0;
	while (k < (LONGINT)n) {
		d[__X(k, d__len)] = (CHAR)(__MOD(i, 10) + 48);
		i = __DIV(i, 10);
		k += 1;
	}
}

void Reals_ConvertL (LONGREAL x, INTEGER n, CHAR *d, LONGINT d__len)
{
	LONGINT i, j, k;
	CHAR str[32];
	if (x < (LONGREAL)0) {
		x = -x;
	}
	i = __ENTIER(x);
	if (i < 0) {
		i = -i;
	}
	Reals_IntToStr(i, (void*)str, ((LONGINT)(32)));
	if ((LONGINT)n >= d__len) {
		n = (int)d__len - 1;
	}
	d[__X(n, d__len)] = 0x00;
	j = n - 1;
	if (j < 0) {
		j = 0;
	}
	k = 0;
	do {
		d[__X(j, d__len)] = str[__X(k, ((LONGINT)(32)))];
		j -= 1;
		k += 1;
	} while (!(str[__X(k, ((LONGINT)(32)))] == 0x00 || j < 0));
	while (j >= 0) {
		d[__X(j, d__len)] = '0';
		j -= 1;
	}
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
