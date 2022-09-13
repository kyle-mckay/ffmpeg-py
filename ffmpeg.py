import os
import subprocess
import glob
sScriptPath = os.path.dirname(os.path.realpath(__file__)) + "/"
sConfigPath = sScriptPath + "config.py"
bConfigExist = os.path.exists(sConfigPath)

# region Functions


def click_on_file(filename):
    '''Open document with default application in Python.'''
    try:
        os.startfile(filename)
    except AttributeError:
        subprocess.call(['open', filename])


def create_config():
    open(sConfigPath, 'x')
    config = open(sConfigPath, 'a')
    ConfigWrite = config.write(f"\
#Effects GUI console directly\n\
bVerbose = True # If `True` verbose messages are enabled in the console while script is running.\n\
bDisableStatus = False # Set to true if you wish to disable the calculating and displaying of status/progress bars in the script (can increase performance)\n\
# Initial Config\n\
sRootPath = 'D:\' # This is the root file path you want power-shell to begin scanning for media if you are wanting to scan all child items of this directory. *This becomes very important if you have `$bRecursiveSearch` set to `$False`*.\n\
bTest = False # If `True` Enables test mode. Test mode only scans and encodes a single source path defined in `bTestPath`. Destination file is saved to your `sExportedDataPath`.\n\
bTestPath = sRootPath + '\Downloads\TestFile.mkv' # Source Path to file you want to test the script on.\n\
sEncodePath = sRootPath + '\Encode\' # The folder/path where you wish to remporarely store encodes while they are being processed. *It is recommended to use a different location from any other files.*\n\
sExportedDataPath = '{sScriptPath}' # The folder/path where you want the exported files to be generated. 'Exported files' does not include encodes.\n\
bRecursiveSearch = False # This controls if you wish to scan the entire root folder specified in `sRootPath` for content. If `True`, all files, folders and subfolders will be subject to at least a scan attempt. If `False`, only the folders indicated in `sDirectoriesCSV` will be subject to a recursive scan.\n\
sDirectories = ['D:\Anime\','D:\TV\','D:\Movies\'] # If you want to only have power-shell scan specific folders for media, you can indicate all paths in this variable using CSV style formatting.\n\
# Exported Data\n\
bEncodeOnly = True # When this is `True`, only items identified as 'needing encode' as per the `Detect Medtadata > Video Metadata > Check if encoding needed` section. If `False` then all items will be added to the CSV regardless if encoding will take place for the file or not. *This does not change whether or not the file **will** be encoded, only if it is logged in the generated CSV file*\n\
bDeleteCSV = False # If `False` then `contents.csv` will be deleted after the script is finished. If `True` then `contents.csv` will **not** be deleted after the script is finished. Instead the next time it runs it will be written over.\n\
bAppendLog = True # If `False` then when a new encoding session begins, the contents of `Encode_Log.txt` are cleared. If `True` then the contents of said text file will append until cleared manually.\n\
bDeleteContents = True # If `False` then the `contents.txt` file generated at scanning will not be deleted after `contents.csv` is created. If `True` then `contents.txt` will be deleted after `contents.csv` is created.\n\
# Encode Config\n\
bRemoveBeforeScan = True # If `True` then  all files in `sEncodePath` are deleted prior to initiated a scan for media\n\
bEncodeAfterScan = True # If `False` then once the CSV is created the script skips the encoding process entirely. If `True` then the script will encode all identified files after the CSV is generated.\n\
iThreads = 2 # The number of cpu threads you wish to dedicate to ffmpeg. ")
# endregion


# region ImportConig
if bConfigExist:
    print("Config path exists, continuing script.")
    import config
else:
    print("Config path does not exist, initiating config creation...")
    create_config()
    print("Script created")
    print(
        f"Please review your config file before running this script again. Script is located in {sScriptPath}. Script will now exit.")
    sInput = input("Press any key to continue...")
    click_on_file(sConfigPath)
    quit()
# endregion
