#include <stdio.h>
#include <stdlib.h>

#include "d2uapi.h"
#include "dos2unix.h"
#include "common.h"
#include "querycp.h"

const char *progname = "dos2unixapi";

int DosToLinuxPublicApiDefault(const char *szDosDocPath, const char *szUnixDocOutputPath)
{
    CFlag kFlag;

    kFlag.NewFile = 0;
    kFlag.verbose = 0;
    kFlag.KeepDate = 0;
    kFlag.ConvMode = CONVMODE_ASCII;
    kFlag.NewLine = 0;
    kFlag.Force = 0;
    kFlag.Follow = SYMLINK_SKIP;
    kFlag.status = 0;
    kFlag.stdio_mode = 1;
    kFlag.to_stdout = 0;
    kFlag.error = 0;
    kFlag.bomtype = FILE_MBS;
    kFlag.add_bom = 0;
    kFlag.keep_utf16 = 0;
    kFlag.file_info = 0;
    kFlag.locale_target = TARGET_UTF8;
    kFlag.add_eol = 0;

    int nRet = DosToLinuxPublicApi(szDosDocPath, szUnixDocOutputPath, &kFlag);
    return nRet;
}

int DosToLinuxPublicApi(const char *szDosDocPath, const char *szUnixDocOutputPath, CFlag *pFlag)
{
    pFlag->verbose = 0;
    pFlag->file_info = 0;
    pFlag->to_stdout = 0;
    pFlag->FromToMode = 0;
    pFlag->stdio_mode = 0;
    pFlag->error = 0;

    int conversion_error;

    if (pFlag->NewFile)
    {
        conversion_error = ConvertNewFile(szDosDocPath, szUnixDocOutputPath, pFlag, progname, ConvertDosToUnix);
        if (pFlag->verbose)
            print_messages(pFlag, szDosDocPath, szUnixDocOutputPath, progname, conversion_error);
    }
    else
    {
        if (pFlag->file_info)
        {

            conversion_error = GetFileInfo(szUnixDocOutputPath, pFlag, progname);
            print_messages_info(pFlag, szUnixDocOutputPath, progname);
        }
        else
        {
            /* Old file mode */
            if (pFlag->to_stdout)
            {
                conversion_error = ConvertToStdout(szUnixDocOutputPath, pFlag, progname, ConvertDosToUnix);
            }
            else
            {
                conversion_error = ConvertNewFile(szUnixDocOutputPath, szUnixDocOutputPath, pFlag, progname, ConvertDosToUnix);
            }
            if (pFlag->verbose)
                print_messages(pFlag, szUnixDocOutputPath, NULL, progname, conversion_error);
        }
    }

    return conversion_error;
}