Import-Module .\MiscUtilities.psm1
Import-Module .\UnZipper.psm1
$codeZipBallDownloadPath = "https://fossies.org/linux/misc/dos2unix-7.5.2.tar.gz"
$codeZipBallTargetPath = ".\code.tar.gz"

function Fetch-Dos2UnixCode {
    if (Test-Path $codeZipBallTargetPath) {
        Remove-Item -Force -Path $codeZipBallTargetPath
    }
    
    [MiscUtilities.Utility]::DownloadFile($codeZipBallDownloadPath , $codeZipBallTargetPath)
    
    if (Test-Path ".\dos2unix-7.5.2") {
        Remove-Item -Recurse -Force -Path ".\dos2unix-7.5.2"
    }
    
    Expand-TarGz -Source $codeZipBallTargetPath -Dest .\
    Remove-Item -Force -Path $codeZipBallTargetPath
    
    $commonHeaderFileContents = [System.IO.File]::ReadAllText($(Get-Item ".\dos2unix-7.5.2\common.h").FullName)
    $flagsCode = [System.Text.RegularExpressions.Regex]::new("typedef\s*struct.*?\{.+?\}.*?CFlag", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($flagsCode.Match($commonHeaderFileContents)) {
        $flagsText = $flagsCode.Matches($commonHeaderFileContents)[0].ToString()
        [System.IO.File]::WriteAllText(".\dos2unix-7.5.2\common.h", 
            @"
#include <Windows.h>
#include "flag.h"
#define VER_REVISION "20240624"
#define VER_DATE "20240624"
$($flagsCode.Replace($commonHeaderFileContents, [System.String]::Empty))
"@
        )

        [System.IO.File]::WriteAllText(".\dos2unix-7.5.2\flag.h", 
            @"
#ifndef __D2U_FLAG_H__
#define __D2U_FLAG_H__
$flagsText;
#endif
"@)
    }
    else {
        throw "cannot extrace flags from common.h header file"
    }
    
    $intMainPattern = [System.Text.RegularExpressions.Regex]::new("int\s*main\s*\(.+", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $dos2unixCodeContents = [System.IO.File]::ReadAllText($(Get-Item ".\dos2unix-7.5.2\dos2unix.c").FullName)
    
    if ($intMainPattern.Match($dos2unixCodeContents)) {
        $dos2unixCodeContents = [System.IO.File]::WriteAllText($(Get-Item ".\dos2unix-7.5.2\dos2unix.c").FullName, $intMainPattern.Replace($dos2unixCodeContents, [System.String]::Empty))
    }
    else {
        throw "cannot match main function from dos2unix.c source code file"
    }
    
    $filesToCopy = @("common.c", "common.h", "dos2unix.c", "dos2unix.h", "querycp.c", "querycp.h", "flag.h")

    $filesToCopy | % { Copy-Item -Force -Path ".\dos2unix-7.5.2\$_" -Destination ".\$_" }
    Remove-Item -Recurse -Force -Path ".\dos2unix-7.5.2"
}