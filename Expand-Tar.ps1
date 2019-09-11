Param(
        $tarFile,
        $dest = ($tarFile -replace '\.tar$','')
    )

function Expand-Tar($tarFile, $dest) {

    if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
        Save-Module -Name 7Zip4Powershell -Path .
        Install-Module -Name 7Zip4Powershell
    }

    Expand-7Zip $tarFile $dest
}

Expand-Tar $tarFile $dest