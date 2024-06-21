$dllB64Content = "<%=DLL_B64_CONTENT%>"

$dllUuid = "<%=DLL_UUID%>"
$dllPath = "$env:TEMP\$dllUuid.dll"

if (-not (Test-Path $dllPath)) {
    [System.IO.File]::WriteAllBytes($dllPath, [System.Convert]::FromBase64String($dllB64Content))
}

$CsCode = @"
using System;
using System.Runtime.InteropServices;
namespace Dos2UnixNativeBinding
{
    public static class NativeBinding
    {
        [DllImport("$($dllPath.Replace("\", "\\"))", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern int DosToLinuxPublicApi(IntPtr szDosDocPath, IntPtr szUnixDocOutputPath, IntPtr pFlag);
    }
}
"@
Add-Type -TypeDefinition $CsCode -Language CSharp
Add-Type @"
    public enum ConvMode
    {
        Ascii = 0,
        SevenBit,
        Iso
    }

    public enum FollowMode
    {
        SkipSymlink = 0,
        FollowSymlink,
        ReplaceSymlink
    }

    public enum Bomtype
    {
        Mbs = 0,
        Utf16LE,
        Utf16BE,
        Utf8,
        Gb18030
    }

    public enum LocaleTarget
    {
        Utf8 = 0,
        Gb18030
    }

    public struct Dos2UnixFlags
    {
        public bool IsNewFile;
        public bool IsKeepDate;
        public ConvMode ConvMode;
        public bool IsNewLine;
        public bool IsForce;
        public bool IsAllowChown;
        public FollowMode FollowMode;
        public Bomtype Bomtype;
        public bool IsAddBom;
        public bool IskeepBom;
        public bool IskeepUtf16;
        public LocaleTarget LocaleTarget;
        public bool IsAddEol;
    }
"@


function Get-DefaultFlag {
    $flag = [Dos2UnixFlags]::new()

    $flag.IsNewFile = $false
    $flag.IsKeepDate = $false
    $flag.ConvMode = [ConvMode]::Ascii
    $flag.IsNewLine = $false
    $flag.IsForce = $false
    $flag.FollowMode = [FollowMode]::SkipSymlink
    $flag.Bomtype = [Bomtype]::Mbs
    $flag.IsAddBom = $false
    $flag.IskeepUtf16 = $false
    $flag.LocaleTarget = [LocaleTarget]::Utf8;
    $flag.IsAddEol = $false
    
    return $flag
}

function Convert-DosToUnix {
    param (
        [System.String]$SourceFile = [System.String]::Empty,
        [System.String]$DestFile = [System.String]::Empty,
        [Dos2UnixFlags]$Flags = $null
    )

    
    function Get-FlagPtr {
        param (
            [Dos2UnixFlags]$Flags
        )

        # (0) NewFile: 0
        # (1) verbose: 4
        # (2) KeepDate: 8
        # (3) ConvMode: 12
        # (4) FromToMode: 16
        # (5) NewLine: 20
        # (6) Force: 24
        # (7) AllowChown: 28
        # (8) Follow: 32
        # (9) status: 36
        # (10) stdio_mode: 40
        # (11) to_stdout: 44
        # (12) error: 48
        # (13) bomtype: 52
        # (14) add_bom: 56
        # (15) keep_bom: 60
        # (16) keep_utf16: 64
        # (17) file_info: 68
        # (18) locale_target: 72
        # (19) line_nr: 76
        # (20) add_eol: 80
        # Struct Size: 84

        $pFlag = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(84)

        for ($i = 0; $i -lt 84; $i++) {
            [System.Runtime.InteropServices.Marshal]::WriteByte($pFlag, $i, 0)
        }

        function Byte-Writer {
            param (
                [System.Byte[]]$InputByte,
                [System.Int32]$Offset
            )

            for ($i = 0; $i -lt $InputByte.Length; $i++) {
                [System.Runtime.InteropServices.Marshal]::WriteByte($pFlag, $i + $Offset, $inputByte[$i])
            }
        }

        $currentStructOffset = 0

        # NewFile Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Convert]::ToInt32($Flags.IsNewFile))) -Offset $currentStructOffset
        $currentStructOffset += 4

        # verbose Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes(0)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # KeepDate Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Convert]::ToInt32($Flags.IsKeepDate))) -Offset $currentStructOffset
        $currentStructOffset += 4

        # ConvMode Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Int32]$Flags.ConvMode)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # FromToMode Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes(0)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # NewLine Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Convert]::ToInt32($Flags.IsNewLine))) -Offset $currentStructOffset
        $currentStructOffset += 4

        # Force Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Convert]::ToInt32($Flags.IsForce))) -Offset $currentStructOffset
        $currentStructOffset += 4

        # AllowChown Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Convert]::ToInt32($Flags.IsAllowChown))) -Offset $currentStructOffset
        $currentStructOffset += 4

        # Follow Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Int32]$Flags.FollowMode)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # status Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes(0)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # stdio_mode Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes(0)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # to_stdout Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes(0)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # error Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes(0)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # bomtype Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Int32]$Flags.Bomtype)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # AddBom Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Convert]::ToInt32($Flags.IsAddBom))) -Offset $currentStructOffset
        $currentStructOffset += 4

        # keepBom Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Convert]::ToInt32($Flags.IskeepBom))) -Offset $currentStructOffset
        $currentStructOffset += 4

        # keepUtf16 Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Convert]::ToInt32($Flags.IskeepUtf16))) -Offset $currentStructOffset
        $currentStructOffset += 4

        # LocaleTarget Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Int32]$Flags.LocaleTarget)) -Offset $currentStructOffset
        $currentStructOffset += 4

        # line_nr Flag
        $currentStructOffset += 4

        # add_eol Flag
        Byte-Writer -InputByte $([System.BitConverter]::GetBytes([System.Convert]::ToInt32($Flags.IsAddEol))) -Offset $currentStructOffset
        $currentStructOffset += 4

        return $pFlag
    }

    $flagsToConv = $Flags
    if ($flagsToConv -eq $null) {
        $flagsToConv = Get-DefaultFlag
    }

    $src = [System.IO.Path]::GetFullPath($SourceFile)
    if (-not $flagsToConv.IsNewFile) {
        $dst = $src
    }
    $dst = [System.IO.Path]::GetFullPath($DestFile)

    if (-not (Test-Path $src)) {
        throw "cannot find source file: $src"
    }

    $dstParentFolder = [System.IO.Directory]::GetParent($dst).FullName
    if (-not (Test-Path $dstParentFolder)) {
        New-Item -Force -Path $dstParentFolder -ItemType Directory
    }

    $srcStrPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($src)
    $dstStrPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($dst)

    $nRetCode = [Dos2UnixNativeBinding.NativeBinding]::DosToLinuxPublicApi($srcStrPtr, $dstStrPtr, $(Get-FlagPtr -Flags $flagsToConv))

    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($srcStrPtr)
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($dstStrPtr)

    if ($nRetCode -ne 0) {
        throw "call dos to unix encountered a failure"
    }
}

