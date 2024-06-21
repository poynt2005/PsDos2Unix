#ifndef __D2U_FLAG_H__
#define __D2U_FLAG_H__

typedef struct
{
    int NewFile;    /* is in new file mode? */
    int verbose;    /* 0 = quiet, 1 = normal, 2 = verbose */
    int KeepDate;   /* should keep date stamp? */
    int ConvMode;   /* 0: ascii, 1: 7bit, 2: iso */
    int FromToMode; /* 0: dos2unix/unix2dos, 1: mac2unix/unix2mac */
    int NewLine;    /* if TRUE, then additional newline */
    int Force;      /* if TRUE, force conversion of all files. */
    int AllowChown; /* if TRUE, allow file ownership change in old file mode. */
    int Follow;     /* 0: skip symlink, 1: follow symbolic link, 2: replace symlink. */
    int status;
    int stdio_mode;       /* if TRUE, stdio mode */
    int to_stdout;        /* write output to stdout in old file mode */
    int error;            /* an error occurred */
    int bomtype;          /* byte order mark */
    int add_bom;          /* 1: write BOM */
    int keep_bom;         /* 1: write BOM if input file has BOM. 0: Do not write BOM */
    int keep_utf16;       /* 1: write UTF-16 format when input file is UTF-16 format */
    int file_info;        /* 1: print file information */
    int locale_target;    /* locale conversion target. 0: UTF-8; 1: GB18030 */
    unsigned int line_nr; /* line number where UTF-16 error occurs */
    int add_eol;          /* Add End Of Line to last line */
} CFlag;

#endif