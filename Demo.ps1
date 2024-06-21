IMport-Module .\Dos2Unix.psm1

$src = $(Get-Item .\CRLF.txt)

$defaultFlag = $(Get-DefaultFlag)
$defaultFlag.IsNewFile = $true

Convert-DosToUnix -SourceFile $($src.FullName) -DestFile .\LF.txt -Flags $defaultFlag
