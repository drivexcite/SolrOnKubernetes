Param(
        $infile
    )

Function Unzip-Tgz {
    Param(
        $infile
    )

    $infile = If ($infile.StartsWith(".")) { $infile.Substring(1, $infile.Length - 1) } Else { $infile }
    $infile = If ($infile.StartsWith([IO.Path]::DirectorySeparatorChar)) { $infile.Substring(1, $infile.Length - 1) } Else { $infile }
    $fileName = If ([System.IO.Path]::IsPathRooted($infile)) { $infile } Else { $PSScriptRoot + [IO.Path]::DirectorySeparatorChar + $infile }

    $outfile = ($fileName -replace '\.tgz$','.tar')

    Write-Host $fileName
    Write-Host $outfile

    $input = New-Object System.IO.FileStream $fileName, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    $output = New-Object System.IO.FileStream $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)

    $buffer = New-Object byte[](1024)
    
    while($true) {
        $read = $gzipstream.Read($buffer, 0, 1024)

        if ($read -le 0)
        {
            break
        }

        $output.Write($buffer, 0, $read)
    }

    $gzipStream.Close()
    $output.Close()
    $input.Close()
}

Unzip-Tgz $infile