
# ffmpreg
Powershell script for how I scan media files and encode them with ffmpeg

## Requirements
- FFMPEG needs to be installed and configured to work with CLI in powershell
- Powershell (obviously)

## Config In Detail

### Set-PSDebug

>`Set-PSDebug -Off`

Turns script debugging features on and off, sets the trace level, and toggles strict mode. If you want on, comment out this line

### Encode_Only 

>`$Encode_Only = $True`

When this is `$True`, only items identified as "needing encode" as per the `Detect Medtadata > Video Metadata > Check if encoding needed` section. If `$False` then all items will be added to the CSV regardless if encoding will take place for the file or not.

>This does not change whether or not the file **will** be encoded, only if it is logged in the generated CSV file

### rootencode

>`$rootencode = "D:\" `

This is the root file path you want power-shell to begin scanning for media.

> This becomes very important if you have `$alldirectories` set to `$False`

### alldirectories 

>`$alldirectories = $False `

This controls if you wish to scan the entire root folder for content.

- If `$True`, all files, folders and subfolders will be subject to at least a scan attempt
- If `$False`, only the folders indicated in `$directoriesCSV` will be subject to a recursive scan.

### directoriesCSV

>`$directoriesCSV = "$rootencode\Anime\,$rootencode\TV\,$rootencode\Movies\"`

or

>`$directoriesCSV = "directory1,directory2,directory3"`

If you want to only have power-shell scan specific folders for media, you can indicate them using CSV style formatting.

### EncodeAfterScan 

>`$EncodeAfterScan = $True `

- If `$False` then once the CSV is created the script skips the encoding process entirely.
- If `$True` then the script will encode after the CSV is generated

### DeleteCSV 

>`$DeleteCSV = $False `

- If `$False` then `contents.csv` will be deleted after the script is finished.
- If `$True` then `contents.csv` will **not** be deleted after the script is finished. Instead the next time it runs it will be written over.

### TestBool 

>`$TestBool = $False `

- If `$False` the script will scan all specified locations for files that need encoding
- If `$True` the script will scan only the path indicated in `$TestPath` and nothing else
