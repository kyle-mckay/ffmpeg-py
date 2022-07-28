$sScriptPath = split-path -parent $MyInvocation.MyCommand.Definition # Gets the path of the script file being executed
#config
    # Initial Config
    Set-PSDebug -Off
    $bVerbose = $False
    $bTest = $False # Enable this if you wish to run the current settings using a single file
    $bTestPath = $sRootPath+"\Downloads\TestFile.mkv" # Path for file to test encode on
    $sRootPath = "D:\" # Where you want to monitor video files for encode
    $sEncodePath = "$sRootPath\Encode\" # Path or folder name where you would like your encodes to be stored while being created
    $sExportedDataPath = $sScriptPath # Where you want your exported data to be stored
    $bRecursiveSearch = $False # Set to false if you do not wish to scan the entire disk
    $sDirectoriesCSV = "D:\Anime\,D:\TV\,D:\Movies\" # CSV of all directories you want scanned
    $bDisableStatus = $True # Set to true if you wish to disable the calculating and displaying of status/progress bars in the script (can increase performance)
    # Exported Data
    $bEncodeOnly = $True # Sets output to only list items needing encode in final csv. If false all items will be added to the CSV regardless if encode will take place
    $bDeleteCSV = $False # Set this value to true if you wish to delete contents.csv after encoding compelte
    $bAppendLog = $True # Set this to true if you wish to append encode log data as new lines instead of starting fresh with each execution
    $bDeleteContents = $True # Set this to true if you wish to keep the contents.txt file generated during initial scan
    # Encode Config
    $bRemoveBeforeScan = $True # Set this value if you would like to delete all old media that may be left behind in the root encoding folder
    $bEncodeAfterScan = $True # Set this value to true if you would like to becin encoding after contents.csv is generated
#Functions
    Function RemoveOldEnc {
        Remove-Item $sEncodePath -Include *.* -Recurse
    }
    Function EncodeCSV {
        # Adds current scanned item to Encode.csv if it meets the requirements
        [pscustomobject]@{
            Bits_Ps = $bits
            height = $height
            T_Bits_Ps = $scale_bits
            T_height = $theight
            Encode = $encode
            Path = $line
        }
    }
    # Begins the encoding process of all items marked "Encode = TRUE" in contents.csv
    Function BeginEncode {
        #Begin encoding
        If ($bAppendLog -eq $False) {Clear-Content -Path $sExportedDataPath\encode_log.txt} # Clears log file at start of encode if true, otherwise appends continuously
        If ($bDisableStatus -eq $False) {
            $steps = (get-content $sExportedDataPath\contents.csv).length
            $step = 1
        }
        #Loop through contents.csv and encode each file identified
            Import-Csv $sExportedDataPath\contents.csv | ForEach-Object {
            if ($($_.encode) -eq "TRUE") {
                If ($bDisableStatus -eq $False) {
                    $percent = ($step/$steps)*100
                }
                #Collect file details
                    $filename = Get-ChildItem $($_.path)
                    $basename = $filename.BaseName #to get name only
                    $outputpath = $sEncodePath+$basename+".mkv"
                    $inputContainer = split-path -path $($_.path)
                    If ($bDisableStatus -eq $False) {Write-Progress -Activity "Encoding: $step/$steps" -Status "$filename" -PercentComplete $percent}
                    Write-Verbose -Message "Working $filename"
                #Create new encode
                    ffmpeg -i "$($_.path)" -b $($_.T_Bits_Ps) -maxrate $($_.T_Bits_Ps) -minrate $($_.T_Bits_Ps) -ab 64k -vcodec libx264 -acodec aac -strict 2 -ac 2 -ar 44100 -s $($_.T_height) -map 0 -y -threads 2 -v quiet -stats $outputpath
                #Check thar files still exist before removal
                    $source = Test-Path $($_.path)
                    $dest = Test-Path $outputpath
                    if ($dest -eq $True -and $source -eq $True) {
                        #Remove input file
                            remove-item $($_.path)
                        #Move new file to original folder
                            move-item $outputpath -Destination $inputContainer
                        #Populate log of encoded files
                            $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
                            $log = $ts+" "+$basename+" encoded in "+$($_.T_height)+"p at "+($($_.T_Bits_Ps)/1000)+"kbp/s | Originally "+$($_.Bits_Ps)/1000+"kbp/s"
                            write-output $log | add-content $sExportedDataPath\encode_log.txt
                            If ($bDisableStatus -eq $False) {
                                $step++
                            }
                            Write-Verbose -Message "Complete"
                    }
            }
            If ($bDisableStatus -eq $False) {Write-Progress -Activity "Encoding: $step/$steps" -Status "$filename" -Completed}
        }
    }
