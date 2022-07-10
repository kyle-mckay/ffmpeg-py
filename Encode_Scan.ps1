#config
Set-PSDebug -Off
$Encode_Only = [bool]"True" #Sets output to only list items needing encode in final csv
cd D:\ #directory of root folder for monitored videos
$activity = "Collecting Metadata from files"
Function Encode_CSV {
    [pscustomobject]@{
        Bits_Ps = $bits
        height = $height
        T_Bits_Ps = $scale_bits
        T_height = $theight
        Encode = $encode
        Path = $line
    }

}

#Running code below

#Generate Contents Lists and repeat based on number of directories
out-file D:\contents.txt #create empty contents file
$d = 3 # number of directories
For ($i = 1; $i -le 3; $i++) {
    if ($i -eq 1) {$gc = "D:\TV\"}Elseif ($i -eq 2) {$gc = "D:\Movies\"}Elseif ($i -eq 3) {$gc = "D:\Anime\"} 
    Get-ChildItem -Path $gc -Recurse -Include "*" | % {$_.FullName} | Write-Output | Add-Content D:\contents.txt

}

#Start grabbing metadata based on contents
$steps = (get-content D:\contents.txt).length
$step = 0
$percent = 0
$ffmpeg =@(
    foreach($line in Get-Content D:\contents.txt)
    {
        Write-Progress -Activity $activity -Status "Progress:" -PercentComplete $percent
        
        #Check file folder and parent folder for ".skip" file to skip the encoding of these folders
        $filepath = Split-Path -Path $line
        $filepath = $filepath + “\*.skip”
        $parentpath = Splir-path -Parent $filepath
        $parentpath = $parentpath + “\*.skip”
        #If skip file not found in either path then get video metadata
        if (!(Test-Path $filepath) -and !(Test-Path $parentpath)
        {
           #Video Metadata
        #$bits = ffprobe “$line” -v error -select_streams v:0  -show_entries stream_tags=BPS -of default=noprint_wrappers=1:nokey=1 #get the video kbps via tag (accurate)
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
            If ([int]$bits -gt $scale_bits*1.3) {$encode = "True"}else {$encode = "False"} #Check if bitrate is greater than target kbp/s if so mark for encode
        
            #Add data to array
            If ($Encode_Only -eq [bool]"True") {
                #If encode only is true, only import items needing encode into csv
                If ($encode -eq [bool]"True") {Encode_CSV}
            }Else {
                #If encode only is false, import all items into csv
                Encode+CSV
            }

        }
        else
        {
          Write-Host "skip file exists, will not be added"
        }
         $step++
         $percent = ($step/$steps)*100
    }
)
$ffmpeg | Export-Csv -Path D:\contents.csv #export array to csv
Write-Progress -Activity $activity -Status "Ready" -Completed
remove-item D:\contents.txt
#Import-Csv .\contents.csv | Out-GridView # display csv #view CSV when complete