#ifndef NIMBASE_H
#define NIMBASE_H

#include <stdint.h>

#define N_LIB_PRIVATE
#define N_NIMCALL(rettype, name) rettype name
#define N_CDECL(rettype, name) rettype name
#define NIM_CONST const
#define NIM_INTBITS 64

typedef char const* NCSTRING;
typedef intptr_t NI;
typedef uintptr_t NU;

static int nim_program_result = 0;

#endif
