#config
Set-PSDebug -Off
cd D:\ #directory of root folder for monitored videos
d:\encode_scan.ps1
#Write-output “Encoding Log - New session:” | add-content .\encode_log.txt
$steps = (get-content D:\contents.csv).length
$step = 1
Import-Csv .\contents.csv | ForEach-Object {
    if ($($_.encode) -eq [bool]"True") {
        $percent = ($step/$steps)*100
        #Collect file details
          $inputFile = Split-Path $($_.path) -Leaf # to get name with extention
          $filename = Get-ChildItem $($_.path)
          $basename = $filename.BaseName #to get name only
          $outputpath = "D:\Encode\"+$basename+".mkv"
          $inputContainer = split-path -path $($_.path)
          Write-Progress -Activity "Encoding: $step/$steps" -Status "$filename" -PercentComplete $percent
          Write-Output "Working $filename"
          #Create new encode
          ffmpeg -i "$($_.path)" -b $($_.T_Bits_Ps) -maxrate $($_.T_Bits_Ps) -minrate $($_.T_Bits_Ps) -ab 64k -vcodec libx264 -acodec aac -strict 2 -ac 2 -ar 44100 -s $($_.T_height) -map 0 -y -threads 2 -v quiet -stats $outputpath
          
        #Check thar files still exist before removal
          $source = Test-Path $($_.path)
          $dest = Test-Path $outputpath

          if ($dest -eq [bool]”True” -and $source -eq [bool]”True”) {
            #Remove input file
              remove-item $($_.path)
            #Move new file to original folder
              move-item $outputpath -Destination $inputContainer
            #Generate data to lof converted files
              $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
              $log = $ts+" "+$basename+” encoded in “+$($_.T_height)+”p at “+($($_.T_Bits_Ps)/1000)+”kbp/s | Originally "+$($_.Bits_Ps)/1000+"kbp/s"
              write-output $log | add-content .\encode_log.txt
              $step++
              Write-Output "Complete"
          }
       
    }
    Write-Progress -Activity "Encoding: $step/$steps" -Status "$filename" -Completed
}