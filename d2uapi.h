#ifndef __D2U_API_H__
#define __D2U_API_H__

#include "flag.h"

#ifdef __cplusplus
extern "C"
{
#endif
    __declspec(dllexport) int DosToLinuxPublicApi(const char *szDosDocPath, const char *szUnixDocOutputPath, CFlag *pFlag);

#ifdef __cplusplus
}
#endif

#endif