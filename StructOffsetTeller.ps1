Write-Host "[Important] You must format C struct code by code formatter like Visual studio, Clang formatter... etc"
Write-Host "[Important] You must use typedef struct {...} STRUCT_NAME; pattern as a struct defination code, must NOT include struct pointer defination"
Write-Host "[Important] Must install mingw-gccx64 compiler in your computer"

$inclSystemHeaders = @(
    "Windows.h",
    "stdio.h",
    "stdlib.h",
    "string.h",
    "stddef.h"
)

$structDef = @"
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
"@

$structPattern = [System.Text.RegularExpressions.Regex]::new("struct.*?\{.+?\}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
$structNamePattern = [System.Text.RegularExpressions.Regex]::new("typedef\s+struct.*?\{.+?\}\s+(.+)?;", [System.Text.RegularExpressions.RegexOptions]::Singleline)

if ($structPattern.IsMatch($structDef) -and $structNamePattern.IsMatch($structDef)) {
    $structNameMatchedResult = $($structNamePattern.Match($structDef)[0].ToString())
    $structNameMatchedResultSplit = $structNameMatchedResult.Split(' ')
    $structName = $structNameMatchedResultSplit[$structNameMatchedResultSplit.Length - 1].Replace(';', [System.String]::Empty).Trim()

    $matchedResult = $($structPattern.Match($structDef)[0].ToString())
    $structContents = [System.Text.RegularExpressions.Regex]::new("}$").Replace([System.Text.RegularExpressions.Regex]::new("struct.*?\{", [System.Text.RegularExpressions.RegexOptions]::Singleline).Replace($matchedResult, [System.String]::Empty), [System.String]::Empty)
    
    $memberContents = @()

    $fieldIdx = 0
    foreach ($line in $structContents.Split([System.Environment]::NewLine)) {
        $lineTrimmed = $line.Trim()
        if ($lineTrimmed.Length -eq 0) {
            continue
        }
        
        $resultLine = $lineTrimmed

        $firstSinglineCommentIndex = $lineTrimmed.IndexOf("//")
        if ($firstSinglineCommentIndex -gt 0) {
            $resultLine = $resultLine.SubString(0, $firstSinglineCommentIndex)
        }
        $resultLine = $resultLine.Trim()
        
        $multiLineCommentPattern = [System.Text.RegularExpressions.Regex]::new("/\*.+?\*/")
        $resultLine = $multiLineCommentPattern.Replace($resultLine, [System.String]::Empty)
        $resultLine = $resultLine.Trim()

        $firstSepIndex = $resultLine.IndexOf(';')
        
        $charArr = @()
        for ($i = $firstSepIndex - 1; $i -ge 0; $i--) {
            if ($resultLine[$i] -eq ' ') {
                break
            }
            $charArr += $resultLine[$i]
        }
        
        $fieldStr = [System.String]::Empty
        for ($i = $charArr.Length; $i -ge 0; $i--) {
            $fieldStr += $charArr[$i]
        }
        $resultLine = $fieldStr.Trim()
        $resultLine = "printf(`"($fieldIdx) $resultLine`: %d\n`", offsetof($structName, $resultLine))"
        $memberContents += $resultLine
        $fieldIdx++
    }

    $headersCode = [System.String]::Empty
    $inclSystemHeaders | % { $headersCode += "#include <$_>$([System.Environment]::NewLine)" }

    $mainCode = [System.String]::Empty
    $memberContents | % { $mainCode += "$_;$([System.Environment]::NewLine)" }

    $cCode = @"
$headersCode
$structNameMatchedResult
int main()
{
    $mainCode
    printf("Struct Size: %d\n", sizeof($structName));
    return 0;
}
"@

    $codeGuid = [System.Guid]::NewGuid().ToString()

    $cCodeResultPath = "$env:temp\$codeGuid.c"
    $executableOutputPath = "$env:temp\$codeGuid.exe"
    [System.IO.File]::WriteAllText($cCodeResultPath, $cCode)

    & gcc $cCodeResultPath -o $executableOutputPath
    Remove-Item -Force -Path $cCodeResultPath

    $executableExecutedResult = $($(& $executableOutputPath).Split([System.Environment]::NewLine) | % { $_.Trim() })
    Remove-Item -Force -Path $executableOutputPath

    Write-Host "$([System.Environment]::NewLine)$([System.Environment]::NewLine)"
    Write-Host "******************* Please Copy Text Below as Comment in your code ******************* $([System.Environment]::NewLine)$([System.Environment]::NewLine)"

    foreach ($line in $executableExecutedResult) {
        Write-Host $line
    }

    Write-Host "$([System.Environment]::NewLine)$([System.Environment]::NewLine)************************************************************************************** $([System.Environment]::NewLine)"
    Write-Host "Finished!!"
}