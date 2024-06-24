Import-Module .\FetchCode.psm1

$restCodeToRemove = $(Fetch-Dos2UnixCode)

$dllUuid = [System.Guid]::NewGuid().ToString()

$templateContent = [System.IO.File]::ReadAllText($(Get-Item .\Dos2Unix.template.psm1).FullName)
$resultContent = $templateContent
$templateVariablePattern = [System.Text.RegularExpressions.Regex]::new("<%=[A-Z0-9_]+%>")

$libPath = $([System.IO.Path]::Combine($env:TEMP, "$dllUuid"))

& gcc -fPIC -static-libgcc -c dos2unix.c -o dos2unix.o
& gcc -fPIC -static-libgcc -c common.c -o common.o
& gcc -fPIC -static-libgcc -c querycp.c -o querycp.o
& gcc -fPIC -static-libgcc -c dos2unixapi.c -o dos2unixapi.o
& gcc -fPIC -static-libgcc --shared common.o dos2unix.o querycp.o dos2unixapi.o "-Wl,--out-implib,$libPath.lib" -o "$libPath.dll"

$variableReplacer = @{
    DLL_B64_CONTENT = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$libPath.dll"))
    DLL_UUID        = $dllUuid
}

$variableReplacerKeys = $($variableReplacer.GetType().GetProperty('Keys').GetValue($variableReplacer) | % { $_.ToString() })

$templateVariablePattern.Matches($templateContent) | % {
    $matchedString = $_.ToString()

    $replacerKey = $matchedString.SubString(3, $matchedString.Length - 5)

    $variableReplacerKeys | % {
        if ($_ -eq $replacerKey) {
            $resultContent = $resultContent.Replace($matchedString, $variableReplacer[$_])
        }
    }
}

New-Item -Force -Path .\Dos2Unix.psm1

[System.IO.File]::WriteAllText($(Get-Item .\Dos2Unix.psm1).FullName, $resultContent)

Remove-Item -Force -Path "$libPath.lib"
Remove-Item -Force -Path "$libPath.dll"
Get-ChildItem .\ | ? { $_.Extension.ToLower() -eq ".o" } | % { Remove-Item -Force -Path $_.FullName }

@("common.c", "common.h", "dos2unix.c", "dos2unix.h", "querycp.c", "querycp.h", "flag.h") | % { Remove-Item -Force -Path $_ }