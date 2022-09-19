import os
import subprocess
import glob
import shutil
import sqlite3
from tabnanny import verbose
sScriptPath = os.path.dirname(os.path.realpath(__file__)) + "/" 
sConfigPath = sScriptPath + "config.py"
sDatabasePath = sScriptPath + "contents.db"
sRootPath = '' # to be defined for first time in function = fscan
sEncodePath = '' # to be defined for first time in function = fscan
sTemp = ''
# region Functions

def TestPath(path):
    bTestPath = os.path.exists(path)
    return bTestPath

def bExists():
    # Function's primary purpose is to re-test varaibles that confirm the file exists
    global bConfigExist, bDatabaseExist
    vprint([1, "Retesting paths for Config and Database"])
    bConfigExist = TestPath(sConfigPath)
    bDatabaseExist = TestPath(sDatabasePath)


def db_create():
    import configparser
    vprint([1, "Creating new SQLite3 database"])
    connection = sqlite3.connect('contents.db')
    cursor = connection.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS Disk_Content
                (Current_Bits INT, Pixel_Height INT, Target_Bits INT, Target_Height INT, Encode INT, Root_path TEXT, File_Path UNIQUE)''')
    
    connection.commit()
    connection.close()
    vprint([1, "Database created"])
    bExists()


def vprint(args):
    if verbose:
        # Confirm that the arguments starts with a number
        #sTemp = args[0]
        if str(args[0]).isnumeric():
            for v in args:
                # Check list for error level label and add string to end of message
                if v == 1:
                    sTemp = "INFO"
                elif v == 2:
                    sTemp = "WARNING"
                elif v == 3:
                    sTemp = "ERROR"
                else:
                    sTemp += ": " + v
            print(sTemp)
        else:
            vprint([2, "Verbose initiated with first value being non-numeric"])
            vprint(args)


def open_file(filename):
    '''Open document with default application in Python.'''
    try:
        os.startfile(filename)
    except AttributeError:
        subprocess.call(['open', filename])

def db_scan_new():
    # Scans directories for files and add's them to the database based on config settings
    print("This still needs work")

def db_remove_old():
    # Queries database for items that were scanned in a path no longer part of the "Root Path" and removes them
    print("This still needs work")

def db_wipe():
    print("This still need work")

def create_config():
    open(sConfigPath, 'x')
    config = open(sConfigPath, 'a')
    ConfigWrite = config.write(f"\
#Effects GUI console directly\n\
bVerbose = True # If `True` verbose messages are enabled in the console while script is running.\n\
bDisableStatus = False # Set to true if you wish to disable the calculating and displaying of status/progress bars in the script (can increase performance)\n\
# Initial Config\n\
sRootPath = '' # This is the root file path you want power-shell to begin scanning for media if you are wanting to scan all child items of this directory. *This becomes very important if you have `$bRecursiveSearch` set to `$False`*.\n\
bTest = False # If `True` Enables test mode. Test mode only scans and encodes a single source path defined in `bTestPath`. Destination file is saved to your `sExportedDataPath`.\n\
bTestPath = '' # Source Path to file you want to test the script on.\n\
sEncodePath = sRootPath + '\Encode\' # The folder/path where you wish to remporarely store encodes while they are being processed. *It is recommended to use a different location from any other files.*\n\
sExportedDataPath = '{sScriptPath}' # The folder/path where you want the exported files to be generated. 'Exported files' does not include encodes.\n\
bRecursiveSearch = False # This controls if you wish to scan the entire root folder specified in `sRootPath` for content. If `True`, all files, folders and subfolders will be subject to at least a scan attempt. If `False`, only the folders indicated in `sDirectoriesCSV` will be subject to a recursive scan.\n\
sDirectories = ['directory 1','directory 2','directory 3'] # If you want to only have power-shell scan specific folders for media, you can indicate all paths in this variable using CSV style formatting.\n\
# Exported Data\n\
bEncodeOnly = True # When this is `True`, only items identified as 'needing encode' as per the `Detect Medtadata > Video Metadata > Check if encoding needed` section. If `False` then all items will be added to the CSV regardless if encoding will take place for the file or not. *This does not change whether or not the file **will** be encoded, only if it is logged in the generated CSV file*\n\
bDeleteDB = False # If `False` then `contents.csv` will be deleted after the script is finished. If `True` then `contents.csv` will **not** be deleted after the script is finished. Instead the next time it runs it will be written over.\n\
bAppendLog = True # If `False` then when a new encoding session begins, the contents of `Encode_Log.txt` are cleared. If `True` then the contents of said text file will append until cleared manually.\n\
bDeleteContents = True # If `False` then the `contents.txt` file generated at scanning will not be deleted after `contents.csv` is created. If `True` then `contents.txt` will be deleted after `contents.csv` is created.\n\
# Encode Config\n\
bRemoveBeforeScan = True # If `True` then  all files in `sEncodePath` are deleted prior to initiated a scan for media\n\
bEncodeAfterScan = True # If `False` then once the CSV is created the script skips the encoding process entirely. If `True` then the script will encode all identified files after the CSV is generated.\n\
iThreads = 2 # The number of cpu threads you wish to dedicate to ffmpeg. ")


def fscan():
    global sRootPath, sEncodePath
    # Check if using root path or list for locations
    if config.bRecursiveSearch:
        sRootPath = config.sRootPath
        vprint(
            [1, f"Recursive search enabled. Will begin scanning {sRootPath}"])
    else:
        sRootPath = config.sDirectories
        vprint(
            [1, f"Recursive Search disabled. Will begin scanning the following directories:\n {sRootPath}"])
    
    # set encode path
    sEncodePath = config.sEncodePath

    # Remove old runs of script to clear up data
    if config.bRemoveBeforeScan:
        vprint([1, "Removal of old encode's is enabled. Processing file removal."])
        for root, dirs, files in os.walk(config.sEncodePath):
            # Remove all files in path first, then directories
            for f in files:
                os.unlink(os.path.join(root, f))
            for d in dirs:
                shutil.rmtree(os.path.join(root, d))
    else:
        vprint([1,"Removal of old encode's is disabled."])

    # Test folder paths before proceeding
    if TestPath(sRootPath):
        # If root path is found
        vprint([1,"Root path found"])
    else:
        # If root path is not found
        vprint([3,"Root Path not found, aborting script"])
        quit()
    if TestPath(sEncodePath):
        # If Encode Path is found
        vprint([1,"Encode path found"])
    else:
        # If encode path is not found
        if sEncodePath == "":
            # Inform if path in config is null or empty
            vprint([2,"Encode path is config is null or empty"])
        else:
            # Inform if path just does not exist
            vprint([2,f"Encode path not found, attempting to create folder. \
                \n Encode Path: {sEncodePath}"])

        if TestPath(sEncodePath) == False:
            if config.bRecursiveSearch == True:
                vprint([2,"Failed to create folder, redirecting to root path."])
                sEncodePath = sRootPath
            else:
                vprint([3,"Failed to create folder. As root path is list of directories script will be aborted."])
                quit()
        # Start Scanning
        if config.bDeleteDB == False:
            # if database is not set to overwrite mode
            db_remove_old() # check if database contains path(s) different from sRootPath global variable
            # identify new items
        # else
            db_wipe()
        db_scan_new()
            # scan all items in path(s)

        


    #     # Start Scanning
    #     #Generate Contents
    #     #Generate Contents Lists and repeat based on number of directories
    #     out-file $sExportedDataPath\contents.txt #create empty contents file
    #     If ($bTest -eq $True) {
    #         $bTestPath | Add-Content $sExportedDataPath\contents.txt # If testmode active, export single path to contents.txt
    #         #Otherwise follow default scan export
    #     }
    #     ElseIf ($bRecursiveSearch -eq $False) {
    #         $sDirectoriesCSV.Split(",") | ForEach-Object {
    #             Get-ChildItem -Path $_ -Recurse -Include "*" | ForEach-Object { $_.FullName } | Write-Output | Add-Content $sExportedDataPath\contents.txt
    #         }
    #     }
    #     Else { Get-ChildItem -Path $sRootPath -Recurse -Include "*" | ForEach-Object { $_.FullName } | Write-Output | Add-Content $sExportedDataPath\contents.txt }
    #     #Detect Metadata
    #     #Begin scanning files
    #     If ($bDisableStatus -eq $False) { $activity = "Collecting Metadata from files" } # If bDisableStatus is False then updates the gui terminal with status bar
    #     #Start grabbing metadata based on contents
    #     $iSteps = (get-content $sExportedDataPath\contents.txt).length
    #     $iStep = 0
    #     $iPercent = 0
    #     $ffmpeg = @(
    #         foreach ($sContentsLine in Get-Content $sExportedDataPath\contents.txt) {
    #             If ($bDisableStatus -eq $False) { Write-Progress -Activity $activity -Status "Progress:" -PercentComplete $iPercent } # If bDisableStatus is False then updates the gui terminal with status bar
    #             #Check file folder and parent folder for ".skip" file to skip the encoding of these folders
    #             $sFilePath = Split-Path -Path $sContentsLine
    #             $sSkipPath = $sFilePath + "\.skip"
    #             $sParentPath = Split-path -Parent $sContentsLine
    #             $sParentSkipPath = $sParentPath + "\.skip"
    #             #If skip file not found in either path then get video metadata
    #             $bScanFile = $True # Reset ScanFile for each item in contents.txt

    #             If ($bTest -eq $False) {
    #                 If ((Test-Path -Path $sSkipPath) -and (Test-Path -Path $sParentSkipPath)) { $bScanFile = $False }
    #             } # Runs if test mode is off - Looks for a .skip file in either the source directory or parent directy. If skip file is found, do not attempt to scan/encode file
    #             If (Test-Path -Path $sContentsLine -PathType Container) { $bScanFile = $False } # If path is to folder, do not attempt to scan/encode path
    #             If ($bScanFile -eq $True) {
    #                 #Video Metadata
    #                 #$iBits = ffprobe "$sContentsLine" -v error -select_streams v:0  -show_entries stream_tags=BPS -of default=noprint_wrappers=1:nokey=1 #get the video kbps via tag (very accurate)
    #                 $iBits = ffprobe "$sContentsLine" -v quiet -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 #if tag blank then get via format (less accurate)
    #                 $iHeight = ffprobe "$sContentsLine"  -v quiet -select_streams v:0  -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 # get video width

    #                 # Logic for desired bitrate based on video height
    #                 if ([int]$iHeight -le 480) {
    #                     $kbps = 1000
    #                     $theight = "640x480"
    #                 }
    #                 elseif ([int]$iHeight -ge 1000) {
    #                     $kbps = 2500
    #                     $theight = "1920x1080"
    #                 }
    #                 else {
    #                     $kbps = 2000
    #                     $theight = "1280x720"
    #                 }

    #                 # Check if encoding needed
    #                 $iScaleBits = [int]$kbps * 1000
    #                 If ($bTest -eq $True) { $bEncode = $True } ElseIf ([int]$iBits -gt $iScaleBits * 1.3) { $bEncode = $True } else {
    #                     $bEncode = $False
    #                     Write-Verbose -Message "Encoding determined not needed for path - $sContentsLine"
    #                 } # Check if bitrate is greater than target kbp/s if so mark for encode

    #                 # Add data to array
    #                 If ($bTest -eq $True) {
    #                     EncodeCSV
    #                     Write-Verbose -Message "Adding to CSV as bTest is True $sContentsLine"
    #                 } #Encode test path even if it doesnt need it
    #                 ElseIf ($bEncodeOnly -eq $True) {
    #                     #If encode only is true, only import items needing encode into csv
    #                     If ($bEncode -eq $True) {
    #                         EncodeCSV
    #                         Write-Verbose -Message "Adding to CSV as bEncode is True - $sContentsLine"
    #                     }
    #                 }
    #                 Else {
    #                     #If encode only is false, import all items into csv
    #                     EncodeCSV
    #                     Write-Verbose -Message "Adding to CSV as bEncode is False - $sContentsLine"
    #                 }

    #             }
    #             Else {
    #                 Write-Verbose -Message "Skip file exists, or path is folder. Skipping - $sContentsLine"
    #             }
    #             If ($bDisableStatus -eq $False) {
    #                 $iStep++
    #                 $iPercent = ($iStep / $iSteps) * 100
    #             } # If bDisableStatus is False then updates the gui terminal with status bar

    #         }
    #     )
    # }
# endregion


bExists()  # Check if required files exist before proceeding
# region Check Config
# check if config file exists
if bConfigExist:
    # if it does, import config file
    import config
    verbose = config.bVerbose
    vprint([1, "Config path exists, continuing script."])
else:
    # if it does not, create the config file and prompt user to review
    verbose = True
    vprint([1, "Config path does not exist, initiating config creation."])
    create_config()
    vprint([1, "Script created"])
    vprint(
        [1, f"Please review your config file before running this script again. Script is located in {sScriptPath}. Script will now exit."])
    sInput = input("Press any key to continue...")
    open_file(sConfigPath)
    quit()

# Verify config validity
if config.bRecursiveSearch == False and config.sDirectories == "":
    vprint([3,f"Configuration is set with 'bRecursiveSearch' = {config.bRecursiveSearch}"])
# endregion

# region Check Database
if bDatabaseExist:
    # database has already been created
    vprint([1, f"Database file exists in path: {sDatabasePath}"])
else:
    # database does not exist
    vprint([1, f"Database file does not exist in path: {sDatabasePath}"])
    db_create()
    if bDatabaseExist:
        vprint([1, "Database creation sucessfull"])
    else:
        vprint(
            [3, f"Database creation failed, cannot be detected in root path: \n{sRootPath}"])

# region start script
fscan()

# endregion
