
# Table of Contents

- [Table of Contents](#table-of-contents)
- [About powershell-ffmpeg](#about-powershell-ffmpeg)
  - [Requirements](#requirements)
  - [Simplified Script Flow](#simplified-script-flow)
  - [Config In Detail](#config-in-detail)

# About powershell-ffmpeg

This repo contains a script that i've put together using powersell as the base language. 

## Requirements

- FFMPEG needs to be installed and configured to work with CLI in powershell.

  - [How to install ffmpeg](https://gist.github.com/barbietunnie/47a3de3de3274956617ce092a3bc03a1) (Github)

- Powershell

## Simplified Script Flow

1. Powershell begins scanning all indicated directories. Each file and folder under that path is added to contents.txt
1. Powershell will begin scanning through each file individually, skipping folders, and and attempts to determine current bitrate, resolution and calculate if the file requires encoding when compared to presets. All files scanned are added to `contents.csv` with the scanned data based on configuration.
1. When `contents.csv` is generated powershell will begin going through each line. If encoding is required it will begin the encode operation by passing through information to ffmpeg.
1. When the file encode is complete, it will delete the source file and move the new file to the same directory with the same naming convention.

## Config In Detail

|Variable Name|Type|Default/Example|Description/Comments|
|--|--|--|--|
|`Set-PSDebug -Off`| cmdlet |Not commented out|Turns script debugging features off, sets the trace level, and toggles strict mode.|
|`$bVerbose`|Boolean|`= $True`|If `$True` verbose messages are enabled in the console while script is running.|
|`$bTest`|Boolean|`= $False`|If `$True` Enables test mode. Test mode only scans and encodes a single source path defined in `$bTestPath`. Destination file is saved to your `$sExportedDataPath`.|
|`$bTestPath`|String|`= "D:\Testfile.mkv"`|Source Path to file you want to test the script on.|
|`$sRootPath`|String|`= "D:\"`|This is the root file path you want power-shell to begin scanning for media if you are wanting to scan all child items of this directory. *This becomes very important if you have `$bRecursiveSearch` set to `$False`*.|
|`$sEncodePath`|String|`= "$rootencode\Encode\"`|The folder/path where you wish to remporarely store encodes while they are being processed. *It is recommended to use a different location from any other files.*|
|`$sExportedDataPath`|String|`=  $sScriptPath`|The folder/path where you want the exported files to be generated. 'Exported files' does not include encodes.|
|`$bRecursiveSearch`|Boolean|`=  $False`|This controls if you wish to scan the entire root folder specified in `$sRootPath` for content. If `$True`, all files, folders and subfolders will be subject to at least a scan attempt. If `$False`, only the folders indicated in `$sDirectoriesCSV` will be subject to a recursive scan.|
|`$sDirectoriesCSV`|String|`= "D:\Anime\,D:\TV\,D:\Movies\"`|If you want to only have power-shell scan specific folders for media, you can indicate all paths in this variable using CSV style formatting.|
|`$bDisableStatus`|Boolean|`= $True`|Set to true if you wish to disable the calculating and displaying of status/progress bars in the script (can increase performance)|
|`$bEncodeOnly`|Boolean|`=  $True`|When this is `$True`, only items identified as "needing encode" as per the `Detect Medtadata > Video Metadata > Check if encoding needed` section. If `$False` then all items will be added to the CSV regardless if encoding will take place for the file or not. *This does not change whether or not the file **will** be encoded, only if it is logged in the generated CSV file*|
|`$bDeleteCSV`|Boolean|`=  $False`|If `$False` then `contents.csv` will be deleted after the script is finished. If `$True` then `contents.csv` will **not** be deleted after the script is finished. Instead the next time it runs it will be written over.|
|`$bAppendLog`|Boolean|`=  $True`|If `$False` then when a new encoding session begins, the contents of `Encode_Log.txt` are cleared. If `$True` then the contents of said text file will append until cleared manually.|
|`$bDeleteContents`|Boolean|`=  $True`|If `$False` then the `contents.txt` file generated at scanning will not be deleted after `contents.csv` is created. If `$True` then `contents.txt` will be deleted after `contents.csv` is created.|
|`$bRemoveBeforeScan`|Boolean|`= $True`|If `$True` then  all files in `$sEncodePath` are deleted prior to initiated a scan for media
|`$bEncodeAfterScan`|Boolean|`=  $True`|If `$False` then once the CSV is created the script skips the encoding process entirely. If `$True` then the script will encode all identified files after the CSV is generated.|