# End Fnctions
# Start Scanning
    Set-Location $sRootPath # set directory of root folder for monitored videos
    if ($bVerbose -eq $True) {$VerbosePreference = "Continue"} Else {$VerbosePreference = "SilentlyContinue"} # If verbose is on, shows verbose messages in console
    If ($bRemoveBeforeScan -eq $True) {RemoveOldEnc} # Remove old encodes
    #Generate Contents
        #Generate Contents Lists and repeat based on number of directories
        out-file $sExportedDataPath\contents.txt #create empty contents file
        If ($bTest -eq $True){
            $bTestPath | Add-Content $sExportedDataPath\contents.txt # If testmode active, export single path to contents.txt 
            #Otherwise follow default scan export
        }ElseIf ($bRecursiveSearch -eq $False){
            $sDirectoriesCSV.Split(",") | ForEach-Object {
                Get-ChildItem -Path $_ -Recurse -Include "*" | ForEach-Object {$_.FullName} | Write-Output | Add-Content $sExportedDataPath\contents.txt
            }
        }Else{Get-ChildItem -Path $sRootPath -Recurse -Include "*" | ForEach-Object {$_.FullName} | Write-Output | Add-Content $sExportedDataPath\contents.txt}
    #Detect Metadata
        #Begin scanning files
            If ($bDisableStatus -eq $False) {$activity = "Collecting Metadata from files"}
        #Start grabbing metadata based on contents
            $steps = (get-content $sExportedDataPath\contents.txt).length
            $step = 0
            $percent = 0
            $ffmpeg =@(
                foreach($line in Get-Content $sExportedDataPath\contents.txt){
                    If ($bDisableStatus -eq $False) {Write-Progress -Activity $activity -Status "Progress:" -PercentComplete $percent}
                    #Check file folder and parent folder for ".skip" file to skip the encoding of these folders
                        $filepath = Split-Path -Path $line
                        $spath = $filepath + "\.skip"
                        $parentpath = Split-path -Parent $line
                        $pspath = $parentpath + "\.skip"
                    #If skip file not found in either path then get video metadata
                        $ScanFile = $True # Reset ScanFile for each item in contents.txt

                        If ($bTest -eq $False) {
                            If ((Test-Path -Path $spath) -and (Test-Path -Path $pspath)) {$ScanFile = $False}
                        } # Checks if TestMode is enabled, if not then scans for skip file. If found scan of file is skipped
                        If (Test-Path -Path $line -PathType Container) {$ScanFile = $False} # Checks if path is to folder
                        If ($ScanFile -eq $True) {
                    #Video Metadata
                        #$bits = ffprobe "$line" -v error -select_streams v:0  -show_entries stream_tags=BPS -of default=noprint_wrappers=1:nokey=1 #get the video kbps via tag (very accurate)
                        $bits = ffprobe "$line" -v quiet -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 #if tag blank then get via format (less accurate)
                        $height = ffprobe "$line"  -v quiet -select_streams v:0  -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 # get video width
                    
                        #logic for bps based on height
                            if ([int]$height -le 480) {
                                $kbps = 1000
                                $theight = "640x480"
                            }elseif ([int]$height -ge 1000) {
                                $kbps = 2500
                                $theight = "1920x1080"
                            }else {
                                $kbps = 2000
                                $theight = "1280x720"
                            }
                    
                        #check if encoding needed
                            $scale_bits = [int]$kbps*1000
                            If($bTest -eq $True) {$encode = $True} ElseIf ([int]$bits -gt $scale_bits*1.3) {$encode = $True} else {
                                $encode = $False
                                Write-Verbose -Message "Encoding determined not needed for path - $line"
                            } #Check if bitrate is greater than target kbp/s if so mark for encode
                    
                        #Add data to array
                            If ($bTest -eq $True) {
                                EncodeCSV
                                Write-Verbose -Message "Adding to CSV as TestBool is True $line"
                            } #Encode test path even if it doesnt need it
                            ElseIf ($bEncodeOnly -eq $True) {
                                #If encode only is true, only import items needing encode into csv
                                If ($encode -eq $True) {
                                    EncodeCSV
                                    Write-Verbose -Message "Adding to CSV as Encode_Only is True - $line"
                                }
                            }Else {
                                #If encode only is false, import all items into csv
                                EncodeCSV
                                Write-Verbose -Message "Adding to CSV as Encode_Only is False - $line"
                            }

                    }Else {
                        Write-Verbose -Message "Skip file exists or path is folder, will not be added to CSV. Path - $line"
                    }
                    $step++
                    $percent = ($step/$steps)*100
                }
            )
#Export CSV
    $ffmpeg | Export-Csv -Path $sExportedDataPath\contents.csv #export array to csv
    If ($bDisableStatus -eq $False) {Write-Progress -Activity $activity -Status "Ready" -Completed}        
    If ($bDeleteContents -eq $True) {remove-item $sExportedDataPath\contents.txt}
    If ($bEncodeAfterScan -eq $True) {BeginEncode} #Begin video encode if turned on in config
    If ($bDeleteCSV -eq $True) {remove-item $sExportedDataPath\contents.csv} #Remove contents csv if marked true in config
