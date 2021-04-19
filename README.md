# Convert-SQLSnippet
PowerShell script to convert SQL Server Management Studio (SSMS) snippets to Azure Data Studio snippets

## Script Contents
Two functions are provided, **Get-SQLSnippet** which takes a single SSMS snippet file and outputs a json string that can be included within an Azure Data Studio snippet file, and **Convert-SQLSnippet** which takes a folder containing snippet files and converts them all into a single complete Azure Data Studio snippet file ready for immediate use within ADS. Convert-SQLSnippet calls Get-SQLSnippet to parse each file.

## Usage
To load the functions into PowerShell, run the following from the directory that contains the script:
```PowerShell
.\Convert-SQLSnippet.ps1
```

To run a conversion on a target directory containing .snippet files and produce a single consolidated ADS-compatible snippet file, run (for example):
```PowerShell
Convert-SQLSnippet "C:\Users\<username>\Documents\SQL Server Management Studio\Code Snippets\SQL\My Code Snippets\" "C:\Users\<username>\AppData\Roaming\azuredatastudio\User\snippets\sql.json" 
```

To run a conversion on a single file and return a json string of and ADS-compatible snippet, run (for example):
```PowerShell
Get-SQLSnippet "MySnippetFile.snippet"
```

## Authors
* **Grant Quick** - *Initial work* - [GrantQuick](https://github.com/GrantQuick)