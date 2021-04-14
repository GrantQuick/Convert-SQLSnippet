Function Get-SQLSnippet{
    <#
    .SYNOPSIS
        Function to convert an SSMS snippet file into a json compatible with
        Azure Data Studio.

    .DESCRIPTION
        Takes an SSMS snippet file and produces a json string which can be 
        added (copied/pasted) to an Azure Data Studio snippet.

    .PARAMETER SourceFile
        The SSMS Snippet file to be converted.

    .EXAMPLE
        PS C:\> Get-SQLSnippet "MySnippetFile.snippet"

    .NOTES
        Function Name: Get-SQLSnippet
        Filename: Convert-SQLSnippet.ps1
        Author: Grant Quick 
        Modified date: 2021-04-13
        Version 1.0 - Initial Release
    #>

    [CmdletBinding()]
    param(
        [parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )
        ][string]$SourceFile
    )

    [xml]$snippetFile = Get-Content -Path $SourceFile -Encoding UTF8

    # Get the pertinent parts
    $title = $snippetFile.CodeSnippets.CodeSnippet.Header.Title
    $prefix = $snippetFile.CodeSnippets.CodeSnippet.Header.Shortcut
    $description = $snippetFile.CodeSnippets.CodeSnippet.Header.Description
    $rawCode = $snippetFile.CodeSnippets.CodeSnippet.Snippet.Code.'#cdata-section'

    if ($prefix -eq '') { $prefix = "snip" }

    # Start of code element formatting
    # Do this by constructing a json record

    # Add quotes around each line of code and put a comma at the end
    $OFS = "`n"
    $splitCode = $rawCode -split $OFS
    $quotedCode = $splitCode | ForEach-Object {'"' + $_ + '",'}

    # Remove superflous quotations and final comma
    $oneLiner = [string]$quotedCode
    $oneLiner = $oneLiner.Substring(1,$oneLiner.Length-3)

    # Build the json record
    $json = [ordered]@{
        "$title"=@{
            prefix=$prefix
            body=@(
                $oneLiner.Replace("	"," ")
            )
            description=$description
        }
    }

    # Convert to an actual json record, but avoid escaping characters in the code
    [string]$x = $json | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }

    # Tidy up the json string
    $x = $x.Substring(1,$x.Length-2)
    $y = $x.Trim()

    # Nicely format the code element
    $splitY = $y -split $OFS

    # Find where the code starts in order to indent each line to the same position
    $spaceCount = $splitY[3].IndexOf('"')
    $spacer = " " * $spaceCount

    # Find where the code element ends
    For ($i=0; $i -lt $splitY.count; $i++) {
        if($splitY[$i].IndexOf('"description":  "') -gt 0) {$descline = $i}
    }

    # Add the requisite number of spaces to each line of code
    For ($i=4; $i -lt $descline -1; $i++) {
        [string]$splitY[$i] = $spacer + $splitY[$i]
    }

    # Convert string array to string in order to output to a file
    # without including blank lines after each array item
    [string]$strSplitY = $splitY

    return $strSplitY
}

Function Convert-SQLSnippet {
    <#
    .SYNOPSIS
        Function to convert a target folder of SSMS snippet files into a single 
        Azure Data Studio snippet file.

    .DESCRIPTION
        When given a folder containing SSMS .snippet files, will convert all .snippets 
        into a single snippet file for use within Azure Data Studio. The snippets will
        be available immediately within ADS.

    .PARAMETER snippetFolder
        The folder containing SSMS snippets.
        Usually "C:\Users\<username>\Documents\SQL Server Management Studio\Code Snippets\SQL\My Code Snippets\"

    .PARAMETER outputFile
        The destination filename. 
        WARNING: If the file already exists, its content will be overwritten.
        Usually "C:\Users\<username>\AppData\Roaming\azuredatastudio\User\snippets\sql.json"

    .EXAMPLE
        PS C:\> Convert-SQLSnippet "C:\Users\<username>\Documents\SQL Server Management Studio\Code Snippets\SQL\My Code Snippets\" "C:\Users\<username>\AppData\Roaming\azuredatastudio\User\snippets\sql.json" 

    .NOTES
        Function Name: Convert-SQLSnippet
        Filename: Convert-SQLSnippet.ps1
        Author: Grant Quick 
        Modified date: 2021-04-13
        Version 1.0 - Initial Release
    #>
    [CmdletBinding()]
    param(
        [parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )
        ][string]$snippetFolder
        ,[parameter(
            Position=1,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )
        ][string]$outputFile
    )

    # Azure Data Studio snippet file placeholder text
    $y = '{
        // Place your snippets for sql here. Each snippet is defined under a snippet name and has a prefix, body and 
        // description. The prefix is what is used to trigger the snippet and the body will be expanded and inserted. Possible variables are:
        // $1, $2 for tab stops, $0 for the final cursor position, and ${1:label}, ${2:another} for placeholders. Placeholders with the 
        // same ids are connected.
        // Example:
        // "Print to console": {
        // 	"prefix": "log",
        // 	"body": [
        // 		"console.log(''''$1'''');",
        // 		"$2"
        // 	],
        // 	"description": "Log output to console"
        // }
        '
    # Count the number of snippet files
    $snippetCount = (Get-ChildItem $snippetFolder -Recurse -Filter *.snippet).Count 
    $i=0

    # Parse each snippet file
    Get-ChildItem $snippetFolder -Recurse -Filter *.snippet |

            ForEach-Object {
                $i++
                $x = Get-SQLSnippet $_.FullName
                $y = $y + $x 
                if ($i -lt $snippetCount) {$y = $y + ',' + "`n    "}
            }

    $y = $y + "`n}"

    # Output converted snippet string into a single file
    $y | Out-File $outputFile -Force -Encoding utf8
}

