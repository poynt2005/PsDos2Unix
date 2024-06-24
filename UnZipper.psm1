Import-Module .\MiscUtilities.psm1

if ((-not (Test-Path .\cs7z)) -or (-not ((Get-Item .\cs7z).PSIsContainer))) {
    $cs7zNugetBallDownloadPath = "https://www.nuget.org/api/v2/package/SevenZipExtractor/1.0.17"
    $cs7zNugetBallDestPath = ".\cs7z.zip"

    if (Test-Path $cs7zNugetBallDestPath) {
        Remove-Item -Force -Path $cs7zNugetBallDestPath
    }

    [MiscUtilities.Utility]::DownloadFile($cs7zNugetBallDownloadPath , $cs7zNugetBallDestPath)

    Expand-Archive -Force -Path $cs7zNugetBallDestPath -DestinationPath .\cs7z

    if (Test-Path $cs7zNugetBallDestPath) {
        Remove-Item -Force -Path $cs7zNugetBallDestPath
    }

    $currentCs7zItems = $(Get-ChildItem .\cs7z)

    Copy-Item -Force -Path .\cs7z\build\x64\7z.dll -Destination .\cs7z\7z.dll
    Copy-Item -Force -Path .\cs7z\lib\net45\SevenZipExtractor.dll .\cs7z\SevenZipExtractor.dll

    $currentCs7zItems | % { Remove-Item -Force -Recurse -Path $_.FullName }
}

Add-Type -Path .\cs7z\SevenZipExtractor.dll

function Expand-TarGz {
    param (
        [System.String]$Source,
        [System.String]$Dest
    )

    New-Item -Force -Path $Dest -ItemType Directory
    $destPath = $(Get-Item $Dest).FullName

    $archiveFile = [SevenZipExtractor.ArchiveFile]::new($(Get-Item $Source).FullName)
    $ms = [System.IO.MemoryStream]::new()
    $archiveFile.Entries[0].Extract($ms);

    $tarFile = [SevenZipExtractor.ArchiveFile]::new($ms, [SevenZipExtractor.SevenZipFormat]::Tar)
 
    foreach ($entry in $tarFile.Entries) {
        $destPath = [System.IO.Path]::Combine($Dest, $entry.FileName)
        if ($entry.IsFolder -and (-not (Test-Path $destPath))) {
            New-Item -Path $destPath -ItemType Directory -Force
            continue
        }
        $entry.Extract($destPath)
    }

    $tarFile.Dispose()
    $archiveFile.Dispose()
}