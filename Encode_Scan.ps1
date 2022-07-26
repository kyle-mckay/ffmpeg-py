#config
Set-PSDebug -Off
$Encode_Only = $True #Sets output to only list items needing encode in final csv. If false all items will be added to the CSV regardless if encode will take place
$rootencode = "D:\" #where you want to monitor video files for encode
Set-Location $rootencode # set directory of root folder for monitored videos
$alldirectories = $False # Set to false if you do not wish to scan the entire disk
$directoriesCSV = "$rootencode\Anime\,$rootencode\TV\,$rootencode\Movies\" # CSV of all directories you want scanned
$EncodeAfterScan = $False #Set this value to true if you would like to becin encoding after contents.csv is generated
$DeleteCSV = $False #Set this value to true if you wish to delete contents.csv after encoding compelte
$TestBool = $False #Enable this if you wish to run the current settings using a single file
#Functions
    
    Function Encode_CSV {
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
    Function BeginEncode{
        #Begin encoding
        $steps = (get-content $rootencode\contents.csv).length
        $step = 1

        #Loop through contents.csv and encode each file identified
        Import-Csv .\contents.csv | ForEach-Object {
            if ($($_.encode) -eq "TRUE") {
                $percent = ($step/$steps)*100
                #Collect file details
                    $filename = Get-ChildItem $($_.path)
                    $basename = $filename.BaseName #to get name only
                    $outputpath = "$rootencode\Encode\"+$basename+".mkv"
                    $inputContainer = split-path -path $($_.path)
                    Write-Progress -Activity "Encoding: $step/$steps" -Status "$filename" -PercentComplete $percent
                    Write-Output "Working $filename"
                
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
                    $log = $ts+" "+$basename+” encoded in “+$($_.T_height)+”p at “+($($_.T_Bits_Ps)/1000)+”kbp/s | Originally "+$($_.Bits_Ps)/1000+"kbp/s"
                    write-output $log | add-content .\encode_log.txt
                    $step++
                    Write-Output "Complete"
                }
    
            }
            Write-Progress -Activity "Encoding: $step/$steps" -Status "$filename" -Completed
        }
    }
    Function GenerateContents {
        #Generate Contents Lists and repeat based on number of directories
        out-file $rootencode\contents.txt #create empty contents file
        If ($TestBool -eq $True){Write-Host $TestPath | Add-Content $rootencode\contents.txt} # If testmode active, export single path to contents.txt 
        #Otherwise follow default scan export
        If ($alldirectories -eq $False){
            $directoriesCSV | ForEach-Object {
                Get-ChildItem -Path $gc -Recurse -Include "*" | ForEach-Object {$_.FullName} | Write-Output | Add-Content $rootencode\contents.txt
            }
        }Else{Get-ChildItem -Path $rootencode -Recurse -Include "*" | ForEach-Object {$_.FullName} | Write-Output | Add-Content $rootencode\contents.txt}
    }

    Function DetectMetadata {
        #Begin scanning files
        $activity = "Collecting Metadata from files"

        #Start grabbing metadata based on contents
        $steps = (get-content $rootencode\contents.txt).length
        $step = 0
        $percent = 0
        $ffmpeg =@(
            foreach($line in Get-Content $rootencode\contents.txt)
                                                                                                                                                                                                        {
            Write-Progress -Activity $activity -Status "Progress:" -PercentComplete $percent
            
            #Check file folder and parent folder for ".skip" file to skip the encoding of these folders
            $filepath = Split-Path -Path $line
            $filepath = $filepath + “\*.skip”
            $parentpath = Split-path -Parent $filepath
            $parentpath = $parentpath + “\*.skip”
            #If skip file not found in either path then get video metadata
            if (!(Test-Path $filepath) -and !(Test-Path $parentpath))
            {
            #Video Metadata
                #$bits = ffprobe “$line” -v error -select_streams v:0  -show_entries stream_tags=BPS -of default=noprint_wrappers=1:nokey=1 #get the video kbps via tag (very accurate)
                $bits = ffprobe “$line” -v quiet -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 #if tag blank then get via format (less accurate)
                $height = ffprobe “$line”  -v quiet -select_streams v:0  -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 # get video width
            
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
                    If ([int]$bits -gt $scale_bits*1.3) {$encode = $True}else {$encode = $False} #Check if bitrate is greater than target kbp/s if so mark for encode
            
                #Add data to array
                    If ($Encode_Only -eq $True) {
                        #If encode only is true, only import items needing encode into csv
                        If ($encode -eq $True) {Encode_CSV}
                    }Else {
                        #If encode only is false, import all items into csv
                        Encode_CSV
                    }

            }
            else
            {
            Write-Host "Skip file exists, will not be added. Path - " Split-path -Parent $filepath
            }
            $step++
            $percent = ($step/$steps)*100
        }
        )
    }
    Function ExportCSV {
        $ffmpeg | Export-Csv -Path $rootencode\contents.csv #export array to csv
        Write-Progress -Activity $activity -Status "Ready" -Completed
        remove-item $rootencode\contents.txt
        #Import-Csv .\contents.csv | Out-GridView # display csv #view CSV when complete
    }
    Function DefaultBehavior {
        GenerateContents
        DetectMetadata
        ExportCSV
    }
    Function TestMode {
        $TestPath = "$RootEncode\Media\Downloads\TestFile.mkv"
        GenerateContents
        DetectMetadata
        ExportCSV
    }

If ($TestBool -eq $False) {DefaultBehavior} Else {TestMode}
If ($EncodeAfterScan -eq $True) {BeginEncode} #Begin video encode if turned on in config
If ($DeleteCSV -eq $True) {remove-item $rootencode\contents.csv} #Remove contents csv if marked true in config